import 'package:equatable/equatable.dart';
import '../../domain/entities/transaction_entity.dart';

class DashboardState extends Equatable {
  final bool isLoading;
  final double totalBalance;
  final List<TransactionEntity> transactions;
  final String? errorMessage;

  const DashboardState({
    this.isLoading = false,
    this.totalBalance = 0.0,
    this.transactions = const [],
    this.errorMessage,
  });

  // Hàm copyWith giúp tạo ra trạng thái mới từ trạng thái cũ mà không làm mất các dữ liệu hiện có
  DashboardState copyWith({
    bool? isLoading,
    double? totalBalance,
    List<TransactionEntity>? transactions,
    String? errorMessage,
  }) {
    return DashboardState(
      isLoading: isLoading ?? this.isLoading,
      totalBalance: totalBalance ?? this.totalBalance,
      transactions: transactions ?? this.transactions,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [
    isLoading,
    totalBalance,
    transactions,
    errorMessage,
  ];
}
