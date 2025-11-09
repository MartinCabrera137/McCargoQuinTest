import 'package:intl/intl.dart';

final _mxn = NumberFormat.currency(locale: 'es_MX', symbol: r'$');
String formatMXN(double v) => _mxn.format(v);
