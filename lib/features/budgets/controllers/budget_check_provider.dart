import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/providers.dart';

/// si es true hay que pedir presupuesto del mes activo
final shouldAskBudgetsProvider = FutureProvider<bool>((ref) async {
  final month = ref.watch(currentMonthProvider);
  final categories = ref.watch(categoriesProvider); // por mes

  // Si no hay categorías definidas para el mes, pedir presupuesto
  if (categories.isEmpty) return true;

  final repo = ref.read(budgetRepositoryProvider);
  final budgets = await repo.getByMonth(month);
  final have = budgets.map((b) => b.categoryId).toSet();

  // Si falta al menos 1 presupuesto para las categorías del mes, pedirlo
  final allSet = categories.every((c) => have.contains(c.id));
  return !allSet;
});
