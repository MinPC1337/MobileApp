import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/dashboard_cubit.dart';
import '../bloc/dashboard_state.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DashboardCubit, DashboardState>(
      builder: (context, state) {
        if (state.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (state.errorMessage != null) {
          return Center(
            child: Text(
              state.errorMessage!,
              style: const TextStyle(color: Colors.red),
            ),
          );
        }

        return Column(
          children: [
            // Phần hiển thị Số dư (Balance Card)
            _buildBalanceCard(state.totalBalance),

            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "Giao dịch gần đây",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ),

            // Danh sách giao dịch
            Expanded(
              child: state.transactions.isEmpty
                  ? const Center(child: Text("Chưa có giao dịch nào."))
                  : ListView.builder(
                      // Chỉ hiển thị tối đa 10 giao dịch gần nhất
                      itemCount: state.transactions.length > 5
                          ? 5
                          : state.transactions.length,
                      itemBuilder: (context, index) {
                        final tx = state.transactions[index];
                        final isIncome = tx.categoryType == 'income';
                        final color = isIncome ? Colors.green : Colors.red;
                        final icon = isIncome
                            ? Icons.arrow_upward
                            : Icons.arrow_downward;

                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: color.shade100,
                            child: Icon(icon, color: color),
                          ),
                          title: Text(
                            tx.note.isNotEmpty
                                ? tx.note
                                : (tx.categoryName ?? 'Giao dịch'),
                          ),
                          subtitle: Text(tx.date.toString().split(' ')[0]),
                          trailing: Text(
                            "${isIncome ? '+' : '-'}${tx.amount.toStringAsFixed(0)}đ",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: color,
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildBalanceCard(double balance) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Colors.blue, Colors.blueAccent],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Tổng số dư",
            style: TextStyle(color: Colors.white70, fontSize: 16),
          ),
          const SizedBox(height: 8),
          Text(
            "$balance VND",
            style: const TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
