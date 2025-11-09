import 'package:cargoquintest/core/utils/colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

const Color _kFocusColor = AppCustomColors.primaryBlue;
const Color _kUnfocusedColor = AppCustomColors.mediumGrey;
const double _kBorderRadius = 16;
const double _kBorderThickness = 2;

class CustomTextFormField extends StatelessWidget {
  final TextEditingController? controller;
  final String? labelText;
  final String? hintText;
  final String? prefixText;
  final Icon? prefixIcon;
  final bool enabled;
  final bool readOnly;
  final TextInputType? keyboardType;
  final FormFieldValidator<String>? validator;
  final ValueChanged<String>? onChanged;
  final int? maxLength;
  final TextAlign textAlign;
  final List<TextInputFormatter>? inputFormatters;

  const CustomTextFormField({
    super.key,
    this.controller,
    this.labelText,
    this.hintText,
    this.prefixText,
    this.prefixIcon,
    this.enabled = true,
    this.readOnly = false,
    this.keyboardType,
    this.validator,
    this.onChanged,
    this.maxLength,
    this.textAlign = TextAlign.start,
    this.inputFormatters,
  });

  // Método auxi
  InputBorder _getBorderStyle({
    required Color color,
    required double thickness,
  }) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(_kBorderRadius),
      borderSide: BorderSide(
        color: color,
        width: thickness,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      // Propiedades para el TextFormField base
      controller: controller,
      enabled: enabled,
      readOnly: readOnly,
      keyboardType: keyboardType,
      validator: validator,
      onChanged: onChanged,
      maxLength: maxLength,
      textAlign: textAlign,
      inputFormatters: inputFormatters,

      // estilo
      decoration: InputDecoration(
        fillColor: Colors.red,
        // Propiedades de texto y contenido
        labelText: labelText,
        hintText: hintText,
        prefixText: prefixText,
        prefixIcon: prefixIcon,
        counterText: maxLength != null ? "" : null,


        // Borde cuando el campo está enfocado (contorno azul)
        focusedBorder: _getBorderStyle(
          color: _kFocusColor,
          thickness: _kBorderThickness,
        ),

        // Borde cuando el campo no está enfocado
        enabledBorder: _getBorderStyle(
          color: _kUnfocusedColor.withOpacity(0.5),
          thickness: 2.0,
        ),

        // Borde cuando el campo tiene un error
        errorBorder: _getBorderStyle(
          color: Theme.of(context).colorScheme.error,
          thickness: _kBorderThickness,
        ),

        // Borde cuando el campo está enfocado y tiene un error
        focusedErrorBorder: _getBorderStyle(
          color: Theme.of(context).colorScheme.error,
          thickness: _kBorderThickness + 0.5,
        ),

        // Relleno interior para dar espacio al texto
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }
}