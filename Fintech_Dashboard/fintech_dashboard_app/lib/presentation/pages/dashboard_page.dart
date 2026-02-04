import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/dashboard_cubit.dart';
import '../bloc/budget/budget_cubit.dart';
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
    final List<Widget> pages = [
      const HomePage(),
      const TransactionPage(),
      const BudgetPage(),
      const SettingsPage(),
    ];

    final List<String> titles = [
      "Trang chủ",
      "Giao dịch",
      "Ngân sách",
      "Cài đặt",
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(titles[_selectedIndex]),
        actions: [
          if (_selectedIndex == 0)
            IconButton(
              icon: const Icon(Icons.refresh),
              tooltip: 'Tải lại',
              onPressed: () =>
                  context.read<DashboardCubit>().loadDashboardData(),
            ),
          if (_selectedIndex == 1)
            IconButton(
              icon: const Icon(Icons.category_outlined),
              tooltip: 'Quản lý Danh mục',
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
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Trang chủ"),
          BottomNavigationBarItem(icon: Icon(Icons.list), label: "Giao dịch"),
          BottomNavigationBarItem(
            icon: Icon(Icons.pie_chart),
            label: "Ngân sách",
          ),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: "Cài đặt"),
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
