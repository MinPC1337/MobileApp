import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/category_entity.dart';
import '../../domain/entities/transaction_entity.dart';
import '../../injection_container.dart' as di;
import '../bloc/auth_cubit.dart';
import '../bloc/auth_state.dart';
import '../bloc/category_cubit.dart';
import '../bloc/category_state.dart' as cat_state;
import '../bloc/dashboard_cubit.dart';
import '../bloc/transaction_form_cubit.dart';
import '../bloc/transaction_form_state.dart';

class AddEditTransactionPage extends StatelessWidget {
  final TransactionEntity? transaction;

  const AddEditTransactionPage({super.key, this.transaction});

  @override
  Widget build(BuildContext context) {
    final authState = context.read<AuthCubit>().state;
    String? userId;
    if (authState is AuthSuccess) {
      userId = authState.user.id;
    }

    if (userId == null) {
      return const Scaffold(
        body: Center(child: Text("Lỗi: Không tìm thấy người dùng.")),
      );
    }

    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => di.sl<TransactionFormCubit>()),
        BlocProvider(
          create: (_) => di.sl<CategoryCubit>(param1: userId)..loadCategories(),
        ),
      ],
      child: BlocListener<TransactionFormCubit, TransactionFormState>(
        listener: (context, state) {
          if (state is TransactionFormSuccess) {
            context.read<DashboardCubit>().loadDashboardData();
            Navigator.of(context).pop();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  transaction == null
                      ? 'Thêm giao dịch thành công!'
                      : 'Cập nhật giao dịch thành công!',
                ),
                backgroundColor: Colors.green,
              ),
            );
          } else if (state is TransactionFormFailure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Lỗi: ${state.message}'),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        child: _AddEditTransactionView(
          transaction: transaction,
          userId: userId,
        ),
      ),
    );
  }
}

class _AddEditTransactionView extends StatefulWidget {
  final TransactionEntity? transaction;
  final String userId;

  const _AddEditTransactionView({this.transaction, required this.userId});

  @override
  State<_AddEditTransactionView> createState() =>
      _AddEditTransactionViewState();
}

class _AddEditTransactionViewState extends State<_AddEditTransactionView> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _amountController;
  late TextEditingController _noteController;
  int? _selectedCategoryId;

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController(
      text: widget.transaction?.amount.toStringAsFixed(0) ?? '',
    );
    _noteController = TextEditingController(
      text: widget.transaction?.note ?? '',
    );
    _selectedCategoryId = widget.transaction?.categoryId;
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      final amount = double.tryParse(_amountController.text);
      if (amount == null || _selectedCategoryId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Vui lòng điền đầy đủ thông tin.')),
        );
        return;
      }

      final cubit = context.read<TransactionFormCubit>();
      if (widget.transaction == null) {
        cubit.submitTransaction(
          amount: amount,
          note: _noteController.text,
          categoryId: _selectedCategoryId!,
          userId: widget.userId,
        );
      } else {
        cubit.updateTransaction(
          originalTransaction: widget.transaction!,
          amount: amount,
          note: _noteController.text,
          categoryId: _selectedCategoryId!,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.transaction == null ? 'Thêm Giao dịch' : 'Sửa Giao dịch',
        ),
      ),
      body: BlocBuilder<TransactionFormCubit, TransactionFormState>(
        builder: (context, formState) {
          if (formState is TransactionFormLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextFormField(
                    controller: _amountController,
                    decoration: const InputDecoration(labelText: 'Số tiền'),
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    validator: (v) => (v == null || v.isEmpty)
                        ? 'Vui lòng nhập số tiền'
                        : null,
                  ),
                  const SizedBox(height: 16),
                  BlocBuilder<CategoryCubit, cat_state.CategoryState>(
                    builder: (context, catState) {
                      if (catState.isLoading) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (catState.categories.isEmpty) {
                        return const Text('Không có danh mục để chọn.');
                      }
                      if (_selectedCategoryId != null &&
                          !catState.categories.any(
                            (c) => c.id == _selectedCategoryId,
                          )) {
                        _selectedCategoryId = null;
                      }

                      // Thay đổi: Bọc Dropdown trong Row và thêm nút "Thêm nhanh"
                      return Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<int>(
                              isExpanded: true, // Để text dài không bị lỗi
                              initialValue: _selectedCategoryId,
                              decoration: const InputDecoration(
                                labelText: 'Danh mục',
                                border: OutlineInputBorder(),
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 16,
                                ),
                              ),
                              items: catState.categories.map((
                                CategoryEntity cat,
                              ) {
                                return DropdownMenuItem<int>(
                                  value: cat.id,
                                  child: Text(cat.name),
                                );
                              }).toList(),
                              onChanged: (v) =>
                                  setState(() => _selectedCategoryId = v),
                              validator: (v) =>
                                  v == null ? 'Vui lòng chọn danh mục' : null,
                            ),
                          ),
                          const SizedBox(width: 10),
                          IconButton.filledTonal(
                            onPressed: () =>
                                _showQuickAddCategoryDialog(context),
                            icon: const Icon(Icons.add),
                            tooltip: "Thêm danh mục mới",
                          ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _noteController,
                    decoration: const InputDecoration(labelText: 'Ghi chú'),
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton(
                    onPressed: _submitForm,
                    child: Text(
                      widget.transaction == null ? 'Thêm' : 'Cập nhật',
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // Hàm hiển thị Dialog thêm nhanh danh mục
  void _showQuickAddCategoryDialog(BuildContext context) {
    final nameController = TextEditingController();
    String type = 'expense'; // Mặc định là chi tiêu
    final categoryCubit = context.read<CategoryCubit>();

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Thêm danh mục mới'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Tên danh mục'),
                autofocus: true,
              ),
              const SizedBox(height: 16),
              StatefulBuilder(
                builder: (context, setState) {
                  return DropdownButtonFormField<String>(
                    initialValue: type,
                    decoration: const InputDecoration(labelText: 'Loại'),
                    items: const [
                      DropdownMenuItem(
                        value: 'expense',
                        child: Text('Chi phí (-)'),
                      ),
                      DropdownMenuItem(
                        value: 'income',
                        child: Text('Thu nhập (+)'),
                      ),
                    ],
                    onChanged: (val) => setState(() => type = val!),
                  );
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Hủy'),
            ),
            ElevatedButton(
              onPressed: () {
                if (nameController.text.isNotEmpty) {
                  // Gọi Cubit để thêm danh mục
                  categoryCubit.addCategory(
                    name: nameController.text,
                    type: type,
                    icon: 'default', // Icon mặc định
                  );
                  Navigator.pop(dialogContext);
                }
              },
              child: const Text('Lưu'),
            ),
          ],
        );
      },
    );
  }
}
