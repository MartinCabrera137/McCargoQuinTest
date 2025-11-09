import 'package:cargoquintest/core/utils/colors.dart';
import 'package:flutter/material.dart';
import 'package:nb_utils/nb_utils.dart';

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
          Text(title, style: boldTextStyle(color: AppCustomColors.primaryBlue, size: 24)),
          Text(
            amountText,
            style: primaryTextStyle(size: 36, letterSpacing: -0.5),
          ),

        ],
      ),
    );
  }
}
