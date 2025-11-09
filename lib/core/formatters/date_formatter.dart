import 'package:cargoquintest/core/formatters/capitalize.dart';
import 'package:intl/intl.dart';

String formatMonthYear(DateTime d) {
  // convertir a texto la fechas
  return capitalize(DateFormat("MMMM yyyy", "es_MX").format(d));
}
