import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:divefriend/data/models/exchange_rates.dart';
import 'package:divefriend/services/api_failure.dart';
import 'package:divefriend/services/exchange_rate_service.dart';

/// Respons contoh: bentuk dan angkanya diambil dari respons nyata
/// api.frankfurter.dev/v1/latest tanggal 2026-10-16 (hanya lima mata uang).
const String _sampleJson =
    '{"amount":1.0,"base":"EUR","date":"2026-10-16","rates":'
    '{"AUD":1.6171,"IDR":20290.28,"JPY":177.82,"SGD":1.4395,"USD":1.1253}}';

Matcher _failureOf(ApiFailureKind kind) {
  return throwsA(isA<ApiFailure>().having((error) => error.kind, 'kind', kind));
}

void main() {
  group('ExchangeRates', () {
    final rates = ExchangeRates.fromJson({
      'base': 'EUR',
      'date': '2026-10-16',
      'rates': {'IDR': 20290.28, 'USD': 1.1253, 'SGD': 1.4395, 'JPY': 177.82},
    });

    test('Euro otomatis bernilai 1 dan tanggal terbaca', () {
      expect(rates.date, '2026-10-16');
      expect(rates.perEuro['EUR'], 1.0);
      expect(rates.perEuro['IDR'], 20290.28);
    });

    test('rupiah ke dolar dan ke euro lewat kurs silang', () {
      expect(rates.convert(1200000, 'IDR', 'USD'), closeTo(66.552, 0.001));
      expect(rates.convert(1200000, 'IDR', 'EUR'), closeTo(59.1416, 0.001));
      expect(rates.convert(1200000, 'IDR', 'SGD'), closeTo(85.1344, 0.001));
    });

    test('dolar ke rupiah, euro, dan yen', () {
      expect(rates.convert(100, 'USD', 'IDR'), closeTo(1803099.62, 0.01));
      expect(rates.convert(100, 'USD', 'EUR'), closeTo(88.8652, 0.001));
      expect(rates.convert(100, 'USD', 'JPY'), closeTo(15802.01, 0.01));
    });

    test('mata uang yang sama tidak berubah nilainya', () {
      expect(rates.convert(100, 'USD', 'USD'), closeTo(100, 1e-9));
    });

    test('mata uang yang tidak ada di data menghasilkan null', () {
      expect(rates.convert(100, 'USD', 'XXX'), isNull);
      expect(rates.convert(100, 'XXX', 'USD'), isNull);
    });

    test('respons yang rusak melempar FormatException', () {
      expect(() => ExchangeRates.fromJson({'base': 'EUR', 'rates': {}}), throwsFormatException);
      expect(
        () => ExchangeRates.fromJson({'base': 'USD', 'date': 'x', 'rates': {}}),
        throwsFormatException,
      );
      expect(
        () => ExchangeRates.fromJson({'base': 'EUR', 'date': 'x', 'rates': 5}),
        throwsFormatException,
      );
    });

    test('nilai bukan angka atau tidak positif dilewati', () {
      final parsed = ExchangeRates.fromJson({
        'base': 'EUR',
        'date': 'x',
        'rates': {'USD': 'abc', 'IDR': 0, 'SGD': 1.4},
      });
      expect(parsed.perEuro.containsKey('USD'), isFalse);
      expect(parsed.perEuro.containsKey('IDR'), isFalse);
      expect(parsed.perEuro['SGD'], 1.4);
    });
  });

  group('FrankfurterRateService', () {
    test('meminta alamat v1/latest dengan daftar mata uang dan membaca hasilnya', () async {
      late Uri requested;
      final service = FrankfurterRateService(
        MockClient((request) async {
          requested = request.url;
          return http.Response(_sampleJson, 200);
        }),
      );

      final rates = await service.fetchLatest();

      expect(requested.host, 'api.frankfurter.dev');
      expect(requested.path, '/v1/latest');
      expect(requested.queryParameters['symbols'], 'IDR,USD,SGD,JPY,AUD');
      expect(rates.date, '2026-10-16');
      expect(rates.perEuro['USD'], 1.1253);
    });

    test('panggilan kedua memakai simpanan, forceRefresh memanggil lagi', () async {
      var calls = 0;
      final service = FrankfurterRateService(
        MockClient((request) async {
          calls++;
          return http.Response(_sampleJson, 200);
        }),
      );

      await service.fetchLatest();
      await service.fetchLatest();
      expect(calls, 1);

      await service.fetchLatest(forceRefresh: true);
      expect(calls, 2);
    });

    test('status bukan 200 dianggap masalah layanan', () async {
      final service = FrankfurterRateService(
        MockClient((request) async => http.Response('error', 500)),
      );
      await expectLater(service.fetchLatest(), _failureOf(ApiFailureKind.server));
    });

    test('gagal terhubung dianggap offline dan tidak disimpan', () async {
      var calls = 0;
      final service = FrankfurterRateService(
        MockClient((request) async {
          calls++;
          if (calls == 1) throw http.ClientException('putus');
          return http.Response(_sampleJson, 200);
        }),
      );

      await expectLater(service.fetchLatest(), _failureOf(ApiFailureKind.offline));
      final rates = await service.fetchLatest();
      expect(rates.perEuro['IDR'], 20290.28);
      expect(calls, 2);
    });

    test('isi bukan JSON, bukan objek, atau tidak lengkap dianggap data rusak', () async {
      for (final body in ['bukan json', '[1,2,3]', '{"base":"EUR"}']) {
        final service = FrankfurterRateService(
          MockClient((request) async => http.Response(body, 200)),
        );
        await expectLater(service.fetchLatest(), _failureOf(ApiFailureKind.badData));
      }
    });
  });

  test('failureText memberi kalimat sesuai jenis kegagalan', () {
    expect(
      failureText(const ApiFailure(ApiFailureKind.offline), 'kurs'),
      'Tidak ada koneksi internet, data kurs belum bisa dimuat.',
    );
    expect(
      failureText(const ApiFailure(ApiFailureKind.server), 'kurs'),
      'Layanan kurs sedang bermasalah. Coba lagi beberapa saat lagi.',
    );
    expect(
      failureText(const ApiFailure(ApiFailureKind.badData), 'kurs'),
      'Data kurs yang diterima tidak bisa dibaca.',
    );
    expect(failureText(StateError('x'), 'kurs'), 'Terjadi kesalahan saat memuat data kurs.');
  });
}
