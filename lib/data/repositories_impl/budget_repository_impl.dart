import '../../domain/entities/budget.dart';
import '../../domain/repositories/budget_repository.dart';
import '../datasources/memory/budget_memory_ds.dart';

class BudgetRepositoryImpl implements BudgetRepository {
  final BudgetMemoryDataSource _ds;
  BudgetRepositoryImpl(this._ds);

  @override Future<void> upsert(Budget b) => _ds.upsert(b);
  @override Future<List<Budget>> getByMonth(DateTime month) => _ds.byMonth(month);
}
