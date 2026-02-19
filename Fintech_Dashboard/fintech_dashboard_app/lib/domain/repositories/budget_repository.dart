import '../entities/budget_entity.dart';

abstract class BudgetRepository {
  Future<void> addBudget(BudgetEntity budget);
  Future<void> updateBudget(BudgetEntity budget);
  Future<void> deleteBudget(BudgetEntity budget);
  Future<List<BudgetEntity>> getBudgets(String userId);
  Future<void> syncPendingBudgets({required String userId});
  Future<void> clearLocalData();
}
