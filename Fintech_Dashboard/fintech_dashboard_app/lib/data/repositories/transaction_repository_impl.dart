import 'dart:async';
import 'package:sqflite/sqflite.dart';
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
    firestoreMap['is_synced'] =
        1; // <--- SỬA: Đánh dấu là 1 trước khi gửi lên Cloud

    // 3. ĐỒNG BỘ LÊN MÂY (Firebase)
    try {
      // Tạo lại model với ID đã có để gửi lên remote
      final modelToSync = TransactionModel.fromMap(firestoreMap);
      // Thêm timeout 3s: Nếu mạng lag quá 3s thì bỏ qua, coi như offline
      await remoteDataSource
          .addTransaction(modelToSync)
          .timeout(const Duration(seconds: 3));

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
      // Tạo một bản sao map và set is_synced = 1 để gửi lên Cloud
      final mapToSync = transactionModel.toMap();
      mapToSync['is_synced'] = 1;
      final modelToSync = TransactionModel.fromMap(mapToSync);

      await remoteDataSource
          .updateTransaction(modelToSync)
          .timeout(const Duration(seconds: 3));

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
      await remoteDataSource
          .deleteTransaction(transaction.userId, transaction.id.toString())
          .timeout(const Duration(seconds: 3));
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
      // Tạo bản sao map và set is_synced = 1 trước khi gửi
      final mapToSync = Map<String, dynamic>.from(map);
      mapToSync['is_synced'] = 1;
      final model = TransactionModel.fromMap(mapToSync);
      try {
        // Đẩy từng mục lên Firebase
        await remoteDataSource
            .addTransaction(model)
            .timeout(const Duration(seconds: 2));

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
    // --- BẮT ĐẦU ĐOẠN MÃ MỚI: ĐỒNG BỘ TỪ FIREBASE VỀ LOCAL ---
    try {
      // 1. (Tùy chọn) Đẩy các thay đổi chưa đồng bộ lên trước để tránh mất dữ liệu
      await syncPendingTransactions(userId: userId);

      // 2. Lấy dữ liệu mới nhất từ Firebase
      // Lưu ý: Bạn cần đảm bảo remoteDataSource có hàm getTransactions(String userId)
      // trả về List<TransactionModel>
      final remoteModels = await remoteDataSource
          .getTransactions(userId)
          .timeout(const Duration(seconds: 3));

      final db = await dbHelper.database;
      await db.transaction((txn) async {
        // 3. CHỈ Xóa những dữ liệu ĐÃ ĐỒNG BỘ (is_synced = 1) của user này
        // Giữ lại các giao dịch chưa đồng bộ (is_synced = 0) để không bị mất khi offline
        await txn.delete(
          'transactions',
          where: 'user_id = ? AND is_synced = 1',
          whereArgs: [userId],
        );

        // 4. Chèn lại dữ liệu mới từ Firebase (Dùng ConflictAlgorithm.replace)
        // Nếu ID trùng với ID đang có (trường hợp vừa sync xong), nó sẽ ghi đè
        for (var model in remoteModels) {
          // Đánh dấu là đã đồng bộ (is_synced = 1)
          final map = model.toMap();
          map['is_synced'] = 1;

          // Sử dụng replace để nếu ID đã tồn tại thì cập nhật lại thông tin mới nhất
          await txn.insert(
            'transactions',
            map,
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }
      });
    } catch (e) {
      // Nếu mất mạng hoặc lỗi server, bỏ qua và dùng dữ liệu Local cũ (Offline mode)
      // print("Sync error: $e");
    }

    final db = await dbHelper.database;
    // Thay đổi: Sử dụng rawQuery với JOIN để lấy thông tin danh mục.
    // Giả định rằng TransactionModel và TransactionEntity đã được cập nhật
    // để chứa các trường như categoryName, categoryType.
    final List<Map<String, dynamic>> maps = await db.rawQuery(
      '''
      SELECT
        t.*,
        c.name as category_name,
        c.type as category_type,
        c.icon as category_icon
      FROM transactions t
      LEFT JOIN categories c ON t.category_id = c.id
      WHERE t.user_id = ?
      ORDER BY t.date DESC
    ''',
      [userId],
    );

    return maps.map((map) => TransactionModel.fromMap(map)).toList();
  }
}
