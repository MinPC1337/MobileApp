import '../../entities/category_entity.dart';
import '../../repositories/category_repository.dart';

class UpdateCategoryUseCase {
  final CategoryRepository repository;

  UpdateCategoryUseCase(this.repository);

  Future<void> call(CategoryEntity category) async {
    return await repository.updateCategory(category);
  }
}
