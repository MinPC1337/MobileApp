import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/entities/category_entity.dart';
import '../../../domain/usecases/categories/add_category_usecase.dart';
import '../../../domain/usecases/categories/get_categories_usecase.dart';
import '../../../domain/usecases/categories/update_category_usecase.dart';
import '../../../domain/usecases/categories/delete_category_usecase.dart';
import 'category_state.dart';

class CategoryCubit extends Cubit<CategoryState> {
  final GetCategoriesUseCase getCategoriesUseCase;
  final AddCategoryUseCase addCategoryUseCase;
  final UpdateCategoryUseCase updateCategoryUseCase;
  final DeleteCategoryUseCase deleteCategoryUseCase;
  final String _userId;

  CategoryCubit({
    required this.getCategoriesUseCase,
    required this.addCategoryUseCase,
    required this.updateCategoryUseCase,
    required this.deleteCategoryUseCase,
    required String userId,
  }) : _userId = userId,
       super(const CategoryState());

  Future<void> loadCategories() async {
    emit(state.copyWith(isLoading: true, errorMessage: null));
    try {
      final categories = await getCategoriesUseCase(_userId);
      emit(state.copyWith(isLoading: false, categories: categories));
    } catch (e) {
      emit(
        state.copyWith(
          isLoading: false,
          errorMessage: 'Không thể tải danh mục.',
        ),
      );
    }
  }

  Future<void> addCategory({
    required String name,
    required String type,
    required String icon,
  }) async {
    // Không emit loading để UI không bị giật khi thêm
    try {
      final newCategory = CategoryEntity(
        name: name,
        type: type,
        icon: icon,
        userId: _userId,
        updatedAt: DateTime.now(),
      );

      await addCategoryUseCase(newCategory);
      // Tải lại danh sách để hiển thị danh mục mới
      await loadCategories();
    } catch (e) {
      // Có thể emit một state lỗi để hiển thị thông báo
    }
  }

  Future<void> updateCategory(CategoryEntity category) async {
    try {
      await updateCategoryUseCase(category);
      await loadCategories();
    } catch (e) {
      emit(state.copyWith(errorMessage: 'Không thể cập nhật danh mục.'));
    }
  }

  Future<void> deleteCategory(CategoryEntity category) async {
    try {
      await deleteCategoryUseCase(category);
      // Xóa khỏi list hiện tại để UI phản hồi nhanh
      final updatedList = List<CategoryEntity>.from(state.categories)
        ..removeWhere((c) => c.id == category.id);
      emit(state.copyWith(categories: updatedList));
    } catch (e) {
      emit(state.copyWith(errorMessage: 'Không thể xóa danh mục.'));
      await loadCategories(); // Reload lại nếu lỗi
    }
  }
}
