import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../data/datasources/memory/month_category_ds.dart';
import '../data/datasources/memory/moth_momory_ds.dart';
import '../data/repositories_impl/month_category_repository_impl.dart';
import '../data/repositories_impl/month_repository_impl.dart';
import '../domain/entities/category.dart';
import '../domain/repositories/month_category_repository.dart';
import '../domain/repositories/month_repository.dart';
import '../domain/repositories/tx_repository.dart';
import '../domain/repositories/budget_repository.dart';
import '../domain/repositories/snapshot_repository.dart';
import '../data/datasources/memory/tx_memory_ds.dart';
import '../data/datasources/memory/budget_memory_ds.dart';
import '../data/datasources/memory/snapshot_memory_ds.dart';
import '../data/repositories_impl/tx_repository_impl.dart';
import '../data/repositories_impl/budget_repository_impl.dart';
import '../data/repositories_impl/snapshot_repository_impl.dart';
import '../domain/usecases/close_month.dart';

final txRepositoryProvider = Provider<TxRepository>(
      (ref) => TxRepositoryImpl(TxMemoryDataSource()),
);

final budgetRepositoryProvider = Provider<BudgetRepository>(
      (ref) => BudgetRepositoryImpl(BudgetMemoryDataSource()),
);

final snapshotRepositoryProvider = Provider<SnapshotRepository>(
      (ref) => SnapshotRepositoryImpl(SnapshotMemoryDataSource()),
);

// Mes actual que se comparte por provider
final currentMonthProvider = StateProvider<DateTime>((ref) {
  final now = DateTime.now();
  return DateTime(now.year, now.month);
});

final closeMonthProvider = Provider<CloseMonth>((ref) => CloseMonth(
  ref.read(txRepositoryProvider),
  ref.read(budgetRepositoryProvider),
  ref.read(snapshotRepositoryProvider),
  ref.read(monthRepositoryProvider),
));


final monthRepositoryProvider = Provider<MonthRepository>(
      (ref) => MonthRepositoryImpl(MonthMemoryDataSource()),
);


// Identificador para no repetir el mes
String monthKey(DateTime m) =>
    '${m.year}-${m.month.toString().padLeft(2, '0')}';

//Meses para los que ya pedi el presupuesto por primera vez
final promptedMonthsProvider = StateProvider<Set<String>>((_) => <String>{});

// inyección de categorías por mes
final monthCategoryRepositoryProvider = Provider<MonthCategoryRepository>(
      (ref) => MonthCategoryRepositoryImpl(MonthCategoryMemoryDataSource()),
);

// lista de categorías del mes ACTIVO (sync)
final categoriesProvider = Provider<List<Category>>((ref) {
  final repo = ref.read(monthCategoryRepositoryProvider);
  final m = ref.watch(currentMonthProvider);
  return repo.getByMonth(m);
});

// listas de categorías por mes para el historial
final categoriesByMonthProvider =
Provider.family<List<Category>, DateTime>((ref, month) {
  final repo = ref.read(monthCategoryRepositoryProvider);
  final m = DateTime(month.year, month.month);
  return repo.getByMonth(m);
});

