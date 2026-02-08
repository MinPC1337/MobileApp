import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/dashboard_cubit.dart';
import '../bloc/budget/budget_cubit.dart';
import '../bloc/setting/settings_cubit.dart';
import 'home_page.dart';
import 'budget_page.dart';
import 'settings_page.dart';
import 'transaction_page.dart';
import 'category_management_page.dart';
import 'add_edit_transaction_page.dart';
import '../bloc/transaction_form_cubit.dart';
import '../../injection_container.dart' as di;

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    // Lắng nghe thay đổi ngôn ngữ
    final isVi =
        context.watch<SettingsCubit>().state.locale.languageCode == 'vi';
    final List<Widget> pages = [
      const HomePage(),
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
        title: Text(titles[_selectedIndex]),
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
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        type: BottomNavigationBarType
            .fixed, // Cố định icon để không bị hiệu ứng nhảy khi có >3 item
        items: [
          BottomNavigationBarItem(
            icon: const Icon(Icons.home),
            label: isVi ? "Trang chủ" : "Home",
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.list),
            label: isVi ? "Giao dịch" : "Transactions",
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.pie_chart),
            label: isVi ? "Ngân sách" : "Budget",
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.settings),
            label: isVi ? "Cài đặt" : "Settings",
          ),
        ],
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
