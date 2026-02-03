import '../../entities/category_entity.dart';
import '../../repositories/category_repository.dart';

class GetCategoriesUseCase {
  final CategoryRepository repository;

  GetCategoriesUseCase(this.repository);

  Future<List<CategoryEntity>> call(String userId) async {
    return await repository.getCategories(userId);
  }
}
