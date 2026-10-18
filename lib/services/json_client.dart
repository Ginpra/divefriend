import 'dart:convert';

import 'package:http/http.dart' as http;

import 'package:divefriend/services/api_failure.dart';

/// GET lalu ubah isinya jadi objek JSON. Dipakai bersama oleh layanan kurs dan gelombang.
/// Gagal koneksi atau lewat 10 detik = offline, status bukan 200 = server, bukan JSON objek = badData.
Future<Map<String, dynamic>> getJsonObject(http.Client client, Uri uri) async {
  final http.Response response;
  try {
    response = await client.get(uri).timeout(const Duration(seconds: 10));
  } on Exception {
    throw const ApiFailure(ApiFailureKind.offline);
  }
  if (response.statusCode != 200) {
    throw const ApiFailure(ApiFailureKind.server);
  }

  Object? decoded;
  try {
    decoded = jsonDecode(response.body);
  } on FormatException {
    decoded = null;
  }
  if (decoded is Map<String, dynamic>) return decoded;
  throw const ApiFailure(ApiFailureKind.badData);
}
