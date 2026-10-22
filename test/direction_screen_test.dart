import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:divefriend/data/models/geo_point.dart';
import 'package:divefriend/data/models/spot.dart';
import 'package:divefriend/data/seed/spots_seed.dart';
import 'package:divefriend/features/direction/direction_screen.dart';
import 'package:divefriend/services/auth_service.dart';
import 'package:divefriend/services/location_service.dart';
import 'package:divefriend/services/map_launcher.dart';
import 'package:divefriend/services/sensor_service.dart';
import 'fakes.dart';

final Spot _banda = spotsSeed.firstWhere((spot) => spot.id == 'banda');

/// Titik 1 derajat lintang di utara Banda: spot ada tepat di selatan, jaraknya sekitar 111 km.
final GeoPoint _northOfBanda = GeoPoint(_banda.latitude! + 1, _banda.longitude!);

Future<void> _pumpDirection(
  WidgetTester tester, {
  Spot? spot,
  LocationService? location,
  SensorService? sensors,
  MapLauncher? maps,
}) async {
  SharedPreferences.setMockInitialValues({});
  final services = buildTestServices(
    auth: AuthService(InMemoryUserRepository(), FakeBiometric(available: false)),
    location: location,
    sensors: sensors,
    maps: maps,
    spots: spotsSeed,
  );
  await tester.pumpWidget(
    MaterialApp(home: DirectionScreen(spot: spot ?? _banda, services: services)),
  );
  await _pumpFrames(tester);
}

/// Memajukan beberapa frame. Tidak memakai pumpAndSettle karena layar Arah menampilkan spinner
/// "Mencari posisi GPS" yang animasinya tidak pernah berhenti, sehingga pumpAndSettle menunggu selamanya.
Future<void> _pumpFrames(WidgetTester tester) async {
  for (var i = 0; i < 5; i++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
}

/// Tombol di kartu rute ada di bawah layar dan baru dibuat setelah di-scroll (ListView membuat isinya sesuai kebutuhan).
Future<void> _tapRouteCardText(WidgetTester tester, String text) async {
  await tester.scrollUntilVisible(find.text(text), 200);
  await tester.ensureVisible(find.text(text));
  await tester.pump();
  await tester.tap(find.text(text));
  await _pumpFrames(tester);
}

String _textOf(WidgetTester tester, String key) {
  return tester.widget<Text>(find.byKey(Key(key))).data!;
}

void main() {
  testWidgets('menampilkan jarak dan arah ke spot setelah posisi GPS didapat', (tester) async {
    await _pumpDirection(
      tester,
      location: FakeLocationService(points: [_northOfBanda]),
      sensors: FakeSensorService(headingValues: [90]),
    );

    expect(_textOf(tester, 'direction_distance'), '111 km');
    expect(_textOf(tester, 'direction_bearing'), 'Arah ke spot: 180° (S)');
    await tester.scrollUntilVisible(find.textContaining('titik pusat kawasan, bukan titik selam'), 200);
    expect(find.textContaining('titik pusat kawasan, bukan titik selam'), findsOneWidget);
  });

  testWidgets('saat posisi belum didapat tampil pesan mencari GPS', (tester) async {
    await _pumpDirection(tester, location: FakeLocationService());

    expect(find.textContaining('Mencari posisi GPS'), findsOneWidget);
    expect(find.byKey(const Key('direction_distance')), findsNothing);
  });

  testWidgets('izin lokasi ditolak: pesan jelas dan tombol coba lagi tanpa tombol pengaturan', (tester) async {
    await _pumpDirection(
      tester,
      location: FakeLocationService(
        error: const LocationFailure(LocationFailureKind.permissionDenied),
      ),
    );

    expect(
      find.text('Izin lokasi belum diberikan, jadi jarak ke spot belum bisa dihitung.'),
      findsOneWidget,
    );
    expect(find.text('Coba lagi'), findsOneWidget);
    expect(find.text('Buka pengaturan'), findsNothing);
  });

  testWidgets('izin ditolak permanen: tombol Buka pengaturan memanggil pengaturan aplikasi', (tester) async {
    final location = FakeLocationService(
      error: const LocationFailure(LocationFailureKind.permissionDeniedForever),
    );
    await _pumpDirection(tester, location: location);

    await tester.tap(find.text('Buka pengaturan'));
    await _pumpFrames(tester);

    expect(location.openedSettings, [LocationFailureKind.permissionDeniedForever]);
  });

  testWidgets('GPS mati: pesan dan tombol Buka pengaturan', (tester) async {
    await _pumpDirection(
      tester,
      location: FakeLocationService(
        error: const LocationFailure(LocationFailureKind.serviceDisabled),
      ),
    );

    expect(
      find.text('GPS di HP sedang mati. Nyalakan layanan lokasi untuk melihat jarak ke spot.'),
      findsOneWidget,
    );
    expect(find.text('Buka pengaturan'), findsOneWidget);
  });

  testWidgets('HP tanpa sensor kompas: jarak tetap tampil dan ada penjelasan', (tester) async {
    await _pumpDirection(
      tester,
      location: FakeLocationService(points: [_northOfBanda]),
      sensors: FakeSensorService(hasCompass: false),
    );

    expect(_textOf(tester, 'direction_distance'), '111 km');
    expect(find.textContaining('HP ini tidak punya sensor kompas'), findsOneWidget);
  });

  testWidgets('kartu rute menampilkan pintu masuk dan langkah perjalanan', (tester) async {
    await _pumpDirection(tester, location: FakeLocationService(points: [_northOfBanda]));

    await tester.scrollUntilVisible(find.byKey(const Key('access_point_name')), 200);
    expect(
      tester.widget<Text>(find.byKey(const Key('access_point_name'))).data,
      'Bandara Pattimura, Ambon',
    );
    expect(find.textContaining('Pelabuhan Tulehu'), findsOneWidget);
  });

  testWidgets('tombol rute selalu dimulai dari lokasi saya (origin kosong)', (tester) async {
    final maps = FakeMapLauncher();
    await _pumpDirection(tester, location: FakeLocationService(points: [_northOfBanda]), maps: maps);

    await _tapRouteCardText(tester, 'Buka rute di Google Maps');

    expect(maps.routes.length, 1);
    expect(maps.routes.single.origin, isNull);
    expect(maps.routes.single.destination, 'Bandara Pattimura, Ambon');
  });

  testWidgets('Lihat titik spot di peta membuka koordinat spot', (tester) async {
    final maps = FakeMapLauncher();
    await _pumpDirection(tester, location: FakeLocationService(points: [_northOfBanda]), maps: maps);

    await _tapRouteCardText(tester, 'Lihat titik spot di peta');

    expect(maps.opened.length, 1);
    expect(maps.opened.single.latitude, _banda.latitude);
    expect(maps.opened.single.longitude, _banda.longitude);
  });

  testWidgets('aplikasi peta gagal dibuka: muncul pesan', (tester) async {
    await _pumpDirection(
      tester,
      location: FakeLocationService(points: [_northOfBanda]),
      maps: FakeMapLauncher(succeeds: false),
    );

    await _tapRouteCardText(tester, 'Buka rute di Google Maps');

    expect(find.text('Aplikasi peta tidak bisa dibuka di HP ini.'), findsOneWidget);
  });

  testWidgets('spot tanpa koordinat menampilkan pesan, tanpa memanggil GPS', (tester) async {
    const spot = Spot(
      id: 'uji',
      name: 'Spot Uji',
      region: 'Uji',
      level: SpotLevel.pemula,
      levelBasis: 'uji',
      types: [SpotType.scuba],
      tagline: 'uji',
      summary: 'uji',
      sources: ['uji'],
    );
    await _pumpDirection(tester, spot: spot);

    expect(find.text('Koordinat tidak tersedia'), findsOneWidget);
  });
}
