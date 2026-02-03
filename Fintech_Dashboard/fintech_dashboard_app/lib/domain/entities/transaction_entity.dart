import 'package:equatable/equatable.dart';

class TransactionEntity extends Equatable {
  final int? id;
  final double amount;
  final String note;
  final DateTime date;
  final int categoryId;
  final String userId;
  final bool isSynced;
  final DateTime updatedAt;
  final String? categoryName;
  final String? categoryType;
  final String? categoryIcon;

  const TransactionEntity({
    this.id,
    required this.amount,
    required this.note,
    required this.date,
    required this.categoryId,
    required this.userId,
    this.isSynced = false,
    required this.updatedAt,
    this.categoryName,
    this.categoryType,
    this.categoryIcon,
  });

  @override
  List<Object?> get props => [
    id,
    amount,
    note,
    date,
    categoryId,
    userId,
    isSynced,
    updatedAt,
    categoryName,
    categoryType,
    categoryIcon,
  ];
}
