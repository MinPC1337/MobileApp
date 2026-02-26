import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/entities/category_entity.dart';
import '../../../domain/entities/transaction_entity.dart';
import '../../../injection_container.dart' as di;
import '../../bloc/auth/auth_cubit.dart';
import '../../bloc/auth/auth_state.dart';
import '../../bloc/category/category_cubit.dart';
import '../../bloc/category/category_state.dart' as cat_state;
import '../../bloc/transaction/transaction_form_cubit.dart';
import '../../bloc/transaction/transaction_form_state.dart';
import '../../bloc/setting/settings_cubit.dart';
import '../../../core/utils/app_icons.dart';

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

  // New state variables for the redesigned UI
  late String _transactionType;
  int? _selectedCategoryId;
  CategoryEntity? _selectedCategory;
  late DateTime _selectedDate;

  @override
  void initState() {
    super.initState();
    final initialTransaction = widget.transaction;

    _amountController = TextEditingController(
      text: initialTransaction?.amount.toStringAsFixed(0) ?? '',
    );
    _noteController = TextEditingController(
      text: initialTransaction?.note ?? '',
    );
    _selectedCategoryId = initialTransaction?.categoryId;
    _selectedDate = initialTransaction?.date ?? DateTime.now();
    _transactionType = initialTransaction?.categoryType ?? 'expense';
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
    if (_formKey.currentState?.validate() ?? false) {
      final amount = double.tryParse(_amountController.text);
      if (amount == null || _selectedCategoryId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isVi
                  ? 'Vui lòng điền đầy đủ thông tin.'
                  : 'Please fill in all fields.',
              style: const TextStyle(color: Colors.white),
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
          date: _selectedDate,
        );
      } else {
        cubit.updateTransaction(
          originalTransaction: widget.transaction!,
          amount: amount,
          note: _noteController.text,
          categoryId: _selectedCategoryId!,
          date: _selectedDate,
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
            // Show a loading overlay instead of replacing the whole screen
            return Stack(
              children: [
                _buildForm(context, isVi, formState),
                Container(
                  color: Colors.black.withOpacity(0.5),
                  child: const Center(child: CircularProgressIndicator()),
                ),
              ],
            );
          }
          return _buildForm(context, isVi, formState);
        },
      ),
    );
  }

  Widget _buildForm(
    BuildContext context,
    bool isVi,
    TransactionFormState formState,
  ) {
    return BlocBuilder<CategoryCubit, cat_state.CategoryState>(
      builder: (context, catState) {
        if (catState.isLoading && _selectedCategory == null) {
          return const Center(child: CircularProgressIndicator());
        }

        // One-time setup to find the selected category object
        if (_selectedCategoryId != null && _selectedCategory == null) {
          try {
            _selectedCategory = catState.categories.firstWhere(
              (c) => c.id == _selectedCategoryId,
            );
          } catch (e) {
            // This can happen if the category was deleted.
            _selectedCategory = null;
            _selectedCategoryId = null;
          }
        }

        final availableCategories = catState.categories
            .where((c) => c.type == _transactionType)
            .toList();

        return Form(
          key: _formKey,
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 24),
                      _buildTypeSelector(context, isVi),
                      const SizedBox(height: 24),
                      _buildAmountInput(context, isVi),
                      const SizedBox(height: 24),
                      _buildCategorySelector(
                        context,
                        isVi,
                        availableCategories,
                      ),
                      const SizedBox(height: 16),
                      _buildDateSelector(context, isVi),
                      const SizedBox(height: 16),
                      _buildNoteField(context, isVi),
                      const SizedBox(height: 100), // Space for the button
                    ],
                  ),
                ),
              ),
              _buildSaveButton(context, isVi, formState),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTypeSelector(BuildContext context, bool isVi) {
    return Center(
      child: SegmentedButton<String>(
        segments: [
          ButtonSegment(
            value: 'expense',
            label: Text(isVi ? 'Chi tiêu' : 'Expense'),
            icon: const Icon(Icons.arrow_downward_rounded),
          ),
          ButtonSegment(
            value: 'income',
            label: Text(isVi ? 'Thu nhập' : 'Income'),
            icon: const Icon(Icons.arrow_upward_rounded),
          ),
        ],
        selected: {_transactionType},
        onSelectionChanged: (newSelection) {
          setState(() {
            _transactionType = newSelection.first;
            if (_selectedCategory != null &&
                _selectedCategory!.type != _transactionType) {
              _selectedCategory = null;
              _selectedCategoryId = null;
            }
          });
        },
      ),
    );
  }

  Widget _buildAmountInput(BuildContext context, bool isVi) {
    final currencySymbol = NumberFormat.compactCurrency(
      locale: isVi ? 'vi_VN' : 'en_US',
      symbol: 'đ',
    ).currencySymbol;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          isVi ? 'Số tiền' : 'Amount',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _amountController,
          style: Theme.of(
            context,
          ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
          decoration: InputDecoration(
            prefixIcon: Padding(
              padding: const EdgeInsets.only(left: 16, right: 8),
              child: Text(
                currencySymbol,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
            prefixIconConstraints: const BoxConstraints(
              minWidth: 0,
              minHeight: 0,
            ),
            hintText: '0',
            filled: true,
            fillColor: Theme.of(
              context,
            ).colorScheme.surfaceVariant.withOpacity(0.3),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
          ),
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          validator: (v) => (v == null || v.isEmpty)
              ? (isVi ? 'Vui lòng nhập số tiền' : 'Please enter amount')
              : null,
        ),
      ],
    );
  }

  // Hàm hiển thị Dialog thêm nhanh danh mục
  void _showQuickAddCategoryDialog(BuildContext context) {
    final isVi =
        context.read<SettingsCubit>().state.locale.languageCode == 'vi';
    final nameController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    String type = 'expense';
    String selectedIcon = 'default';
    final categoryCubit = context.read<CategoryCubit>();

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          contentPadding: const EdgeInsets.all(16),
          title: Text(isVi ? 'Thêm danh mục mới' : 'Add New Category'),
          content: StatefulBuilder(
            builder: (context, setState) {
              // Wrap the content in a Container to give the AlertDialog a specific size
              // This prevents the "RenderViewport does not support returning intrinsic dimensions" error
              return SizedBox(
                width: double.maxFinite,
                child: Form(
                  key: formKey,
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TextFormField(
                          controller: nameController,
                          decoration: InputDecoration(
                            labelText: isVi ? 'Tên danh mục' : 'Category Name',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          autofocus: true,
                          validator: (v) => (v == null || v.isEmpty)
                              ? (isVi
                                    ? 'Vui lòng nhập tên'
                                    : 'Please enter name')
                              : null,
                        ),
                        const SizedBox(height: 16),
                        DropdownButtonFormField<String>(
                          value: type,
                          decoration: InputDecoration(
                            labelText: isVi ? 'Loại' : 'Type',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
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
                        ),
                        const SizedBox(height: 16),
                        Text(
                          isVi ? 'Chọn biểu tượng' : 'Choose Icon',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          height: 150,
                          child: GridView.builder(
                            itemCount: AppIcons.categoryIcons.length,
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 5,
                                  crossAxisSpacing: 8,
                                  mainAxisSpacing: 8,
                                ),
                            itemBuilder: (context, index) {
                              final iconName = AppIcons.categoryIcons.keys
                                  .elementAt(index);
                              final iconData = AppIcons.categoryIcons.values
                                  .elementAt(index);
                              final isSelected = selectedIcon == iconName;
                              return InkWell(
                                onTap: () =>
                                    setState(() => selectedIcon = iconName),
                                borderRadius: BorderRadius.circular(12),
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? Theme.of(
                                            context,
                                          ).colorScheme.primaryContainer
                                        : Theme.of(context)
                                              .colorScheme
                                              .surfaceVariant
                                              .withOpacity(0.3),
                                    borderRadius: BorderRadius.circular(12),
                                    border: isSelected
                                        ? Border.all(
                                            color: Theme.of(
                                              context,
                                            ).colorScheme.primary,
                                            width: 2,
                                          )
                                        : null,
                                  ),
                                  child: Icon(
                                    iconData,
                                    color: isSelected
                                        ? Theme.of(context).colorScheme.primary
                                        : Theme.of(
                                            context,
                                          ).textTheme.bodyLarge?.color,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(isVi ? 'Hủy' : 'Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  categoryCubit.addCategory(
                    name: nameController.text,
                    type: type,
                    icon: selectedIcon,
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

  Widget _buildCategorySelector(
    BuildContext context,
    bool isVi,
    List<CategoryEntity> categories,
  ) {
    return FormField<CategoryEntity>(
      initialValue: _selectedCategory,
      validator: (value) {
        if (value == null) {
          return isVi ? 'Vui lòng chọn danh mục' : 'Please select a category';
        }
        return null;
      },
      builder: (formFieldState) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            InkWell(
              onTap: () async {
                final result = await _showCategoryPicker(
                  context,
                  isVi,
                  categories,
                );
                if (result != null) {
                  setState(() {
                    _selectedCategory = result;
                    _selectedCategoryId = result.id;
                    formFieldState.didChange(result);
                  });
                }
              },
              borderRadius: BorderRadius.circular(16),
              child: InputDecorator(
                decoration: InputDecoration(
                  labelText: isVi ? 'Danh mục' : 'Category',
                  filled: true,
                  fillColor: Theme.of(
                    context,
                  ).colorScheme.surfaceVariant.withOpacity(0.3),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  errorText: formFieldState.errorText,
                ),
                child: _selectedCategory == null
                    ? Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            isVi ? 'Chọn danh mục' : 'Select a category',
                            style: TextStyle(
                              color: Theme.of(context).hintColor,
                            ),
                          ),
                          const Icon(Icons.arrow_drop_down),
                        ],
                      )
                    : Row(
                        children: [
                          CircleAvatar(
                            radius: 14,
                            backgroundColor:
                                (_selectedCategory!.type == 'income'
                                        ? Colors.green
                                        : Colors.red)
                                    .withOpacity(0.2),
                            child: Icon(
                              AppIcons.getIconFromString(
                                _selectedCategory!.icon,
                              ),
                              size: 16,
                              color: _selectedCategory!.type == 'income'
                                  ? Colors.green
                                  : Colors.red,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(child: Text(_selectedCategory!.name)),
                          const Icon(Icons.arrow_drop_down),
                        ],
                      ),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<CategoryEntity?> _showCategoryPicker(
    BuildContext context,
    bool isVi,
    List<CategoryEntity> categories,
  ) {
    return showModalBottomSheet<CategoryEntity>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (bottomSheetContext) {
        return BlocProvider.value(
          value: BlocProvider.of<CategoryCubit>(context),
          child: DraggableScrollableSheet(
            expand: false,
            initialChildSize: 0.6,
            maxChildSize: 0.9,
            builder: (_, scrollController) {
              return Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 8, 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          isVi ? 'Chọn Danh mục' : 'Select Category',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(bottomSheetContext),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: GridView.builder(
                      controller: scrollController,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: categories.length + 1,
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 4,
                            childAspectRatio: 1.0,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                          ),
                      itemBuilder: (ctx, index) {
                        if (index == categories.length) {
                          return _buildAddCategoryButton(
                            bottomSheetContext,
                            isVi,
                          );
                        }
                        final category = categories[index];
                        return _buildCategoryGridItem(
                          bottomSheetContext,
                          category,
                        );
                      },
                    ),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildCategoryGridItem(BuildContext context, CategoryEntity category) {
    final color = category.type == 'income' ? Colors.green : Colors.red;
    return InkWell(
      onTap: () => Navigator.pop(context, category),
      borderRadius: BorderRadius.circular(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: color.withOpacity(0.15),
            child: Icon(
              AppIcons.getIconFromString(category.icon),
              color: color,
              size: 24,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            category.name,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }

  Widget _buildAddCategoryButton(BuildContext context, bool isVi) {
    return InkWell(
      onTap: () {
        Navigator.pop(context);
        _showQuickAddCategoryDialog(this.context);
      },
      borderRadius: BorderRadius.circular(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
            child: Icon(
              Icons.add,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              size: 24,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            isVi ? 'Thêm mới' : 'Add New',
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }

  Widget _buildDateSelector(BuildContext context, bool isVi) {
    return FormField<DateTime>(
      initialValue: _selectedDate,
      builder: (formFieldState) {
        return InkWell(
          onTap: () async {
            final pickedDate = await showDatePicker(
              context: context,
              initialDate: _selectedDate,
              firstDate: DateTime(2020),
              lastDate: DateTime.now().add(const Duration(days: 365)),
            );
            if (pickedDate != null) {
              setState(() {
                _selectedDate = pickedDate;
                formFieldState.didChange(pickedDate);
              });
            }
          },
          borderRadius: BorderRadius.circular(16),
          child: InputDecorator(
            decoration: InputDecoration(
              labelText: isVi ? 'Ngày' : 'Date',
              filled: true,
              fillColor: Theme.of(
                context,
              ).colorScheme.surfaceVariant.withOpacity(0.3),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  DateFormat.yMMMd(
                    isVi ? 'vi_VN' : 'en_US',
                  ).format(_selectedDate),
                ),
                const Icon(Icons.calendar_today_outlined, size: 20),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildNoteField(BuildContext context, bool isVi) {
    return TextFormField(
      controller: _noteController,
      decoration: InputDecoration(
        labelText: isVi ? 'Ghi chú (không bắt buộc)' : 'Note (optional)',
        filled: true,
        fillColor: Theme.of(
          context,
        ).colorScheme.surfaceVariant.withOpacity(0.3),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
      ),
      textCapitalization: TextCapitalization.sentences,
    );
  }

  Widget _buildSaveButton(
    BuildContext context,
    bool isVi,
    TransactionFormState formState,
  ) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: formState is TransactionFormLoading ? null : _submitForm,
          icon: formState is TransactionFormLoading
              ? Container(
                  width: 24,
                  height: 24,
                  padding: const EdgeInsets.all(2.0),
                  child: const CircularProgressIndicator(
                    strokeWidth: 3,
                    color: Colors.white,
                  ),
                )
              : Icon(
                  widget.transaction == null
                      ? Icons.add_rounded
                      : Icons.check_rounded,
                ),
          label: Text(
            widget.transaction == null
                ? (isVi ? 'Thêm Giao dịch' : 'Add Transaction')
                : (isVi ? 'Lưu Thay đổi' : 'Save Changes'),
          ),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
      ),
    );
  }
}
