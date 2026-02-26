import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/entities/transaction_entity.dart';
import '../../bloc/budget/budget_cubit.dart';
import '../../bloc/dashboard/dashboard_cubit.dart';
import '../../bloc/dashboard/dashboard_state.dart';
import '../../bloc/setting/settings_cubit.dart';
import 'package:intl/intl.dart';
import 'add_edit_transaction_page.dart';
import '../../../core/utils/app_icons.dart';

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

  String _formatDateHeader(DateTime date, bool isVi) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    if (date == today) return isVi ? 'Hôm nay' : 'Today';
    if (date == yesterday) return isVi ? 'Hôm qua' : 'Yesterday';
    return DateFormat(
      isVi ? 'd MMMM, yyyy' : 'MMMM d, yyyy',
      isVi ? 'vi_VN' : 'en_US',
    ).format(date);
  }

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

        // --- NEW GROUPING LOGIC BY DATE ---
        final groupedByDate = <DateTime, List<TransactionEntity>>{};
        for (final tx in filteredTransactions) {
          final dateKey = DateTime(tx.date.year, tx.date.month, tx.date.day);
          if (groupedByDate[dateKey] == null) {
            groupedByDate[dateKey] = [];
          }
          groupedByDate[dateKey]!.add(tx);
        }

        final dateKeys = groupedByDate.keys.toList();
        dateKeys.sort((a, b) => b.compareTo(a)); // Sort newest first

        // Create a flat list for the ListView.builder
        final List<dynamic> flatList = [];
        for (var date in dateKeys) {
          flatList.add(date); // Add date header
          flatList.addAll(
            groupedByDate[date]!,
          ); // Add transactions for that date
        }
        // -------------------------

        return Column(
          children: [
            // --- FILTER BAR ---
            _buildFilterBar(context, isVi),
            // ------------------

            // --- TRANSACTION LIST ---
            Expanded(
              child: filteredTransactions.isEmpty
                  ? Center(
                      child: Text(
                        isVi
                            ? 'Không tìm thấy giao dịch'
                            : 'No transactions found',
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.only(bottom: 80),
                      itemCount: flatList.length,
                      itemBuilder: (context, index) {
                        final item = flatList[index];
                        if (item is DateTime) {
                          return _buildDateHeader(context, item, isVi);
                        } else if (item is TransactionEntity) {
                          return _buildTransactionItem(context, item, isVi);
                        }
                        return const SizedBox.shrink();
                      },
                    ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildFilterBar(BuildContext context, bool isVi) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        children: [
          // Search Field
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: isVi
                  ? 'Tìm kiếm theo ghi chú, danh mục...'
                  : 'Search by note, category...',
              prefixIcon: const Icon(Icons.search, size: 20),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 20),
                      onPressed: () {
                        _searchController.clear();
                        setState(() => _searchQuery = '');
                      },
                    )
                  : null,
              filled: true,
              fillColor: Theme.of(
                context,
              ).colorScheme.surfaceVariant.withOpacity(0.5),
              contentPadding: const EdgeInsets.symmetric(
                vertical: 0,
                horizontal: 16,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(30),
                borderSide: BorderSide.none,
              ),
            ),
            onChanged: (value) => setState(() => _searchQuery = value),
          ),
          const SizedBox(height: 8),
          // Filter Chips
          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                // Date filter
                ActionChip(
                  avatar: const Icon(Icons.calendar_today, size: 16),
                  label: Text(
                    _selectedDateRange == null
                        ? (isVi ? 'Tất cả thời gian' : 'All time')
                        : '${DateFormat.Md(isVi ? 'vi_VN' : 'en_US').format(_selectedDateRange!.start)} - ${DateFormat.Md(isVi ? 'vi_VN' : 'en_US').format(_selectedDateRange!.end)}',
                  ),
                  onPressed: () async {
                    final picked = await showDateRangePicker(
                      context: context,
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                      initialDateRange: _selectedDateRange,
                    );
                    if (picked != null) {
                      setState(() => _selectedDateRange = picked);
                    }
                  },
                ),
                if (_selectedDateRange != null)
                  Padding(
                    padding: const EdgeInsets.only(left: 4.0),
                    child: InkWell(
                      onTap: () => setState(() => _selectedDateRange = null),
                      child: const Icon(Icons.close, size: 18),
                    ),
                  ),
                const VerticalDivider(),
                // Type filters
                _buildFilterChip(
                  label: isVi ? 'Tất cả' : 'All',
                  value: 'all',
                  isSelected: _filterType == 'all',
                ),
                const SizedBox(width: 8),
                _buildFilterChip(
                  label: isVi ? 'Thu nhập' : 'Income',
                  value: 'income',
                  isSelected: _filterType == 'income',
                  selectedColor: Colors.green,
                ),
                const SizedBox(width: 8),
                _buildFilterChip(
                  label: isVi ? 'Chi tiêu' : 'Expense',
                  value: 'expense',
                  isSelected: _filterType == 'expense',
                  selectedColor: Colors.red,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateHeader(BuildContext context, DateTime date, bool isVi) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        _formatDateHeader(date, isVi),
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.bold,
          color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.7),
        ),
      ),
    );
  }

  Widget _buildTransactionItem(
    BuildContext context,
    TransactionEntity tx,
    bool isVi,
  ) {
    final isIncome = tx.categoryType == 'income';
    final color = isIncome ? Colors.green.shade600 : Colors.red.shade600;
    final icon = AppIcons.getIconFromString(tx.categoryIcon);

    return Dismissible(
      key: ValueKey(tx.id),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.red.shade700,
          borderRadius: BorderRadius.circular(16),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 20.0),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      confirmDismiss: (direction) async {
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text(isVi ? 'Xác nhận Xóa' : 'Confirm Delete'),
              content: Text(
                isVi
                    ? 'Bạn có chắc chắn muốn xóa giao dịch này không?'
                    : 'Are you sure you want to delete this transaction?',
              ),
              actions: <Widget>[
                TextButton(
                  child: Text(isVi ? 'Hủy' : 'Cancel'),
                  onPressed: () => Navigator.of(context).pop(false),
                ),
                TextButton(
                  style: TextButton.styleFrom(foregroundColor: Colors.red),
                  child: Text(isVi ? 'Xóa' : 'Delete'),
                  onPressed: () => Navigator.of(context).pop(true),
                ),
              ],
            );
          },
        );
        return confirmed ?? false;
      },
      onDismissed: (direction) {
        context.read<DashboardCubit>().deleteTransaction(tx);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isVi ? 'Đã xóa giao dịch' : 'Transaction deleted'),
          ),
        );
      },
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        elevation: 1,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: ListTile(
          onTap: () async {
            final result = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => AddEditTransactionPage(transaction: tx),
              ),
            );
            if (result == true && context.mounted) {
              context.read<DashboardCubit>().loadDashboardData();
              context.read<BudgetCubit>().loadBudgetData();
            }
          },
          leading: CircleAvatar(
            backgroundColor: color.withOpacity(0.1),
            child: Icon(icon, color: color, size: 20),
          ),
          title: Text(
            tx.categoryName ?? (isVi ? 'Chưa phân loại' : 'Uncategorized'),
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          subtitle: tx.note.isNotEmpty
              ? Text(tx.note, maxLines: 1, overflow: TextOverflow.ellipsis)
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
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required String value,
    required bool isSelected,
    Color? selectedColor,
  }) {
    final theme = Theme.of(context);
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) setState(() => _filterType = value);
      },
      shape: StadiumBorder(
        side: BorderSide(
          color: isSelected ? Colors.transparent : theme.dividerColor,
        ),
      ),
      backgroundColor: theme.cardColor,
      selectedColor: selectedColor ?? theme.colorScheme.primary,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : theme.textTheme.bodyLarge?.color,
      ),
      checkmarkColor: Colors.white,
    );
  }
}
