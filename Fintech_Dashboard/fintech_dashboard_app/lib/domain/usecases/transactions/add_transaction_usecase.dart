import '../../entities/transaction_entity.dart';
import '../../repositories/transaction_repository.dart';

class AddTransactionUseCase {
  final TransactionRepository repository;

  AddTransactionUseCase(this.repository);

  Future<void> call(TransactionEntity transaction) async {
    if (transaction.amount <= 0) {
      throw Exception("Số tiền phải lớn hơn 0");
    }
    return await repository.addTransaction(transaction);
  }
}
