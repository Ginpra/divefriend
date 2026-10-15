import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';

/// Hash password: salt acak + SHA-256 diulang 10.000 kali.
/// Salt membuat dua pengguna dengan password sama punya hash berbeda,
/// pengulangan membuat tebak-tebakan massal jadi lambat.
class PasswordHasher {
  static const int _rounds = 10000;

  static String generateSalt() {
    final random = Random.secure();
    final bytes = List<int>.generate(16, (_) => random.nextInt(256));
    return base64Url.encode(bytes);
  }

  static String hash(String password, String salt) {
    var value = '$salt$password';
    for (var i = 0; i < _rounds; i++) {
      value = sha256.convert(utf8.encode(value)).toString();
    }
    return value;
  }
}
