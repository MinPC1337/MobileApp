import '../entities/transaction_entity.dart';

abstract class TransactionRepository {
  // Lưu giao dịch (Logic chính: Local -> Cloud)
  Future<void> addTransaction(TransactionEntity transaction);

  // Lấy danh sách giao dịch từ Local
  Future<List<TransactionEntity>> getTransactions();

  // Đồng bộ các giao dịch chưa được đẩy lên Cloud
  Future<void> syncPendingTransactions();
}
