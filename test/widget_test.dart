import 'package:flutter_test/flutter_test.dart';

import 'package:divefriend/main.dart';

void main() {
  testWidgets('Layar uji build tampil dan tombol menambah hitungan', (tester) async {
    await tester.pumpWidget(const DiveFriendApp());

    expect(find.text('DiveFriend'), findsOneWidget);
    expect(find.text('0'), findsOneWidget);

    await tester.tap(find.text('Ketuk untuk tes hot reload'));
    await tester.pump();

    expect(find.text('1'), findsOneWidget);
  });
}
