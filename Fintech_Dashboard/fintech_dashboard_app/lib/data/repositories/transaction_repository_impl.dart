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

    // 2. LƯU VÀO MÁY TRƯỚC (SQLite)
    // is_synced lúc này mặc định là 0 (false)
    final id = await (await dbHelper.database).insert(
      'transactions',
      transactionModel.toMap(),
    );

    // 3. ĐỒNG BỘ LÊN MÂY (Firebase)
    try {
      await firestore
          .collection('users')
          .doc(transaction.userId)
          .collection('transactions')
          .doc(id.toString())
          .set(transactionModel.toMap());

      // 4. NẾU THÀNH CÔNG -> Cập nhật lại trạng thái is_synced trong SQLite
      await (await dbHelper.database).update(
        'transactions',
        {'is_synced': 1},
        where: 'id = ?',
        whereArgs: [id],
      );
    } catch (e) {
      // Nếu lỗi (mất mạng), is_synced vẫn là 0.
      // Hàm syncPendingTransactions sẽ xử lý sau.
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
