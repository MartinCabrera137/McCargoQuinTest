import 'package:cargoquintest/core/utils/colors.dart';
import 'package:flutter/material.dart';
import '../../../shared/widgets/Custom_text_fromfield.dart';
import 'package:nb_utils/nb_utils.dart';


class AddCategoryResult {
  final String id;
  final String name;
  final String amount;
  const AddCategoryResult({required this.id, required this.name, required this.amount});
}

class AddCategoryDialog extends StatefulWidget {
  const AddCategoryDialog({super.key, required this.options, required this.excludeIds});

  final Map<String, String> options; // id -> nombre
  final Set<String> excludeIds;

  @override
  State<AddCategoryDialog> createState() => _AddCategoryDialogState();
}

class _AddCategoryDialogState extends State<AddCategoryDialog> {
  final _formKey = GlobalKey<FormState>();
  String? _selectedId;
  final _nameCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();

  @override
  void dispose() {
    _nameCtrl.dispose();
    _amountCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final entries = widget.options.entries.where((e) => !widget.excludeIds.contains(e.key)).toList()
      ..sort((a, b) => a.value.toLowerCase().compareTo(b.value.toLowerCase()));

    return AlertDialog(
      surfaceTintColor: Colors.transparent,
      title: Text('Agregar categoría', style: boldTextStyle(size: 18), textAlign: TextAlign.center),
      icon: Icon(Icons.add, color: AppCustomColors.primaryBlue, size: 32),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.0)),

      content: Form(
        key: _formKey,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [

              DropdownButtonFormField<String>(
                isExpanded: true,
                style: primaryTextStyle(), // nb_utils
                decoration: _outlinedDecoration(
                  context,
                  label: 'Selecciona de la lista',
                  prefixIcon: Icons.list,
                ),
                icon: Icon(
                  Icons.expand_more,
                  color: AppCustomColors.primaryBlue
                ),
                borderRadius: BorderRadius.circular(16),
                dropdownColor: Theme.of(context).colorScheme.surface,
                menuMaxHeight: 320,
                items: [
                  ...entries.map((e) => DropdownMenuItem(
                    value: e.key,
                    child: Text(e.value, style: primaryTextStyle()),
                  )),
                  DropdownMenuItem(
                    value: 'other',
                    child: Text('Otra categoría', style: primaryTextStyle(weight: FontWeight.w600)),
                  ),
                ],
                value: _selectedId,
                onChanged: (v) {
                  setState(() {
                    _selectedId = v;
                    if (v != 'other') _nameCtrl.clear();
                  });
                },
                validator: (v) => v == null ? 'Elige una opción' : null,
              ),


              if (_selectedId == 'other') ...[
                const SizedBox(height: 8),
                CustomTextFormField(
                  controller: _nameCtrl,
                  hintText: 'Nombre de la categoría',
                  validator: (v) {
                    if (_selectedId == 'other' && (v == null || v.trim().isEmpty)) {
                      return 'Escribe un nombre';
                    }
                    return null;
                  },
                ),
              ],
              const SizedBox(height: 8),
              CustomTextFormField(
                controller: _amountCtrl,
                textAlign: TextAlign.right,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                prefixIcon: Icon(Icons.attach_money, color: AppCustomColors.primaryBlue),
                labelText: 'Presupuesto (MXN)',
                validator: (v) {
                  final t = (v ?? '').replaceAll(',', '.').trim();
                  final d = double.tryParse(t);
                  if (d == null || d < 0) return 'Ingresa un monto valido';
                  return null;
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text('Cancelar', style: secondaryTextStyle(color: Colors.black),)),
        AppButton(
          color: AppCustomColors.primaryBlue,
          shapeBorder: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          text: 'Agregar',
          textColor: Colors.white,
          textStyle: primaryTextStyle(color: Colors.white),
          onTap: () {
            if (!_formKey.currentState!.validate()) return;
            final amount = _amountCtrl.text.replaceAll(',', '.').trim();
            if (_selectedId == 'other') {
              final name = _nameCtrl.text.trim();
              final slug = name.toLowerCase().replaceAll(RegExp(r'\s+'), '_');
              final id = '${slug}_${DateTime.now().millisecondsSinceEpoch}';
              Navigator.pop(context, AddCategoryResult(id: id, name: name, amount: amount));
            } else {
              final id = _selectedId!;
              final name = widget.options[id]!;
              Navigator.pop(context, AddCategoryResult(id: id, name: name, amount: amount));
            }
          },
        ),
      ],
    );
  }

  InputDecoration _outlinedDecoration(BuildContext context, {
    required String label,
    IconData? prefixIcon,
    bool highlighted = false,
  }) {
    final cs = Theme.of(context).colorScheme;
    final borderRadius = BorderRadius.circular(12);
    final baseColor = highlighted ? AppCustomColors.primaryBlue : cs.outlineVariant;
    return InputDecoration(
      labelText: label,
      isDense: true,
      prefixIcon: prefixIcon != null
          ? Icon(prefixIcon, color: AppCustomColors.primaryBlue)
          : null,
      enabledBorder: OutlineInputBorder(
        borderRadius: borderRadius,
        borderSide: BorderSide(color: baseColor, width: 1.4),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: borderRadius,
        borderSide: BorderSide(color: AppCustomColors.primaryBlue, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: borderRadius,
        borderSide: BorderSide(color: AppCustomColors.errorRed, width: 1.4),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: borderRadius,
        borderSide: BorderSide(color: AppCustomColors.errorRed, width: 2),
      ),
    );
  }

}
