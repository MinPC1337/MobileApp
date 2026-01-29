import '../entities/transaction_entity.dart';
import '../repositories/transaction_repository.dart';

class DeleteTransactionUseCase {
  final TransactionRepository repository;

  DeleteTransactionUseCase(this.repository);

  Future<void> call(TransactionEntity transaction) async {
    return await repository.deleteTransaction(transaction);
  }
}
