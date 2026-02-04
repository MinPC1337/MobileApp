import '../../entities/budget_entity.dart';
import '../../repositories/budget_repository.dart';

class UpdateBudgetUseCase {
  final BudgetRepository repository;

  UpdateBudgetUseCase(this.repository);

  Future<void> call(BudgetEntity budget) async {
    return await repository.updateBudget(budget);
  }
}
