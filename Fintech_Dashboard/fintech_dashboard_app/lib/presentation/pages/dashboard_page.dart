import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../bloc/dashboard/dashboard_cubit.dart';
import '../bloc/budget/budget_cubit.dart';
import '../bloc/setting/settings_cubit.dart';
import 'home/home_page.dart';
import 'budget/budget_page.dart';
import 'setting/settings_page.dart';
import 'transaction/transaction_page.dart';
import 'transaction/category_management_page.dart';
import 'transaction/add_edit_transaction_page.dart';
import '../bloc/transaction/transaction_form_cubit.dart';
import '../../injection_container.dart' as di;

// Helper class for structuring notification data before displaying
class _NotificationInfo {
  final String message;
  final IconData icon;
  final Color iconColor;
  final DateTime date;

  _NotificationInfo({
    required this.message,
    required this.icon,
    required this.iconColor,
    required this.date,
  });
}

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  int _selectedIndex = 0;

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void _showNotifications(BuildContext context) {
    final budgetState = context.read<BudgetCubit>().state;
    final dashboardState = context.read<DashboardCubit>().state;
    final isVi =
        context.read<SettingsCubit>().state.locale.languageCode == 'vi';

    // Use a list of structured data to make sorting and grouping easier
    final List<_NotificationInfo> notifications = [];

    // 1. Overall spending notification (vs income)
    double totalIncome = 0;
    double totalExpense = 0;
    for (var tx in dashboardState.transactions) {
      if (tx.categoryType == 'income') {
        totalIncome += tx.amount;
      } else {
        totalExpense += tx.amount;
      }
    }

    if (totalIncome > 0) {
      final percentage = (totalExpense / totalIncome) * 100;
      String? message;
      IconData? icon;
      Color? iconColor;

      if (percentage > 100) {
        message = isVi
            ? 'Tổng chi tiêu đã vượt tổng thu nhập! (${percentage.toStringAsFixed(0)}%)'
            : 'Total expenses have exceeded total income! (${percentage.toStringAsFixed(0)}%)';
        icon = Icons.error_outline;
        iconColor = Colors.red;
      } else if (percentage >= 80) {
        message = isVi
            ? 'Tổng chi tiêu sắp bằng tổng thu nhập. (${percentage.toStringAsFixed(0)}%)'
            : 'Total expenses are nearing total income. (${percentage.toStringAsFixed(0)}%)';
        icon = Icons.warning_amber_rounded;
        iconColor = Colors.orange;
      }

      if (message != null) {
        DateTime? warningDate;
        final expenseTransactions = dashboardState.transactions
            .where((tx) => tx.categoryType == 'expense')
            .toList();
        if (expenseTransactions.isNotEmpty) {
          expenseTransactions.sort((a, b) => b.date.compareTo(a.date));
          warningDate = expenseTransactions.first.date;
        }

        if (warningDate != null) {
          notifications.add(
            _NotificationInfo(
              message: message,
              icon: icon!,
              iconColor: iconColor!,
              date: warningDate,
            ),
          );
        }
      }
    }

    // 2. Budget notifications
    final budgets = budgetState.budgets;
    final budgetTransactions = budgetState.transactions;
    final categories = budgetState.categories;
    final categoryMap = {for (var cat in categories) cat.id: cat};

    for (var budget in budgets) {
      final category = categoryMap[budget.categoryId];
      if (category == null) continue;

      final spent = budgetTransactions
          .where(
            (t) =>
                t.categoryId == budget.categoryId &&
                t.categoryType == 'expense',
          )
          .fold(0.0, (sum, t) => sum + t.amount);

      final limit = budget.amount;
      if (limit > 0) {
        final percentage = (spent / limit) * 100;
        String? message;
        IconData? icon;
        Color? iconColor;

        if (percentage > 100) {
          message = isVi
              ? 'Vượt ngân sách cho "${category.name}"! (${percentage.toStringAsFixed(0)}%)'
              : 'Over budget for "${category.name}"! (${percentage.toStringAsFixed(0)}%)';
          icon = Icons.error_outline;
          iconColor = Colors.red;
        } else if (percentage >= 80) {
          message = isVi
              ? 'Sắp hết ngân sách cho "${category.name}". Đã dùng ${percentage.toStringAsFixed(0)}%.'
              : 'Nearing budget limit for "${category.name}". Used ${percentage.toStringAsFixed(0)}%.';
          icon = Icons.warning_amber_rounded;
          iconColor = Colors.orange;
        }

        if (message != null) {
          DateTime? warningDate;
          final categoryTransactions = budgetTransactions
              .where(
                (t) =>
                    t.categoryId == budget.categoryId &&
                    t.categoryType == 'expense',
              )
              .toList();
          if (categoryTransactions.isNotEmpty) {
            categoryTransactions.sort((a, b) => b.date.compareTo(a.date));
            warningDate = categoryTransactions.first.date;
          }

          if (warningDate != null) {
            notifications.add(
              _NotificationInfo(
                message: message,
                icon: icon!,
                iconColor: iconColor!,
                date: warningDate,
              ),
            );
          }
        }
      }
    }

    // 3. Sort notifications by date (newest first)
    notifications.sort((a, b) => b.date.compareTo(a.date));

    // 4. Build the final list of widgets with group headers
    final List<Widget> notificationWidgets = [];
    DateTime? lastDateHeader;

    for (final notification in notifications) {
      final notificationDate = DateTime(
        notification.date.year,
        notification.date.month,
        notification.date.day,
      );

      if (lastDateHeader == null || notificationDate.isBefore(lastDateHeader)) {
        notificationWidgets.add(
          Padding(
            padding: const EdgeInsets.only(top: 16.0, bottom: 8.0, left: 8.0),
            child: Text(
              _getGroupHeader(notificationDate, isVi),
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).hintColor,
              ),
            ),
          ),
        );
        lastDateHeader = notificationDate;
      }

      notificationWidgets.add(
        ListTile(
          leading: Icon(notification.icon, color: notification.iconColor),
          title: Text(notification.message),
        ),
      );
    }

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 8.0, bottom: 8.0),
                child: Text(
                  isVi ? 'Thông báo' : 'Notifications',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
              ),
              if (notificationWidgets.isEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 32.0),
                    child: Column(
                      children: [
                        Icon(
                          Icons.notifications_off_outlined,
                          size: 48,
                          color: Colors.grey,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          isVi
                              ? 'Không có thông báo mới.'
                              : 'No new notifications.',
                        ),
                      ],
                    ),
                  ),
                )
              else
                Flexible(
                  child: ListView(
                    shrinkWrap: true,
                    children: notificationWidgets,
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  String _getGroupHeader(DateTime date, bool isVi) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    if (date == today) {
      return isVi ? 'Hôm nay' : 'Today';
    } else if (date == yesterday) {
      return isVi ? 'Hôm qua' : 'Yesterday';
    } else {
      // Use a more descriptive format for older dates
      return DateFormat.yMMMd(isVi ? 'vi_VN' : 'en_US').format(date);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isVi =
        context.watch<SettingsCubit>().state.locale.languageCode == 'vi';
    final List<Widget> pages = [
      HomePage(onViewAllTransactions: () => _onItemTapped(1)),
      const TransactionPage(),
      const BudgetPage(),
      const SettingsPage(),
    ];

    final List<String> titles = [
      isVi ? "Trang chủ" : "Home",
      isVi ? "Giao dịch" : "Transactions",
      isVi ? "Ngân sách" : "Budget",
      isVi ? "Cài đặt" : "Settings",
    ];

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        title: Text(
          titles[_selectedIndex],
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
        actions: [
          if (_selectedIndex == 0)
            IconButton(
              icon: const Icon(Icons.notifications_outlined),
              tooltip: isVi ? 'Thông báo' : 'Notifications',
              onPressed: () {
                _showNotifications(context);
              },
            ),
          if (_selectedIndex == 1)
            IconButton(
              icon: const Icon(Icons.category_outlined),
              tooltip: isVi ? 'Quản lý Danh mục' : 'Manage Categories',
              onPressed: () {
                Navigator.of(context)
                    .push(
                      MaterialPageRoute(
                        builder: (_) => const CategoryManagementPage(),
                      ),
                    )
                    .then((_) {
                      // Tải lại dữ liệu ngân sách để cập nhật danh sách danh mục mới nhất
                      if (context.mounted) {
                        context.read<BudgetCubit>().loadBudgetData();
                      }
                    });
              },
            ),
        ],
      ),
      body: pages[_selectedIndex],
      bottomNavigationBar: Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 20,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BottomNavigationBar(
            currentIndex: _selectedIndex,
            onTap: _onItemTapped,
            type: BottomNavigationBarType.fixed,
            backgroundColor: Colors.transparent,
            elevation: 0,
            selectedItemColor: Theme.of(context).colorScheme.primary,
            unselectedItemColor: Theme.of(
              context,
            ).textTheme.bodySmall?.color?.withOpacity(0.6),
            items: [
              BottomNavigationBarItem(
                icon: const Icon(Icons.home_rounded),
                label: isVi ? "Trang chủ" : "Home",
              ),
              BottomNavigationBarItem(
                icon: const Icon(Icons.swap_horiz_rounded),
                label: isVi ? "Giao dịch" : "Transactions",
              ),
              BottomNavigationBarItem(
                icon: const Icon(Icons.pie_chart_outline_rounded),
                label: isVi ? "Ngân sách" : "Budget",
              ),
              BottomNavigationBarItem(
                icon: const Icon(Icons.settings_rounded),
                label: isVi ? "Cài đặt" : "Settings",
              ),
            ],
          ),
        ),
      ),
      floatingActionButton:
          _selectedIndex ==
              1 // Chỉ hiển thị ở tab Giao dịch
          ? FloatingActionButton(
              onPressed: () async {
                // Điều hướng và chờ kết quả trả về
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => BlocProvider(
                      create: (_) => di.sl<TransactionFormCubit>(),
                      child: const AddEditTransactionPage(),
                    ),
                  ),
                );
                // Nếu kết quả là true (thêm thành công), tải lại dữ liệu
                if (result == true) {
                  if (!context.mounted) return;
                  context.read<DashboardCubit>().loadDashboardData();
                  // Tải lại ngân sách để cập nhật tiến độ chi tiêu và danh mục mới (nếu có)
                  context.read<BudgetCubit>().loadBudgetData();
                }
              },
              child: const Icon(Icons.add),
            )
          : null,
    );
  }
}
