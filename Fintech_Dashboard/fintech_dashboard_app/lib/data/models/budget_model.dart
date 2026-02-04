import '../../domain/entities/budget_entity.dart';

class BudgetModel extends BudgetEntity {
  const BudgetModel({
    super.id,
    required super.amount,
    required super.categoryId,
    required super.userId,
    required super.createdAt,
  });

  factory BudgetModel.fromMap(Map<String, dynamic> map) {
    return BudgetModel(
      id: map['id'],
      amount: map['amount'],
      categoryId: map['category_id'],
      userId: map['user_id'],
      createdAt: DateTime.parse(map['created_at']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'amount': amount,
      'category_id': categoryId,
      'user_id': userId,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory BudgetModel.fromEntity(BudgetEntity entity) {
    return BudgetModel(
      id: entity.id,
      amount: entity.amount,
      categoryId: entity.categoryId,
      userId: entity.userId,
      createdAt: entity.createdAt,
    );
  }
}
