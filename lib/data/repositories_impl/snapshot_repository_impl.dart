import '../../domain/entities/month_snapshot.dart';
import '../../domain/repositories/snapshot_repository.dart';
import '../datasources/memory/snapshot_memory_ds.dart';

class SnapshotRepositoryImpl implements SnapshotRepository {
  final SnapshotMemoryDataSource _ds;
  SnapshotRepositoryImpl(this._ds);

  @override Future<void> save(MonthSnapshot s) => _ds.save(s);
  @override Future<List<MonthSnapshot>> all() => _ds.all();
}
