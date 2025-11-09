import '../entities/budget.dart';

abstract class BudgetRepository {
  Future<void> upsert(Budget budget);
  Future<List<Budget>> getByMonth(DateTime month);
}
