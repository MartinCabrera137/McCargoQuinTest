import '../../../domain/entities/tx.dart';

class TxMemoryDataSource {
  final _items = <Tx>[];

  Future<void> add(Tx tx) async => _items.add(tx);

  Future<List<Tx>> byMonth(DateTime month) async {
    final y = month.year, m = month.month;
    return _items.where((t) => t.date.year == y && t.date.month == m).toList();
  }

  Future<List<Tx>> search({
    required DateTime month,
    String? query,
    String? categoryId,
  }) async {
    final base = await byMonth(month);
    final q = query?.toLowerCase().trim();
    return base.where((t) {
      final matchQ = q == null || q.isEmpty || t.concept.toLowerCase().contains(q);
      final matchC = categoryId == null
          ? true
          : (t.type == TxType.expense && t.categoryId == categoryId);
      return matchQ && matchC;
    }).toList();
  }

  Future<void> clearMonth(DateTime month) async {
    final y = month.year, m = month.month;
    _items.removeWhere((t) => t.date.year == y && t.date.month == m);
  }

  Future<void> delete(String id) async => _items.removeWhere((t) => t.id == id);
  Future<int> countByCategoryInMonth(DateTime m, String catId) async {
    final y=m.year, mm=m.month;
    return _items.where((t) =>
    t.type == TxType.expense &&
        t.categoryId == catId &&
        t.date.year == y && t.date.month == mm
    ).length;
  }

}
