import 'package:intl/intl.dart';

/// Formato de moneda estilo recibo guatemalteco: "Q 3,686.14"
/// (coma para miles, punto para decimales), y fechas en español.
class AppFormatters {
  AppFormatters._();

  static final NumberFormat _currency = NumberFormat.currency(
    locale: 'en_US',
    symbol: 'Q ',
    decimalDigits: 2,
  );

  static final DateFormat _date = DateFormat('d MMM yyyy', 'es');
  static final DateFormat _shortDate = DateFormat('d MMM', 'es');

  static String currency(double value) => _currency.format(value);

  static String date(DateTime value) => _date.format(value);

  static String shortDate(DateTime value) => _shortDate.format(value);
}
