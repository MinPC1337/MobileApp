import 'package:flutter_bloc/flutter_bloc.dart';
import 'dashboard_state.dart';
import '../../domain/entities/transaction_entity.dart';
import '../../domain/usecases/get_transactions_usecase.dart';
import '../../domain/usecases/delete_transaction_usecase.dart';

class DashboardCubit extends Cubit<DashboardState> {
  final GetTransactionsUseCase getTransactionsUseCase;
  final DeleteTransactionUseCase deleteTransactionUseCase;

  DashboardCubit({
    required this.getTransactionsUseCase,
    required this.deleteTransactionUseCase,
  }) : super(const DashboardState());

  Future<void> loadDashboardData() async {
    // 1. Bật trạng thái Loading
    emit(state.copyWith(isLoading: true, errorMessage: null));

    try {
      // 2. Lấy dữ liệu thông qua UseCase
      final transactions = await getTransactionsUseCase();

      // 3. Tính toán số dư
      double balance = 0;
      for (var tx in transactions) {
        // Logic mẫu: Giả định CategoryId 1 là Thu nhập (Income)
        if (tx.categoryId == 1) {
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
        if (tx.categoryId == 1) {
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
