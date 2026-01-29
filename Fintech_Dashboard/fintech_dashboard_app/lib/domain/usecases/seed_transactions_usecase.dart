import '../entities/transaction_entity.dart';
import '../repositories/transaction_repository.dart';

class SeedTransactionsUseCase {
  final TransactionRepository repository;

  SeedTransactionsUseCase(this.repository);

  Future<void> call(String userId) async {
    final existingTransactions = await repository.getTransactions();

    if (existingTransactions.isEmpty) {
      final now = DateTime.now();

      final dummyData = [
        TransactionEntity(
          amount: 10000000,
          note: 'Lương tháng 01/2026',
          date: now.subtract(const Duration(days: 2)),
          categoryId: 1, // Giả định 1 là ID của danh mục "Lương"
          userId: userId,
          isSynced: false,
          updatedAt: now,
        ),
        TransactionEntity(
          amount: 50000,
          note: 'Ăn sáng phở bò',
          date: now.subtract(const Duration(hours: 5)),
          categoryId: 2, // Giả định 2 là ID của danh mục "Ăn uống"
          userId: userId,
          isSynced: false,
          updatedAt: now,
        ),
        TransactionEntity(
          amount: 150000,
          note: 'Mua sách Flutter Clean Architecture',
          date: now,
          categoryId: 3, // Giả định 3 là ID của danh mục "Giáo dục"
          userId: userId,
          isSynced: false,
          updatedAt: now,
        ),
      ];

      for (var tx in dummyData) {
        await repository.addTransaction(tx);
      }
    }
  }
}
