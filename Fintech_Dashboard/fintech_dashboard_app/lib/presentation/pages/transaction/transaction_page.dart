import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/entities/transaction_entity.dart';
import '../../bloc/budget/budget_cubit.dart';
import '../../bloc/dashboard/dashboard_cubit.dart';
import '../../bloc/dashboard/dashboard_state.dart';
import '../../bloc/setting/settings_cubit.dart';
import 'add_edit_transaction_page.dart';

class TransactionPage extends StatelessWidget {
  const TransactionPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Lắng nghe thay đổi ngôn ngữ từ SettingsCubit
    final isVi =
        context.watch<SettingsCubit>().state.locale.languageCode == 'vi';

    return BlocBuilder<DashboardCubit, DashboardState>(
      builder: (context, state) {
        if (state.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (state.errorMessage != null) {
          return Center(child: Text(state.errorMessage!));
        }

        if (state.transactions.isEmpty) {
          return Center(
            child: Text(
              isVi ? "Chưa có giao dịch nào." : "No transactions yet.",
            ),
          );
        }

        // Logic nhóm giao dịch theo danh mục (chuyển từ HomePage sang)
        final groupedTransactions = <String, List<dynamic>>{};
        for (final tx in state.transactions) {
          final categoryName =
              tx.categoryName ?? (isVi ? 'Chưa phân loại' : 'Uncategorized');
          if (groupedTransactions[categoryName] == null) {
            groupedTransactions[categoryName] = [];
          }
          groupedTransactions[categoryName]!.add(tx);
        }

        final categoryKeys = groupedTransactions.keys.toList();
        categoryKeys.sort(); // Sắp xếp tên danh mục A-Z

        return Column(
          children: [
            Expanded(
              child: ListView.builder(
                itemCount: categoryKeys.length,
                itemBuilder: (context, index) {
                  final categoryName = categoryKeys[index];
                  final transactionsForCategory =
                      groupedTransactions[categoryName]!;

                  // Tính tổng tiền cho nhóm này
                  double categoryTotal = 0;
                  for (var t in transactionsForCategory) {
                    if (t.categoryType == 'income') {
                      categoryTotal += t.amount;
                    } else {
                      categoryTotal -= t.amount;
                    }
                  }

                  final displayTotal = categoryTotal.abs();

                  return ExpansionTile(
                    title: Text(
                      categoryName,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      "${isVi ? 'Tổng' : 'Total'}: ${displayTotal.toStringAsFixed(0)}đ",
                    ),
                    initiallyExpanded: true,
                    children: transactionsForCategory.map<Widget>((tx) {
                      final isIncome = tx.categoryType == 'income';
                      final color = isIncome ? Colors.green : Colors.red;
                      final icon = isIncome
                          ? Icons.arrow_upward
                          : Icons.arrow_downward;

                      // Chức năng vuốt để xóa
                      return Dismissible(
                        key: ValueKey(tx.id),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          color: Colors.red,
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.symmetric(horizontal: 20.0),
                          child: const Icon(Icons.delete, color: Colors.white),
                        ),
                        confirmDismiss: (direction) async {
                          // Hiển thị hộp thoại xác nhận trước khi xóa
                          final confirmed = await showDialog<bool>(
                            context: context,
                            builder: (BuildContext context) {
                              return AlertDialog(
                                title: Text(
                                  isVi ? 'Xác nhận Xóa' : 'Confirm Delete',
                                ),
                                content: Text(
                                  isVi
                                      ? 'Bạn có chắc chắn muốn xóa giao dịch này không?'
                                      : 'Are you sure you want to delete this transaction?',
                                ),
                                actions: <Widget>[
                                  TextButton(
                                    child: Text(isVi ? 'Hủy' : 'Cancel'),
                                    onPressed: () =>
                                        Navigator.of(context).pop(false),
                                  ),
                                  TextButton(
                                    style: TextButton.styleFrom(
                                      foregroundColor: Colors.red,
                                    ),
                                    child: Text(isVi ? 'Xóa' : 'Delete'),
                                    onPressed: () =>
                                        Navigator.of(context).pop(true),
                                  ),
                                ],
                              );
                            },
                          );
                          return confirmed ?? false;
                        },
                        onDismissed: (direction) {
                          context.read<DashboardCubit>().deleteTransaction(
                            tx as TransactionEntity,
                          );
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                isVi
                                    ? 'Đã xóa giao dịch'
                                    : 'Transaction deleted',
                              ),
                            ),
                          );
                        },
                        child: ListTile(
                          leading: Icon(icon, color: color),
                          title: Text(
                            tx.note.isNotEmpty ? tx.note : categoryName,
                          ),
                          subtitle: Text(tx.date.toString().split(' ')[0]),
                          trailing: Text(
                            "${isIncome ? '+' : '-'}${tx.amount.toStringAsFixed(0)}đ",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: color,
                            ),
                          ),
                          // Chức năng nhấn để sửa
                          onTap: () async {
                            final result = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => AddEditTransactionPage(
                                  transaction: tx as TransactionEntity,
                                ),
                              ),
                            );
                            // Nếu sửa thành công (result == true), tải lại dữ liệu
                            if (result == true && context.mounted) {
                              context
                                  .read<DashboardCubit>()
                                  .loadDashboardData();
                              // Cập nhật lại ngân sách vì giao dịch thay đổi ảnh hưởng đến số tiền đã chi
                              context.read<BudgetCubit>().loadBudgetData();
                            }
                          },
                        ),
                      );
                    }).toList(),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}
