import 'package:equatable/equatable.dart';

abstract class TransactionFormState extends Equatable {
  const TransactionFormState();
  @override
  List<Object> get props => [];
}

class TransactionFormInitial extends TransactionFormState {}

class TransactionFormLoading extends TransactionFormState {}

class TransactionFormSuccess extends TransactionFormState {}

class TransactionFormFailure extends TransactionFormState {
  final String message;
  const TransactionFormFailure(this.message);
}
