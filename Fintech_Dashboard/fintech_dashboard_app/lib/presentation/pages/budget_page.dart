import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/budget_entity.dart';
import '../../domain/entities/category_entity.dart';
import '../bloc/budget/budget_cubit.dart';
import '../bloc/budget/budget_state.dart';
import '../bloc/setting/settings_cubit.dart';
import 'category_management_page.dart';

class BudgetPage extends StatelessWidget {
  const BudgetPage({super.key});

  @override
  Widget build(BuildContext context) {
    final isVi =
        context.watch<SettingsCubit>().state.locale.languageCode == 'vi';
    return Scaffold(
      body: BlocBuilder<BudgetCubit, BudgetState>(
        builder: (context, state) {
          if (state.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state.errorMessage != null) {
            return Center(child: Text(state.errorMessage!));
          }
          if (state.budgets.isEmpty) {
            return Center(
              child: Text(
                isVi
                    ? "Chưa có ngân sách nào được thiết lập."
                    : "No budgets set yet.",
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: state.budgets.length,
            itemBuilder: (context, index) {
              final budget = state.budgets[index];

              // 1. Tìm tên danh mục
              final category = state.categories
                  .cast<CategoryEntity>()
                  .firstWhere(
                    (c) => c.id == budget.categoryId,
                    orElse: () => CategoryEntity(
                      id: -1,
                      name: isVi ? 'Không xác định' : 'Unknown',
                      type: 'expense',
                      icon: '',
                      updatedAt: DateTime.now(),
                    ),
                  );

              // 2. Tính toán số tiền đã chi
              final spentAmount = state.transactions
                  .where(
                    (t) =>
                        t.categoryId == budget.categoryId &&
                        t.categoryType == 'expense', // Chỉ tính chi tiêu
                  )
                  .fold(0.0, (sum, t) => sum + t.amount);

              final progress = (spentAmount / budget.amount).clamp(0.0, 1.0);
              final isOverBudget = spentAmount > budget.amount;

              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            category.name,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.delete_outline,
                              color: Colors.grey,
                            ),
                            onPressed: () {
                              _confirmDelete(context, budget);
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      LinearProgressIndicator(
                        value: progress,
                        backgroundColor: Colors.grey[200],
                        color: isOverBudget ? Colors.red : Colors.blue,
                        minHeight: 10,
                        borderRadius: BorderRadius.circular(5),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "${spentAmount.toStringAsFixed(0)} đ",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: isOverBudget ? Colors.red : Colors.black,
                            ),
                          ),
                          Text(
                            "${isVi ? 'Giới hạn' : 'Limit'}: ${budget.amount.toStringAsFixed(0)} đ",
                            style: const TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                      if (isOverBudget)
                        Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(
                            isVi
                                ? "Bạn đã vượt quá ngân sách!"
                                : "You have exceeded the budget!",
                            style: const TextStyle(
                              color: Colors.red,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: BlocBuilder<BudgetCubit, BudgetState>(
        builder: (context, state) {
          if (state.isLoading) {
            return const SizedBox.shrink();
          }
          return FloatingActionButton(
            onPressed: () => _showAddBudgetDialog(context, state.categories),
            child: const Icon(Icons.add),
          );
        },
      ),
    );
  }

  void _confirmDelete(BuildContext context, BudgetEntity budget) {
    final isVi =
        context.read<SettingsCubit>().state.locale.languageCode == 'vi';
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isVi ? "Xóa ngân sách" : "Delete Budget"),
        content: Text(
          isVi
              ? "Bạn có chắc chắn muốn xóa ngân sách này?"
              : "Are you sure you want to delete this budget?",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(isVi ? "Hủy" : "Cancel"),
          ),
          TextButton(
            onPressed: () {
              context.read<BudgetCubit>().deleteBudget(budget);
              Navigator.pop(ctx);
            },
            child: Text(
              isVi ? "Xóa" : "Delete",
              style: const TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  void _showAddBudgetDialog(
    BuildContext context,
    List<CategoryEntity> categories,
  ) {
    final isVi =
        context.read<SettingsCubit>().state.locale.languageCode == 'vi';
    final cubit = context.read<BudgetCubit>();
    final amountController = TextEditingController();
    int? selectedCategoryId;
    // Lọc chỉ lấy danh mục chi tiêu (expense)
    // Cải tiến: So sánh không phân biệt hoa thường và xóa khoảng trắng thừa
    final expenseCategories = categories
        .where((c) => c.type.trim().toLowerCase() == 'expense')
        .toList();

    if (expenseCategories.isEmpty) {
      final hasAnyCategories = categories.isNotEmpty;
      final message = hasAnyCategories
          ? (isVi
                ? 'Bạn có ${categories.length} danh mục, nhưng không có danh mục nào là "Chi phí".'
                : 'You have ${categories.length} categories, but none are "Expense".')
          : (isVi
                ? 'Chưa có danh mục chi tiêu nào để tạo ngân sách.'
                : 'No expense categories available to create budget.');

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          action: SnackBarAction(
            label: isVi ? 'Tạo ngay' : 'Create Now',
            onPressed: () {
              Navigator.of(context)
                  .push(
                    MaterialPageRoute(
                      builder: (_) => const CategoryManagementPage(),
                    ),
                  )
                  .then((_) {
                    if (context.mounted) {
                      context.read<BudgetCubit>().loadBudgetData();
                    }
                  });
            },
          ),
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(isVi ? "Thiết lập ngân sách" : "Set Budget"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<int>(
                decoration: InputDecoration(
                  labelText: isVi ? "Danh mục" : "Category",
                ),
                items: expenseCategories.map((c) {
                  return DropdownMenuItem(value: c.id, child: Text(c.name));
                }).toList(),
                onChanged: (val) => selectedCategoryId = val,
              ),
              TextField(
                controller: amountController,
                decoration: InputDecoration(
                  labelText: isVi ? "Số tiền giới hạn" : "Limit Amount",
                ),
                keyboardType: TextInputType.number,
                // Bạn có thể thêm inputFormatters ở đây nếu muốn chặn ký tự chữ
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(isVi ? "Hủy" : "Cancel"),
            ),
            ElevatedButton(
              onPressed: () {
                if (selectedCategoryId != null &&
                    amountController.text.isNotEmpty) {
                  // Xử lý dấu phẩy thành dấu chấm và xóa khoảng trắng thừa
                  final amount = double.tryParse(
                    amountController.text.replaceAll(',', '.').trim(),
                  );
                  if (amount != null) {
                    cubit.addBudget(
                      categoryId: selectedCategoryId!,
                      amount: amount,
                    );
                    Navigator.pop(dialogContext);
                  }
                }
              },
              child: Text(isVi ? "Lưu" : "Save"),
            ),
          ],
        );
      },
    );
  }
}
