import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/entities/category_entity.dart';
import '../../../injection_container.dart' as di;
import '../../bloc/auth/auth_cubit.dart';
import '../../bloc/auth/auth_state.dart';
import '../../bloc/category/category_cubit.dart';
import '../../bloc/category/category_state.dart';
import '../../bloc/setting/settings_cubit.dart';
import '../../../core/utils/app_icons.dart';

class CategoryManagementPage extends StatelessWidget {
  const CategoryManagementPage({super.key});

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthCubit>().state;
    final isVi =
        context.watch<SettingsCubit>().state.locale.languageCode == 'vi';
    String? userId;
    if (authState is AuthSuccess) {
      userId = authState.user.id;
    }

    if (userId == null) {
      return Scaffold(
        body: Center(
          child: Text(
            isVi ? "Lỗi: Không tìm thấy người dùng." : "Error: User not found.",
          ),
        ),
      );
    }

    return BlocProvider(
      create: (_) => di.sl<CategoryCubit>(param1: userId)..loadCategories(),
      child: Scaffold(
        appBar: AppBar(
          title: Text(isVi ? 'Quản lý Danh mục' : 'Manage Categories'),
        ),
        body: BlocBuilder<CategoryCubit, CategoryState>(
          builder: (context, state) {
            if (state.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }
            if (state.errorMessage != null) {
              return Center(child: Text(state.errorMessage!));
            }
            if (state.categories.isEmpty) {
              return Center(
                child: Text(
                  isVi ? 'Chưa có danh mục nào.' : 'No categories found.',
                ),
              );
            }
            return ListView.builder(
              itemCount: state.categories.length,
              itemBuilder: (context, index) {
                final category = state.categories[index];
                final isIncome = category.type == 'income';
                final isDefault = category.userId == null;

                return Dismissible(
                  key: ValueKey(category.id),
                  direction: isDefault
                      ? DismissDirection.none
                      : DismissDirection.endToStart,
                  background: Container(
                    color: Colors.red,
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: const Icon(Icons.delete, color: Colors.white),
                  ),
                  confirmDismiss: (direction) async {
                    return await showDialog(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: Text(isVi ? 'Xác nhận xóa' : 'Confirm Delete'),
                        content: Text(
                          isVi
                              ? 'Bạn có chắc muốn xóa danh mục này?'
                              : 'Are you sure you want to delete this category?',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(ctx).pop(false),
                            child: Text(isVi ? 'Hủy' : 'Cancel'),
                          ),
                          TextButton(
                            onPressed: () => Navigator.of(ctx).pop(true),
                            child: Text(
                              isVi ? 'Xóa' : 'Delete',
                              style: const TextStyle(color: Colors.red),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                  onDismissed: (direction) {
                    context.read<CategoryCubit>().deleteCategory(category);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          isVi ? 'Đã xóa danh mục' : 'Category deleted',
                        ),
                      ),
                    );
                  },
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: (isIncome ? Colors.green : Colors.red)
                          .withOpacity(0.1),
                      child: Icon(
                        AppIcons.getIconFromString(category.icon),
                        color: isIncome ? Colors.green : Colors.red,
                        size: 20,
                      ),
                    ),
                    title: Text(category.name),
                    subtitle: Text(
                      isDefault
                          ? (isVi ? 'Mặc định' : 'Default')
                          : (isVi ? 'Cá nhân' : 'Personal'),
                    ),
                    trailing: isDefault
                        ? null // Cannot edit default categories
                        : const Icon(Icons.edit, size: 20),
                    onTap: () {
                      if (!isDefault) {
                        _showAddCategoryDialog(
                          context,
                          context.read<CategoryCubit>(),
                          category: category,
                        );
                      }
                    },
                  ),
                );
              },
            );
          },
        ),
        floatingActionButton: BlocBuilder<CategoryCubit, CategoryState>(
          builder: (context, state) {
            return FloatingActionButton(
              onPressed: () {
                _showAddCategoryDialog(context, context.read<CategoryCubit>());
              },
              child: const Icon(Icons.add),
            );
          },
        ),
      ),
    );
  }

  void _showAddCategoryDialog(
    BuildContext context,
    CategoryCubit cubit, {
    CategoryEntity? category,
  }) {
    final isVi =
        context.read<SettingsCubit>().state.locale.languageCode == 'vi';
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController(text: category?.name ?? '');
    String type = category?.type ?? 'expense';
    String selectedIcon = category?.icon ?? 'default';

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          contentPadding: const EdgeInsets.all(16),
          title: Text(
            category == null
                ? (isVi ? 'Thêm Danh mục mới' : 'Add New Category')
                : (isVi ? 'Sửa Danh mục' : 'Edit Category'),
          ),
          content: StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
              // Wrap the content in a Container to give the AlertDialog a specific size
              // This prevents the "RenderViewport does not support returning intrinsic dimensions" error
              return SizedBox(
                width: double.maxFinite,
                child: Form(
                  key: formKey,
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TextFormField(
                          controller: nameController,
                          decoration: InputDecoration(
                            labelText: isVi ? 'Tên danh mục' : 'Category Name',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          validator: (value) => (value == null || value.isEmpty)
                              ? (isVi
                                    ? 'Vui lòng nhập tên'
                                    : 'Please enter name')
                              : null,
                        ),
                        const SizedBox(height: 16),
                        DropdownButtonFormField<String>(
                          value: type,
                          decoration: InputDecoration(
                            labelText: isVi ? 'Loại' : 'Type',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          items: [
                            DropdownMenuItem(
                              value: 'expense',
                              child: Text(isVi ? 'Chi phí' : 'Expense'),
                            ),
                            DropdownMenuItem(
                              value: 'income',
                              child: Text(isVi ? 'Thu nhập' : 'Income'),
                            ),
                          ],
                          onChanged: (value) => setState(() => type = value!),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          isVi ? 'Chọn biểu tượng' : 'Choose Icon',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          height: 150,
                          child: GridView.builder(
                            itemCount: AppIcons.categoryIcons.length,
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 5,
                                  crossAxisSpacing: 8,
                                  mainAxisSpacing: 8,
                                ),
                            itemBuilder: (context, index) {
                              final iconName = AppIcons.categoryIcons.keys
                                  .elementAt(index);
                              final iconData = AppIcons.categoryIcons.values
                                  .elementAt(index);
                              final isSelected = selectedIcon == iconName;
                              return InkWell(
                                onTap: () =>
                                    setState(() => selectedIcon = iconName),
                                borderRadius: BorderRadius.circular(12),
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? Theme.of(
                                            context,
                                          ).colorScheme.primaryContainer
                                        : Theme.of(context)
                                              .colorScheme
                                              .surfaceVariant
                                              .withOpacity(0.3),
                                    borderRadius: BorderRadius.circular(12),
                                    border: isSelected
                                        ? Border.all(
                                            color: Theme.of(
                                              context,
                                            ).colorScheme.primary,
                                            width: 2,
                                          )
                                        : null,
                                  ),
                                  child: Icon(
                                    iconData,
                                    color: isSelected
                                        ? Theme.of(context).colorScheme.primary
                                        : Theme.of(
                                            context,
                                          ).textTheme.bodyLarge?.color,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(isVi ? 'Hủy' : 'Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  if (category == null) {
                    cubit.addCategory(
                      name: nameController.text,
                      type: type,
                      icon: selectedIcon,
                    );
                  } else {
                    cubit.updateCategory(
                      CategoryEntity(
                        id: category.id,
                        name: nameController.text,
                        type: type,
                        icon: selectedIcon,
                        userId: category.userId,
                        updatedAt: DateTime.now(),
                      ),
                    );
                  }
                  Navigator.of(dialogContext).pop();
                }
              },
              child: Text(
                category == null
                    ? (isVi ? 'Thêm' : 'Add')
                    : (isVi ? 'Lưu' : 'Save'),
              ),
            ),
          ],
        );
      },
    );
  }
}
