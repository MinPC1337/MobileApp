import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/entities/budget_entity.dart';
import '../../../domain/entities/transaction_entity.dart';
import '../../../domain/usecases/budgets/add_budget_usecase.dart';
import '../../../domain/usecases/budgets/delete_budget_usecase.dart';
import '../../../domain/usecases/budgets/get_budgets_usecase.dart';
import '../../../domain/usecases/categories/get_categories_usecase.dart';
import '../../../domain/usecases/transactions/get_transactions_usecase.dart';
import 'budget_state.dart';

class BudgetCubit extends Cubit<BudgetState> {
  final GetBudgetsUseCase getBudgetsUseCase;
  final AddBudgetUseCase addBudgetUseCase;
  final DeleteBudgetUseCase deleteBudgetUseCase;
  final GetTransactionsUseCase getTransactionsUseCase;
  final GetCategoriesUseCase getCategoriesUseCase;
  final String _userId;

  BudgetCubit({
    required this.getBudgetsUseCase,
    required this.addBudgetUseCase,
    required this.deleteBudgetUseCase,
    required this.getTransactionsUseCase,
    required this.getCategoriesUseCase,
    required String userId,
  }) : _userId = userId,
       super(const BudgetState());

  Future<void> loadBudgetData({bool forceReload = false}) async {
    if (state.isLoading && !forceReload) {
      return;
    }
    emit(state.copyWith(isLoading: true, errorMessage: null));
    try {
      // 1. Tải Danh mục trước (Quan trọng để hiển thị Dropdown khi thêm ngân sách)
      // Tách riêng ra để nếu tải Ngân sách lỗi thì Danh mục vẫn có dữ liệu
      final categories = await getCategoriesUseCase(_userId);

      List<BudgetEntity> budgets = [];
      List<TransactionEntity> transactions = [];
      String? errorMsg;

      // 2. Tải Ngân sách và Giao dịch
      try {
        final results = await Future.wait([
          getBudgetsUseCase(_userId),
          getTransactionsUseCase(userId: _userId),
        ]);
        budgets = List<BudgetEntity>.from(results[0] as List);
        transactions = List<TransactionEntity>.from(results[1] as List);
      } catch (e) {
        // Nếu lỗi ở đây (thường do lệch DB), ghi nhận lỗi nhưng vẫn giữ categories
        errorMsg = 'Lỗi dữ liệu ngân sách. Vui lòng cài đặt lại ứng dụng.';
      }

      emit(
        state.copyWith(
          isLoading: false,
          categories: categories, // Danh mục luôn được cập nhật
          budgets: budgets,
          transactions: transactions,
          errorMessage: errorMsg,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          isLoading: false,
          errorMessage: 'Không thể tải dữ liệu ngân sách.',
        ),
      );
    }
  }

  Future<void> addBudget({
    required int categoryId,
    required double amount,
  }) async {
    // 1. Báo hiệu đang xử lý ngay lập tức để UI phản hồi (ẩn nút FAB, hiện loading...)
    emit(state.copyWith(isLoading: true, errorMessage: null));
    try {
      final newBudget = BudgetEntity(
        amount: amount,
        categoryId: categoryId,
        userId: _userId,
        createdAt: DateTime.now(),
      );

      await addBudgetUseCase(newBudget);
      // 2. Buộc tải lại dữ liệu (forceReload = true) để đảm bảo danh sách được cập nhật ngay
      await loadBudgetData(forceReload: true);
    } catch (e) {
      emit(
        state.copyWith(
          isLoading: false,
          errorMessage: 'Không thể thêm ngân sách.',
        ),
      );
    }
  }

  Future<void> deleteBudget(BudgetEntity budget) async {
    try {
      await deleteBudgetUseCase(budget);
      // Cập nhật UI ngay lập tức
      final updatedList = List<BudgetEntity>.from(state.budgets)
        ..removeWhere((b) => b.id == budget.id);
      emit(state.copyWith(budgets: updatedList));
    } catch (e) {
      emit(state.copyWith(errorMessage: 'Không thể xóa ngân sách.'));
      await loadBudgetData();
    }
  }
}
