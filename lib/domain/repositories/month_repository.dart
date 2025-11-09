abstract class MonthRepository {
  Future<void> markClosed(int year, int month);
  Future<bool> isClosed(int year, int month);
  Future<List<DateTime>> closedMonths();
}
