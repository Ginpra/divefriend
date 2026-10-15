import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:divefriend/app_services.dart';
import 'package:divefriend/data/seed/spots_seed.dart';
import 'package:divefriend/main.dart';
import 'package:divefriend/services/auth_service.dart';
import 'fakes.dart';

/// Membuat app dengan satu akun siap pakai (budi / password123), tanpa SQLite asli.
Future<void> _pumpApp(WidgetTester tester) async {
  SharedPreferences.setMockInitialValues({});
  final auth = AuthService(
    InMemoryUserRepository(),
    FakeBiometric(available: false),
  );
  await tester.runAsync(
    () => auth.register(name: 'Budi', username: 'budi', password: 'password123'),
  );
  final services = AppServices(
    spots: InMemorySpotRepository(spotsSeed),
    auth: auth,
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

void main() {
  testWidgets('login kosong ditolak validasi', (tester) async {
    await _pumpApp(tester);
    await tester.ensureVisible(find.text('Masuk'));
    await tester.tap(find.text('Masuk'));
    await tester.pump();

    expect(find.text('Wajib diisi'), findsWidgets);
    expect(find.text('Taman Nasional Bunaken'), findsNothing);
  });

  testWidgets('password salah menampilkan pesan error', (tester) async {
    await _pumpApp(tester);
    await _login(tester, 'budi', 'salah-salah');

    expect(find.text('Username atau password salah'), findsOneWidget);
    expect(find.text('Taman Nasional Bunaken'), findsNothing);
  });

  testWidgets('login benar membuka Beranda berisi daftar spot', (tester) async {
    await _pumpApp(tester);
    await _login(tester, 'budi', 'password123');

    expect(find.text('Taman Nasional Bunaken'), findsOneWidget);
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
}
