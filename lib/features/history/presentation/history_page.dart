import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/providers.dart';
import '../../../domain/entities/month_snapshot.dart';
import '../../../core/formatters/currency_formatter.dart';
import '../../budgets/controllers/category_usage_provider.dart';
import '../../dashboard/controllers/month_txs_provider.dart';
import '../../dashboard/controllers/totals_provider.dart';

final snapshotsProvider = FutureProvider<List<MonthSnapshot>>((ref) {
  return ref.read(snapshotRepositoryProvider).all();
});


class HistoryPage extends ConsumerWidget {
  const HistoryPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final snaps = ref.watch(snapshotsProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Histórico'),
        actions: [
          IconButton(
            icon: const Icon(Icons.lock_clock),
            tooltip: 'Cerrar mes',
            onPressed: () async {
              final ok = await showDialog<bool>(
                context: context,
                builder: (_) => AlertDialog(
                  title: const Text('Cerrar mes'),
                  content: const Text('Esto congelará las métricas del mes y reiniciará acumulados. ¿Continuar?'),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
                    FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Cerrar')),
                  ],
                ),
              );
              if (ok == true) {
                final cm = ref.read(currentMonthProvider);
                await ref.read(closeMonthProvider)(cm);

                // Avanzar al siguiente mes
                final next = DateTime(cm.year, cm.month + 1);
                ref.read(currentMonthProvider.notifier).state = DateTime(next.year, next.month);

                // invalidar cálculos
                ref.invalidate(totalsProvider);
                ref.invalidate(categoryUsageProvider);
                ref.invalidate(monthTxsProvider);
                ref.invalidate(snapshotsProvider);

                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Mes cerrado')));
              }
            },
          ),
        ],
      ),
      body: snaps.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (list) => list.isEmpty
            ? const Center(child: Text('Aún no hay meses cerrados'))
            : ListView.separated(
                itemCount: list.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (_, i) {
                  final s = list[i];
                  final ym = '${s.year.toString().padLeft(4, '0')}-${s.month.toString().padLeft(2, '0')}';
                  return ListTile(
                    title: Text('Mes $ym'),
                    subtitle: Text('Ingreso: ${formatMXN(s.totalIncome)}   Gasto: ${formatMXN(s.totalExpense)}'),
                    trailing: Text('Ahorro: ${formatMXN(s.totalIncome - s.totalExpense)}'),
                  );
                },
              ),
      ),
    );
  }
}
