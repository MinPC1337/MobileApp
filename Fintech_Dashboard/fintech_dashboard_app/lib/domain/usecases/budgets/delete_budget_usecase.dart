import '../../entities/budget_entity.dart';
import '../../repositories/budget_repository.dart';

class DeleteBudgetUseCase {
  final BudgetRepository repository;

  DeleteBudgetUseCase(this.repository);

  Future<void> call(BudgetEntity budget) async {
    return await repository.deleteBudget(budget);
  }
}
