import 'package:flutter/material.dart';
import '../../../core/utils/colors.dart';

InputDecoration dropListDecorator(BuildContext context, {
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