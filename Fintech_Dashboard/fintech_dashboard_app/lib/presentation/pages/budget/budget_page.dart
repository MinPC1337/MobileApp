import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../domain/entities/budget_entity.dart';
import '../../../domain/entities/category_entity.dart';
import '../../bloc/budget/budget_cubit.dart';
import '../../bloc/budget/budget_state.dart';
import '../../bloc/setting/settings_cubit.dart';
import '../../../core/utils/app_icons.dart';
import '../transaction/category_management_page.dart';

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
              final percentage = (spentAmount / budget.amount) * 100;
              final isOverBudget = spentAmount > budget.amount;
              final isWarning =
                  !isOverBudget && spentAmount > (budget.amount * 0.7);

              Color statusColor;
              String statusText = '';

              if (isOverBudget) {
                statusColor = Colors.red;
                statusText = isVi
                    ? "Bạn đã vượt quá ngân sách!"
                    : "You have exceeded the budget!";
              } else if (isWarning) {
                statusColor = Colors.orange;
                statusText = isVi
                    ? "Bạn sắp hết ngân sách!"
                    : "You are running out of budget!";
              } else {
                statusColor = Colors.blue;
              }

              return Container(
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: statusColor.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              AppIcons.getIconFromString(category.icon),
                              color: statusColor,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  category.name,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  "${percentage.toStringAsFixed(1)}%",
                                  style: TextStyle(
                                    color: statusColor,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.delete_outline,
                              color: Colors.grey,
                            ),
                            onPressed: () => _confirmDelete(context, budget),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: LinearProgressIndicator(
                          value: progress,
                          backgroundColor: Theme.of(
                            context,
                          ).dividerColor.withOpacity(0.1),
                          color: statusColor,
                          minHeight: 8,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            NumberFormat.currency(
                              locale: isVi ? 'vi_VN' : 'en_US',
                              symbol: 'đ',
                              decimalDigits: 0,
                            ).format(spentAmount),
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: statusColor,
                              fontSize: 15,
                            ),
                          ),
                          Text(
                            "${isVi ? 'Giới hạn' : 'Limit'}: ${NumberFormat.compactCurrency(locale: isVi ? 'vi_VN' : 'en_US', symbol: 'đ', decimalDigits: 0).format(budget.amount)}",
                            style: TextStyle(
                              color: Theme.of(context).hintColor,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                      if (statusText.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 12.0),
                          child: Row(
                            children: [
                              Icon(
                                Icons.info_outline_rounded,
                                size: 16,
                                color: statusColor,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                statusText,
                                style: TextStyle(
                                  color: statusColor,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
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
    final formKey = GlobalKey<FormState>();
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
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28.0),
          ),
          title: Text(isVi ? "Thiết lập ngân sách" : "Set Budget"),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<int>(
                  decoration: InputDecoration(
                    labelText: isVi ? "Danh mục" : "Category",
                    prefixIcon: const Icon(Icons.category_outlined),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  items: expenseCategories.map((c) {
                    return DropdownMenuItem(value: c.id, child: Text(c.name));
                  }).toList(),
                  onChanged: (val) => selectedCategoryId = val,
                  validator: (value) {
                    if (value == null) {
                      return isVi
                          ? 'Vui lòng chọn danh mục'
                          : 'Please select a category';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: amountController,
                  decoration: InputDecoration(
                    labelText: isVi ? "Số tiền giới hạn" : "Limit Amount",
                    prefixIcon: const Icon(Icons.monetization_on_outlined),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return isVi
                          ? 'Vui lòng nhập số tiền'
                          : 'Please enter an amount';
                    }
                    final amount = double.tryParse(
                      value.replaceAll(',', '.').trim(),
                    );
                    if (amount == null || amount <= 0) {
                      return isVi ? 'Số tiền không hợp lệ' : 'Invalid amount';
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
          actionsPadding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(isVi ? "Hủy" : "Cancel"),
            ),
            FilledButton(
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  final amount = double.tryParse(
                    amountController.text.replaceAll(',', '.').trim(),
                  )!;
                  cubit.addBudget(
                    categoryId: selectedCategoryId!,
                    amount: amount,
                  );
                  Navigator.pop(dialogContext);
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
