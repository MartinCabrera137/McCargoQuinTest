import 'package:cargoquintest/features/shared/widgets/Custom_text_fromfield.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:uuid/uuid.dart';
import '../../../../app/providers.dart';
import '../../../../core/utils/colors.dart';
import '../../../../core/utils/date_utils.dart';
import '../../../../domain/entities/tx.dart';
import '../../../../domain/entities/category.dart';
import '../../../budgets/controllers/budget_check_provider.dart';
import '../../../budgets/controllers/category_usage_provider.dart';
import '../../../dashboard/controllers/month_txs_provider.dart';
import '../../../dashboard/controllers/totals_provider.dart';
import '../../../shared/widgets/drop_list_decorator.dart';

class AddTxSheet extends StatefulWidget {
  final bool isExpenseDefault;

  const AddTxSheet({super.key, this.isExpenseDefault = true});

  @override
  State<AddTxSheet> createState() => _AddTxSheetState();
}

class _AddTxSheetState extends State<AddTxSheet> {
  final _formKey = GlobalKey<FormState>();
  final _conceptCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();
  late TxType _type;
  late DateTime _date;
  String? _categoryId;

  @override
  void initState() {
    super.initState();
    _type = widget.isExpenseDefault ? TxType.expense : TxType.income;
    _date = DateTime.now();
  }

  @override
  void dispose() {
    _conceptCtrl.dispose();
    _amountCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, ref, _) {
        final month = ref.watch(currentMonthProvider);
        final s = monthStart(month);
        final e = monthEnd(month);
        if (_date.year != month.year || _date.month != month.month) {
          _date = s;
        } else {
          _date = clampToMonth(month, _date);
        }
        // si no se setea respaldo aqui
        _date = clampToMonth(month, _date);

        final List<Category> categories = ref.watch(categoriesProvider);
        return Padding(
          padding: EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 16 + MediaQuery.of(context).viewInsets.bottom),
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    height: 4,
                    width: 40,
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(color: Colors.black12, borderRadius: BorderRadius.circular(2)),
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: SegmentedButton<TxType>(
                          style: ButtonStyle(
                            shape: WidgetStatePropertyAll(RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                            side: WidgetStateProperty.resolveWith<BorderSide>((states) {
                              final cs = Theme.of(context).colorScheme;
                              final focusedOrSelected = states.contains(WidgetState.selected) || states.contains(WidgetState.focused);
                              return BorderSide(color: focusedOrSelected ? AppCustomColors.primaryBlue : cs.outlineVariant, width: focusedOrSelected ? 2 : 1.4);
                            }),
                            backgroundColor: WidgetStateProperty.resolveWith<Color?>((states) {
                              final cs = Theme.of(context).colorScheme;
                              return states.contains(WidgetState.selected) ? AppCustomColors.primaryBlue.withAlpha(32) : cs.surface;
                            }),
                            foregroundColor: WidgetStateProperty.resolveWith<Color?>((states) {
                              final cs = Theme.of(context).colorScheme;
                              return states.contains(WidgetState.selected) ? AppCustomColors.primaryBlue : cs.onSurfaceVariant;
                            }),
                            padding: const WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: 12, vertical: 10)),
                            visualDensity: VisualDensity.compact,
                          ),
                          segments: [
                            ButtonSegment(
                              value: TxType.expense,
                              icon: Icon(Icons.remove_circle, color: AppCustomColors.primaryBlue),
                              label: Text('Gasto', style: primaryTextStyle()),
                            ),
                            ButtonSegment(
                              value: TxType.income,
                              icon: Icon(Icons.add, color: AppCustomColors.primaryBlue),
                              label: Text('Ingreso', style: primaryTextStyle()),
                            ),
                          ],
                          selected: {_type},
                          onSelectionChanged: (s) => setState(() => _type = s.first),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  //solo pedir la categoria en los gastos
                  if (_type == TxType.expense)
                    DropdownButtonFormField<String>(
                      initialValue: _categoryId,
                      //
                      decoration: dropListDecorator(context, label: 'Categoria', prefixIcon: Icons.list),
                      icon: Icon(Icons.expand_more, color: AppCustomColors.primaryBlue),
                      borderRadius: BorderRadius.circular(16),
                      dropdownColor: Theme.of(context).colorScheme.surface,
                      items: categories.map((c) => DropdownMenuItem(value: c.id, child: Text(c.name))).toList(),
                      onChanged: (v) => setState(() => _categoryId = v),
                      validator: (v) => _type == TxType.expense && v == null ? 'Elige una categoría' : null,
                    ),

                  const SizedBox(height: 12),
                  CustomTextFormField(
                    controller: _conceptCtrl,
                    hintText: 'Concepto (1–24)',
                    maxLength: 24,
                    validator: (v) {
                      final t = v?.trim() ?? '';
                      if (t.isEmpty) return 'Requerido';
                      if (t.length > 24) return 'Máximo 24 caracteres';
                      return null;
                    },
                  ),
                  const SizedBox(height: 8),
                  CustomTextFormField(
                    controller: _amountCtrl,
                    hintText: 'Monto (MXN)',
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    validator: (v) {
                      final t = v?.replaceAll(',', '.').trim() ?? '';
                      final d = double.tryParse(t);
                      if (d == null || d <= 0) return 'Monto inválido';
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),

                  Row(
                    children: [
                      Expanded(child: Text('Fecha del Movimiento: ${_date.toLocal().toString().split(' ').first}', style: primaryTextStyle())),
                      AppButton(
                        color: AppCustomColors.primaryBlueWithAlpha,
                        shapeBorder: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        onTap: () async {
                          final picked = await showDatePicker(context: context, initialDate: _date, firstDate: s, lastDate: e);
                          if (picked != null) setState(() => _date = picked);
                        },
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.today, color: Colors.white, size: 20),
                            const SizedBox(width: 8),
                            Text('Cambiar fecha', style: boldTextStyle(color: Colors.white)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  AppButton(
                    color: AppCustomColors.primaryBlue,
                    shapeBorder: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    onTap: () async {
                      if (!_formKey.currentState!.validate()) return;
                      _date = clampToMonth(month, _date);

                      if (_type == TxType.expense) {
                        final needBudgets = await ref.refresh(shouldAskBudgetsProvider.future);
                        if (needBudgets) {
                          if (!mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Define primero el presupuesto de este mes.')));
                          return;
                        }
                      }

                      final id = const Uuid().v4();
                      final amt = double.parse(_amountCtrl.text.replaceAll(',', '.')).toStringAsFixed(2);

                      final tx = Tx(
                        id: id,
                        date: _date,
                        type: _type,
                        categoryId: _type == TxType.expense ? _categoryId! : null,
                        // nulo si es ingreso
                        concept: _conceptCtrl.text.trim(),
                        amount: double.parse(amt),
                      );

                      final repo = ref.read(txRepositoryProvider);
                      await repo.add(tx);

                      // refrescar por si hay pendiens
                      ref.invalidate(totalsProvider);
                      ref.invalidate(categoryUsageProvider);
                      //guardar al cerar mes
                      ref.invalidate(monthTxsProvider);

                      if (!mounted) return;
                      Navigator.of(context).pop(true);
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${_type == TxType.expense ? 'Gasto' : 'Ingreso'} agregado')));
                    },
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.save, color: Colors.white, size: 20),
                        const SizedBox(width: 8),
                        Text(_type == TxType.expense ? 'Registrar Gasto' : 'Registrar Ingreso', style: boldTextStyle(color: Colors.white)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
