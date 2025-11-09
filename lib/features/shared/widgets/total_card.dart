import 'package:flutter/material.dart';

class TotalCard extends StatelessWidget {
  final String title;
  final String amountText;
  const TotalCard({super.key, required this.title, required this.amountText});

  @override
  Widget build(BuildContext context) {
    final titleColor = const Color(0xFF0D2A8A); // azul oscuro
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [BoxShadow(blurRadius: 12, color: Color(0x11000000), offset: Offset(0, 6))],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(color: titleColor, fontSize: 22, fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          Text(
            amountText,
            style: const TextStyle(fontSize: 36, fontWeight: FontWeight.w800, letterSpacing: -0.5),
          ),
        ],
      ),
    );
  }
}
