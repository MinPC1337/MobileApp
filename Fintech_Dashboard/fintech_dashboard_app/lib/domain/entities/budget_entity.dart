import 'package:equatable/equatable.dart';

class BudgetEntity extends Equatable {
  final int? id;
  final double amountLimit;
  final DateTime startDate;
  final DateTime endDate;
  final int categoryId;
  final String userId;
  final DateTime updatedAt;

  const BudgetEntity({
    this.id,
    required this.amountLimit,
    required this.startDate,
    required this.endDate,
    required this.categoryId,
    required this.userId,
    required this.updatedAt,
  });

  @override
  List<Object?> get props => [
    id,
    amountLimit,
    startDate,
    endDate,
    categoryId,
    userId,
    updatedAt,
  ];
}
