import '../entities/transaction_entity.dart';
import '../repositories/transaction_repository.dart';

class GetTransactionsUseCase {
  final TransactionRepository repository;

  GetTransactionsUseCase(this.repository);

  Future<List<TransactionEntity>> call({required String userId}) async {
    // UseCase có thể thêm logic ở đây, ví dụ như sắp xếp hoặc lọc
    // trước khi trả về cho tầng Presentation.
    return await repository.getTransactions(userId: userId);
  }
}
