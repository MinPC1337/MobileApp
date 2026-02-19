import '../entities/category_entity.dart';

abstract class CategoryRepository {
  Future<List<CategoryEntity>> getCategories(String userId);
  Future<void> addCategory(CategoryEntity category);
  Future<void> updateCategory(CategoryEntity category);
  Future<void> deleteCategory(CategoryEntity category);
  Future<void> syncPendingCategories({required String userId});
  Future<void> clearLocalData();
}
