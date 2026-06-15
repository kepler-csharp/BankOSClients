import 'package:intl/intl.dart';

/// Utilidades de formato para moneda y fechas.
class Formatters {
  Formatters._();

  static String money(double amount, String currency) {
    final symbol = switch (currency.toUpperCase()) {
      'USD' => '\$',
      'EUR' => '€',
      'GBP' => '£',
      'COP' => '\$',
      _ => '',
    };
    final f = NumberFormat.currency(
      locale: 'es_CO',
      symbol: symbol,
      decimalDigits: currency.toUpperCase() == 'COP' ? 0 : 2,
    );
    return '${f.format(amount)} ${currency.toUpperCase()}';
  }

  static String date(DateTime? d) {
    if (d == null) return '';
    return DateFormat('dd/MM/yyyy HH:mm').format(d.toLocal());
  }

  static String shortDate(DateTime? d) {
    if (d == null) return '';
    return DateFormat('dd MMM, HH:mm', 'es').format(d.toLocal());
  }

  static String mmss(int totalSeconds) {
    final m = (totalSeconds ~/ 60).toString().padLeft(2, '0');
    final s = (totalSeconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }
}
