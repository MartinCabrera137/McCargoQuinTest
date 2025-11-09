import 'package:flutter/material.dart';
import '../../../../core/formatters/currency_formatter.dart';
import '../../controllers/category_usage_provider.dart';

class CategoryUsageTile extends StatelessWidget {
  final CategoryUsage usage;
  const CategoryUsageTile({super.key, required this.usage});

  Color _barColor() {
    if (usage.overLimit) return const Color(0xFFE74C3C); // rojo
    if (usage.nearLimit) return const Color(0xFFF39C12); // narajan
    return const Color(0xFF2ECC71); // verde
  }

  @override
  Widget build(BuildContext context) {
    final titleColor = const Color(0xFF0D2A8A);

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
          // categoria y chip de excesp
          Row(
            children: [
              Expanded(
                child: Text(
                  usage.categoryName,
                  style: TextStyle(
                    color: titleColor,
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
              ),
              if (usage.overLimit)
                const _Chip(text: 'Excedido')
              else if (usage.nearLimit)
                const _Chip(text: 'Cerca del límite'),
            ],
          ),
          const SizedBox(height: 6),

          // Presupuesto y gasto
          Row(
            children: [
              Expanded(
                child: Text(
                  'Presupuesto: ${formatMXN(usage.budget)}',
                  style: const TextStyle(fontSize: 13, color: Colors.black54),
                ),
              ),
              Text(
                'Gastado: ${formatMXN(usage.spent)}',
                style: const TextStyle(fontSize: 13, color: Colors.black54),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // porcentaje
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text('${(usage.budget == 0 && usage.spent == 0) ? 0 : (usage.spent / (usage.budget == 0 ? usage.spent == 0 ? 1 : usage.spent : usage.budget) * 100).clamp(0, 100).toStringAsFixed(0)}%',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
              ),
            ],
          ),

          // Barra de progreso
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              height: 12,
              child: Stack(
                children: [
                  Container(color: const Color(0xFFECEFF3)),
                  FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: usage.percent,
                    child: Container(color: _barColor()),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String text;
  const _Chip({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFEDE7F6),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF5E35B1)),
      ),
    );
  }
}
