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
import '../bloc/transaction_form_cubit.dart';
import '../bloc/transaction_form_state.dart';
import '../bloc/setting/settings_cubit.dart';

class AddEditTransactionPage extends StatelessWidget {
  final TransactionEntity? transaction;

  const AddEditTransactionPage({super.key, this.transaction});

  @override
  Widget build(BuildContext context) {
    final authState = context.read<AuthCubit>().state;
    // Lắng nghe ngôn ngữ hiện tại
    final isVi =
        context.watch<SettingsCubit>().state.locale.languageCode == 'vi';
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
            Navigator.of(context).pop(true); // Trả về true khi thành công
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  transaction == null
                      ? (isVi
                            ? 'Thêm giao dịch thành công!'
                            : 'Transaction added successfully!')
                      : (isVi
                            ? 'Cập nhật giao dịch thành công!'
                            : 'Transaction updated successfully!'),
                ),
                backgroundColor: Colors.green,
              ),
            );
          } else if (state is TransactionFormFailure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  isVi ? 'Lỗi: ${state.message}' : 'Error: ${state.message}',
                ),
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
    final isVi =
        context.read<SettingsCubit>().state.locale.languageCode == 'vi';
    if (_formKey.currentState!.validate()) {
      final amount = double.tryParse(_amountController.text);
      if (amount == null || _selectedCategoryId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isVi
                  ? 'Vui lòng điền đầy đủ thông tin.'
                  : 'Please fill in all fields.',
            ),
          ),
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
    final isVi =
        context.watch<SettingsCubit>().state.locale.languageCode == 'vi';
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.transaction == null
              ? (isVi ? 'Thêm Giao dịch' : 'Add Transaction')
              : (isVi ? 'Sửa Giao dịch' : 'Edit Transaction'),
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
                    decoration: InputDecoration(
                      labelText: isVi ? 'Số tiền' : 'Amount',
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    validator: (v) => (v == null || v.isEmpty)
                        ? (isVi
                              ? 'Vui lòng nhập số tiền'
                              : 'Please enter amount')
                        : null,
                  ),
                  const SizedBox(height: 16),
                  BlocBuilder<CategoryCubit, cat_state.CategoryState>(
                    builder: (context, catState) {
                      if (catState.isLoading) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (catState.categories.isEmpty) {
                        return Text(
                          isVi
                              ? 'Không có danh mục để chọn.'
                              : 'No categories available.',
                        );
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
                              decoration: InputDecoration(
                                labelText: isVi ? 'Danh mục' : 'Category',
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
                              validator: (v) => v == null
                                  ? (isVi
                                        ? 'Vui lòng chọn danh mục'
                                        : 'Please select a category')
                                  : null,
                            ),
                          ),
                          const SizedBox(width: 10),
                          IconButton.filledTonal(
                            onPressed: () =>
                                _showQuickAddCategoryDialog(context),
                            icon: const Icon(Icons.add),
                            tooltip: isVi
                                ? "Thêm danh mục mới"
                                : "Add new category",
                          ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _noteController,
                    decoration: InputDecoration(
                      labelText: isVi ? 'Ghi chú' : 'Note',
                    ),
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton(
                    onPressed: _submitForm,
                    child: Text(
                      widget.transaction == null
                          ? (isVi ? 'Thêm' : 'Add')
                          : (isVi ? 'Cập nhật' : 'Update'),
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
    final isVi =
        context.read<SettingsCubit>().state.locale.languageCode == 'vi';
    final nameController = TextEditingController();
    String type = 'expense'; // Mặc định là chi tiêu
    final categoryCubit = context.read<CategoryCubit>();

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(isVi ? 'Thêm danh mục mới' : 'Add New Category'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: InputDecoration(
                  labelText: isVi ? 'Tên danh mục' : 'Category Name',
                ),
                autofocus: true,
              ),
              const SizedBox(height: 16),
              StatefulBuilder(
                builder: (context, setState) {
                  return DropdownButtonFormField<String>(
                    initialValue: type,
                    decoration: InputDecoration(
                      labelText: isVi ? 'Loại' : 'Type',
                    ),
                    items: [
                      DropdownMenuItem(
                        value: 'expense',
                        child: Text(isVi ? 'Chi phí (-)' : 'Expense (-)'),
                      ),
                      DropdownMenuItem(
                        value: 'income',
                        child: Text(isVi ? 'Thu nhập (+)' : 'Income (+)'),
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
              child: Text(isVi ? 'Hủy' : 'Cancel'),
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
              child: Text(isVi ? 'Lưu' : 'Save'),
            ),
          ],
        );
      },
    );
  }
}
