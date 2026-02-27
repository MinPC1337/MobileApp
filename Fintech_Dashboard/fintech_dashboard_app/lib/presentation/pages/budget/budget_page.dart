import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../domain/entities/budget_entity.dart';
import '../../../domain/entities/category_entity.dart';
import '../../bloc/budget/budget_cubit.dart';
import '../../bloc/budget/budget_state.dart';
import '../../bloc/setting/settings_cubit.dart';
import '../../../core/utils/app_icons.dart';
import 'budget_detail_page.dart';
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

          final now = DateTime.now();
          final today = DateTime(now.year, now.month, now.day);

          final activeBudgets = state.budgets.where((b) {
            final bEnd = DateTime(
              b.endDate.year,
              b.endDate.month,
              b.endDate.day,
            );
            return !bEnd.isBefore(today);
          }).toList();

          if (activeBudgets.isEmpty) {
            return Center(
              child: Text(
                isVi
                    ? "Chưa có ngân sách nào đang hoạt động."
                    : "No active budgets set yet.",
              ),
            );
          }

          // Tính toán tổng ngân sách và tổng chi tiêu cho tất cả ngân sách đang hoạt động
          double totalLimit = 0;
          double totalSpentAll = 0;

          for (var budget in activeBudgets) {
            totalLimit += budget.amount;
            final bSpent = state.transactions
                .where(
                  (t) =>
                      t.categoryId == budget.categoryId &&
                      t.categoryType == 'expense' &&
                      !t.date.isBefore(budget.startDate) &&
                      t.date.isBefore(
                        budget.endDate.add(const Duration(days: 1)),
                      ),
                )
                .fold(0.0, (sum, t) => sum + t.amount);
            totalSpentAll += bSpent;
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: activeBudgets.length + 1, // +1 cho thẻ tổng quan
            itemBuilder: (context, index) {
              if (index == 0) {
                // Hiển thị thẻ tổng quan ở vị trí đầu tiên
                final progress = totalLimit > 0
                    ? (totalSpentAll / totalLimit).clamp(0.0, 1.0)
                    : 0.0;
                final isOver = totalSpentAll > totalLimit;
                final percentage = totalLimit > 0
                    ? (totalSpentAll / totalLimit) * 100
                    : 0.0;

                return Container(
                  margin: const EdgeInsets.only(bottom: 24),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: isOver
                          ? [Colors.red.shade400, Colors.red.shade700]
                          : [Colors.blue.shade400, Colors.blue.shade700],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: (isOver ? Colors.red : Colors.blue).withOpacity(
                          0.4,
                        ),
                        blurRadius: 12,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isVi ? "Tổng ngân sách" : "Total Budget",
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: LinearProgressIndicator(
                          value: progress,
                          backgroundColor: Colors.white.withOpacity(0.3),
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                          minHeight: 12,
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
                            ).format(totalSpentAll),
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              fontSize: 16,
                            ),
                          ),
                          Text(
                            "${isVi ? 'của' : 'of'} ${NumberFormat.compactCurrency(locale: isVi ? 'vi_VN' : 'en_US', symbol: 'đ', decimalDigits: 0).format(totalLimit)}",
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Align(
                        alignment: Alignment.centerRight,
                        child: Text(
                          "${percentage.toStringAsFixed(1)}%",
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }

              final budget = activeBudgets[index - 1];

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
                        t.categoryId == budget.categoryId && // Đúng danh mục
                        t.categoryType == 'expense' && // Là chi tiêu
                        !t.date.isBefore(
                          budget.startDate,
                        ) && // Sau hoặc bằng ngày bắt đầu
                        t.date.isBefore(
                          budget.endDate.add(const Duration(days: 1)),
                        ), // Trước hoặc bằng ngày kết thúc
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

              return InkWell(
                onTap: () {
                  // 1. Lọc các giao dịch cho ngân sách này
                  final budgetTransactions = state.transactions
                      .where(
                        (t) =>
                            t.categoryId == budget.categoryId &&
                            t.categoryType == 'expense' &&
                            !t.date.isBefore(budget.startDate) &&
                            t.date.isBefore(
                              budget.endDate.add(const Duration(days: 1)),
                            ),
                      )
                      .toList();

                  // Sắp xếp theo ngày, mới nhất lên đầu
                  budgetTransactions.sort((a, b) => b.date.compareTo(a.date));

                  // 2. Điều hướng đến trang chi tiết
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => BudgetDetailPage(
                        budget: budget,
                        category: category,
                        budgetTransactions: budgetTransactions,
                        spentAmount: spentAmount,
                      ),
                    ),
                  );
                },
                borderRadius: BorderRadius.circular(24),
                child: Container(
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
                                  const SizedBox(height: 2),
                                  Text(
                                    "${DateFormat.yMd(isVi ? 'vi_VN' : 'en_US').format(budget.startDate)} - ${DateFormat.yMd(isVi ? 'vi_VN' : 'en_US').format(budget.endDate)}",
                                    style: TextStyle(
                                      color: Theme.of(context).hintColor,
                                      fontSize: 12,
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
    final now = DateTime.now();
    DateTimeRange selectedDateRange = DateTimeRange(
      start: DateTime(now.year, now.month, 1),
      end: DateTime(now.year, now.month + 1, 0),
    );

    // Cải tiến: So sánh không phân biệt hoa thường và xóa khoảng trắng thừa
    final expenseCategories = categories
        .where((c) => c.type.trim().toLowerCase() == 'expense')
        .toList();

    // Lọc bỏ các danh mục đã có ngân sách đang hoạt động (chưa hết hạn)
    final budgets = cubit.state.budgets;
    final today = DateTime(now.year, now.month, now.day);
    final activeCategoryIds = budgets
        .where((b) {
          final bEnd = DateTime(b.endDate.year, b.endDate.month, b.endDate.day);
          // Ngân sách còn hạn nếu ngày kết thúc >= hôm nay
          return !bEnd.isBefore(today);
        })
        .map((b) => b.categoryId)
        .toSet();

    final availableCategories = expenseCategories
        .where((c) => !activeCategoryIds.contains(c.id))
        .toList();

    if (availableCategories.isEmpty) {
      final hasAnyCategories = categories.isNotEmpty;
      String message;

      if (expenseCategories.isEmpty) {
        message = hasAnyCategories
            ? (isVi
                  ? 'Bạn có ${categories.length} danh mục, nhưng không có danh mục nào là "Chi phí".'
                  : 'You have ${categories.length} categories, but none are "Expense".')
            : (isVi
                  ? 'Chưa có danh mục chi tiêu nào để tạo ngân sách.'
                  : 'No expense categories available to create budget.');
      } else {
        message = isVi
            ? 'Tất cả danh mục chi tiêu đã có ngân sách đang hoạt động.'
            : 'All expense categories already have active budgets.';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          action: expenseCategories.isEmpty
              ? SnackBarAction(
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
                )
              : null,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      // Sử dụng StatefulBuilder để quản lý trạng thái (ngày tháng) bên trong dialog
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (stfContext, stfSetState) {
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
                      items: availableCategories.map((c) {
                        return DropdownMenuItem(
                          value: c.id,
                          child: Text(c.name),
                        );
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
                    InkWell(
                      onTap: () async {
                        final picked = await showDateRangePicker(
                          context: context,
                          initialDateRange: selectedDateRange,
                          firstDate: DateTime(now.year - 5),
                          lastDate: DateTime(now.year + 5),
                          helpText: isVi
                              ? 'Chọn khoảng thời gian'
                              : 'Select date range',
                          cancelText: isVi ? 'HỦY' : 'CANCEL',
                          confirmText: isVi ? 'CHỌN' : 'OK',
                        );
                        if (picked != null) {
                          stfSetState(() => selectedDateRange = picked);
                        }
                      },
                      child: InputDecorator(
                        decoration: InputDecoration(
                          labelText: isVi ? "Thời gian áp dụng" : "Date Range",
                          prefixIcon: const Icon(Icons.date_range_outlined),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: Text(
                          '${DateFormat.yMd(isVi ? 'vi_VN' : 'en_US').format(selectedDateRange.start)} - ${DateFormat.yMd(isVi ? 'vi_VN' : 'en_US').format(selectedDateRange.end)}',
                        ),
                      ),
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
                          return isVi
                              ? 'Số tiền không hợp lệ'
                              : 'Invalid amount';
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
                        startDate: selectedDateRange.start,
                        endDate: selectedDateRange.end,
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
      },
    );
  }
}
