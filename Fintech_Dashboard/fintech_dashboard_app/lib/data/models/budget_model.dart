import '../../domain/entities/budget_entity.dart';

class BudgetModel extends BudgetEntity {
  const BudgetModel({
    super.id,
    required super.amountLimit,
    required super.startDate,
    required super.endDate,
    required super.categoryId,
    required super.userId,
    required super.updatedAt,
  });

  factory BudgetModel.fromMap(Map<String, dynamic> map) {
    return BudgetModel(
      id: map['id'],
      amountLimit: map['amount_limit'],
      startDate: DateTime.parse(map['start_date']),
      endDate: DateTime.parse(map['end_date']),
      categoryId: map['category_id'],
      userId: map['user_id'],
      updatedAt: DateTime.parse(map['updated_at']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'amount_limit': amountLimit,
      'start_date': startDate.toIso8601String(),
      'end_date': endDate.toIso8601String(),
      'category_id': categoryId,
      'user_id': userId,
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}
