import '../../domain/entities/transaction_entity.dart';
import '../../domain/repositories/transaction_repository.dart';
import '../data_sources/local/database_helper.dart';
import '../data_sources/remote/transaction_remote_data_source.dart';
import '../models/transaction_model.dart';

class TransactionRepositoryImpl implements TransactionRepository {
  final DatabaseHelper dbHelper;
  final TransactionRemoteDataSource remoteDataSource;

  TransactionRepositoryImpl({
    required this.dbHelper,
    required this.remoteDataSource,
  });

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
      // Tạo lại model với ID đã có để gửi lên remote
      final modelToSync = TransactionModel.fromMap(firestoreMap);
      await remoteDataSource.addTransaction(modelToSync);

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
      await remoteDataSource.updateTransaction(transactionModel);

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
      await remoteDataSource.deleteTransaction(
        transaction.userId,
        transaction.id.toString(),
      );
    } catch (e) {
      // Bỏ qua lỗi nếu offline. Giao dịch đã bị xóa ở local.
    }
  }

  @override
  Future<void> syncPendingTransactions({required String userId}) async {
    // 1. Lấy tất cả giao dịch chưa đồng bộ của user hiện tại
    final db = await dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'transactions',
      // Lọc theo cả trạng thái chưa đồng bộ và đúng user
      where: 'is_synced = ? AND user_id = ?',
      whereArgs: [0, userId],
    );

    for (var map in maps) {
      final model = TransactionModel.fromMap(map);
      try {
        // Đẩy từng mục lên Firebase
        await remoteDataSource.addTransaction(model);

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
  Future<List<TransactionEntity>> getTransactions({
    required String userId,
  }) async {
    final db = await dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'transactions',
      where: 'user_id = ?', // Chỉ lấy giao dịch của user hiện tại
      whereArgs: [userId],
      orderBy: 'date DESC',
    );

    return maps.map((map) => TransactionModel.fromMap(map)).toList();
  }
}
