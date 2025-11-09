import 'package:flutter/material.dart';
import 'package:nb_utils/nb_utils.dart';
import '../../../shared/widgets/Custom_text_fromfield.dart';
import 'package:cargoquintest/core/utils/colors.dart';

class Picked {
  final String id;
  final String name;
  final TextEditingController amount;
  Picked(this.id, this.name, String initial)
      : amount = TextEditingController(text: initial);
}
class PickedTile extends StatelessWidget {
  const PickedTile({super.key,
    required this.item,
    required this.isClosed,
    this.onRemove,
  });

  final Picked item;
  final bool isClosed;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    return Card(
      surfaceTintColor: Colors.white,
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: EdgeInsets.all(0),
      child: Padding(
        padding: EdgeInsetsGeometry.symmetric(vertical: 8, horizontal: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(tooltip: 'Quitar', onPressed: onRemove, icon: const Icon(Icons.delete, color:  AppCustomColors.errorRed,)),
            Expanded(child: Text(item.name, style: primaryTextStyle())),
            SizedBox(
              width: 128,
              child: CustomTextFormField(
                controller: item.amount,
                enabled: !isClosed,
                textAlign: TextAlign.right,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                prefixIcon: Icon(Icons.attach_money, color: AppCustomColors.primaryBlue),
                validator: (v) {
                  final t = (v ?? '').replaceAll(',', '.').trim();
                  final d = double.tryParse(t);
                  if (d == null || d < 0) return 'Ingresa un monto valido';
                  return null;
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}