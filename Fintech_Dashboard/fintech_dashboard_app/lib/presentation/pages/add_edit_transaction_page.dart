import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/transaction_entity.dart';

import '../bloc/auth_cubit.dart';
import '../bloc/auth_state.dart';
import '../bloc/transaction_form_cubit.dart';
import '../bloc/transaction_form_state.dart';

class AddEditTransactionPage extends StatefulWidget {
  final TransactionEntity? transaction;
  const AddEditTransactionPage({super.key, this.transaction});

  @override
  State<AddEditTransactionPage> createState() => _AddEditTransactionPageState();
}

class _AddEditTransactionPageState extends State<AddEditTransactionPage> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  int _selectedCategoryId = 2; // Mặc định là chi tiêu (ID=2)

  bool get isEditing => widget.transaction != null;

  @override
  void initState() {
    super.initState();
    if (isEditing) {
      final tx = widget.transaction!;
      _amountController.text = tx.amount.toStringAsFixed(0);
      _noteController.text = tx.note;
      _selectedCategoryId = tx.categoryId;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? "Sửa Giao dịch" : "Thêm Giao dịch mới"),
      ),
      body: BlocListener<TransactionFormCubit, TransactionFormState>(
        listener: (context, state) {
          if (state is TransactionFormSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text("Lưu giao dịch thành công!"),
                backgroundColor: Colors.green,
              ),
            );
            Navigator.of(
              context,
            ).pop(true); // Trả về true để báo hiệu cần reload
          } else if (state is TransactionFormFailure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        child: Form(
          key: _formKey,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                TextFormField(
                  controller: _amountController,
                  decoration: const InputDecoration(
                    labelText: "Số tiền",
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  validator: (value) =>
                      (value?.isEmpty ?? true) ? "Vui lòng nhập số tiền" : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _noteController,
                  decoration: const InputDecoration(
                    labelText: "Ghi chú",
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) =>
                      (value?.isEmpty ?? true) ? "Vui lòng nhập ghi chú" : null,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<int>(
                  initialValue: _selectedCategoryId,
                  items: const [
                    DropdownMenuItem(value: 1, child: Text("Thu nhập")),
                    DropdownMenuItem(value: 2, child: Text("Chi tiêu")),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _selectedCategoryId = value);
                    }
                  },
                  decoration: const InputDecoration(
                    labelText: "Loại giao dịch",
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 24),
                BlocBuilder<TransactionFormCubit, TransactionFormState>(
                  builder: (context, state) {
                    if (state is TransactionFormLoading) {
                      return const CircularProgressIndicator();
                    }
                    return ElevatedButton(
                      onPressed: _submit,
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 50),
                      ),
                      child: const Text("LƯU"),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      final authState = context.read<AuthCubit>().state;
      if (authState is AuthSuccess) {
        if (isEditing) {
          context.read<TransactionFormCubit>().updateTransaction(
            originalTransaction: widget.transaction!,
            amount: double.parse(_amountController.text),
            note: _noteController.text,
            categoryId: _selectedCategoryId,
          );
        } else {
          context.read<TransactionFormCubit>().submitTransaction(
            amount: double.parse(_amountController.text),
            note: _noteController.text,
            categoryId: _selectedCategoryId,
            userId: authState.user.id,
          );
        }
      }
    }
  }
}
