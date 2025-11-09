import 'package:cargoquintest/core/utils/colors.dart';
import 'package:cargoquintest/features/budgets/presentation/widgets/add_category_dialog.dart';
import 'package:cargoquintest/features/budgets/presentation/widgets/picked_category.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/providers.dart';
import '../../../core/formatters/date_formatter.dart';
import '../../../domain/entities/budget.dart';
import '../../../domain/entities/category.dart';
import '../../dashboard/controllers/totals_provider.dart';
import '../controllers/budget_check_provider.dart';
import '../controllers/category_usage_provider.dart';
import 'package:nb_utils/nb_utils.dart';

const _defaultCategories = <String>['Vivienda', 'Alimentos', 'Transporte', 'Salud', 'Educación', 'Entretenimiento', 'Ahorro', 'Otros'];

class BudgetSetupSheet extends ConsumerStatefulWidget {
  const BudgetSetupSheet({super.key});

  @override
  ConsumerState<BudgetSetupSheet> createState() => _BudgetSetupSheetState();
}

class _BudgetSetupSheetState extends ConsumerState<BudgetSetupSheet> {
  final _formKey = GlobalKey<FormState>();
  final Map<String, Picked> _picked = {}; // id -> picked

  @override
  void dispose() {
    for (final p in _picked.values) {
      p.amount.dispose();
    }
    super.dispose();
  }

  Future<void> _openAddCategoryDialog({required Map<String, String> options, required bool isClosed}) async {
    if (isClosed) return;

    final res = await showDialog<AddCategoryResult>(
      context: context,
      builder: (_) => AddCategoryDialog(options: options, excludeIds: _picked.keys.toSet()),
    );

    if (res != null && mounted) {
      setState(() => _picked[res.id] = Picked(res.id, res.name, res.amount));
    }
  }

  @override
  Widget build(BuildContext context) {
    final month = ref.watch(currentMonthProvider);
    final monthFormat = formatMonthYear(month);
    final catsExisting = ref.watch(categoriesProvider);
    final monthRepo = ref.read(monthRepositoryProvider);

    final Map<String, String> baseOptions = {
      for (final c in catsExisting) c.id: c.name,
      for (final n in _defaultCategories) n.toLowerCase().replaceAll(' ', '_'): n,
    };

    for (final c in catsExisting) {
      _picked.putIfAbsent(c.id, () => Picked(c.id, c.name, ''));
    }

    return FutureBuilder<bool>(
      future: monthRepo.isClosed(month.year, month.month),
      builder: (_, snap) {
        final isClosed = snap.data == true;

        return Container(
          decoration: BoxDecoration(
            color: AppCustomColors.backgroundGrey,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 8,
              ),
            ],
          ),          child: Padding(
            padding: EdgeInsets.only(left: 16, right: 16, top: 12, bottom: 16 + MediaQuery.of(context).viewInsets.bottom),
            child: Form(
              key: _formKey,
              child: SingleChildScrollView(
                keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      height: 4,
                      width: 64,
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(color: AppCustomColors.mediumGrey, borderRadius: BorderRadius.circular(2)),
                    ),

                    Text(
                      isClosed ? 'Mes cerrado (solo lectura)' : 'Presupuesto $monthFormat',
                      style: boldTextStyle(size: 24, color: AppCustomColors.primaryBlue)
                    ),
                    const SizedBox(height: 12),
                    Align(
                      alignment: AlignmentGeometry.centerLeft,
                      child: Text(
                          isClosed ? '' : 'Agrega las categorias y el presupuesto de gastos que necesitas para este mes.',
                          style: primaryTextStyle()
                      ),
                    ),
                    const SizedBox(height: 8),
                    AppButton(
                      color: AppCustomColors.primaryBlue,
                      shapeBorder: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                      onTap: isClosed
                          ? null
                          : () {
                              _openAddCategoryDialog(options: baseOptions, isClosed: isClosed);
                            },
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.add, color: Colors.white, size: 20),
                          const SizedBox(width: 8),
                          Text(_picked.isEmpty ? 'Agregar categoría' : 'Agregar otra categoria', style: primaryTextStyle(color: Colors.white)),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),


                    if (_picked.isNotEmpty) ...[

                      // Encabezado
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text('Categorías agregadas', style: boldTextStyle()),
                      ),
                      const SizedBox(height: 8),

                      // Lista de categorías
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _picked.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (_, i) {
                          final item = _picked.values.elementAt(i);
                          return PickedTile(
                            item: item,
                            isClosed: isClosed,
                            onRemove: isClosed ? null : () => setState(() => _picked.remove(item.id)),
                          );
                        },
                      ),

                      const SizedBox(height: 16),

                      // Guardar / Cerrar (solo visible cuando hay categorías)
                      AppButton(
                        width: double.infinity,
                        color: AppCustomColors.primaryBlue,
                        disabledColor: AppCustomColors.mediumGrey,
                        shapeBorder: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        onTap: isClosed
                            ? () => Navigator.pop(context, false)
                            : () async {
                          if (!_formKey.currentState!.validate()) return;

                          final repoCat = ref.read(monthCategoryRepositoryProvider);
                          final repoBud = ref.read(budgetRepositoryProvider);

                          final toSave = <Category>[];
                          final budgets = <Budget>[];

                          for (final p in _picked.values) {
                            final raw = p.amount.text.replaceAll(',', '.').trim();
                            final amt = double.tryParse(raw) ?? 0;
                            final cat = Category(p.id, p.name);
                            toSave.add(cat);
                            budgets.add(Budget(
                              categoryId: cat.id,
                              year: month.year,
                              month: month.month,
                              amount: double.parse(amt.toStringAsFixed(2)),
                            ));
                          }

                          repoCat.upsertMany(month, toSave);
                          for (final b in budgets) { await repoBud.upsert(b); }

                          ref.invalidate(categoriesProvider);
                          ref.invalidate(shouldAskBudgetsProvider);
                          ref.invalidate(categoryUsageProvider);
                          ref.invalidate(totalsProvider);

                          if (!mounted) return;
                          Navigator.of(context).pop(true);
                        },
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(isClosed ? Icons.close : Icons.save, color: Colors.white, size: 20),
                            const SizedBox(width: 8),
                            Text('Guardar presupuesto', style: boldTextStyle(color: Colors.white)),
                          ],
                        ),
                      ),

                    ],
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
