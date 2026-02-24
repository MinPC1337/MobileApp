import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/entities/category_entity.dart';
import '../../../domain/entities/transaction_entity.dart';
import '../../bloc/budget/budget_cubit.dart';
import '../../bloc/budget/budget_state.dart';
import '../../bloc/dashboard/dashboard_cubit.dart';
import '../../bloc/dashboard/dashboard_state.dart';
import '../../bloc/setting/settings_cubit.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final isVi =
        context.watch<SettingsCubit>().state.locale.languageCode == 'vi';
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

        // Tính toán tổng thu và tổng chi
        double totalIncome = 0;
        double totalExpense = 0;
        for (var tx in state.transactions) {
          if (tx.categoryType == 'income') {
            totalIncome += tx.amount;
          } else {
            totalExpense += tx.amount;
          }
        }

        return ListView(
          children: [
            // Phần hiển thị Số dư (Balance Card)
            _buildBalanceCard(
              state.totalBalance,
              totalIncome,
              totalExpense,
              isVi,
            ),

            // Biểu đồ tròn chi tiêu
            _buildExpensePieChart(state.transactions, isVi),

            // Biểu đồ ngân sách
            _buildBudgetBarChart(context, isVi),

            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  isVi ? "Giao dịch gần đây" : "Recent Transactions",
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

            // Danh sách giao dịch
            state.transactions.isEmpty
                ? Padding(
                    padding: const EdgeInsets.symmetric(vertical: 48.0),
                    child: Center(
                      child: Text(
                        isVi
                            ? "Chưa có giao dịch nào."
                            : "No transactions yet.",
                      ),
                    ),
                  )
                : ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
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
                              : (tx.categoryName ??
                                    (isVi ? 'Giao dịch' : 'Transaction')),
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
          ],
        );
      },
    );
  }

  Widget _buildBalanceCard(
    double balance,
    double income,
    double expense,
    bool isVi,
  ) {
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
          Text(
            isVi ? "Tổng số dư" : "Total Balance",
            style: const TextStyle(color: Colors.white70, fontSize: 16),
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
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Hiển thị Tổng thu
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.arrow_upward,
                      color: Colors.greenAccent,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isVi ? "Thu nhập" : "Income",
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        "${income.toStringAsFixed(0)}đ",
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              // Hiển thị Tổng chi
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.arrow_downward,
                      color: Colors.redAccent,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isVi ? "Chi tiêu" : "Expense",
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        "${expense.toStringAsFixed(0)}đ",
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildExpensePieChart(
    List<TransactionEntity> transactions,
    bool isVi,
  ) {
    // 1. Lọc và nhóm dữ liệu chi tiêu (Expense)
    final expenses = transactions
        .where((t) => t.categoryType == 'expense')
        .toList();

    if (expenses.isEmpty) {
      return const SizedBox.shrink();
    }

    final Map<String, double> dataMap = {};
    double totalExpense = 0;

    for (var tx in expenses) {
      final catName = tx.categoryName ?? (isVi ? 'Khác' : 'Other');
      dataMap[catName] = (dataMap[catName] ?? 0) + tx.amount;
      totalExpense += tx.amount;
    }

    // Sắp xếp giảm dần theo số tiền
    final sortedKeys = dataMap.keys.toList()
      ..sort((a, b) => dataMap[b]!.compareTo(dataMap[a]!));

    // Danh sách màu sắc để hiển thị
    final List<Color> colors = [
      Colors.blue,
      Colors.red,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.teal,
      Colors.amber,
      Colors.brown,
    ];

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(
              isVi ? 'Chi tiêu theo danh mục' : 'Expenses by Category',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                // Biểu đồ
                SizedBox(
                  height: 150,
                  width: 150,
                  child: PieChart(
                    PieChartData(
                      sectionsSpace: 2,
                      centerSpaceRadius: 30,
                      sections: sortedKeys.asMap().entries.map((entry) {
                        final index = entry.key;
                        final key = entry.value;
                        final value = dataMap[key]!;
                        final color = colors[index % colors.length];
                        final percentage = (value / totalExpense * 100);

                        return PieChartSectionData(
                          color: color,
                          value: value,
                          title: '${percentage.toStringAsFixed(0)}%',
                          radius: 40,
                          titleStyle: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
                const SizedBox(width: 24),
                // Chú thích (Legend)
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: sortedKeys.asMap().entries.map((entry) {
                      final index = entry.key;
                      final key = entry.value;
                      final color = colors[index % colors.length];
                      final value = dataMap[key]!;
                      final percentage = (value / totalExpense * 100);

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 4.0),
                        child: Row(
                          children: [
                            Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                color: color,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                '$key (${percentage.toStringAsFixed(0)}%)',
                                style: const TextStyle(fontSize: 12),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBudgetBarChart(BuildContext context, bool isVi) {
    return BlocBuilder<BudgetCubit, BudgetState>(
      builder: (context, state) {
        if (state.budgets.isEmpty) {
          return const SizedBox.shrink();
        }

        final List<Map<String, dynamic>> chartData = [];
        for (var budget in state.budgets) {
          final category = state.categories.cast<CategoryEntity>().firstWhere(
            (c) => c.id == budget.categoryId,
            orElse: () => CategoryEntity(
              id: -1,
              name: isVi ? 'Khác' : 'Other',
              type: 'expense',
              icon: '',
              updatedAt: DateTime.now(),
            ),
          );

          final spent = state.transactions
              .where(
                (t) =>
                    t.categoryId == budget.categoryId &&
                    t.categoryType == 'expense',
              )
              .fold(0.0, (sum, t) => sum + t.amount);

          chartData.add({
            'name': category.name,
            'limit': budget.amount,
            'spent': spent,
          });
        }

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Text(
                  isVi ? 'Tiến độ ngân sách' : 'Budget Progress',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),
                AspectRatio(
                  aspectRatio: 1.5,
                  child: BarChart(
                    BarChartData(
                      alignment: BarChartAlignment.spaceAround,
                      barTouchData: BarTouchData(
                        touchTooltipData: BarTouchTooltipData(
                          getTooltipColor: (_) => Colors.blueGrey,
                        ),
                      ),
                      titlesData: FlTitlesData(
                        show: true,
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (value, meta) {
                              if (value.toInt() >= 0 &&
                                  value.toInt() < chartData.length) {
                                final name =
                                    chartData[value.toInt()]['name'] as String;
                                return Padding(
                                  padding: const EdgeInsets.only(top: 8.0),
                                  child: Text(
                                    name.length > 4
                                        ? '${name.substring(0, 4)}..'
                                        : name,
                                    style: const TextStyle(fontSize: 10),
                                  ),
                                );
                              }
                              return const SizedBox.shrink();
                            },
                          ),
                        ),
                        leftTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        topTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        rightTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                      ),
                      borderData: FlBorderData(show: false),
                      gridData: const FlGridData(show: false),
                      barGroups: chartData.asMap().entries.map((entry) {
                        final index = entry.key;
                        final data = entry.value;
                        final limit = data['limit'] as double;
                        final spent = data['spent'] as double;
                        final isOver = spent > limit;

                        return BarChartGroupData(
                          x: index,
                          barRods: [
                            BarChartRodData(
                              toY: limit,
                              color: Colors.grey.shade300,
                              width: 10,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            BarChartRodData(
                              toY: spent,
                              color: isOver ? Colors.red : Colors.blue,
                              width: 10,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
