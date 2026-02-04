import 'package:equatable/equatable.dart';
import '../../../../domain/entities/budget_entity.dart';
import '../../../../domain/entities/category_entity.dart';
import '../../../../domain/entities/transaction_entity.dart';

class BudgetState extends Equatable {
  final bool isLoading;
  final List<BudgetEntity> budgets;
  final List<TransactionEntity> transactions;
  final List<CategoryEntity> categories;
  final String? errorMessage;

  const BudgetState({
    this.isLoading = false,
    this.budgets = const [],
    this.transactions = const [],
    this.categories = const [],
    this.errorMessage,
  });

  BudgetState copyWith({
    bool? isLoading,
    List<BudgetEntity>? budgets,
    List<TransactionEntity>? transactions,
    List<CategoryEntity>? categories,
    String? errorMessage,
  }) {
    return BudgetState(
      isLoading: isLoading ?? this.isLoading,
      budgets: budgets ?? this.budgets,
      transactions: transactions ?? this.transactions,
      categories: categories ?? this.categories,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [
    isLoading,
    budgets,
    transactions,
    categories,
    errorMessage,
  ];
}
