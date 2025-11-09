// lib/features/dashboard/presentation/dashboard_page.dart
import 'package:cargoquintest/core/utils/colors.dart';
import 'package:cargoquintest/features/shared/widgets/total_Card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/formatters/date_formatter.dart';
import '../../../core/formatters/currency_formatter.dart';
import '../../../app/providers.dart';

import '../../transactions/presentation/widgets/add_tx_sheet.dart';
import '../../budgets/presentation/budget_setup_sheet.dart';
import '../../budgets/presentation/widgets/category_usage_tile.dart';

import '../controllers/totals_provider.dart';
import '../controllers/month_txs_provider.dart';
import '../../budgets/controllers/budget_check_provider.dart';
import '../../budgets/controllers/category_usage_provider.dart';
import '../../history/presentation/history_page.dart' show snapshotsProvider;
import '../../../domain/entities/tx.dart';

class DashboardPage extends ConsumerStatefulWidget {
  const DashboardPage({super.key});
  @override
  ConsumerState<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends ConsumerState<DashboardPage> {
  bool _isBudgetSheetOpen = false;
  //para checar si ya se ejecuto el promt para pedir el presupuesto
  bool _bootPromptChecked = false;

  @override
  Widget build(BuildContext context) {
    final month = ref.watch(currentMonthProvider);
    final totalsAsync = ref.watch(totalsProvider);

// Observar si faltan presupuestos para el mes activo
    if (!_bootPromptChecked) {
      _bootPromptChecked = true;
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (!mounted) return;

        final key = monthKey(month);
        final prompted = ref.read(promptedMonthsProvider);

        // Si ya preguntamos en este mes durante esta sesión, no abrir de nuevo
        if (prompted.contains(key) || _isBudgetSheetOpen) return;

        // Forzamos reevaluación fresca del provider
        final need = await ref.refresh(shouldAskBudgetsProvider.future);
        if (need == true && mounted) {
          _isBudgetSheetOpen = true;
          // Marcar como "ya preguntado" ANTES de abrir (evita rebotes al navegar)
          ref.read(promptedMonthsProvider.notifier).state = {...prompted, key};

          final saved = await showModalBottomSheet<bool>(
            context: context,
            isScrollControlled: true,
            builder: (_) => const BudgetSetupSheet(),
          );

          _isBudgetSheetOpen = false;

          if (saved == true && mounted) {
            ref.invalidate(shouldAskBudgetsProvider);
            ref.invalidate(totalsProvider);
            ref.invalidate(categoryUsageProvider);
            ref.invalidate(monthTxsProvider);
          }
        }
      });
    }

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text(formatMonthYear(month)),
        actions: [
          Consumer(builder: (context, ref, _) {
            final m = ref.watch(currentMonthProvider);
            final monthRepo = ref.read(monthRepositoryProvider);
            return FutureBuilder<bool>(
              future: monthRepo.isClosed(m.year, m.month),
              builder: (_, snap) {
                final closed = snap.data == true;
                return Row(children: [
                  if (closed)
                    const Padding(
                      padding: EdgeInsets.only(right: 8),
                      child: Chip(label: Text('CERRADO')),
                    ),
                  IconButton(
                    tooltip: 'Transacciones',
                    icon: const Icon(Icons.list_alt),
                    onPressed: () => context.push('/transactions'),
                  ),
                  IconButton(
                    tooltip: 'Presupuestos',
                    icon: const Icon(Icons.account_balance_wallet),
                    onPressed: () => context.push('/budgets'),
                  ),
                  IconButton(
                    tooltip: 'Histórico',
                    icon: const Icon(Icons.history),
                    onPressed: () => context.push('/history'),
                  ),
                  IconButton(
                    tooltip: 'Cerrar mes',
                    icon: const Icon(Icons.lock_clock),
                    onPressed: () async {
                      final ok = await showDialog<bool>(
                        context: context,
                        builder: (_) => AlertDialog(
                          title: const Text('Cerrar mes'),
                          content: const Text(
                            'Esto congelará las métricas del mes y avanzará al siguiente mes. ¿Continuar?',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: const Text('Cancelar'),
                            ),
                            FilledButton(
                              onPressed: () => Navigator.pop(context, true),
                              child: const Text('Cerrar'),
                            ),
                          ],
                        ),
                      );
                      if (ok == true) {
                        final cm = ref.read(currentMonthProvider);
                        await ref.read(closeMonthProvider)(cm);

                        // Avanzar al siguiente mes
                        final next = DateTime(cm.year, cm.month + 1);
                        ref.read(currentMonthProvider.notifier).state =
                            DateTime(next.year, next.month);

                        // Invalidar cálculos y listas, y re-evaluar presupuesto
                        ref.invalidate(totalsProvider);
                        ref.invalidate(categoryUsageProvider);
                        ref.invalidate(monthTxsProvider);
                        ref.invalidate(snapshotsProvider);
                        ref.invalidate(shouldAskBudgetsProvider);

                        //reiniciar a false el boot
                        _bootPromptChecked = false;

                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Mes cerrado')),
                        );
                      }
                    },
                  ),
                ]);
              },
            );
          }),
        ],
      ),
      body: totalsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (t) => Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Totales
              Row(
                children: [
                  Expanded(
                    child: TotalCard(title: 'Gastos', amountText: formatMXN(t.expense)),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TotalCard(title: 'Ingresos', amountText: formatMXN(t.income)),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TotalCard(title: 'Ahorro', amountText: formatMXN(t.net)),

              const SizedBox(height: 24),

              // Por categoría (barras)
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Por categoría',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(height: 8),

              Expanded(
                child: Consumer(
                  builder: (context, ref, _) {
                    final usageAsync = ref.watch(categoryUsageProvider);
                    return usageAsync.when(
                      loading: () => const Center(child: CircularProgressIndicator()),
                      error: (e, _) => Center(child: Text('Error: $e')),
                      data: (list) => ListView.separated(
                        itemCount: list.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (_, i) => CategoryUsageTile(usage: list[i]),
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 24),

              // Movimientos del mes
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Movimientos del mes',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Consumer(
                builder: (context, ref, _) {
                  final txsAsync = ref.watch(monthTxsProvider);
                  return txsAsync.when(
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (e, _) => Text('Error: $e'),
                    data: (list) {
                      final items = list.take(10).toList();
                      if (items.isEmpty) return const Text('Aún no hay movimientos');
                      return Column(
                        children: items
                            .map(
                              (t) => ListTile(
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                          leading: Icon(t.type == TxType.expense ? Icons.remove_circle : Icons.add_circle),
                          title: Text(t.concept),
                          subtitle: Text(t.date.toLocal().toString().split(' ').first),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(formatMXN(t.amount)),
                              const SizedBox(width: 8),
                              IconButton(
                                icon: const Icon(Icons.delete_outline),
                                tooltip: 'Eliminar',
                                onPressed: () async {
                                  final ok = await showDialog<bool>(
                                    context: context,
                                    builder: (_) => AlertDialog(
                                      title: const Text('Eliminar movimiento'),
                                      content: const Text('Esta acción no se puede deshacer. ¿Continuar?'),
                                      actions: [
                                        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
                                        FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Eliminar')),
                                      ],
                                    ),
                                  );
                                  if (ok == true) {
                                    final repo = ref.read(txRepositoryProvider);
                                    await repo.delete(t.id);
                                    ref.invalidate(monthTxsProvider);
                                    ref.invalidate(totalsProvider);
                                    ref.invalidate(categoryUsageProvider);
                                    if (!mounted) return;
                                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Movimiento eliminado')));
                                  }
                                },
                              ),
                            ],
                          ),
                        )
                      )
                            .toList(),
                      );
                    },
                  );
                },
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
          backgroundColor: AppCustomColors.primaryBlue,
        onPressed: () async {
          //Validar presupuesto antes de abrir AddTx
          final need = await ref.refresh(shouldAskBudgetsProvider.future);
          if (need == true) {
            final savedBudget = await showModalBottomSheet<bool>(
              context: context,
              isScrollControlled: true,
              builder: (_) => const BudgetSetupSheet(),
            );
            if (savedBudget == true) {
              ref.invalidate(shouldAskBudgetsProvider);
              ref.invalidate(totalsProvider);
              ref.invalidate(categoryUsageProvider);


            } else {
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Define el presupuesto del mes antes de continuar.'),
                ),
              );
              return;
            }
          }

          // Ya con presupuesto, abrir AddTx
          final savedTx = await showModalBottomSheet<bool>(
            context: context,
            isScrollControlled: true,
            builder: (_) => const AddTxSheet(),
          );
          if (savedTx == true) {
            ref.invalidate(totalsProvider);
            ref.invalidate(categoryUsageProvider);
            ref.invalidate(monthTxsProvider);
          }
        },
        child: const Icon(Icons.add, color: Colors.white,size: 24),
      ),
    );
  }
}
