import 'dart:async';
import 'package:sqflite/sqflite.dart';
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
  Future<List<BudgetEntity>> getBudgets(String userId) async {
    // 1. Cố gắng đồng bộ dữ liệu từ remote về local
    try {
      await syncPendingBudgets(userId: userId);

      final remoteBudgets = await remoteDataSource
          .getBudgets(userId)
          .timeout(const Duration(seconds: 10));

      final db = await dbHelper.database;
      await db.transaction((txn) async {
        // Xóa các ngân sách cũ đã đồng bộ của user
        await txn.delete(
          'budgets',
          where: 'user_id = ? AND is_synced = 1',
          whereArgs: [userId],
        );

        // Chèn dữ liệu mới từ Firebase vào Local
        for (var model in remoteBudgets) {
          final map = model.toMap();
          map['id'] = model.id; // Đảm bảo ID từ Firebase được giữ nguyên

          await txn.insert(
            'budgets',
            map,
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }
      });
    } catch (e) {
      // Nếu có lỗi (mất mạng, timeout), bỏ qua và dùng dữ liệu Local cũ
      // print("Sync budgets error: $e");
    }

    // 2. Luôn trả về dữ liệu từ local DB
    final db = await dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'budgets',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'created_at DESC',
    );

    return maps.map((map) => BudgetModel.fromMap(map)).toList();
  }

  @override
  Future<void> addBudget(BudgetEntity budget) async {
    final budgetModel = BudgetModel.fromEntity(budget);
    final db = await dbHelper.database;

    // 1. Lưu Local trước (is_synced mặc định là 0)
    final map = budgetModel.toMap();
    if (map['id'] == null) {
      map.remove('id');
    }
    final localId = await db.insert('budgets', map);

    // 2. Cố gắng đồng bộ lên Firebase
    try {
      final mapToSync = budgetModel.toMap();
      mapToSync['id'] = localId;
      mapToSync['is_synced'] = 1;
      final modelToSync = BudgetModel.fromMap(mapToSync);

      await remoteDataSource
          .addBudget(modelToSync)
          .timeout(const Duration(seconds: 5));

      // 3. Nếu thành công, cập nhật trạng thái đã sync
      await db.update(
        'budgets',
        {'is_synced': 1},
        where: 'id = ?',
        whereArgs: [localId],
      );
    } catch (e) {
      // Lỗi offline, sẽ được đồng bộ sau.
    }
  }

  @override
  Future<void> updateBudget(BudgetEntity budget) async {
    if (budget.id == null) {
      throw Exception("Cannot update budget without ID");
    }
    final budgetModel = BudgetModel.fromEntity(budget);
    final db = await dbHelper.database;

    // 1. Cập nhật Local, đánh dấu là chưa đồng bộ
    await db.update(
      'budgets',
      budgetModel.toMap()..['is_synced'] = 0,
      where: 'id = ?',
      whereArgs: [budget.id],
    );

    // 2. Cố gắng đồng bộ lên Firebase
    try {
      final mapToSync = budgetModel.toMap();
      mapToSync['is_synced'] = 1;
      final modelToSync = BudgetModel.fromMap(mapToSync);

      await remoteDataSource
          .updateBudget(modelToSync)
          .timeout(const Duration(seconds: 5));

      // 3. Nếu thành công, cập nhật lại trạng thái đã sync
      await db.update(
        'budgets',
        {'is_synced': 1},
        where: 'id = ?',
        whereArgs: [budget.id],
      );
    } catch (e) {
      // Lỗi offline.
    }
  }

  @override
  Future<void> deleteBudget(BudgetEntity budget) async {
    if (budget.id == null) return;
    final db = await dbHelper.database;

    // 1. Xóa Local
    await db.delete('budgets', where: 'id = ?', whereArgs: [budget.id]);

    // 2. Cố gắng xóa trên Remote
    try {
      await remoteDataSource
          .deleteBudget(budget.userId, budget.id.toString())
          .timeout(const Duration(seconds: 5));
    } catch (e) {
      // Lỗi offline.
    }
  }

  @override
  Future<void> syncPendingBudgets({required String userId}) async {
    final db = await dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'budgets',
      where: 'is_synced = ? AND user_id = ?',
      whereArgs: [0, userId],
    );

    for (var map in maps) {
      final mapToSync = Map<String, dynamic>.from(map);
      mapToSync['is_synced'] = 1;
      final model = BudgetModel.fromMap(mapToSync);
      try {
        await remoteDataSource
            .addBudget(model)
            .timeout(const Duration(seconds: 5));

        await db.update(
          'budgets',
          {'is_synced': 1},
          where: 'id = ?',
          whereArgs: [model.id],
        );
      } catch (e) {
        continue;
      }
    }
  }

  @override
  Future<void> clearLocalData() async {
    final db = await dbHelper.database;
    await db.delete('budgets');
  }
}
