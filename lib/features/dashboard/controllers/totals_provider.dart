import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/providers.dart';
import '../../../domain/entities/tx.dart';

class Totals {
  final double income;
  final double expense;
  const Totals({required this.income, required this.expense});
  double get net => income - expense;
}

final totalsProvider = FutureProvider<Totals>((ref) async {
  final repo = ref.read(txRepositoryProvider);
  final month = ref.read(currentMonthProvider); // prmer dia del mes
  final txs = await repo.getByMonth(month);

  double income = 0, expense = 0;
  for (final t in txs) {
    if (t.type == TxType.income) {
      income += t.amount;
    } else {
      expense += t.amount;
    }
  }
  return Totals(income: income, expense: expense);
});
