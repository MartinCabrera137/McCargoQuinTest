// lib/features/dashboard/presentation/dashboard_page.dart
import 'package:cargoquintest/core/utils/colors.dart';
import 'package:cargoquintest/features/dashboard/presentation/widgets/featured_card.dart';
import 'package:cargoquintest/features/shared/widgets/total_Card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:nb_utils/nb_utils.dart';

import '../../../core/formatters/date_formatter.dart';
import '../../../core/formatters/currency_formatter.dart';
import '../../../app/providers.dart';

import '../../transactions/presentation/widgets/add_tx_sheet.dart';
import '../../budgets/presentation/budget_setup_sheet.dart';
import '../../budgets/presentation/widgets/category_usage_tile.dart';

import '../../transactions/presentation/widgets/transactions_usage_tile.dart';
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

//chips
enum DashTab { budgets, moves }

class _DashboardPageState extends ConsumerState<DashboardPage> {
  //chhips
  DashTab _tab = DashTab.budgets;

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
          // Marcar como "ya preguntado" antes de reabir
          ref.read(promptedMonthsProvider.notifier).state = {...prompted, key};

          final saved = await showModalBottomSheet<bool>(context: context, isScrollControlled: true, builder: (_) => const BudgetSetupSheet());

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
      backgroundColor: AppCustomColors.backgroundGrey,
      appBar: AppBar(
        backgroundColor: AppCustomColors.primaryBlue,
        automaticallyImplyLeading: false,
        title: Row(
          children: [
            Text(
              'Martin Cabrera Test',
              style: boldTextStyle(color: AppCustomColors.white, size: 24, fontStyle: FontStyle.italic),
            ),
          ],
        ),
      ),

      body: totalsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),

        data: (t) => SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _quickActions(context, ref),
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  formatMonthYear(month),
                  style: boldTextStyle(size: 24, color: AppCustomColors.primaryBlue),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 128,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  itemCount: 3,
                  separatorBuilder: (_, __) => const SizedBox(width: 12),
                  itemBuilder: (context, i) {
                    switch (i) {
                      case 0:
                        return TotalCard(title: 'Gastos', amountText: formatMXN(t.expense));
                      case 1:
                        return TotalCard(title: 'Ingresos', amountText: formatMXN(t.income));
                      default:
                        return TotalCard(title: 'Ahorro', amountText: formatMXN(t.net));
                    }
                  },
                ),
              ),
              const SizedBox(height: 8),
              AppButton(
                width: double.infinity,
                elevation: 0,
                color: AppCustomColors.errorRed,
                shapeBorder: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                onTap: () async {
                  final ok = await showDialog<bool>(
                    context: context,
                    builder: (_) => AlertDialog(
                      title: Text('Cerrar mes', style: boldTextStyle(size: 18), textAlign: TextAlign.center),
                      icon: Icon(Icons.save_alt_outlined, color: AppCustomColors.primaryBlue, size: 32),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.0)),
                      surfaceTintColor: Colors.white,
                      content: Text('Esto congelará las métricas del mes y avanzará al siguiente mes. ¿Continuar?', style: primaryTextStyle(),),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
                        AppButton(
                          color: AppCustomColors.primaryBlue,
                          shapeBorder: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          text: 'Agregar',
                          textColor: Colors.white,
                          textStyle: primaryTextStyle(color: Colors.white),
                          onTap: () => Navigator.pop(context, true), child: Text('Cerrar mes', style: primaryTextStyle(color: Colors.white))
                        ),
                      ],
                    ),
                  );
                  if (ok == true) {
                    final cm = ref.read(currentMonthProvider);
                    await ref.read(closeMonthProvider)(cm);
                    final next = DateTime(cm.year, cm.month + 1);
                    ref.read(currentMonthProvider.notifier).state = DateTime(next.year, next.month);
                    ref.invalidate(totalsProvider);
                    ref.invalidate(categoryUsageProvider);
                    ref.invalidate(monthTxsProvider);
                    ref.invalidate(snapshotsProvider);
                    ref.invalidate(shouldAskBudgetsProvider);
                    _bootPromptChecked = false;
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Mes cerrado')));
                  }
                },
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.lock_clock, color: Colors.white, size: 20),
                    const SizedBox(width: 8),
                    Text('Cerrar mes', style: boldTextStyle(color: Colors.white)),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _tabSelector(),
              const SizedBox(height: 8),

              AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: _tab == DashTab.budgets ? _budgetsList() : _movesList(),
              ),
              const SizedBox(height: 32),
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
            final savedBudget = await showModalBottomSheet<bool>(context: context, isScrollControlled: true, builder: (_) => const BudgetSetupSheet());
            if (savedBudget == true) {
              ref.invalidate(shouldAskBudgetsProvider);
              ref.invalidate(totalsProvider);
              ref.invalidate(categoryUsageProvider);
            } else {
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Define el presupuesto del mes antes de continuar.')));
              return;
            }
          }

          // Ya con presupuesto, abrir AddTx
          final savedTx = await showModalBottomSheet<bool>(context: context, isScrollControlled: true, builder: (_) => const AddTxSheet());
          if (savedTx == true) {
            ref.invalidate(totalsProvider);
            ref.invalidate(categoryUsageProvider);
            ref.invalidate(monthTxsProvider);
          }
        },
        child: const Icon(Icons.add, color: Colors.white, size: 24),
      ),
    );
  }


  Widget _quickActions(BuildContext context, WidgetRef ref) {
    final m = ref.watch(currentMonthProvider);
    final monthRepo = ref.read(monthRepositoryProvider);

    return FutureBuilder<bool>(
      future: monthRepo.isClosed(m.year, m.month),
      builder: (_, snap) {

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              height: 115,
              child: ListView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                children: [
                  const SizedBox(width: 8),
                  FeatureCard(
                    icon: Icons.history,
                    title: 'Ver histórico',
                    subtitle: 'Consulta tus métricas mes a mes.',
                    onTap: () => context.push('/history'),
                    colors: [AppCustomColors.primaryBlue, AppCustomColors.primaryBlue],
                    filled: true,
                  ),
                  const SizedBox(width: 12),
                  FeatureCard(
                    icon: Icons.list_alt,
                    title: 'Todos los movimientos',
                    subtitle: 'Explora y filtra tus transacciones.',
                    onTap: () => context.push('/transactions'),
                    filled: false, // card blanca
                  ),
                  const SizedBox(width: 8),
                ],
              ),
            ),
          ],
        );
      },
    );
  }


  Widget _pill(String text, bool selected, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppCustomColors.primaryBlue : Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: selected ? [const BoxShadow(color: Color(0x1A000000), blurRadius: 6, offset: Offset(0, 2))] : null,
        ),
        child: Text(
          text,
          style: selected ? boldTextStyle(color: Colors.white) : boldTextStyle(color: AppCustomColors.primaryBlue),
        ),
      ),
    );
  }

  Widget _tabSelector() {
    return Row(
      children: [
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              children: [
                _pill('Presupuesto mensual', _tab == DashTab.budgets, () {
                  setState(() => _tab = DashTab.budgets);
                }),
                const SizedBox(width: 8),
                _pill('Movimientos del mes', _tab == DashTab.moves, () {
                  setState(() => _tab = DashTab.moves);
                }),
              ],
            ),
          ),
        ),
        if (_tab == DashTab.budgets) const SizedBox(width: 8),
      ],
    );
  }

  Widget _budgetsList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppButton(
          color: Colors.transparent,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
          shapeBorder: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          onTap: () => context.push('/budgets'),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.edit, color: AppCustomColors.primaryBlue, size: 16),
              const SizedBox(width: 8),
              Text('Editar presupuesto', style: boldTextStyle(color: AppCustomColors.primaryBlue)),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Consumer(
          builder: (context, ref, _) {
            final usageAsync = ref.watch(categoryUsageProvider);
            return usageAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
              data: (list) => ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: const EdgeInsets.only(top: 8),
                itemCount: list.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (_, i) => CategoryUsageTile(usage: list[i]),
              ),
            );
          },
        ),
      ],
    );
  }
  Widget _movesList() {
    return Consumer(
      builder: (context, ref, _) {
        final txsAsync = ref.watch(monthTxsProvider);
        final cats = ref.watch(categoriesProvider);
        final catById = {for (final c in cats) c.id: c.name};

        return txsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Error: $e')),
          data: (list) {
            final items = list.take(50).toList();
            if (items.isEmpty) return const Center(child: Text('Aún no hay movimientos'));
            return ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.only(top: 8),
              itemCount: items.length,
              itemBuilder: (_, i) {
                final t = items[i];
                return TransactionTile(
                  tx: t,
                  categoryName: t.categoryId != null ? catById[t.categoryId] : null,
                  onDelete: () async {
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
                );
              },
            );
          },
        );
      },
    );
  }}
