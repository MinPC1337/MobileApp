import 'package:equatable/equatable.dart';

class BudgetEntity extends Equatable {
  final int? id;
  final double amount;
  final int categoryId;
  final String userId;
  final DateTime createdAt;

  const BudgetEntity({
    this.id,
    required this.amount,
    required this.categoryId,
    required this.userId,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [id, amount, categoryId, userId, createdAt];
}
