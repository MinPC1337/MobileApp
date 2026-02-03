import 'package:equatable/equatable.dart';
import '../../../domain/entities/category_entity.dart';

class CategoryState extends Equatable {
  final bool isLoading;
  final List<CategoryEntity> categories;
  final String? errorMessage;

  const CategoryState({
    this.isLoading = false,
    this.categories = const [],
    this.errorMessage,
  });

  CategoryState copyWith({
    bool? isLoading,
    List<CategoryEntity>? categories,
    String? errorMessage,
  }) {
    return CategoryState(
      isLoading: isLoading ?? this.isLoading,
      categories: categories ?? this.categories,
      errorMessage: errorMessage, // Không giữ lại lỗi cũ khi state thay đổi
    );
  }

  @override
  List<Object?> get props => [isLoading, categories, errorMessage];
}
