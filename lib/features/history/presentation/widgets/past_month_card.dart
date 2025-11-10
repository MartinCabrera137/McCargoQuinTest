import 'package:flutter/material.dart';
import 'package:nb_utils/nb_utils.dart';
import '../../../../core/formatters/capitalize.dart';
import '../../../../core/utils/colors.dart';
import '../../../../core/formatters/currency_formatter.dart';
import '../../../../domain/entities/month_snapshot.dart';
import 'package:intl/intl.dart';

class PastMonthCard extends StatelessWidget {
  final MonthSnapshot snap;
  final VoidCallback? onTap;

  const PastMonthCard({
    super.key,
    required this.snap,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final income = snap.totalIncome;
    final expense = snap.totalExpense;
    final saving = income - expense;

    final savingColor = saving >= 0
        ? AppCustomColors.successGreen
        : AppCustomColors.errorRed;

    // Ratio de gasto vs ingreso para la barrita
    final spendRatio = income <= 0 ? 0.0 : (expense / income).clamp(0.0, 1.0);

    final label = DateFormat('MMMM yyyy', 'es_MX').format(DateTime(snap.year, snap.month));


    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // primer row
            Row(
              children: [
                Container(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3F5F8),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    capitalize(label),
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      letterSpacing: .2,
                    ),
                  ),
                ),
                const Spacer(),
                Icon(
                  saving >= 0 ? Icons.trending_up : Icons.trending_down,
                  size: 18,
                  color: savingColor,
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Stats en cuadritos
            Row(
              children: [
                _Stat(
                  label: 'Ingreso',
                  value: formatMXN(income),
                  icon: Icons.south_west,
                ),
                const SizedBox(width: 12),
                _Stat(
                  label: 'Gasto',
                  value: formatMXN(expense),
                  icon: Icons.north_east,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _Stat(
                    label: 'Ahorro',
                    value: formatMXN(saving),
                    icon: Icons.savings_outlined,
                    valueColor: savingColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Progreso de consumo (gasto vs ingreso)
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: spendRatio,
                minHeight: 10,
                backgroundColor: const Color(0xFFE9EDF2),
                valueColor: AlwaysStoppedAnimation<Color>(
                  saving >= 0
                      ? AppCustomColors.primaryBlue
                      : AppCustomColors.errorRed,
                ),
              ),
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Consumo del ingreso',
                  style: TextStyle(
                    fontSize: 12,
                    color: Color(0xFF6B7280),
                  ),
                ),
                Text(
                  '${(spendRatio * 100).toStringAsFixed(0)}%',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF6B7280),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color? valueColor;

  const _Stat({
    required this.label,
    required this.value,
    required this.icon,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFFF9FAFB),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: Column(
          children: [
            Icon(icon, size: 18, color: const Color(0xFF6B7280)),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 11,
                            color: Color(0xFF6B7280),
                          )),
                      const SizedBox(height: 2),
                      Text(
                        value,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: valueColor ?? const Color(0xFF111827),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
