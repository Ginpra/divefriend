/// Kurs terbaru dari Frankfurter. Frankfurter memakai Euro sebagai mata uang dasar,
/// jadi [perEuro] berisi "berapa unit mata uang ini untuk 1 Euro" (EUR sendiri = 1).
/// Konversi antar dua mata uang apa pun dihitung lewat Euro.
class ExchangeRates {
  const ExchangeRates({required this.date, required this.perEuro});

  /// Tanggal kurs, format "2026-10-16" (apa adanya dari Frankfurter).
  final String date;
  final Map<String, double> perEuro;

  /// Respons yang tidak lengkap atau bukan berbasis Euro dianggap rusak (FormatException).
  factory ExchangeRates.fromJson(Map<String, dynamic> json) {
    final date = json['date'];
    final rates = json['rates'];
    if (date is! String || rates is! Map || json['base'] != 'EUR') {
      throw const FormatException('Respons kurs tidak lengkap');
    }
    final perEuro = <String, double>{'EUR': 1.0};
    rates.forEach((code, value) {
      if (code is String && value is num && value > 0) {
        perEuro[code] = value.toDouble();
      }
    });
    return ExchangeRates(date: date, perEuro: perEuro);
  }

  /// Null kalau salah satu mata uang tidak ada di data kurs.
  double? convert(double amount, String from, String to) {
    final fromRate = perEuro[from];
    final toRate = perEuro[to];
    if (fromRate == null || toRate == null) return null;
    return amount * toRate / fromRate;
  }
}
