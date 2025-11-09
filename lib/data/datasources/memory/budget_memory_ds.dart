import '../../../domain/entities/budget.dart';

class BudgetMemoryDataSource {
  final _items = <Budget>[];

  Future<void> upsert(Budget b) async {
    final i = _items.indexWhere((x) =>
    x.categoryId == b.categoryId && x.year == b.year && x.month == b.month);
    if (i == -1) { _items.add(b); } else { _items[i] = b; }
  }

  Future<List<Budget>> byMonth(DateTime month) async {
    final y = month.year, m = month.month;
    return _items.where((b) => b.year == y && b.month == m).toList();
  }
}
