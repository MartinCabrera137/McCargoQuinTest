import '../entities/month_snapshot.dart';

abstract class SnapshotRepository {
  Future<void> save(MonthSnapshot snapshot);
  Future<List<MonthSnapshot>> all();
}
