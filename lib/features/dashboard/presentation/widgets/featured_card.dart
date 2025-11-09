import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nb_utils/nb_utils.dart';

import '../../../../core/utils/colors.dart';

class FeatureCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final List<Color> colors; //1 pra claro 2 para oscura
  final bool filled;

  const FeatureCard({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.colors = const [],
    this.filled = true,
  });

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width * 0.78;

    final bg = filled
        ? null
        : Colors.white;

    final grad = filled
        ? LinearGradient(colors: colors.isNotEmpty
        ? colors
        : [const Color(0xFF87A6FF), AppCustomColors.primaryBlue])
        : null;

    return SizedBox(
      width: w,
      child: Material(
        color: Colors.transparent,
        child: Ink(
          decoration: BoxDecoration(
            color: bg,
            gradient: grad,
            borderRadius: BorderRadius.circular(24),
            boxShadow: const [BoxShadow(color: Color(0x1A000000), blurRadius: 12, offset: Offset(0, 6))],
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(24),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 56, height: 56,
                    decoration: BoxDecoration(
                      color: filled ? Colors.white.withOpacity(.2) : const Color(0xFFF0F2F7),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, size: 28, color: filled ? Colors.white : AppCustomColors.primaryBlue),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: boldTextStyle(color: filled ? Colors.white : AppCustomColors.primaryBlue, size: 18)),
                        const SizedBox(height: 6),
                        Text(
                          subtitle,
                          overflow: TextOverflow.ellipsis,
                          style: primaryTextStyle(
                            color: filled ? Colors.white.withOpacity(.95) : const Color(0xFF4B5563),
                          ),
                          maxLines: 2,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(Icons.more_horiz, color: filled ? Colors.white : AppCustomColors.primaryBlue.withAlpha(128)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
