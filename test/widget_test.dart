import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:divefriend/data/models/sea_conditions.dart';
import 'package:divefriend/data/models/spot.dart';
import 'package:divefriend/data/remote/spot_remote_source.dart';
import 'package:divefriend/data/seed/spots_seed.dart';
import 'package:divefriend/features/converter/time_converter_card.dart';
import 'package:divefriend/app.dart';
import 'package:divefriend/services/api_failure.dart';
import 'package:divefriend/services/auth_service.dart';
import 'package:divefriend/services/exchange_rate_service.dart';
import 'package:divefriend/services/marine_service.dart';
import 'fakes.dart';

/// Membuat app dengan satu akun siap pakai (budi / password123), tanpa SQLite asli.
Future<void> _pumpApp(
  WidgetTester tester, {
  ExchangeRateService? rates,
  MarineService? marine,
  SpotRemoteSource? spotRemote,
}) async {
  SharedPreferences.setMockInitialValues({});
  final auth = AuthService(
    InMemoryUserRepository(),
    FakeBiometric(available: false),
  );
  await tester.runAsync(
    () => auth.register(name: 'Budi', username: 'budi', password: 'password123'),
  );
  final services = buildTestServices(
    auth: auth,
    rates: rates,
    marine: marine,
    spotRemote: spotRemote,
    spots: spotsSeed,
  );
  await tester.pumpWidget(DiveFriendApp(services: services));
  await tester.pumpAndSettle();
}

Future<void> _login(WidgetTester tester, String username, String password) async {
  await tester.enterText(find.byType(TextFormField).at(0), username);
  await tester.enterText(find.byType(TextFormField).at(1), password);
  await tester.ensureVisible(find.text('Masuk'));
  await tester.tap(find.text('Masuk'));
  await tester.pumpAndSettle();
}

/// Membuka menu Fitur lewat bottom navigation lalu memilih satu fitur.
Future<void> _openFeature(WidgetTester tester, String name) async {
  await tester.tap(
    find.descendant(of: find.byType(NavigationBar), matching: find.text('Fitur')).first,
  );
  await tester.pumpAndSettle();
  await tester.tap(find.text(name));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('login kosong ditolak validasi', (tester) async {
    await _pumpApp(tester);
    await tester.ensureVisible(find.text('Masuk'));
    await tester.tap(find.text('Masuk'));
    await tester.pump();

    expect(find.text('Wajib diisi'), findsWidgets);
    expect(find.text('Kepulauan Banda'), findsNothing);
  });

  testWidgets('password salah menampilkan pesan error', (tester) async {
    await _pumpApp(tester);
    await _login(tester, 'budi', 'salah-salah');

    expect(find.text('Username atau password salah'), findsOneWidget);
    expect(find.text('Kepulauan Banda'), findsNothing);
  });

  testWidgets('login benar membuka Beranda berisi daftar spot', (tester) async {
    await _pumpApp(tester);
    await _login(tester, 'budi', 'password123');

    expect(find.text('Kepulauan Banda'), findsOneWidget);
  });

  testWidgets('pencarian tanpa hasil menampilkan state kosong', (tester) async {
    await _pumpApp(tester);
    await _login(tester, 'budi', 'password123');

    await tester.enterText(find.byType(TextField), 'zzzzzz');
    await tester.pumpAndSettle();

    expect(find.text('Spot tidak ditemukan'), findsOneWidget);
  });

  testWidgets('filter level menyaring daftar', (tester) async {
    await _pumpApp(tester);
    await _login(tester, 'budi', 'password123');

    await tester.tap(find.widgetWithText(ChoiceChip, 'Lanjutan'));
    await tester.pumpAndSettle();

    expect(find.text('Raja Ampat'), findsOneWidget);
    expect(find.text('Wakatobi'), findsNothing);
  });

  testWidgets('Detail Spot menampilkan gelombang dan harga simulasi', (tester) async {
    await _pumpApp(tester);
    await _openBandaDetail(tester);

    expect(find.text('Gelombang laut hari ini'), findsOneWidget);
    expect(find.text('0,6 m'), findsOneWidget);
    expect(find.text('0,9 m'), findsOneWidget);

    expect(find.text('Harga simulasi'), findsOneWidget);
    expect(find.text('IDR 3.000.000'), findsOneWidget);
    expect(find.text('USD 166,38'), findsOneWidget);
    expect(find.text('EUR 147,85'), findsOneWidget);
    expect(find.text('SGD 212,84'), findsOneWidget);
  });

  testWidgets('Detail Spot saat offline: pesan jelas, tombol coba lagi, harga rupiah tetap ada', (tester) async {
    const offline = ApiFailure(ApiFailureKind.offline);
    await _pumpApp(
      tester,
      rates: FakeRateService(failure: offline),
      marine: FakeMarineService(failure: offline),
    );
    await _openBandaDetail(tester);

    expect(
      find.text('Tidak ada koneksi internet, data gelombang belum bisa dimuat.'),
      findsOneWidget,
    );
    expect(
      find.text('Tidak ada koneksi internet, data kurs belum bisa dimuat.'),
      findsOneWidget,
    );
    expect(find.text('Coba lagi'), findsNWidgets(2));
    expect(find.text('IDR 3.000.000'), findsOneWidget);
    expect(find.text('USD 166,38'), findsNothing);
  });

  testWidgets('Detail Spot dengan data gelombang kosong menampilkan penjelasan', (tester) async {
    await _pumpApp(tester, marine: FakeMarineService(conditions: const SeaConditions()));
    await _openBandaDetail(tester);

    expect(
      find.textContaining('Model belum punya data gelombang untuk titik ini'),
      findsOneWidget,
    );
  });

  testWidgets('layar Konversi dibuka dari menu dan menghitung kurs', (tester) async {
    await _pumpApp(tester);
    await _login(tester, 'budi', 'password123');

    await _openFeature(tester, 'Konversi');

    expect(find.text('Kalkulator mata uang'), findsOneWidget);
    expect(_textOf(tester, 'currency_result'), '= IDR 1.803.100');

    await tester.enterText(find.byType(TextField), '1');
    await tester.pumpAndSettle();
    expect(_textOf(tester, 'currency_result'), '= IDR 18.031');

    await tester.enterText(find.byType(TextField), 'abc');
    await tester.pumpAndSettle();
    expect(find.text('Masukkan jumlah berupa angka untuk melihat hasilnya.'), findsOneWidget);
  });

  testWidgets('kalkulator kurs menampilkan pesan saat offline', (tester) async {
    await _pumpApp(
      tester,
      rates: FakeRateService(failure: const ApiFailure(ApiFailureKind.offline)),
    );
    await _login(tester, 'budi', 'password123');

    await _openFeature(tester, 'Konversi');

    expect(
      find.text('Tidak ada koneksi internet, data kurs belum bisa dimuat.'),
      findsOneWidget,
    );
  });

  testWidgets('konverter waktu: London memakai BST sebelum dan GMT sesudah 25 Oktober 2026', (tester) async {
    await _pumpTimeCard(tester, DateTime.utc(2026, 10, 24, 12));
    expect(_textOf(tester, 'time_wib'), '12.00');
    expect(_textOf(tester, 'time_wita'), '13.00');
    expect(_textOf(tester, 'time_wit'), '14.00');
    expect(_textOf(tester, 'time_london'), '06.00');

    await _pumpTimeCard(tester, DateTime.utc(2026, 10, 25, 12));
    expect(_textOf(tester, 'time_london'), '05.00');
  });

  testWidgets('konverter waktu: mengganti zona asal ke WIT', (tester) async {
    await _pumpTimeCard(tester, DateTime.utc(2026, 10, 24, 12));

    await tester.tap(find.widgetWithText(ChoiceChip, 'WIT'));
    await tester.pump();

    expect(_textOf(tester, 'time_wit'), '12.00');
    expect(_textOf(tester, 'time_wib'), '10.00');
    expect(_textOf(tester, 'time_london'), '04.00');
  });

  testWidgets('tombol Arah ke Spot di Detail Spot membuka layar arah', (tester) async {
    // Layar dibuat sangat tinggi supaya seluruh Detail Spot terlihat tanpa perlu scroll.
    tester.view.physicalSize = const Size(800, 3600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await _pumpApp(tester);
    await _openBandaDetail(tester);

    await tester.tap(find.text('Arah ke Spot'));
    await _pumpFrames(tester);

    expect(find.textContaining('Mencari posisi GPS'), findsOneWidget);
  });

  testWidgets('menu Logbook membuka layar logbook yang masih kosong', (tester) async {
    await _pumpApp(tester);
    await _login(tester, 'budi', 'password123');

    await _openFeature(tester, 'Logbook');

    expect(find.text('Logbook masih kosong'), findsOneWidget);
  });

  testWidgets('Beranda menyinkronkan spot dari Supabase: data online menimpa data lokal', (tester) async {
    const onlineSpot = Spot(
      id: 'online',
      name: 'Spot Online Uji',
      region: 'Wilayah Uji',
      level: SpotLevel.pemula,
      levelBasis: 'uji',
      types: [SpotType.scuba],
      tagline: 'uji',
      summary: 'uji',
      sources: ['uji'],
    );
    await _pumpApp(tester, spotRemote: FakeSpotRemoteSource(spots: [onlineSpot]));
    await _login(tester, 'budi', 'password123');

    expect(find.text('Spot Online Uji'), findsOneWidget);
    expect(find.text('Kepulauan Banda'), findsNothing);
    expect(
      tester.widget<Text>(find.byKey(const Key('sync_status'))).data,
      'Data spot disinkronkan dari Supabase (1 spot).',
    );
  });

  testWidgets('Beranda saat sinkron gagal (offline): data lokal tetap tampil dan ada pesan', (tester) async {
    await _pumpApp(
      tester,
      spotRemote: FakeSpotRemoteSource(failure: const ApiFailure(ApiFailureKind.offline)),
    );
    await _login(tester, 'budi', 'password123');

    expect(find.text('Kepulauan Banda'), findsOneWidget);
    expect(
      tester.widget<Text>(find.byKey(const Key('sync_status'))).data,
      'Tidak ada koneksi internet, memakai data spot lokal.',
    );
  });

  testWidgets('Beranda tanpa Supabase menampilkan status belum diatur', (tester) async {
    await _pumpApp(tester);
    await _login(tester, 'budi', 'password123');

    expect(
      tester.widget<Text>(find.byKey(const Key('sync_status'))).data,
      'Supabase belum diatur, memakai data spot lokal.',
    );
  });

  testWidgets('tombol sinkronkan di bar atas menjalankan sinkronisasi lagi', (tester) async {
    final remote = FakeSpotRemoteSource(failure: const ApiFailure(ApiFailureKind.offline));
    await _pumpApp(tester, spotRemote: remote);
    await _login(tester, 'budi', 'password123');
    expect(remote.calls, 1);

    await tester.tap(find.byTooltip('Sinkronkan data spot'));
    await tester.pumpAndSettle();

    expect(remote.calls, 2);
  });
}

/// Login lalu buka Detail Spot Kepulauan Banda (WIT, harga simulasi 3.000.000 rupiah).
Future<void> _openBandaDetail(WidgetTester tester) async {
  await _login(tester, 'budi', 'password123');
  await tester.ensureVisible(find.text('Kepulauan Banda'));
  await tester.tap(find.text('Kepulauan Banda'));
  await tester.pumpAndSettle();
}

/// Pengganti pumpAndSettle untuk layar yang menampilkan spinner tanpa henti (layar Arah ke Spot saat mencari GPS).
Future<void> _pumpFrames(WidgetTester tester) async {
  for (var i = 0; i < 5; i++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
}

String _textOf(WidgetTester tester, String key) {
  return tester.widget<Text>(find.byKey(Key(key))).data!;
}

Future<void> _pumpTimeCard(WidgetTester tester, DateTime initialTime) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        // Key unik supaya setiap pemanggilan membuat State baru (jam awal dibaca di initState).
        body: SingleChildScrollView(
          child: TimeConverterCard(key: UniqueKey(), initialTime: initialTime),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

