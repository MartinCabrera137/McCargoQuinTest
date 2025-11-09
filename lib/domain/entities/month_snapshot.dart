class MonthSnapshot {
  final int year;
  final int month;
  final double totalIncome;
  final double totalExpense;
  final Map<String, double> consumedByCategory;

  const MonthSnapshot({
    required this.year,
    required this.month,
    required this.totalIncome,
    required this.totalExpense,
    required this.consumedByCategory,
  });
}
