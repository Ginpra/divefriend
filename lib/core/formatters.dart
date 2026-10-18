import 'package:divefriend/core/currencies.dart';

/// Format angka gaya Indonesia: titik untuk ribuan, koma untuk desimal.
/// Contoh: 1200000 jadi "1.200.000", dan 66.55 (2 desimal) jadi "66,55".
String formatNumber(double value, {int decimals = 0}) {
  final parts = value.abs().toStringAsFixed(decimals).split('.');
  final grouped = parts[0].replaceAllMapped(
    RegExp(r'\B(?=(\d{3})+(?!\d))'),
    (_) => '.',
  );
  final sign = value < 0 ? '-' : '';
  return decimals == 0 ? '$sign$grouped' : '$sign$grouped,${parts[1]}';
}

String formatMoney(double amount, Currency currency) {
  return '${currency.code} ${formatNumber(amount, decimals: currency.decimals)}';
}
