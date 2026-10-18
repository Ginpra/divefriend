import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:divefriend/data/seed/spots_seed.dart';
import 'package:divefriend/features/logbook/logbook_screen.dart';
import 'package:divefriend/services/auth_service.dart';
import 'package:divefriend/services/logbook_service.dart';
import 'fakes.dart';

late LogbookService _logbook;
late int _userId;

/// Membuka layar Logbook dengan pengguna yang sudah login dan logbook di memori.
Future<void> _pumpLogbook(WidgetTester tester, {int prefilledEntries = 0}) async {
  SharedPreferences.setMockInitialValues({});
  final auth = AuthService(InMemoryUserRepository(), FakeBiometric(available: false));
  await tester.runAsync(() async {
    await auth.register(name: 'Budi', username: 'budi', password: 'password123');
    await auth.login('budi', 'password123');
  });
  _userId = auth.currentUser!.id;
  _logbook = LogbookService(InMemoryLogbookRepository());
  await tester.runAsync(() async {
    for (var i = 1; i <= prefilledEntries; i++) {
      await _logbook.addEntry(
        userId: _userId,
        diveDate: DateTime(2026, 10, i),
        spotId: 'banda',
        spotName: 'Kepulauan Banda',
        maxDepthM: 10 + i,
        bottomTimeMin: 40,
        notes: 'Catatan nomor $i',
      );
    }
  });

  final services = buildTestServices(auth: auth, logbook: _logbook, spots: spotsSeed);
  await tester.pumpWidget(MaterialApp(home: LogbookScreen(services: services)));
  await tester.pumpAndSettle();
}

String _integrityMessage(WidgetTester tester) {
  return tester.widget<Text>(find.byKey(const Key('integrity_message'))).data!;
}

void main() {
  testWidgets('logbook kosong menampilkan state kosong dan tombol Catatan baru', (tester) async {
    await _pumpLogbook(tester);

    expect(find.text('Logbook masih kosong'), findsOneWidget);
    expect(find.text('Catatan baru'), findsOneWidget);
    expect(find.text('Cek Integritas'), findsOneWidget);
  });

  testWidgets('catatan tampil dengan yang terbaru di atas', (tester) async {
    await _pumpLogbook(tester, prefilledEntries: 2);

    expect(find.text('Penyelaman #1'), findsOneWidget);
    expect(find.text('Penyelaman #2'), findsOneWidget);
    expect(find.text('Catatan nomor 2'), findsOneWidget);
    final topOfTwo = tester.getTopLeft(find.text('Penyelaman #2')).dy;
    final topOfOne = tester.getTopLeft(find.text('Penyelaman #1')).dy;
    expect(topOfTwo, lessThan(topOfOne));
  });

  testWidgets('Cek Integritas pada rantai utuh', (tester) async {
    await _pumpLogbook(tester, prefilledEntries: 2);

    await tester.tap(find.byKey(const Key('verify_chain')));
    await tester.pumpAndSettle();

    expect(
      _integrityMessage(tester),
      'Rantai utuh. Semua 2 catatan cocok dengan hash-nya dan terhubung berurutan.',
    );
    expect(find.text('Catatan ini gagal dicek'), findsNothing);
  });

  testWidgets('Cek Integritas mendeteksi catatan yang dipalsukan', (tester) async {
    await _pumpLogbook(tester, prefilledEntries: 2);
    await tester.runAsync(() => _logbook.simulateTampering(_userId));

    await tester.tap(find.byKey(const Key('verify_chain')));
    await tester.pumpAndSettle();

    expect(
      _integrityMessage(tester),
      'Catatan #1 berubah. Isinya tidak lagi cocok dengan hash yang tersimpan.',
    );
    expect(find.text('Catatan ini gagal dicek'), findsOneWidget);
  });

  testWidgets('menu demo: simulasi pemalsuan lalu pulihkan', (tester) async {
    await _pumpLogbook(tester, prefilledEntries: 2);

    await tester.tap(find.byTooltip('Menu demo'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Simulasi pemalsuan (demo)'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('verify_chain')));
    await tester.pumpAndSettle();
    expect(find.text('Catatan ini gagal dicek'), findsOneWidget);

    await tester.tap(find.byTooltip('Menu demo'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Pulihkan simulasi'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('verify_chain')));
    await tester.pumpAndSettle();
    expect(find.text('Catatan ini gagal dicek'), findsNothing);
    expect(_integrityMessage(tester).startsWith('Rantai utuh.'), isTrue);
  });

  testWidgets('form menolak isian kosong', (tester) async {
    tester.view.physicalSize = const Size(800, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await _pumpLogbook(tester);

    await tester.tap(find.byKey(const Key('add_entry')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('save_entry')));
    await tester.pumpAndSettle();

    expect(find.text('Isi angka bulat 1 sampai 150'), findsOneWidget);
    expect(find.text('Isi angka bulat 1 sampai 300'), findsOneWidget);
    expect(find.text('Pilih spot selam dulu'), findsOneWidget);
    expect(find.text('Penyelaman #1'), findsNothing);
  });

  testWidgets('mengisi form lalu menyimpan menambah catatan ke logbook', (tester) async {
    tester.view.physicalSize = const Size(800, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await _pumpLogbook(tester);

    await tester.tap(find.byKey(const Key('add_entry')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('pick_spot')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Kepulauan Banda'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const Key('field_depth')), '18');
    await tester.enterText(find.byKey(const Key('field_time')), '45');
    await tester.enterText(find.byKey(const Key('field_notes')), 'Arus tenang');
    await tester.tap(find.byKey(const Key('save_entry')));
    await tester.pumpAndSettle();

    expect(find.text('Penyelaman #1'), findsOneWidget);
    expect(find.text('Kepulauan Banda'), findsOneWidget);
    expect(find.text('18 m'), findsOneWidget);
    expect(find.text('45 menit'), findsOneWidget);
    expect(find.text('Arus tenang'), findsOneWidget);
    expect(find.text('Logbook masih kosong'), findsNothing);

    final saved = await tester.runAsync(() => _logbook.entries(_userId));
    expect(saved!.length, 1);
    expect(saved.single.spotId, 'banda');
  });
}
