import '../../../domain/entities/month_snapshot.dart';

class SnapshotMemoryDataSource {
  final _items = <MonthSnapshot>[];
  Future<void> save(MonthSnapshot s) async => _items.add(s);
  Future<List<MonthSnapshot>> all() async => List.unmodifiable(_items);
}
