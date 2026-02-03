import '../entities/category_entity.dart';

abstract class CategoryRepository {
  Future<List<CategoryEntity>> getCategories(String userId);
  Future<void> addCategory(CategoryEntity category);
}
