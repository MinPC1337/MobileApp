import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
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
                return ListTile(
                  leading: Icon(
                    isIncome ? Icons.arrow_circle_up : Icons.arrow_circle_down,
                    color: isIncome ? Colors.green : Colors.red,
                  ),
                  title: Text(category.name),
                  subtitle: Text(
                    category.userId == null ? 'Mặc định' : 'Cá nhân',
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

  void _showAddCategoryDialog(BuildContext context, CategoryCubit cubit) {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController();
    String type = 'expense'; // Loại mặc định

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Thêm Danh mục mới'),
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
                  cubit.addCategory(
                    name: nameController.text,
                    type: type,
                    icon: 'default',
                  );
                  Navigator.of(dialogContext).pop();
                }
              },
              child: const Text('Thêm'),
            ),
          ],
        );
      },
    );
  }
}
