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
    final db = await dbHelper.database;
    // Lấy danh mục mặc định (user_id IS NULL) VÀ danh mục riêng của user
    final List<Map<String, dynamic>> maps = await db.query(
      'categories',
      where: 'user_id IS NULL OR user_id = ?',
      whereArgs: [userId],
      orderBy: 'name ASC',
    );

    return maps.map((map) => CategoryModel.fromMap(map)).toList();
  }

  @override
  Future<void> addCategory(CategoryEntity category) async {
    final db = await dbHelper.database;

    // 1. Chuyển Entity sang Model để có thể dùng toMap()
    final categoryModel = CategoryModel.fromEntity(category);
    final categoryMap = categoryModel.toMap();
    categoryMap.remove('id'); // Để SQLite tự sinh ID

    final id = await db.insert('categories', categoryMap);

    // 2. Cập nhật lại ID cho model để gửi lên server
    final newCategoryModel = CategoryModel(
      id: id,
      name: category.name,
      type: category.type,
      icon: category.icon,
      userId: category.userId,
      updatedAt: category.updatedAt,
    );

    // 3. Gửi lên Remote (FireStore)
    try {
      await remoteDataSource.addCategory(newCategoryModel);
    } catch (e) {
      // Bỏ qua lỗi mạng, chỉ cần lưu local thành công
    }
  }
}
