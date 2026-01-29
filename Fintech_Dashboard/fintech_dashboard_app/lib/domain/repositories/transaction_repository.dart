import '../entities/transaction_entity.dart';

abstract class TransactionRepository {
  // Lưu giao dịch (Logic chính: Local -> Cloud)
  Future<void> addTransaction(TransactionEntity transaction);

  // Sửa giao dịch
  Future<void> updateTransaction(TransactionEntity transaction);

  // Xóa giao dịch
  Future<void> deleteTransaction(TransactionEntity transaction);

  // Lấy danh sách giao dịch từ Local
  Future<List<TransactionEntity>> getTransactions({required String userId});

  // Đồng bộ các giao dịch chưa được đẩy lên Cloud
  Future<void> syncPendingTransactions({required String userId});
}
