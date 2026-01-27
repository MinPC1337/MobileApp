import 'package:equatable/equatable.dart';

class UserEntity extends Equatable {
  final String id;
  final String email;
  final String displayName;
  final String currency;
  final DateTime createdAt;

  const UserEntity({
    required this.id,
    required this.email,
    required this.displayName,
    required this.currency,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [id, email, displayName, currency, createdAt];
}
