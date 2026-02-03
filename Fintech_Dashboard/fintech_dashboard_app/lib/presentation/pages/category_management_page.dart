import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/category_entity.dart';
import '../../injection_container.dart' as di;
import '../bloc/auth_cubit.dart';
import '../bloc/auth_state.dart';
import '../bloc/category_cubit.dart';
import '../bloc/category_state.dart';

class CategoryManagementPage extends StatelessWidget {
  const CategoryManagementPage({super.key});

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthCubit>().state;
    String? userId;
    if (authState is AuthSuccess) {
      userId = authState.user.id;
    }

    if (userId == null) {
      return const Scaffold(
        body: Center(child: Text("Lỗi: Không tìm thấy người dùng.")),
      );
    }

    return BlocProvider(
      create: (_) => di.sl<CategoryCubit>(param1: userId)..loadCategories(),
      child: Scaffold(
        appBar: AppBar(title: const Text('Quản lý Danh mục')),
        body: BlocBuilder<CategoryCubit, CategoryState>(
          builder: (context, state) {
            if (state.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }
            if (state.errorMessage != null) {
              return Center(child: Text(state.errorMessage!));
            }
            if (state.categories.isEmpty) {
              return const Center(child: Text('Chưa có danh mục nào.'));
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
                        title: const Text('Xác nhận xóa'),
                        content: const Text(
                          'Bạn có chắc muốn xóa danh mục này?',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(ctx).pop(false),
                            child: const Text('Hủy'),
                          ),
                          TextButton(
                            onPressed: () => Navigator.of(ctx).pop(true),
                            child: const Text(
                              'Xóa',
                              style: TextStyle(color: Colors.red),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                  onDismissed: (direction) {
                    context.read<CategoryCubit>().deleteCategory(category);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Đã xóa danh mục')),
                    );
                  },
                  child: ListTile(
                    leading: Icon(
                      isIncome
                          ? Icons.arrow_circle_up
                          : Icons.arrow_circle_down,
                      color: isIncome ? Colors.green : Colors.red,
                    ),
                    title: Text(category.name),
                    subtitle: Text(isDefault ? 'Mặc định' : 'Cá nhân'),
                    trailing: isDefault
                        ? null
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
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController(text: category?.name ?? '');
    String type = category?.type ?? 'expense'; // Loại mặc định

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(category == null ? 'Thêm Danh mục mới' : 'Sửa Danh mục'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Tên danh mục'),
                  validator: (value) => (value == null || value.isEmpty)
                      ? 'Vui lòng nhập tên'
                      : null,
                ),
                StatefulBuilder(
                  builder: (BuildContext context, StateSetter setState) {
                    return DropdownButtonFormField<String>(
                      initialValue: type,
                      decoration: const InputDecoration(labelText: 'Loại'),
                      items: const [
                        DropdownMenuItem(
                          value: 'expense',
                          child: Text('Chi phí'),
                        ),
                        DropdownMenuItem(
                          value: 'income',
                          child: Text('Thu nhập'),
                        ),
                      ],
                      onChanged: (value) => setState(() => type = value!),
                    );
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Hủy'),
            ),
            ElevatedButton(
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  if (category == null) {
                    cubit.addCategory(
                      name: nameController.text,
                      type: type,
                      icon: 'default',
                    );
                  } else {
                    cubit.updateCategory(
                      CategoryEntity(
                        id: category.id,
                        name: nameController.text,
                        type: type,
                        icon: category.icon,
                        userId: category.userId,
                        updatedAt: DateTime.now(),
                      ),
                    );
                  }
                  Navigator.of(dialogContext).pop();
                }
              },
              child: Text(category == null ? 'Thêm' : 'Lưu'),
            ),
          ],
        );
      },
    );
  }
}
