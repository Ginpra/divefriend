/// Satu mata uang yang didukung aplikasi. [decimals] = jumlah angka di belakang koma saat ditampilkan.
class Currency {
  const Currency(this.code, this.name, {this.decimals = 2});

  final String code;
  final String name;
  final int decimals;
}

/// Semua kode di bawah sudah dicek ada di daftar mata uang Frankfurter (api.frankfurter.dev/v1/currencies).
/// EUR wajib ada karena Frankfurter memakai Euro sebagai mata uang dasar.
const List<Currency> supportedCurrencies = [
  Currency('IDR', 'Rupiah', decimals: 0),
  Currency('USD', 'Dolar Amerika'),
  Currency('EUR', 'Euro'),
  Currency('SGD', 'Dolar Singapura'),
  Currency('JPY', 'Yen Jepang', decimals: 0),
  Currency('AUD', 'Dolar Australia'),
];

/// Empat mata uang untuk harga paket di Detail Spot dan Booking.
const List<String> priceCurrencyCodes = ['IDR', 'USD', 'EUR', 'SGD'];

Currency currencyByCode(String code) {
  return supportedCurrencies.firstWhere((currency) => currency.code == code);
}
