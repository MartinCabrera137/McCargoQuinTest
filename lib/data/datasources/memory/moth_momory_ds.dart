class MonthMemoryDataSource {
  final _closed = <String>{};

  Future<void> markClosed(int year, int month) async {
    _closed.add("$year-${month.toString().padLeft(2, '0')}");
  }

  Future<bool> isClosed(int year, int month) async {
    return _closed.contains("$year-${month.toString().padLeft(2, '0')}");
  }

  Future<List<DateTime>> all() async {
    return _closed.map((s) {
      final parts = s.split('-');
      return DateTime(int.parse(parts[0]), int.parse(parts[1]));
    }).toList()
      ..sort((a, b) => b.compareTo(a)); // orden desendente
  }
}
