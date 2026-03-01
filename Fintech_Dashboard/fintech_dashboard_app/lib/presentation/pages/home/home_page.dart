import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../domain/entities/budget_entity.dart';
import '../../../domain/entities/category_entity.dart';
import '../../../domain/entities/transaction_entity.dart';
import '../../bloc/budget/budget_cubit.dart';
import '../../bloc/budget/budget_state.dart';
import '../../bloc/dashboard/dashboard_cubit.dart';
import '../../bloc/dashboard/dashboard_state.dart';
import '../../bloc/setting/settings_cubit.dart';
import '../../../core/utils/app_icons.dart';
import '../transaction/add_edit_transaction_page.dart';

class HomePage extends StatefulWidget {
  final VoidCallback onViewAllTransactions;

  const HomePage({super.key, required this.onViewAllTransactions});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  DateTime _selectedDate = DateTime.now();

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

        // Lọc giao dịch theo tháng đã chọn
        final monthlyTransactions = state.transactions.where((tx) {
          return tx.date.year == _selectedDate.year &&
              tx.date.month == _selectedDate.month;
        }).toList();

        // Tính toán tổng thu và tổng chi
        double totalIncome = 0;
        double totalExpense = 0;
        // Chỉ tính tổng thu/chi cho tháng được chọn để hiển thị tương ứng
        for (var tx in monthlyTransactions) {
          if (tx.categoryType == 'income') {
            totalIncome += tx.amount;
          } else {
            totalExpense += tx.amount;
          }
        }
        return RefreshIndicator(
          onRefresh: () async {
            // Lấy các cubit trước khi thực hiện các tác vụ bất đồng bộ
            // và chạy chúng song song để cải thiện hiệu suất.
            final dashboardCubit = context.read<DashboardCubit>();
            final budgetCubit = context.read<BudgetCubit>();
            await Future.wait([
              dashboardCubit.loadDashboardData(),
              budgetCubit.loadBudgetData(),
            ]);
          },
          child: ListView(
            children: [
              // Widget chọn tháng
              _buildMonthSelector(isVi),

              // Phần hiển thị Số dư (Balance Card)
              _buildBalanceCard(
                state.totalBalance,
                totalIncome,
                totalExpense,
                isVi,
              ),

              // Biểu đồ tròn chi tiêu
              _buildExpensePieChart(
                context,
                monthlyTransactions, // Truyền danh sách đã lọc theo tháng
                totalExpense,
                isVi,
              ),

              // Biểu đồ ngân sách
              BlocBuilder<BudgetCubit, BudgetState>(
                builder: (context, budgetState) {
                  if (budgetState.isLoading && budgetState.budgets.isEmpty) {
                    return const SizedBox.shrink();
                  }
                  if (budgetState.budgets.isEmpty) {
                    return const SizedBox.shrink();
                  }
                  // Use data from BudgetState for the budget chart for consistency
                  return _buildBudgetBarChart(
                    context,
                    budgetState.budgets,
                    budgetState.transactions,
                    budgetState.categories,
                    isVi,
                  );
                },
              ),

              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 8, 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      isVi ? "Giao dịch gần đây" : "Recent Transactions",
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    TextButton(
                      onPressed: widget.onViewAllTransactions,
                      child: Text(isVi ? 'Xem tất cả' : 'See all'),
                    ),
                  ],
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
                        final color = isIncome
                            ? Colors.green.shade600
                            : Colors.red.shade600;
                        final icon = AppIcons.getIconFromString(
                          tx.categoryIcon,
                        );

                        return Card(
                          margin: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 6,
                          ),
                          elevation: 1,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: ListTile(
                            onTap: () async {
                              final result = await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      AddEditTransactionPage(transaction: tx),
                                ),
                              );
                              if (result == true && context.mounted) {
                                context
                                    .read<DashboardCubit>()
                                    .loadDashboardData();
                                context.read<BudgetCubit>().loadBudgetData();
                              }
                            },
                            leading: CircleAvatar(
                              backgroundColor: color.withOpacity(0.1),
                              child: Icon(icon, color: color, size: 20),
                            ),
                            title: Text(
                              tx.categoryName ??
                                  (isVi ? 'Chưa phân loại' : 'Uncategorized'),
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            subtitle: tx.note.isNotEmpty
                                ? Text(
                                    tx.note,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  )
                                : null,
                            trailing: Text(
                              "${isIncome ? '+' : '-'}${NumberFormat.compactCurrency(locale: isVi ? 'vi_VN' : 'en_US', symbol: 'đ', decimalDigits: 0).format(tx.amount)}",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: color,
                                fontSize: 15,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMonthSelector(bool isVi) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: () {
              setState(() {
                _selectedDate = DateTime(
                  _selectedDate.year,
                  _selectedDate.month - 1,
                );
              });
            },
          ),
          Row(
            children: [
              const Icon(Icons.calendar_month, size: 20, color: Colors.blue),
              const SizedBox(width: 8),
              Text(
                DateFormat(
                  isVi ? 'MM/yyyy' : 'MMMM yyyy',
                  isVi ? 'vi_VN' : 'en_US',
                ).format(_selectedDate),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: () {
              setState(() {
                _selectedDate = DateTime(
                  _selectedDate.year,
                  _selectedDate.month + 1,
                );
              });
            },
          ),
        ],
      ),
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
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.4),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
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
                        isVi ? "Thu nhập (Tháng)" : "Income (Mo)",
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
                        isVi ? "Chi tiêu (Tháng)" : "Expense (Mo)",
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
    BuildContext context,
    List<TransactionEntity> transactions,
    double totalExpense,
    bool isVi,
  ) {
    // 1. Lọc và nhóm dữ liệu chi tiêu (Expense)
    final expenses = transactions
        .where((t) => t.categoryType == 'expense')
        .toList();

    if (expenses.isEmpty || totalExpense == 0) {
      // Hiển thị thông báo trống thay vì ẩn hoàn toàn để người dùng biết tháng này chưa có dữ liệu
      return Card(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Center(
            child: Text(
              isVi
                  ? 'Không có dữ liệu chi tiêu trong tháng này'
                  : 'No expense data for this month',
              style: const TextStyle(color: Colors.grey),
            ),
          ),
        ),
      );
    }

    final Map<String, double> dataMap = {};
    for (var tx in expenses) {
      final catName = tx.categoryName ?? (isVi ? 'Khác' : 'Other');
      dataMap[catName] = (dataMap[catName] ?? 0) + tx.amount;
    }

    // Sắp xếp giảm dần theo số tiền
    final sortedKeys = dataMap.keys.toList();
    sortedKeys.sort((a, b) => dataMap[b]!.compareTo(dataMap[a]!));

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
          crossAxisAlignment: CrossAxisAlignment.start,
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
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0.0, end: 1.0),
                    duration: const Duration(milliseconds: 750),
                    curve: Curves.easeOut,
                    builder: (context, animationValue, child) {
                      return PieChart(
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
                              color: color, // Giữ màu sắc không đổi
                              value:
                                  value, // Giữ value không đổi để tỉ lệ luôn đúng
                              title: '${percentage.toStringAsFixed(0)}%',
                              radius:
                                  50 *
                                  animationValue, // Thay vào đó, animate bán kính
                              titleStyle: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Colors.white.withOpacity(animationValue),
                              ),
                            );
                          }).toList(),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 24),
                // Chú thích (Legend)
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: sortedKeys.take(5).map((key) {
                      final index = sortedKeys.indexOf(key);
                      final color = colors[index % colors.length];
                      final value = dataMap[key]!;
                      final percentage = (value / totalExpense * 100);

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 4.0),
                        child: Row(
                          children: [
                            Container(width: 12, height: 12, color: color),
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

  Widget _buildBudgetBarChart(
    BuildContext context,
    List<BudgetEntity> budgets,
    List<TransactionEntity> transactions,
    List<CategoryEntity> categories,
    bool isVi,
  ) {
    // Xác định ngày đầu và cuối của tháng được chọn
    final startOfMonth = DateTime(_selectedDate.year, _selectedDate.month, 1);
    final endOfMonth = DateTime(
      _selectedDate.year,
      _selectedDate.month + 1,
      0,
      23,
      59,
      59,
    );

    // Lọc các ngân sách có hiệu lực trong tháng được chọn (có giao nhau về thời gian)
    final activeBudgets = budgets.where((b) {
      return b.startDate.isBefore(endOfMonth) &&
          b.endDate.isAfter(startOfMonth);
    }).toList();

    if (activeBudgets.isEmpty) {
      return const SizedBox.shrink();
    }

    final List<Map<String, dynamic>> chartData = [];
    // Không giới hạn số lượng ngân sách
    for (var budget in activeBudgets) {
      final category = categories.cast<CategoryEntity>().firstWhere(
        (c) => c.id == budget.categoryId,
        orElse: () => CategoryEntity(
          id: -1,
          name: isVi ? 'Khác' : 'Other',
          type: 'expense',
          icon: '',
          updatedAt: DateTime.now(),
        ),
      );

      // Tính toán chi tiêu CHỈ trong tháng được chọn và nằm trong khoảng thời gian ngân sách
      final spent = transactions
          .where(
            (t) =>
                t.categoryId == budget.categoryId && // Đúng danh mục
                t.categoryType == 'expense' && // Là chi tiêu
                t.date.year == _selectedDate.year && // Trong năm đã chọn
                t.date.month == _selectedDate.month && // Trong tháng đã chọn
                !t.date.isBefore(
                  budget.startDate,
                ) && // Sau hoặc bằng ngày bắt đầu
                t.date.isBefore(
                  budget.endDate.add(const Duration(days: 1)),
                ), // Trước hoặc bằng ngày kết thúc
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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isVi ? 'Tiến độ ngân sách' : 'Budget Progress',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 200,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SizedBox(
                  width: chartData.length * 60.0,
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0.0, end: 1.0),
                    duration: const Duration(milliseconds: 750),
                    curve: Curves.easeOut,
                    builder: (context, animationValue, child) {
                      return BarChart(
                        BarChartData(
                          alignment: BarChartAlignment.spaceAround,
                          barTouchData: BarTouchData(
                            enabled: animationValue == 1.0,
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
                                  final index = value.toInt();
                                  if (index >= 0 && index < chartData.length) {
                                    final name =
                                        chartData[index]['name'] as String;
                                    return SideTitleWidget(
                                      meta: meta,
                                      space: 4.0,
                                      child: Text(
                                        name.length > 5
                                            ? '${name.substring(0, 4)}...'
                                            : name,
                                        style: const TextStyle(fontSize: 10),
                                      ),
                                    );
                                  }
                                  return const Text('');
                                },
                                reservedSize: 30,
                              ),
                            ),
                            leftTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                reservedSize: 40,
                                getTitlesWidget: (value, meta) {
                                  return SideTitleWidget(
                                    meta: meta,
                                    space: 4,
                                    child: Text(
                                      NumberFormat.compactCurrency(
                                        locale: isVi ? 'vi_VN' : 'en_US',
                                        symbol: '',
                                        decimalDigits: 0,
                                      ).format(value),
                                      style: const TextStyle(
                                        color: Colors.grey,
                                        fontSize: 10,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                            topTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false),
                            ),
                            rightTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false),
                            ),
                          ),
                          borderData: FlBorderData(show: false),
                          gridData: FlGridData(
                            show: true,
                            drawVerticalLine: false,
                            getDrawingHorizontalLine: (value) {
                              return FlLine(
                                color: Colors.grey.withOpacity(0.2),
                                strokeWidth: 1,
                              );
                            },
                          ),
                          barGroups: chartData.asMap().entries.map((entry) {
                            final index = entry.key;
                            final data = entry.value;
                            final limit = data['limit'] as double;
                            final spent = data['spent'] as double;
                            final isOver = spent > limit;
                            final isWarning = !isOver && spent > (limit * 0.7);

                            return BarChartGroupData(
                              x: index,
                              barRods: [
                                BarChartRodData(
                                  toY: spent * animationValue,
                                  color: isOver
                                      ? Colors.red
                                      : (isWarning
                                            ? Colors.orange
                                            : Colors.blue),
                                  width: 22,
                                  borderRadius: const BorderRadius.all(
                                    Radius.circular(6),
                                  ),
                                  backDrawRodData: BackgroundBarChartRodData(
                                    show: true,
                                    toY: limit,
                                    color: Colors.grey.shade300,
                                  ),
                                ),
                              ],
                            );
                          }).toList(),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
