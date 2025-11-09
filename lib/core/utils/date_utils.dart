DateTime monthStart(DateTime d) => DateTime(d.year, d.month, 1);
DateTime monthEnd(DateTime d)   => DateTime(d.year, d.month + 1, 0); // último día del mes
DateTime clampToMonth(DateTime baseMonth, DateTime d) {
  final s = monthStart(baseMonth);
  final e = monthEnd(baseMonth);
  if (d.isBefore(s)) return s;
  if (d.isAfter(e))  return e;
  return d;
}
