import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/providers.dart';
import '../../../domain/entities/tx.dart';

class CategoryUsage {
  final String categoryId;
  final String categoryName;
  final double budget;   // presupuesto total del mes
  final double spent;    // gasto total acumulado
  final double percent;  // para las barras
  final bool nearLimit;  // cerca del limite mas de 80 menos de 100
  final bool overLimit;  // gastado mas del limite

  const CategoryUsage({
    required this.categoryId,
    required this.categoryName,
    required this.budget,
    required this.spent,
    required this.percent,
    required this.nearLimit,
    required this.overLimit,
  });
}

/// lista que guarda el consumo por categoria
final categoryUsageProvider = FutureProvider<List<CategoryUsage>>((ref) async {
    final month = ref.watch(currentMonthProvider);
    final txRepo = ref.read(txRepositoryProvider);
    final budgetRepo = ref.read(budgetRepositoryProvider);
    final cats = ref.read(categoriesProvider);


  final txs = await txRepo.getByMonth(month);
  final budgets = await budgetRepo.getByMonth(month);
  final budgetMap = {for (final b in budgets) b.categoryId: b.amount};

  // agrupar gastos por categoría
  final spentByCat = <String, double>{};
  for (final t in txs) {
    if (t.type == TxType.expense && t.categoryId != null) {
      spentByCat[t.categoryId!] = (spentByCat[t.categoryId!] ?? 0) + t.amount;
    }
  }

  final result = <CategoryUsage>[];
  for (final c in cats) {
    final budget = (budgetMap[c.id] ?? 0).toDouble();
    final spent = (spentByCat[c.id] ?? 0).toDouble();
    final percentRaw = budget <= 0
        ? (spent > 0 ? 1.0 : 0.0)
        : (spent / budget);
    final percent = percentRaw.clamp(0.0, 1.0);
    final over = budget > 0 && spent > budget;
    final near = !over && percentRaw >= 0.8;

    result.add(CategoryUsage(
      categoryId: c.id,
      categoryName: c.name,
      budget: double.parse(budget.toStringAsFixed(2)),
      spent: double.parse(spent.toStringAsFixed(2)),
      percent: percent,
      nearLimit: near,
      overLimit: over,
    ));
  }

  return result;
});
