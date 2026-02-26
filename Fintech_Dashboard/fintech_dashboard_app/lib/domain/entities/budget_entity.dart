import 'package:equatable/equatable.dart';

class BudgetEntity extends Equatable {
  final int? id;
  final double amount;
  final int categoryId;
  final String userId;
  final DateTime startDate;
  final DateTime endDate;
  final DateTime createdAt;

  final bool isSynced;
  const BudgetEntity({
    this.id,
    required this.amount,
    required this.categoryId,
    required this.userId,
    required this.startDate,
    required this.endDate,
    required this.createdAt,
    this.isSynced = false,
  });

  @override
  List<Object?> get props => [
    id,
    amount,
    categoryId,
    userId,
    startDate,
    endDate,
    createdAt,
    isSynced,
  ];
}
