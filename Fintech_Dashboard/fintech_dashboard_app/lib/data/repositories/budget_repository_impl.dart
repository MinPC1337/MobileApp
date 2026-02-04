import '../../domain/entities/budget_entity.dart';
import '../../domain/repositories/budget_repository.dart';
import '../data_sources/local/database_helper.dart';
import '../data_sources/remote/budget_remote_data_source.dart';
import '../models/budget_model.dart';

class BudgetRepositoryImpl implements BudgetRepository {
  final DatabaseHelper dbHelper;
  final BudgetRemoteDataSource remoteDataSource;

  BudgetRepositoryImpl({
    required this.dbHelper,
    required this.remoteDataSource,
  });

  @override
  Future<void> addBudget(BudgetEntity budget) async {
    final db = await dbHelper.database;
    final budgetModel = BudgetModel.fromEntity(budget);
    final budgetMap = budgetModel.toMap();
    budgetMap.remove('id');

    final id = await db.insert('budgets', budgetMap);

    final newBudgetModel = BudgetModel(
      id: id,
      amount: budget.amount,
      categoryId: budget.categoryId,
      userId: budget.userId,
      createdAt: budget.createdAt,
    );

    try {
      await remoteDataSource.addBudget(newBudgetModel);
    } catch (e) {
      // Ignore offline error
    }
  }

  @override
  Future<void> updateBudget(BudgetEntity budget) async {
    final db = await dbHelper.database;
    final budgetModel = BudgetModel.fromEntity(budget);

    await db.update(
      'budgets',
      budgetModel.toMap(),
      where: 'id = ?',
      whereArgs: [budget.id],
    );

    try {
      await remoteDataSource.updateBudget(budgetModel);
    } catch (e) {
      // Ignore offline error
    }
  }

  @override
  Future<void> deleteBudget(BudgetEntity budget) async {
    final db = await dbHelper.database;
    await db.delete('budgets', where: 'id = ?', whereArgs: [budget.id]);

    try {
      await remoteDataSource.deleteBudget(budget.userId, budget.id.toString());
    } catch (e) {
      // Ignore offline error
    }
  }

  @override
  Future<List<BudgetEntity>> getBudgets(String userId) async {
    final db = await dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'budgets',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'created_at DESC',
    );
    return maps.map((map) => BudgetModel.fromMap(map)).toList();
  }
}
