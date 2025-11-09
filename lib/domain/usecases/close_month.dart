import '../entities/month_snapshot.dart';
import '../entities/tx.dart';
import '../repositories/tx_repository.dart';
import '../repositories/budget_repository.dart';
import '../repositories/snapshot_repository.dart';
import '../repositories/month_repository.dart';

class CloseMonth {
  final TxRepository txRepo;
  final BudgetRepository budgetRepo;
  final SnapshotRepository snapshotRepo;
  final MonthRepository monthRepo;
  CloseMonth(this.txRepo, this.budgetRepo, this.snapshotRepo, this.monthRepo);

  Future<void> call(DateTime month) async {
    final txs = await txRepo.getByMonth(month);

    double income = 0, expense = 0;
    final spentByCat = <String, double>{};
    for (final t in txs) {
      if (t.type == TxType.income) {
        income += t.amount;
      } else {
        expense += t.amount;
        final id = t.categoryId;
        if (id != null) {
          spentByCat[id] = (spentByCat[id] ?? 0) + t.amount;
        }
      }
    }

    final snap = MonthSnapshot(
      year: month.year,
      month: month.month,
      totalIncome: double.parse(income.toStringAsFixed(2)),
      totalExpense: double.parse(expense.toStringAsFixed(2)),
      consumedByCategory: {
        for (final e in spentByCat.entries)
          e.key: double.parse(e.value.toStringAsFixed(2))
      },
    );

    await snapshotRepo.save(snap);
    await monthRepo.markClosed(month.year, month.month);

  }
}
