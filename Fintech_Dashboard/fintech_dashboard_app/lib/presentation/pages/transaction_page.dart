import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../injection_container.dart' as di;
import '../bloc/dashboard_cubit.dart';
import '../bloc/dashboard_state.dart';
import '../bloc/transaction_form_cubit.dart';
import 'add_edit_transaction_page.dart';

class TransactionPage extends StatelessWidget {
  const TransactionPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DashboardCubit, DashboardState>(
      builder: (context, state) {
        if (state.isLoading && state.transactions.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        if (state.transactions.isEmpty) {
          return const Center(child: Text("Chưa có giao dịch nào."));
        }

        return ListView.builder(
          itemCount: state.transactions.length,
          itemBuilder: (context, index) {
            final tx = state.transactions[index];
            final isIncome = tx.categoryId == 1;
            return Dismissible(
              key: Key(tx.id.toString()),
              direction: DismissDirection.endToStart,
              onDismissed: (_) {
                context.read<DashboardCubit>().deleteTransaction(tx);
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text('Đã xóa "${tx.note}"')));
              },
              background: Container(
                color: Colors.red,
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: const Icon(Icons.delete, color: Colors.white),
              ),
              child: InkWell(
                onTap: () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => BlocProvider(
                        create: (_) => di.sl<TransactionFormCubit>(),
                        child: AddEditTransactionPage(transaction: tx),
                      ),
                    ),
                  );
                  if (result == true) {
                    if (!context.mounted) return;
                    context.read<DashboardCubit>().loadDashboardData();
                  }
                },
                child: ListTile(
                  leading: Icon(
                    isIncome ? Icons.arrow_circle_up : Icons.arrow_circle_down,
                    color: isIncome ? Colors.green : Colors.red,
                    size: 40,
                  ),
                  title: Text(tx.note),
                  subtitle: Text(tx.date.toString().split(' ')[0]),
                  trailing: Text(
                    "${isIncome ? '+' : '-'}${tx.amount.toStringAsFixed(0)}đ",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isIncome ? Colors.green : Colors.red,
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
