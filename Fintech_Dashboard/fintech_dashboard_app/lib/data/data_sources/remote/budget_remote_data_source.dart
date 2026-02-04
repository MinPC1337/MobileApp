import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/budget_model.dart';

abstract class BudgetRemoteDataSource {
  Future<void> addBudget(BudgetModel budget);
  Future<void> updateBudget(BudgetModel budget);
  Future<void> deleteBudget(String userId, String budgetId);
  Future<List<BudgetModel>> getBudgets(String userId);
}

class BudgetRemoteDataSourceImpl implements BudgetRemoteDataSource {
  final FirebaseFirestore firestore;

  BudgetRemoteDataSourceImpl(this.firestore);

  @override
  Future<void> addBudget(BudgetModel budget) async {
    await firestore
        .collection('users')
        .doc(budget.userId)
        .collection('budgets')
        .doc(budget.id.toString())
        .set(budget.toMap());
  }

  @override
  Future<void> updateBudget(BudgetModel budget) async {
    await firestore
        .collection('users')
        .doc(budget.userId)
        .collection('budgets')
        .doc(budget.id.toString())
        .update(budget.toMap());
  }

  @override
  Future<void> deleteBudget(String userId, String budgetId) async {
    await firestore
        .collection('users')
        .doc(userId)
        .collection('budgets')
        .doc(budgetId)
        .delete();
  }

  @override
  Future<List<BudgetModel>> getBudgets(String userId) async {
    return [];
  }
}
