import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:divefriend/data/repositories/dummy_spot_repository.dart';
import 'package:divefriend/main.dart';

Future<void> _loginToHome(WidgetTester tester) async {
  await tester.pumpWidget(
    DiveFriendApp(
      spotRepository: DummySpotRepository(simulatedDelay: Duration.zero),
    ),
  );
  await tester.enterText(find.byType(TextFormField).at(0), 'tester');
  await tester.enterText(find.byType(TextFormField).at(1), 'password123');
  await tester.ensureVisible(find.text('Masuk'));
  await tester.tap(find.text('Masuk'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('login kosong ditolak validasi', (tester) async {
    await tester.pumpWidget(
      DiveFriendApp(
        spotRepository: DummySpotRepository(simulatedDelay: Duration.zero),
      ),
    );
    await tester.ensureVisible(find.text('Masuk'));
    await tester.tap(find.text('Masuk'));
    await tester.pump();

    expect(find.text('Wajib diisi'), findsWidgets);
    expect(find.text('Bunaken'), findsNothing);
  });

  testWidgets('login valid membuka Beranda berisi daftar spot', (tester) async {
    await _loginToHome(tester);

    expect(find.text('Bunaken'), findsOneWidget);
  });

  testWidgets('pencarian tanpa hasil menampilkan state kosong', (tester) async {
    await _loginToHome(tester);

    await tester.enterText(find.byType(TextField), 'zzzzzz');
    await tester.pumpAndSettle();

    expect(find.text('Spot tidak ditemukan'), findsOneWidget);
  });

  testWidgets('filter level menyaring daftar', (tester) async {
    await _loginToHome(tester);

    await tester.tap(find.widgetWithText(ChoiceChip, 'Lanjutan'));
    await tester.pumpAndSettle();

    expect(find.text('Raja Ampat'), findsOneWidget);
    expect(find.text('Tulamben'), findsNothing);
  });
}
