import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
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
              icon: const Icon(Icons.refresh),
              tooltip: isVi ? 'Tải lại' : 'Refresh',
              onPressed: () =>
                  context.read<DashboardCubit>().loadDashboardData(),
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
