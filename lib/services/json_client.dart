import 'dart:convert';

import 'package:http/http.dart' as http;

import 'package:divefriend/services/api_failure.dart';

/// GET lalu ubah isinya jadi JSON. Dipakai bersama oleh layanan kurs, gelombang, dan Supabase.
/// Gagal koneksi atau lewat 10 detik = offline, status bukan 200 = server, isi bukan JSON = badData.
Future<Object> getJson(http.Client client, Uri uri, {Map<String, String>? headers}) async {
  final http.Response response;
  try {
    response = await client.get(uri, headers: headers).timeout(const Duration(seconds: 10));
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
  if (decoded == null) throw const ApiFailure(ApiFailureKind.badData);
  return decoded;
}

/// Seperti [getJson], tapi isinya harus objek JSON, kalau bukan dianggap badData.
Future<Map<String, dynamic>> getJsonObject(http.Client client, Uri uri) async {
  final decoded = await getJson(client, uri);
  if (decoded is Map<String, dynamic>) return decoded;
  throw const ApiFailure(ApiFailureKind.badData);
}

/// Seperti [getJson], tapi isinya harus daftar JSON, kalau bukan dianggap badData.
Future<List<dynamic>> getJsonList(http.Client client, Uri uri, {Map<String, String>? headers}) async {
  final decoded = await getJson(client, uri, headers: headers);
  if (decoded is List<dynamic>) return decoded;
  throw const ApiFailure(ApiFailureKind.badData);
}
