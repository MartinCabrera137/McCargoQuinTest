import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/providers.dart';
import '../../../core/formatters/currency_formatter.dart';
import '../../../domain/entities/budget.dart';
import '../../../domain/entities/category.dart';
import '../../dashboard/controllers/totals_provider.dart';
import '../controllers/budget_check_provider.dart';
import '../controllers/category_usage_provider.dart';

class BudgetsPage extends ConsumerWidget {
  const BudgetsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final month = ref.watch(currentMonthProvider);
    final cats = ref.watch(categoriesProvider);
    final budgetRepo = ref.watch(budgetRepositoryProvider);
    final catRepo = ref.watch(monthCategoryRepositoryProvider);
    final monthRepo = ref.read(monthRepositoryProvider);

    return FutureBuilder<bool>(
      future: monthRepo.isClosed(month.year, month.month),
      builder: (_, snap) {
        final isClosed = snap.data == true;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Editar presupuesto del mes actual'),
            actions: [
              IconButton(
                tooltip: 'Agregar categoría',
                onPressed: isClosed ? null : () async {
                  final nameCtrl = TextEditingController();
                  final amountCtrl = TextEditingController();
                  final ok = await showDialog<bool>(
                    context: context,
                    builder: (_) => AlertDialog(
                      title: const Text('Nueva categoría'),
                      content: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Nombre')),
                          TextField(
                            controller: amountCtrl,
                            decoration: const InputDecoration(labelText: 'Presupuesto (MXN)'),
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          ),
                        ],
                      ),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
                        FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Agregar')),
                      ],
                    ),
                  );
                  if (ok == true) {
                    final name = nameCtrl.text.trim();
                    final amt = double.tryParse(amountCtrl.text.replaceAll(',', '.').trim()) ?? 0;
                    if (name.isNotEmpty) {
                      final id = DateTime.now().millisecondsSinceEpoch.toString();
                      catRepo.upsert(month, Category(id, name));
                      await budgetRepo.upsert(Budget(
                        categoryId: id, year: month.year, month: month.month,
                        amount: double.parse(amt.toStringAsFixed(2)),
                      ));
                      ref.invalidate(categoriesProvider);
                      ref.invalidate(shouldAskBudgetsProvider);
                      ref.invalidate(categoryUsageProvider);
                      ref.invalidate(totalsProvider);
                    }
                  }
                },
                icon: const Icon(Icons.add),
              ),
            ],
          ),
          body: FutureBuilder<List<Budget>>(
            future: budgetRepo.getByMonth(month),
            builder: (_, snap) {
              final budgets = snap.data ?? const <Budget>[];
              final map = { for (final b in budgets) b.categoryId : b };

              if (cats.isEmpty) {
                return const Center(child: Text('Aún no hay categorías en este mes'));
              }

              return ListView.separated(
                padding: const EdgeInsets.all(12),
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemCount: cats.length,
                itemBuilder: (_, i) {
                  final Category c = cats[i];
                  final amount = (map[c.id]?.amount ?? 0).toStringAsFixed(2);
                  final nameCtrl = TextEditingController(text: c.name);
                  final amountCtrl = TextEditingController(text: amount);

                  return ListTile(
                    title: TextField(
                      controller: nameCtrl,
                      enabled: !isClosed,
                      decoration: const InputDecoration(border: InputBorder.none),
                      style: const TextStyle(fontWeight: FontWeight.w600),
                      onSubmitted: (v) {
                        if (v.trim().isEmpty) return;
                        ref.read(monthCategoryRepositoryProvider).rename(month, c.id, v.trim());
                        ref.invalidate(categoryUsageProvider);
                      },
                    ),
                    subtitle: Text('Presupuesto: ${formatMXN(double.tryParse(amount) ?? 0)}'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 120,
                          child: TextField(
                            controller: amountCtrl,
                            enabled: !isClosed,
                            textAlign: TextAlign.right,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: const InputDecoration(prefixText: r'$ '),
                            onSubmitted: (v) async {
                              final a = double.tryParse(v.replaceAll(',', '.')) ?? 0;
                              await budgetRepo.upsert(Budget(
                                categoryId: c.id, year: month.year, month: month.month,
                                amount: double.parse(a.toStringAsFixed(2)),
                              ));
                              ref.invalidate(categoryUsageProvider);
                              ref.invalidate(totalsProvider);
                            },
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline),
                          tooltip: 'Eliminar categoría',
                          onPressed: isClosed ? null : () async {
                            final nameCtrl = TextEditingController();
                            final amountCtrl = TextEditingController();
                            final ok = await showDialog<bool>(
                              context: context,
                              builder: (_) => AlertDialog(
                                title: const Text('Nueva categoría'),
                                content: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Nombre')),
                                    TextField(
                                      controller: amountCtrl,
                                      decoration: const InputDecoration(labelText: 'Presupuesto (MXN)'),
                                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                    ),
                                  ],
                                ),
                                actions: [
                                  TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
                                  FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Agregar')),
                                ],
                              ),
                            );
                            if (ok == true) {
                              final name = nameCtrl.text.trim();
                              final amt  = double.tryParse(amountCtrl.text.replaceAll(',', '.').trim()) ?? 0;
                              if (name.isNotEmpty) {
                                final id = DateTime.now().millisecondsSinceEpoch.toString();

                                // repos
                                final month = ref.read(currentMonthProvider);
                                final catRepo = ref.read(monthCategoryRepositoryProvider);
                                final budRepo = ref.read(budgetRepositoryProvider);

                                // persistir
                                catRepo.upsert(month, Category(id, name));
                                await budRepo.upsert(Budget(
                                  categoryId: id, year: month.year, month: month.month,
                                  amount: double.parse(amt.toStringAsFixed(2)),
                                ));

                                // invalidar para refrescar UI y ver los cambios
                                ref.invalidate(categoriesProvider);
                                ref.invalidate(shouldAskBudgetsProvider);
                                ref.invalidate(categoryUsageProvider);
                                ref.invalidate(totalsProvider);

                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Categoría añadida')),
                                  );
                                }
                              }
                            }
                          },
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        );
      },
    );
  }
}
