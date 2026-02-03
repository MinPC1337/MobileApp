import '../../entities/category_entity.dart';
import '../../repositories/category_repository.dart';

class AddCategoryUseCase {
  final CategoryRepository repository;

  AddCategoryUseCase(this.repository);

  Future<void> call(CategoryEntity category) async {
    return await repository.addCategory(category);
  }
}
