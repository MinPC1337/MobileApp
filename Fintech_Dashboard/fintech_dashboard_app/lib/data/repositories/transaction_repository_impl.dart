import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/transaction_entity.dart';
import '../../domain/repositories/transaction_repository.dart';
import '../data_sources/local/database_helper.dart';
import '../models/transaction_model.dart';

class TransactionRepositoryImpl implements TransactionRepository {
  final DatabaseHelper dbHelper;
  final FirebaseFirestore firestore;

  TransactionRepositoryImpl({required this.dbHelper, required this.firestore});

  @override
  Future<void> addTransaction(TransactionEntity transaction) async {
    // 1. Chuyển đổi Entity sang Model để làm việc với Data Source
    final transactionModel = TransactionModel.fromEntity(transaction);
    final db = await dbHelper.database;

    // 2. LƯU VÀO MÁY TRƯỚC (SQLite)
    // is_synced lúc này mặc định là 0 (false)
    final localId = await db.insert('transactions', transactionModel.toMap());
    final firestoreMap = transactionModel.toMap();
    firestoreMap['id'] = localId;

    // 3. ĐỒNG BỘ LÊN MÂY (Firebase)
    try {
      await firestore
          .collection('users')
          .doc(transaction.userId)
          .collection('transactions')
          .doc(localId.toString())
          .set(firestoreMap);

      // 4. NẾU THÀNH CÔNG -> Cập nhật lại trạng thái is_synced trong SQLite
      await db.update(
        'transactions',
        {'is_synced': 1},
        where: 'id = ?',
        whereArgs: [localId],
      );
    } catch (e) {
      // Nếu lỗi (mất mạng), is_synced vẫn là 0.
      // Hàm syncPendingTransactions sẽ xử lý sau.
    }
  }

  @override
  Future<void> updateTransaction(TransactionEntity transaction) async {
    if (transaction.id == null) {
      throw Exception("Không thể cập nhật giao dịch không có ID");
    }

    // 1. Chuyển đổi Entity sang Model
    final transactionModel = TransactionModel.fromEntity(transaction);

    // 2. Cập nhật trong SQLite, đánh dấu là chưa đồng bộ
    final db = await dbHelper.database;
    await db.update(
      'transactions',
      transactionModel.toMap()..['is_synced'] = 0,
      where: 'id = ?',
      whereArgs: [transaction.id],
    );

    // 3. Cố gắng cập nhật lên Firestore
    try {
      await firestore
          .collection('users')
          .doc(transaction.userId)
          .collection('transactions')
          .doc(transaction.id.toString())
          .update(transactionModel.toMap());

      // 4. Nếu thành công, cập nhật lại is_synced trong SQLite
      await db.update(
        'transactions',
        {'is_synced': 1},
        where: 'id = ?',
        whereArgs: [transaction.id],
      );
    } catch (e) {
      // Bỏ qua lỗi nếu offline.
    }
  }

  @override
  Future<void> deleteTransaction(TransactionEntity transaction) async {
    if (transaction.id == null) return;

    // 1. Xóa khỏi cơ sở dữ liệu local (SQLite)
    final db = await dbHelper.database;
    await db.delete(
      'transactions',
      where: 'id = ?',
      whereArgs: [transaction.id],
    );

    // 2. Cố gắng xóa khỏi Firestore.
    // Ghi chú: Để có một hệ thống offline-first hoàn hảo cho việc xóa,
    // cần một cơ chế "soft-delete" hoặc một hàng đợi xóa riêng.
    // Tuy nhiên, với yêu cầu hiện tại, việc xóa trực tiếp và chấp nhận
    // rủi ro mất đồng bộ khi offline là một giải pháp đơn giản hơn.
    try {
      await firestore
          .collection('users')
          .doc(transaction.userId)
          .collection('transactions')
          .doc(transaction.id.toString())
          .delete();
    } catch (e) {
      // Bỏ qua lỗi nếu offline. Giao dịch đã bị xóa ở local.
    }
  }

  @override
  Future<void> syncPendingTransactions() async {
    // 1. Lấy tất cả giao dịch có is_synced = 0
    final db = await dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'transactions',
      where: 'is_synced = ?',
      whereArgs: [0],
    );

    for (var map in maps) {
      final model = TransactionModel.fromMap(map);
      try {
        // Đẩy từng mục lên Firebase
        await firestore
            .collection('users')
            .doc(model.userId)
            .collection('transactions')
            .doc(model.id.toString())
            .set(model.toMap());

        // Cập nhật lại local
        await db.update(
          'transactions',
          {'is_synced': 1},
          where: 'id = ?',
          whereArgs: [model.id],
        );
      } catch (e) {
        continue; // Bỏ qua nếu vẫn chưa có mạng
      }
    }
  }

  @override
  Future<List<TransactionEntity>> getTransactions() async {
    final db = await dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'transactions',
      orderBy: 'date DESC',
    );

    return maps.map((map) => TransactionModel.fromMap(map)).toList();
  }
}
