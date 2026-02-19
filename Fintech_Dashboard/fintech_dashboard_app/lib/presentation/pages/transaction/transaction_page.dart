import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/entities/transaction_entity.dart';
import '../../bloc/budget/budget_cubit.dart';
import '../../bloc/dashboard/dashboard_cubit.dart';
import '../../bloc/dashboard/dashboard_state.dart';
import '../../bloc/setting/settings_cubit.dart';
import 'add_edit_transaction_page.dart';

class TransactionPage extends StatefulWidget {
  const TransactionPage({super.key});

  @override
  State<TransactionPage> createState() => _TransactionPageState();
}

class _TransactionPageState extends State<TransactionPage> {
  String _searchQuery = '';
  String _filterType = 'all'; // 'all', 'income', 'expense'
  DateTimeRange? _selectedDateRange;
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

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

        // --- LOGIC LỌC DỮ LIỆU ---
        final filteredTransactions = state.transactions.where((tx) {
          // 1. Lọc theo từ khóa tìm kiếm (Ghi chú hoặc Tên danh mục)
          final note = tx.note.toLowerCase();
          final category = (tx.categoryName ?? '').toLowerCase();
          final query = _searchQuery.toLowerCase();
          final matchesSearch =
              note.contains(query) || category.contains(query);

          // 2. Lọc theo loại (Thu/Chi)
          final matchesType =
              _filterType == 'all' || tx.categoryType == _filterType;

          // 3. Lọc theo ngày
          bool matchesDate = true;
          if (_selectedDateRange != null) {
            // Chuẩn hóa ngày để so sánh chính xác (bỏ qua giờ phút giây)
            final txDate = DateTime(tx.date.year, tx.date.month, tx.date.day);
            final start = _selectedDateRange!.start;
            final end = _selectedDateRange!.end;
            // start <= txDate <= end
            matchesDate = !txDate.isBefore(start) && !txDate.isAfter(end);
          }

          return matchesSearch && matchesType && matchesDate;
        }).toList();
        // -------------------------

        // Logic nhóm giao dịch theo danh mục (chuyển từ HomePage sang)
        final groupedTransactions = <String, List<dynamic>>{};
        for (final tx in filteredTransactions) {
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
            // --- THANH TÌM KIẾM VÀ BỘ LỌC ---
            Container(
              padding: const EdgeInsets.all(8.0),
              color: Theme.of(context).cardColor,
              child: Column(
                children: [
                  // Thanh tìm kiếm
                  TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: isVi
                          ? 'Tìm kiếm giao dịch...'
                          : 'Search transactions...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: 0,
                        horizontal: 10,
                      ),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                _searchController.clear();
                                setState(() => _searchQuery = '');
                              },
                            )
                          : null,
                    ),
                    onChanged: (value) => setState(() => _searchQuery = value),
                  ),
                  const SizedBox(height: 8),
                  // Các nút lọc
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        // Lọc theo ngày
                        ActionChip(
                          avatar: const Icon(Icons.calendar_today, size: 16),
                          label: Text(
                            _selectedDateRange == null
                                ? (isVi ? 'Tất cả thời gian' : 'All time')
                                : '${_selectedDateRange!.start.day}/${_selectedDateRange!.start.month} - ${_selectedDateRange!.end.day}/${_selectedDateRange!.end.month}',
                          ),
                          onPressed: () async {
                            final picked = await showDateRangePicker(
                              context: context,
                              firstDate: DateTime(2020),
                              lastDate: DateTime.now().add(
                                const Duration(days: 365),
                              ),
                              initialDateRange: _selectedDateRange,
                            );
                            if (picked != null) {
                              setState(() => _selectedDateRange = picked);
                            } else {
                              // Nếu user hủy hoặc muốn xóa lọc ngày, có thể thêm logic xóa ở đây
                              // Hiện tại giữ nguyên nếu hủy
                            }
                          },
                        ),
                        if (_selectedDateRange != null)
                          IconButton(
                            icon: const Icon(Icons.close, size: 18),
                            onPressed: () =>
                                setState(() => _selectedDateRange = null),
                          ),
                        const SizedBox(width: 8),
                        // Lọc theo loại (ChoiceChips)
                        Wrap(
                          spacing: 8.0,
                          children: [
                            _buildFilterChip(
                              label: isVi ? 'Tất cả' : 'All',
                              value: 'all',
                              isSelected: _filterType == 'all',
                            ),
                            _buildFilterChip(
                              label: isVi ? 'Thu nhập' : 'Income',
                              value: 'income',
                              isSelected: _filterType == 'income',
                              color: Colors.green.withValues(),
                            ),
                            _buildFilterChip(
                              label: isVi ? 'Chi tiêu' : 'Expense',
                              value: 'expense',
                              isSelected: _filterType == 'expense',
                              color: Colors.red.withValues(),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // --------------------------------
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

  Widget _buildFilterChip({
    required String label,
    required String value,
    required bool isSelected,
    Color? color,
  }) {
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) setState(() => _filterType = value);
      },
      selectedColor: color ?? Theme.of(context).primaryColor.withValues(),
    );
  }
}
