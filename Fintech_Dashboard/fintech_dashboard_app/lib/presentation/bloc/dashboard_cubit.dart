import 'package:flutter_bloc/flutter_bloc.dart';
import 'dashboard_state.dart';
import '../../domain/entities/transaction_entity.dart';
import '../../domain/usecases/transactions/get_transactions_usecase.dart';
import '../../domain/usecases/transactions/delete_transaction_usecase.dart';

class DashboardCubit extends Cubit<DashboardState> {
  final GetTransactionsUseCase getTransactionsUseCase;
  final DeleteTransactionUseCase deleteTransactionUseCase;
  final String _userId;

  DashboardCubit({
    required this.getTransactionsUseCase,
    required this.deleteTransactionUseCase,
    required String userId,
  }) : _userId = userId,
       super(const DashboardState());

  Future<void> loadDashboardData() async {
    // 1. Bật trạng thái Loading
    emit(state.copyWith(isLoading: true, errorMessage: null));

    try {
      // 2. Lấy dữ liệu thông qua UseCase, sử dụng userId đã lưu
      final transactions = await getTransactionsUseCase(userId: _userId);

      // 3. Tính toán số dư
      double balance = 0;
      for (var tx in transactions) {
        // Cải tiến: Dựa vào 'type' của category thay vì ID cứng.
        // Giả định TransactionEntity giờ có thuộc tính 'categoryType'.
        if (tx.categoryType == 'income') {
          balance += tx.amount;
        } else {
          balance -= tx.amount;
        }
      }

      // 4. Cập nhật trạng thái thành công với dữ liệu mới
      emit(
        state.copyWith(
          isLoading: false,
          totalBalance: balance,
          transactions: transactions,
        ),
      );
    } catch (e) {
      // 5. Cập nhật trạng thái lỗi
      emit(
        state.copyWith(
          isLoading: false,
          errorMessage: "Không thể tải dữ liệu: ${e.toString()}",
        ),
      );
    }
  }

  Future<void> deleteTransaction(TransactionEntity transaction) async {
    try {
      // Gọi use case để xóa
      await deleteTransactionUseCase(transaction);

      // Cập nhật lại state ngay lập tức để UI phản hồi nhanh
      final updatedTransactions = List<TransactionEntity>.from(
        state.transactions,
      )..remove(transaction);

      double newBalance = 0;
      for (var tx in updatedTransactions) {
        // Cải tiến: Dựa vào 'type' của category.
        if (tx.categoryType == 'income') {
          newBalance += tx.amount;
        } else {
          newBalance -= tx.amount;
        }
      }

      emit(
        state.copyWith(
          transactions: updatedTransactions,
          totalBalance: newBalance,
        ),
      );
    } catch (e) {
      // Có thể emit một state lỗi riêng để thông báo cho người dùng
    }
  }
}
