import 'package:flutter_test/flutter_test.dart';

import 'package:divefriend/services/password_hasher.dart';

void main() {
  test('password dan salt yang sama menghasilkan hash yang sama', () {
    final first = PasswordHasher.hash('rahasia123', 'garam');
    final second = PasswordHasher.hash('rahasia123', 'garam');
    expect(first, second);
  });

  test('salt berbeda menghasilkan hash berbeda', () {
    final first = PasswordHasher.hash('rahasia123', 'garam1');
    final second = PasswordHasher.hash('rahasia123', 'garam2');
    expect(first, isNot(second));
  });

  test('password berbeda menghasilkan hash berbeda', () {
    final first = PasswordHasher.hash('rahasia123', 'garam');
    final second = PasswordHasher.hash('rahasia124', 'garam');
    expect(first, isNot(second));
  });

  test('hash tidak memuat password polos', () {
    expect(PasswordHasher.hash('rahasia123', 'garam'), isNot(contains('rahasia123')));
  });

  test('salt acak tidak pernah sama', () {
    expect(PasswordHasher.generateSalt(), isNot(PasswordHasher.generateSalt()));
  });
}
