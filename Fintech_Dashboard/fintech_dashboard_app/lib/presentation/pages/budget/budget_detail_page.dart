import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/entities/budget_entity.dart';
import '../../../domain/entities/category_entity.dart';
import '../../../domain/entities/transaction_entity.dart';
import '../../bloc/setting/settings_cubit.dart';
import '../../../core/utils/app_icons.dart';

class BudgetDetailPage extends StatelessWidget {
  final BudgetEntity budget;
  final CategoryEntity category;
  final List<TransactionEntity> budgetTransactions;
  final double spentAmount;

  const BudgetDetailPage({
    super.key,
    required this.budget,
    required this.category,
    required this.budgetTransactions,
    required this.spentAmount,
  });

  @override
  Widget build(BuildContext context) {
    final isVi =
        context.watch<SettingsCubit>().state.locale.languageCode == 'vi';
    final progress = (spentAmount / budget.amount).clamp(0.0, 1.0);
    final isOverBudget = spentAmount > budget.amount;
    final statusColor = isOverBudget ? Colors.red : Colors.blue;

    return Scaffold(
      appBar: AppBar(title: Text(category.name)),
      body: ListView(
        children: [
          // Summary Card
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isVi ? 'Tổng quan ngân sách' : 'Budget Overview',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  "${DateFormat.yMd(isVi ? 'vi_VN' : 'en_US').format(budget.startDate)} - ${DateFormat.yMd(isVi ? 'vi_VN' : 'en_US').format(budget.endDate)}",
                  style: TextStyle(
                    color: Theme.of(context).hintColor,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 16),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: progress,
                    backgroundColor: Theme.of(
                      context,
                    ).dividerColor.withOpacity(0.1),
                    color: statusColor,
                    minHeight: 10,
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
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      "${isVi ? 'của' : 'of'} ${NumberFormat.currency(locale: isVi ? 'vi_VN' : 'en_US', symbol: 'đ', decimalDigits: 0).format(budget.amount)}",
                      style: TextStyle(
                        color: Theme.of(context).hintColor,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              isVi ? 'Giao dịch liên quan' : 'Related Transactions',
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
          // Transactions List
          if (budgetTransactions.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 48.0),
              child: Center(
                child: Text(
                  isVi
                      ? 'Không có giao dịch nào trong ngân sách này.'
                      : 'No transactions in this budget.',
                ),
              ),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: budgetTransactions.length,
              itemBuilder: (context, index) {
                final tx = budgetTransactions[index];
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.red.withOpacity(0.1),
                    child: Icon(
                      AppIcons.getIconFromString(category.icon),
                      color: Colors.red,
                      size: 20,
                    ),
                  ),
                  title: Text(
                    tx.note.isNotEmpty
                        ? tx.note
                        : (isVi ? 'Không có ghi chú' : 'No note'),
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(
                    DateFormat.yMMMd(isVi ? 'vi_VN' : 'en_US').format(tx.date),
                  ),
                  trailing: Text(
                    "-${NumberFormat.currency(locale: isVi ? 'vi_VN' : 'en_US', symbol: 'đ', decimalDigits: 0).format(tx.amount)}",
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.red,
                      fontSize: 15,
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}
