import '../../domain/entities/budget_entity.dart';

class BudgetModel extends BudgetEntity {
  const BudgetModel({
    super.id,
    required super.amount,
    required super.categoryId,
    required super.userId,
    required super.startDate,
    required super.endDate,
    required super.createdAt,
    super.isSynced,
  });

  factory BudgetModel.fromMap(Map<String, dynamic> map) {
    return BudgetModel(
      id: map['id'],
      amount: map['amount'],
      categoryId: map['category_id'],
      userId: map['user_id'],
      startDate: DateTime.parse(map['start_date']),
      endDate: DateTime.parse(map['end_date']),
      createdAt: DateTime.parse(map['created_at']),
      isSynced: map['is_synced'] == 1,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'amount': amount,
      'category_id': categoryId,
      'user_id': userId,
      'start_date': startDate.toIso8601String(),
      'end_date': endDate.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'is_synced': isSynced ? 1 : 0,
    };
  }

  factory BudgetModel.fromEntity(BudgetEntity entity) {
    return BudgetModel(
      id: entity.id,
      amount: entity.amount,
      categoryId: entity.categoryId,
      userId: entity.userId,
      startDate: entity.startDate,
      endDate: entity.endDate,
      createdAt: entity.createdAt,
      isSynced: entity.isSynced,
    );
  }
}
