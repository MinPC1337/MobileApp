import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/entities/budget_entity.dart';
import '../../../domain/entities/category_entity.dart';
import '../../../domain/entities/transaction_entity.dart';
import '../../bloc/setting/settings_cubit.dart';
import '../../../core/utils/app_icons.dart';
import 'budget_detail_page.dart';

class BudgetHistoryPage extends StatelessWidget {
  final List<BudgetEntity> expiredBudgets;
  final List<CategoryEntity> categories;
  final List<TransactionEntity> transactions;

  const BudgetHistoryPage({
    super.key,
    required this.expiredBudgets,
    required this.categories,
    required this.transactions,
  });

  @override
  Widget build(BuildContext context) {
    final isVi =
        context.watch<SettingsCubit>().state.locale.languageCode == 'vi';
    return Scaffold(
      appBar: AppBar(
        title: Text(isVi ? 'Lịch sử Ngân sách' : 'Budget History'),
      ),
      body: expiredBudgets.isEmpty
          ? Center(
              child: Text(
                isVi
                    ? 'Không có ngân sách nào đã hết hạn.'
                    : 'No expired budgets found.',
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: expiredBudgets.length,
              itemBuilder: (context, index) {
                final budget = expiredBudgets[index];

                final category = categories.cast<CategoryEntity>().firstWhere(
                  (c) => c.id == budget.categoryId,
                  orElse: () => CategoryEntity(
                    id: -1,
                    name: isVi ? 'Không xác định' : 'Unknown',
                    type: 'expense',
                    icon: '',
                    updatedAt: DateTime.now(),
                  ),
                );

                final spentAmount = transactions
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

                final progress = (spentAmount / budget.amount).clamp(0.0, 1.0);
                final percentage = (spentAmount / budget.amount) * 100;
                final isOverBudget = spentAmount > budget.amount;

                final statusColor = isOverBudget ? Colors.red : Colors.blue;

                return InkWell(
                  onTap: () {
                    final budgetTransactions = transactions
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

                    budgetTransactions.sort((a, b) => b.date.compareTo(a.date));

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
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
