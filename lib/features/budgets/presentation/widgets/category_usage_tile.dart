import 'package:cargoquintest/core/utils/colors.dart';
import 'package:flutter/material.dart';
import 'package:nb_utils/nb_utils.dart';
import '../../../../core/formatters/currency_formatter.dart';
import '../../controllers/category_usage_provider.dart';

class CategoryUsageTile extends StatelessWidget {
  final CategoryUsage usage;
  const CategoryUsageTile({super.key, required this.usage});

  Color _barColor() {
    if (usage.overLimit) return AppCustomColors.errorRed;
    if (usage.nearLimit) return AppCustomColors.warningOrange;
    return AppCustomColors.primaryBlue;
  }

  @override
  Widget build(BuildContext context) {
    final p = usage.budget <= 0 ? (usage.spent > 0 ? 1000.0 : 0.0) : (usage.spent / usage.budget) * 100.0;
    final showNear = p >= 80 && p <= 100;
    final showOver = p > 100;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [BoxShadow(blurRadius: 10, color: Color(0x14000000), offset: Offset(0, 4))],
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(usage.categoryName, style: boldTextStyle(size: 18))),
              if (showOver)
                _PulsingChip(text: 'Límite excedido', color: AppCustomColors.errorRed, maxScale: 1.14)
              else if (showNear)
                _PulsingChip(text: 'Cerca del límite', color: AppCustomColors.primaryBlue, maxScale: 1.08),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Presupuesto', style: primaryTextStyle()),
              Text(formatMXN(usage.budget), style: primaryTextStyle(size: 24, letterSpacing: 2.5)),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Gastado: ${formatMXN(usage.spent)}', style: secondaryTextStyle()),
            ],
          ),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              height: 16,
              child: Stack(
                children: [
                  Container(color: const Color(0xFFEFF2F7)),
                  FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: usage.percent.clamp(0.0, 1.0),
                    child: Container(color: _barColor()),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 4),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              'Disponible: ${formatMXN((usage.budget - usage.spent))}',
              style: secondaryTextStyle(),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}

class _PulsingChip extends StatefulWidget {
  final String text;
  final Color color;
  final double maxScale;
  const _PulsingChip({required this.text, required this.color, required this.maxScale});

  @override
  State<_PulsingChip> createState() => _PulsingChipState();
}

class _PulsingChipState extends State<_PulsingChip> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 800))..repeat(reverse: true);
  @override
  void dispose() { _c.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: Tween(begin: 1.0, end: widget.maxScale).animate(CurvedAnimation(parent: _c, curve: Curves.easeInOut)),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 10),
        decoration: BoxDecoration(
          color: widget.color.withAlpha(64),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: widget.color, width: 1.2),
        ),
        child: Text(widget.text, style: boldTextStyle(color: widget.color, size: 12)),
      ),
    );
  }
}
