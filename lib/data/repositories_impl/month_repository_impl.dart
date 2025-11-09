import '../../domain/repositories/month_repository.dart';
import '../datasources/memory/moth_momory_ds.dart';

class MonthRepositoryImpl implements MonthRepository {
  final MonthMemoryDataSource _ds;
  MonthRepositoryImpl(this._ds);

  @override Future<void> markClosed(int y, int m) => _ds.markClosed(y, m);
  @override Future<bool> isClosed(int y, int m) => _ds.isClosed(y, m);
  @override Future<List<DateTime>> closedMonths() => _ds.all();
}
