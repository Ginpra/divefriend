import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:divefriend/services/auth_service.dart';
import 'fakes.dart';

AuthService _newService({bool biometricSucceeds = true}) {
  return AuthService(
    InMemoryUserRepository(),
    FakeBiometric(succeeds: biometricSucceeds),
  );
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('register lalu login dengan password benar berhasil', () async {
    final auth = _newService();
    await auth.register(name: 'Budi', username: 'Budi', password: 'password123');

    final user = await auth.login('budi', 'password123');

    expect(user.name, 'Budi');
    expect(auth.currentUser?.username, 'budi');
  });

  test('password yang tersimpan bukan password polos', () async {
    final auth = _newService();
    final user = await auth.register(
      name: 'Budi',
      username: 'budi',
      password: 'password123',
    );

    expect(user.passwordHash, isNot('password123'));
    expect(user.salt, isNotEmpty);
  });

  test('login dengan password salah ditolak', () async {
    final auth = _newService();
    await auth.register(name: 'Budi', username: 'budi', password: 'password123');

    expect(
      () => auth.login('budi', 'salah-salah'),
      throwsA(isA<AuthException>()),
    );
    expect(auth.currentUser, isNull);
  });

  test('username yang sama tidak boleh didaftarkan dua kali', () async {
    final auth = _newService();
    await auth.register(name: 'Budi', username: 'budi', password: 'password123');

    expect(
      () => auth.register(name: 'Lain', username: ' BUDI ', password: 'password456'),
      throwsA(isA<AuthException>()),
    );
  });

  test('session dipulihkan setelah app dibuka lagi, hilang setelah logout', () async {
    final auth = _newService();
    await auth.register(name: 'Budi', username: 'budi', password: 'password123');
    await auth.login('budi', 'password123');

    auth.currentUser = null; // meniru app ditutup lalu dibuka lagi
    expect((await auth.restoreSession())?.username, 'budi');

    await auth.logout();
    expect(await auth.restoreSession(), isNull);
  });

  test('biometrik: aktifkan di profil lalu masuk tanpa password', () async {
    final auth = _newService();
    await auth.register(name: 'Budi', username: 'budi', password: 'password123');
    await auth.login('budi', 'password123');

    expect(await auth.enableBiometric(), isTrue);
    await auth.logout();

    expect(await auth.canLoginWithBiometric(), isTrue);
    final user = await auth.loginWithBiometric();
    expect(user?.username, 'budi');
    expect(auth.currentUser?.username, 'budi');
  });

  test('biometrik gagal tidak membuat pengguna login', () async {
    final auth = _newService(biometricSucceeds: false);
    await auth.register(name: 'Budi', username: 'budi', password: 'password123');
    await auth.login('budi', 'password123');

    expect(await auth.enableBiometric(), isFalse);
    await auth.logout();

    expect(await auth.canLoginWithBiometric(), isFalse);
    expect(await auth.loginWithBiometric(), isNull);
    expect(auth.currentUser, isNull);
  });
}
