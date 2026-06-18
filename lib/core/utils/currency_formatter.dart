import 'package:intl/intl.dart';

String formatCurrency(num value) {
  return NumberFormat.currency(locale: 'en_IN', symbol: '₹').format(value);
}
