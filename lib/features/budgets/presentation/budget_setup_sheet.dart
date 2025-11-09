import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/providers.dart';
import '../../../core/formatters/date_formatter.dart';
import '../../../domain/entities/budget.dart';
import '../../../domain/entities/category.dart';
import '../../dashboard/controllers/totals_provider.dart';
import '../controllers/budget_check_provider.dart';
import '../controllers/category_usage_provider.dart';

const _presets = <String>[
  'Vivienda', 'Alimentos', 'Transporte', 'Salud', 'Educación',
  'Entretenimiento', 'Ahorro', 'Otros',
];

class BudgetSetupSheet extends ConsumerStatefulWidget {
  const BudgetSetupSheet({super.key});
  @override
  ConsumerState<BudgetSetupSheet> createState() => _BudgetSetupSheetState();
}

class _BudgetSetupSheetState extends ConsumerState<BudgetSetupSheet> {
  final _formKey = GlobalKey<FormState>();
  // categoríaId con nombre/monto/seleccionada
  final Map<String, TextEditingController> _amountCtrls = {};
  final Map<String, String> _names = {};
  final Map<String, bool> _selected = {};

  @override
  void initState() {
    super.initState();
    // precargar controles con presets (no seleccionados)
    for (final name in _presets) {
      final id = name.toLowerCase().replaceAll(' ', '_');
      _amountCtrls[id] = TextEditingController(text: '');
      _names[id] = name;
      _selected[id] = false;
    }
  }

  @override
  void dispose() {
    for (final c in _amountCtrls.values) { c.dispose(); }
    super.dispose();
  }

  Future<void> _addCustomCategory() async {
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
      final n = nameCtrl.text.trim();
      final a = amountCtrl.text.replaceAll(',', '.').trim();
      if (n.isEmpty) return;
      final id = DateTime.now().millisecondsSinceEpoch.toString();
      setState(() {
        _names[id] = n;
        _amountCtrls[id] = TextEditingController(text: a);
        _selected[id] = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final month = ref.watch(currentMonthProvider);
    final monthFormat = formatMonthYear(month);
    // por si el usuario vuelve a abrir las categ
    final catsExisting = ref.watch(categoriesProvider);
    final monthRepo = ref.read(monthRepositoryProvider);

    return FutureBuilder<bool>(
      future: monthRepo.isClosed(month.year, month.month),
      builder: (_, snap) {
        final isClosed = snap.data == true;
        return Padding(
          padding: EdgeInsets.only(
            left: 16, right: 16, top: 12,
            bottom: 16 + MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(height: 4, width: 40, margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(color: Colors.black26, borderRadius: BorderRadius.circular(2))),
                  Text(
                    isClosed ? 'Mes cerrado (solo lectura)' : 'Define el presupuesto para el mes de $monthFormat',
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 12),

                  // Si ya existen categorías en este mes las muestro para seleccion rapida
                  if (catsExisting.isNotEmpty) ...[
                    ...catsExisting.map((c) {
                      final id = c.id;
                      _names.putIfAbsent(id, () => c.name);
                      _amountCtrls.putIfAbsent(id, () => TextEditingController(text: ''));
                      _selected[id] = true; // si ya se seleccionaron
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Row(
                          children: [
                            Expanded(child: Text(c.name, style: const TextStyle(fontWeight: FontWeight.w600))),
                            SizedBox(
                              width: 140,
                              child: TextFormField(
                                controller: _amountCtrls[id],
                                enabled: !isClosed,
                                textAlign: TextAlign.right,
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                decoration: const InputDecoration(prefixText: r'$ '),
                                validator: (v) {
                                  final t = (v ?? '').replaceAll(',', '.').trim();
                                  final d = double.tryParse(t);
                                  if (d == null || d < 0) return 'Monto inválido';
                                  return null;
                                },
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                    const Divider(height: 24),
                  ],

                  // Presets que falten
                  ..._names.entries.map((e) {
                    final id = e.key;
                    final name = e.value;
                    final notExisting = catsExisting.indexWhere((c) => c.id == id) == -1 &&
                        !catsExisting.any((c) => c.name.toLowerCase() == name.toLowerCase());
                    if (!notExisting) return const SizedBox.shrink();
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          Checkbox(
                            value: _selected[id] ?? false,
                            onChanged: isClosed ? null : (v) => setState(() => _selected[id] = v ?? false),
                          ),
                          Expanded(child: Text(name)),
                          SizedBox(
                            width: 140,
                            child: TextFormField(
                              controller: _amountCtrls[id],
                              enabled: !isClosed && (_selected[id] ?? false),
                              textAlign: TextAlign.right,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              decoration: const InputDecoration(prefixText: r'$ '),
                              validator: (v) {
                                if (!(_selected[id] ?? false)) return null;
                                final t = (v ?? '').replaceAll(',', '.').trim();
                                final d = double.tryParse(t);
                                if (d == null || d < 0) return 'Monto inválido';
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),

                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      onPressed: isClosed ? null : _addCustomCategory,
                      icon: const Icon(Icons.add),
                      label: const Text('Otra categoría'),
                    ),
                  ),

                  const SizedBox(height: 4),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      icon: const Icon(Icons.save),
                      label: Text(isClosed ? 'Cerrar' : 'Guardar presupuestos'),
                      onPressed: isClosed ? () => Navigator.pop(context, false) : () async {
                        if (!_formKey.currentState!.validate()) return;

                        // Construye categorías elegidas + montos
                        final repoCat = ref.read(monthCategoryRepositoryProvider);
                        final repoBud = ref.read(budgetRepositoryProvider);

                        final toSave = <Category>[];
                        final budgets = <Budget>[];

                        // existentes (si estaban en el mes)
                        for (final c in catsExisting) {
                          final raw = (_amountCtrls[c.id]?.text ?? '').replaceAll(',', '.').trim();
                          final amt = double.tryParse(raw) ?? 0;
                          toSave.add(c);
                          budgets.add(Budget(categoryId: c.id, year: month.year, month: month.month,
                              amount: double.parse(amt.toStringAsFixed(2))));
                        }

                        // presets + otras elegidas
                        for (final id in _names.keys) {
                          if (_selected[id] != true) continue;
                          final name = _names[id]!;
                          final raw = (_amountCtrls[id]?.text ?? '').replaceAll(',', '.').trim();
                          final amt = double.tryParse(raw) ?? 0;
                          // si ya existe por nombre en el mes, sáltarllo
                          if (catsExisting.any((c) => c.name.toLowerCase() == name.toLowerCase())) continue;

                          final cat = Category(id,name);
                          toSave.add(cat);
                          budgets.add(Budget(categoryId: cat.id, year: month.year, month: month.month,
                              amount: double.parse(amt.toStringAsFixed(2))));
                        }

                        // persistir
                        repoCat.upsertMany(month, toSave);
                        for (final b in budgets) { await repoBud.upsert(b); }

                        // invalidar cálculos
                        ref.invalidate(categoriesProvider);
                        ref.invalidate(shouldAskBudgetsProvider);
                        ref.invalidate(categoryUsageProvider);
                        ref.invalidate(totalsProvider);


                        if (!mounted) return;
                        Navigator.of(context).pop(true);
                      },
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
