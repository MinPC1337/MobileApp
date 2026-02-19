import 'dart:async';
import 'package:sqflite/sqflite.dart';
import '../../domain/entities/category_entity.dart';
import '../../domain/repositories/category_repository.dart';
import '../data_sources/local/database_helper.dart';
import '../data_sources/remote/category_remote_data_source.dart';
import '../models/category_model.dart';

class CategoryRepositoryImpl implements CategoryRepository {
  final DatabaseHelper dbHelper;
  final CategoryRemoteDataSource remoteDataSource;

  CategoryRepositoryImpl({
    required this.dbHelper,
    required this.remoteDataSource,
  });

  @override
  Future<List<CategoryEntity>> getCategories(String userId) async {
    // 1. Cố gắng đồng bộ dữ liệu từ remote về local
    try {
      // Đồng bộ các mục chưa được đẩy lên server
      await syncPendingCategories(userId: userId);

      // Lấy dữ liệu mới nhất từ Firebase
      final remoteCategories = await remoteDataSource
          .getCategories(userId)
          .timeout(const Duration(seconds: 10));

      final db = await dbHelper.database;
      await db.transaction((txn) async {
        // Xóa các danh mục cũ đã đồng bộ của user này trong Local
        // Giữ lại danh mục mặc định (user_id IS NULL) và danh mục chưa sync (is_synced = 0)
        await txn.delete(
          'categories',
          // Sửa lỗi: Chỉ xóa các mục đã đồng bộ
          where: 'user_id = ? AND is_synced = 1',
          whereArgs: [userId],
        );

        // Chèn dữ liệu mới từ Firebase vào Local
        for (var model in remoteCategories) {
          final map = model.toMap();
          map['id'] = model.id; // Đảm bảo ID từ Firebase được giữ nguyên

          await txn.insert(
            'categories',
            map,
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }
      });
    } catch (e) {
      // Nếu có lỗi (mất mạng, timeout), bỏ qua và dùng dữ liệu Local cũ (Offline mode)
      // print("Sync categories error: $e");
    }

    // 2. Luôn trả về dữ liệu từ local DB
    final db = await dbHelper.database;
    // Lấy cả danh mục của User và danh mục Mặc định (user_id là null)
    final List<Map<String, dynamic>> maps = await db.query(
      'categories',
      where: 'user_id = ? OR user_id IS NULL',
      whereArgs: [userId],
      orderBy: 'type, name', // Sắp xếp theo loại rồi đến tên
    );

    return maps.map((map) => CategoryModel.fromMap(map)).toList();
  }

  @override
  Future<void> addCategory(CategoryEntity category) async {
    final categoryModel = CategoryModel.fromEntity(category);
    final db = await dbHelper.database;

    // 1. Lưu Local trước (is_synced mặc định là 0)
    final map = categoryModel.toMap();
    if (map['id'] == null) {
      map.remove('id'); // Để SQLite tự động sinh ID
    }
    final localId = await db.insert('categories', map);

    // 2. Cố gắng đồng bộ lên Firebase
    try {
      // Tạo model mới với ID từ local DB để gửi lên remote
      final mapToSync = categoryModel.toMap();
      mapToSync['id'] = localId;
      mapToSync['is_synced'] = 1;
      final modelToSync = CategoryModel.fromMap(mapToSync);

      await remoteDataSource
          .addCategory(modelToSync)
          .timeout(const Duration(seconds: 5));

      // 3. Nếu thành công, cập nhật trạng thái đã sync
      await db.update(
        'categories',
        {'is_synced': 1},
        where: 'id = ?',
        whereArgs: [localId],
      );
    } catch (e) {
      // Nếu lỗi (offline), is_synced vẫn là 0, sẽ được đồng bộ sau.
    }
  }

  @override
  Future<void> updateCategory(CategoryEntity category) async {
    if (category.id == null) {
      throw Exception("Cannot update category without ID");
    }
    final categoryModel = CategoryModel.fromEntity(category);
    final db = await dbHelper.database;

    // 1. Cập nhật Local, đánh dấu là chưa đồng bộ
    await db.update(
      'categories',
      categoryModel.toMap()..['is_synced'] = 0,
      where: 'id = ?',
      whereArgs: [category.id],
    );

    // 2. Cố gắng đồng bộ lên Firebase
    try {
      final mapToSync = categoryModel.toMap();
      mapToSync['is_synced'] = 1;
      final modelToSync = CategoryModel.fromMap(mapToSync);

      await remoteDataSource
          .updateCategory(modelToSync)
          .timeout(const Duration(seconds: 5));

      // 3. Nếu thành công, cập nhật lại trạng thái đã sync
      await db.update(
        'categories',
        {'is_synced': 1},
        where: 'id = ?',
        whereArgs: [category.id],
      );
    } catch (e) {
      // Nếu lỗi (offline), is_synced vẫn là 0.
    }
  }

  @override
  Future<void> deleteCategory(CategoryEntity category) async {
    if (category.id == null) return;
    final db = await dbHelper.database;

    // 1. Xóa Local
    await db.delete('categories', where: 'id = ?', whereArgs: [category.id]);

    // 2. Cố gắng xóa trên Remote
    try {
      if (category.userId != null) {
        await remoteDataSource
            .deleteCategory(category.userId!, category.id.toString())
            .timeout(const Duration(seconds: 5));
      }
    } catch (e) {
      // Bỏ qua lỗi offline. Việc xóa sẽ không được đồng bộ.
      // Một giải pháp hoàn thiện hơn cần cơ chế "soft-delete".
    }
  }

  @override
  Future<void> syncPendingCategories({required String userId}) async {
    final db = await dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'categories',
      where: 'is_synced = ? AND user_id = ?',
      whereArgs: [0, userId],
    );

    for (var map in maps) {
      final mapToSync = Map<String, dynamic>.from(map);
      mapToSync['is_synced'] = 1;
      final model = CategoryModel.fromMap(mapToSync);
      try {
        // addCategory trên remote hoạt động như upsert (set)
        await remoteDataSource
            .addCategory(model)
            .timeout(const Duration(seconds: 5));

        await db.update(
          'categories',
          {'is_synced': 1},
          where: 'id = ?',
          whereArgs: [model.id],
        );
      } catch (e) {
        continue; // Nếu lỗi, bỏ qua và thử lại lần sau
      }
    }
  }

  @override
  Future<void> clearLocalData() async {
    final db = await dbHelper.database;
    // Chỉ xóa danh mục của người dùng, giữ lại danh mục mặc định
    await db.delete('categories', where: 'user_id IS NOT NULL');
  }
}
