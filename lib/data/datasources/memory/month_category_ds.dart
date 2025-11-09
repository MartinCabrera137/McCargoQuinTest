import '../../../domain/entities/category.dart';

class MonthCategoryMemoryDataSource {
  final Map<String, List<Category>> _store = {};

  String _key(DateTime m) => '${m.year}-${m.month.toString().padLeft(2,'0')}';

  List<Category> getByMonth(DateTime m) => List.unmodifiable(_store[_key(m)] ?? []);

  void upsert(DateTime m, Category c) {
    final k = _key(m);
    final list = _store.putIfAbsent(k, () => <Category>[]);
    final idx = list.indexWhere((x) => x.id == c.id);
    if (idx >= 0) list[idx] = c; else list.add(c);
  }

  void upsertMany(DateTime m, List<Category> cs) {
    for (final c in cs) { upsert(m, c); }
  }

  void rename(DateTime m, String id, String name) {
    final list = _store[_key(m)];
    if (list == null) return;
    final idx = list.indexWhere((x) => x.id == id);
    if (idx >= 0) list[idx] = Category(list[idx].id,name);
  }

  bool delete(DateTime m, String id) {
    final list = _store[_key(m)];
    if (list == null) return false;
    final before = list.length;
    list.removeWhere((x) => x.id == id);
    return list.length != before;
  }
}
