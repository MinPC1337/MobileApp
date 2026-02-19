import 'package:equatable/equatable.dart';

class CategoryEntity extends Equatable {
  final int? id;
  final String name;
  final String type;
  final String icon;
  final String? userId;
  final DateTime updatedAt;

  final bool isSynced;
  const CategoryEntity({
    this.id,
    required this.name,
    required this.type,
    required this.icon,
    this.userId,
    required this.updatedAt,
    this.isSynced = false,
  });

  @override
  List<Object?> get props => [
    id,
    name,
    type,
    icon,
    userId,
    updatedAt,
    isSynced,
  ];
}
