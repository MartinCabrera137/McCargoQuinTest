// lib/features/transactions/presentation/widgets/transactions_usage_tile.dart
import 'package:flutter/material.dart';
import 'package:nb_utils/nb_utils.dart';
import '../../../../core/formatters/currency_formatter.dart';
import '../../../../core/utils/colors.dart';
import '../../../../domain/entities/tx.dart';

class TransactionTile extends StatelessWidget {
  final Tx tx;
  final String? categoryName;
  final VoidCallback? onDelete;
  final VoidCallback? onTap;

  const TransactionTile({
    super.key,
    required this.tx,
    this.categoryName,
    this.onDelete,
    this.onTap,
  });

  String _short(DateTime d) {
    const m = ['ENE','FEB','MAR','ABR','MAY','JUN','JUL','AGO','SEP','OCT','NOV','DIC'];
    return '${d.day.toString().padLeft(2, '0')} ${m[d.month - 1]}';
  }

  @override
  Widget build(BuildContext context) {
    final isIncome = tx.type == TxType.income;

    final sign        = isIncome ? '+' : '-';
    final amountText  = '$sign${formatMXN(tx.amount)}';
    final amountColor = isIncome ? AppCustomColors.successGreen : AppCustomColors.errorRed;

    final iconBg    = isIncome ? AppCustomColors.successGreen.withAlpha(32)
        : AppCustomColors.errorRed.withAlpha(32);
    final iconColor = isIncome ? AppCustomColors.successGreen : AppCustomColors.errorRed;
    final icon      = isIncome ? Icons.south_west : Icons.north_east;

    final cs = Theme.of(context).colorScheme;

    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: cs.outlineVariant.withAlpha(64))),
        ),
        child: Row(
          children: [
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle),
              child: Icon(icon, color: iconColor, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(tx.concept, style: boldTextStyle()),
                  const SizedBox(height: 2),
                  Text(isIncome ? 'Ingreso' : (categoryName ?? 'Gasto'), style: secondaryTextStyle()),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(amountText, style: boldTextStyle(color: amountColor)),
                const SizedBox(height: 2),
                Text(_short(tx.date), style: secondaryTextStyle()),
              ],
            ),
            const SizedBox(width: 8),
            if (onDelete != null)
              IconButton(icon: const Icon(Icons.delete_outline), onPressed: onDelete),
          ],
        ),
      ),
    );
  }
}
