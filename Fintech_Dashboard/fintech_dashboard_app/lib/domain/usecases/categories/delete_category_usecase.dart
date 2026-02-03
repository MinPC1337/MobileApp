import '../../entities/category_entity.dart';
import '../../repositories/category_repository.dart';

class DeleteCategoryUseCase {
  final CategoryRepository repository;

  DeleteCategoryUseCase(this.repository);

  Future<void> call(CategoryEntity category) async {
    return await repository.deleteCategory(category);
  }
}
