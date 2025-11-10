// lib/features/budgets/presentation/budgets_page.dart
import 'package:cargoquintest/core/utils/colors.dart';
import 'package:cargoquintest/features/budgets/presentation/widgets/add_category_dialog.dart';
import 'package:cargoquintest/features/shared/widgets/Custom_text_fromfield.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nb_utils/nb_utils.dart';

import '../../../app/providers.dart';
import '../../../core/formatters/currency_formatter.dart';
import '../../../domain/entities/budget.dart';
import '../../../domain/entities/category.dart';
import '../../dashboard/controllers/totals_provider.dart';
import '../controllers/budget_check_provider.dart';
import '../controllers/category_usage_provider.dart';

const _defaults = <String>[
  'Vivienda',
  'Alimentos',
  'Transporte',
  'Salud',
  'Educación',
  'Entretenimiento',
  'Ahorro',
  'Otros',
];

class BudgetsPage extends ConsumerStatefulWidget {
  const BudgetsPage({super.key});
  @override
  ConsumerState<BudgetsPage> createState() => _BudgetsPageState();
}

class _BudgetsPageState extends ConsumerState<BudgetsPage> {
  final _formKey = GlobalKey<FormState>();

  final Map<String, TextEditingController> _amountCtrls = {};
  final Map<String, TextEditingController> _nameCtrls = {};

  final Set<String> _hydrated = {}; // ids ya sincronizados con repo
  bool _dirty = false;
  bool _updating = false; // evita marcar dirty en updates programáticos

  void _syncCtrls(
      List<Category> cats,
      Map<String, double> amounts, {
        required bool budgetsReady,
      }) {
    _nameCtrls.removeWhere((id, _) => !cats.any((c) => c.id == id));
    _amountCtrls.removeWhere((id, _) => !cats.any((c) => c.id == id));

    for (final c in cats) {
      final targetAmount = (amounts[c.id] ?? 0).toStringAsFixed(2);

      if (!_nameCtrls.containsKey(c.id)) {
        final ctrl = TextEditingController(text: c.name);
        ctrl.addListener(() {
          if (_updating) return;
          setState(() => _dirty = true);
        });
        _nameCtrls[c.id] = ctrl;
      } else if (budgetsReady && _nameCtrls[c.id]!.text != c.name) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _updating = true;
          _nameCtrls[c.id]!.text = c.name;
          _updating = false;
        });
      }

      if (!_amountCtrls.containsKey(c.id)) {
        // Inicial: muestra 0.00 pero luego hidratamos post-frame
        final ctrl = TextEditingController(text: budgetsReady ? targetAmount : '0.00');
        ctrl.addListener(() {
          if (_updating) return;
          setState(() => _dirty = true);
        });
        _amountCtrls[c.id] = ctrl;
        if (budgetsReady) _hydrated.add(c.id);
      } else if (budgetsReady && !_hydrated.contains(c.id)) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _updating = true;
          if (_amountCtrls[c.id]!.text != targetAmount) {
            _amountCtrls[c.id]!.text = targetAmount;
          }
          _updating = false;
          _hydrated.add(c.id);
        });
      }
    }
  }


  Future<void> _openAddCategoryDialog({
    required Map<String, String> options,
    required Set<String> exclude,
    required bool isClosed,
  }) async {
    if (isClosed) return;
    final res = await showDialog<AddCategoryResult>(
      context: context,
      builder: (_) => AddCategoryDialog(options: options, excludeIds: exclude),
    );
    if (res == null) return;

    final month = ref.read(currentMonthProvider);
    final catRepo = ref.read(monthCategoryRepositoryProvider);
    final budRepo = ref.read(budgetRepositoryProvider);

    catRepo.upsert(month, Category(res.id, res.name));
    await budRepo.upsert(
      Budget(
        categoryId: res.id,
        year: month.year,
        month: month.month,
        amount: double.tryParse(res.amount.replaceAll(',', '.')) ?? 0,
      ),
    );

    ref.invalidate(categoriesProvider);
    ref.invalidate(categoryUsageProvider);
    ref.invalidate(totalsProvider);
    ref.invalidate(shouldAskBudgetsProvider);

    setState(() {
      _dirty = false;
      _nameCtrls.clear();
      _amountCtrls.clear();
      _hydrated.clear();
    });
  }

  Future<void> _saveAll({
    required List<Category> cats,
    required Map<String, double> prevAmounts,
    required bool isClosed,
  }) async {
    if (isClosed || !_formKey.currentState!.validate()) return;

    final month = ref.read(currentMonthProvider);
    final catRepo = ref.read(monthCategoryRepositoryProvider);
    final budRepo = ref.read(budgetRepositoryProvider);

    for (final c in cats) {
      final newName = _nameCtrls[c.id]?.text.trim() ?? c.name;
      if (newName.isNotEmpty && newName != c.name) {
        catRepo.rename(month, c.id, newName);
      }

      final raw = (_amountCtrls[c.id]?.text ?? '').replaceAll(',', '.').trim();
      final a = double.tryParse(raw) ?? 0;
      if (a != (prevAmounts[c.id] ?? 0)) {
        await budRepo.upsert(
          Budget(
            categoryId: c.id,
            year: month.year,
            month: month.month,
            amount: double.parse(a.toStringAsFixed(2)),
          ),
        );
      }
    }

    ref.invalidate(categoriesProvider);
    ref.invalidate(categoryUsageProvider);
    ref.invalidate(totalsProvider);

    if (!mounted) return;
    setState(() => _dirty = false);
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Presupuesto guardado')));
  }

  @override
  void dispose() {
    for (final c in _amountCtrls.values) {
      c.dispose();
    }
    for (final c in _nameCtrls.values) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final month = ref.watch(currentMonthProvider);
    final cats = ref.watch(categoriesProvider);
    final monthRepo = ref.read(monthRepositoryProvider);
    final usageAsync = ref.watch(categoryUsageProvider);

    return FutureBuilder<bool>(
      future: monthRepo.isClosed(month.year, month.month),
      builder: (_, snap) {
        final isClosed = snap.data == true;

        return Scaffold(
          backgroundColor: AppCustomColors.backgroundGrey,
          appBar: AppBar(
            backgroundColor: AppCustomColors.backgroundGrey,
            title: Text('Editar presupuesto', style: boldTextStyle(color: AppCustomColors.primaryBlue)),
          ),
          body: Form(
            key: _formKey,
            child: FutureBuilder<List<Budget>>(
              future: ref.read(budgetRepositoryProvider).getByMonth(month),
              builder: (_, bs) {
                final budgets = bs.data ?? const <Budget>[];
                final amounts = {for (final b in budgets) b.categoryId: b.amount};

                _syncCtrls(
                  cats,
                  amounts,
                  budgetsReady: bs.connectionState == ConnectionState.done,
                );

                final usageList = usageAsync.maybeWhen(data: (l) => l, orElse: () => const []);
                final usageById = {for (final u in usageList) u.categoryId: u};

                final options = {
                  for (final n in _defaults) n.toLowerCase().replaceAll(' ', '_'): n,
                  for (final c in cats) c.id: c.name,
                };

                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                      child: Row(
                        children: [
                          AppButton(
                            elevation: 0,
                            color: AppCustomColors.primaryBlue,
                            shapeBorder: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            onTap: isClosed
                                ? null
                                : () => _openAddCategoryDialog(
                              options: options,
                              exclude: cats.map((e) => e.id).toSet(),
                              isClosed: isClosed,
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.add, color: Colors.white, size: 18),
                                const SizedBox(width: 8),
                                Text('Agregar categoría', style: boldTextStyle(color: Colors.white)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemCount: cats.length,
                          itemBuilder: (_, i) {
                            final c = cats[i];
                            final u = usageById[c.id];
                            final spent = u?.spent ?? 0.0;

                            final repoAmount  = amounts[c.id] ?? 0.0;
                            final ctrlText    = (_amountCtrls[c.id]?.text ?? '').replaceAll(',', '.');
                            final ctrlAmount  = double.tryParse(ctrlText);
                            final budget      = _hydrated.contains(c.id) ? (ctrlAmount ?? repoAmount) : repoAmount;

                            final percentRaw  = budget <= 0 ? (spent > 0 ? 1.0 : 0.0) : (spent / budget);
                            final percent     = percentRaw.isFinite ? percentRaw.clamp(0.0, 1.0) : 0.0;

                            final over = budget > 0 && spent > budget;
                            final near = !over && budget > 0 && (spent / budget) >= .8;

                            Color barColor() {
                              if (over) return AppCustomColors.errorRed;
                              if (near) return AppCustomColors.warningOrange;
                              return AppCustomColors.primaryBlue;
                            }

                            return Container(
                              // ...
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: TextField(
                                          controller: _nameCtrls[c.id],
                                          enabled: !isClosed,
                                          decoration: const InputDecoration(isDense: true, border: InputBorder.none),
                                          style: boldTextStyle(size: 18),
                                        ),
                                      ),
                                      if (over) _Chip(text: 'Límite excedido', color: AppCustomColors.errorRed)
                                      else if (near) _Chip(text: 'Cerca del límite', color: AppCustomColors.primaryBlue),
                                    ],
                                  ),
                                  const SizedBox(height: 2),
                                  Text('Presupuesto', style: secondaryTextStyle()),
                                  const SizedBox(height: 2),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: CustomTextFormField(
                                          controller: _amountCtrls[c.id]!,
                                          enabled: !isClosed,
                                          textAlign: TextAlign.left,
                                          prefixText: r'$ ',
                                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                          validator: (v) {
                                            final t = (v ?? '').replaceAll(',', '.').trim();
                                            final d = double.tryParse(t);
                                            if (d == null || d < 0) return 'Monto inválido';
                                            return null;
                                          },
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Text('Gastado: ${formatMXN(spent)}', style: secondaryTextStyle()),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: SizedBox(
                                      height: 14,
                                      child: Stack(
                                        children: [
                                          Container(color: const Color(0xFFEFF2F7)),
                                          FractionallySizedBox(
                                            alignment: Alignment.centerLeft,
                                            widthFactor: percent,
                                            child: Container(color: barColor()),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: Text('Disponible: ${formatMXN(budget - spent)}', style: secondaryTextStyle()),
                                  ),
                                ],
                              ),
                            );
                          }
                      ),
                    ),
                    SafeArea(
                      top: false,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                        child: AppButton(
                          width: double.infinity,
                          color: AppCustomColors.primaryBlue,
                          disabledColor: AppCustomColors.primaryBlue,
                          shapeBorder: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          onTap: (!_dirty || isClosed)
                              ? null
                              : () async {
                            final budgets = await ref.read(budgetRepositoryProvider).getByMonth(month);
                            final prev = {for (final b in budgets) b.categoryId: b.amount};
                            await _saveAll(cats: cats, prevAmounts: prev, isClosed: isClosed);
                            setState(() {
                              _hydrated.clear(); // volver a hidratar con repo fresco en el próximo build
                            });
                          },
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.save, color: Colors.white, size: 20),
                              const SizedBox(width: 8),
                              Text('Guardar cambios', style: boldTextStyle(color: Colors.white)),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        );
      },
    );
  }
}

class _Chip extends StatelessWidget {
  final String text;
  final Color color;
  const _Chip({required this.text, required this.color});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 10),
      decoration: BoxDecoration(
        color: color.withAlpha(40),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color, width: 1.1),
      ),
      child: Text(text, style: boldTextStyle(color: color, size: 12)),
    );
  }
}
