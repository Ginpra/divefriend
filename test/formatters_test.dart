import 'package:flutter_test/flutter_test.dart';

import 'package:divefriend/core/currencies.dart';
import 'package:divefriend/core/formatters.dart';

void main() {
  test('formatNumber memakai titik ribuan dan koma desimal', () {
    expect(formatNumber(1200000), '1.200.000');
    expect(formatNumber(999), '999');
    expect(formatNumber(1234), '1.234');
    expect(formatNumber(1234.5, decimals: 2), '1.234,50');
    expect(formatNumber(66.55206, decimals: 2), '66,55');
    expect(formatNumber(0.4, decimals: 1), '0,4');
    expect(formatNumber(-1500), '-1.500');
  });

  test('formatMoney mengikuti jumlah desimal tiap mata uang', () {
    expect(formatMoney(1200000, currencyByCode('IDR')), 'IDR 1.200.000');
    expect(formatMoney(66.552, currencyByCode('USD')), 'USD 66,55');
    expect(formatMoney(15802.0083, currencyByCode('JPY')), 'JPY 15.802');
  });

  test('mata uang harga adalah empat dan semuanya terdaftar', () {
    expect(priceCurrencyCodes.length, 4);
    expect(priceCurrencyCodes, contains('IDR'));
    for (final code in priceCurrencyCodes) {
      expect(currencyByCode(code).code, code);
    }
    expect(supportedCurrencies.length, greaterThanOrEqualTo(3));
  });
}
