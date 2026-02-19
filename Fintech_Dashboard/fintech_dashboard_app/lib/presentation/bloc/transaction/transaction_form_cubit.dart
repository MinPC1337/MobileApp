import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/entities/transaction_entity.dart';
import '../../../domain/usecases/transactions/add_transaction_usecase.dart';
// import '../../domain/usecases/delete_transaction_usecase.dart';
// import '../../domain/usecases/get_transactions_usecase.dart';
import '../../../domain/usecases/transactions/update_transaction_usecase.dart';
import 'transaction_form_state.dart';

class TransactionFormCubit extends Cubit<TransactionFormState> {
  final AddTransactionUseCase addTransactionUseCase;
  final UpdateTransactionUseCase updateTransactionUseCase;

  TransactionFormCubit({
    required this.addTransactionUseCase,
    required this.updateTransactionUseCase,
  }) : super(TransactionFormInitial());

  Future<void> submitTransaction({
    required double amount,
    required String note,
    required int categoryId,
    required String userId,
  }) async {
    emit(TransactionFormLoading());
    try {
      final transaction = TransactionEntity(
        amount: amount,
        note: note,
        date: DateTime.now(),
        categoryId: categoryId,
        userId: userId,
        updatedAt: DateTime.now(),
      );
      await addTransactionUseCase(transaction);
      emit(TransactionFormSuccess());
    } catch (e) {
      emit(
        TransactionFormFailure(e.toString().replaceFirst('Exception: ', '')),
      );
    }
  }

  Future<void> updateTransaction({
    required TransactionEntity originalTransaction,
    required double amount,
    required String note,
    required int categoryId,
  }) async {
    emit(TransactionFormLoading());
    try {
      final updatedTransaction = TransactionEntity(
        id: originalTransaction.id, // Giữ lại ID cũ
        amount: amount,
        note: note,
        date: originalTransaction.date, // Giữ lại ngày tạo ban đầu
        categoryId: categoryId,
        userId: originalTransaction.userId,
        isSynced: originalTransaction.isSynced,
        updatedAt: DateTime.now(), // Cập nhật thời gian sửa đổi
      );
      await updateTransactionUseCase(updatedTransaction);
      emit(TransactionFormSuccess());
    } catch (e) {
      emit(
        TransactionFormFailure(e.toString().replaceFirst('Exception: ', '')),
      );
    }
  }
}
