import 'dart:convert';

import 'package:http/http.dart' as http;

import 'package:divefriend/data/models/spot.dart';

/// Satu giliran percakapan, dari pengguna atau dari asisten.
class ChatTurn {
  const ChatTurn({required this.fromUser, required this.text});

  final bool fromUser;
  final String text;
}

enum GeminiFailureKind { notConfigured, offline, rateLimited, badKey, server, badData }

/// Alasan asisten tidak bisa menjawab, dikelompokkan supaya layar menampilkan pesan yang jelas.
class GeminiFailure implements Exception {
  const GeminiFailure(this.kind);

  final GeminiFailureKind kind;
}

/// Kontrak asisten AI. Layar hanya bergantung pada kelas ini, jadi tes bisa memakai versi palsu.
abstract class GeminiService {
  /// False kalau kunci API belum diisi di lib/config/secrets.dart.
  bool get isConfigured;

  /// Jawaban untuk percakapan [history] (giliran terakhir adalah pertanyaan pengguna).
  /// [systemPrompt] berisi aturan perilaku dan data spot, dibuat dengan [buildSystemPrompt].
  Future<String> reply(List<ChatTurn> history, {required String systemPrompt});
}

/// Ringkasan data spot yang dikirim sebagai konteks, supaya jawaban asisten sejalan dengan data aplikasi.
String buildSpotContext(List<Spot> spots) {
  final lines = <String>[];
  for (final spot in spots) {
    final biota = spot.biota.isEmpty ? 'tidak tersedia' : spot.biota.take(6).join(', ');
    lines.add(
      '- ${spot.name} (${spot.region}), level estimasi ${spot.level.label}, '
      'kedalaman ${spot.depthText ?? 'tidak tersedia'}, '
      'musim ${spot.bestSeason ?? 'tidak tersedia'}, biota: $biota',
    );
  }
  return lines.join('\n');
}

/// Aturan perilaku asisten. Larangan saran medis dan keselamatan adalah syarat proyek.
String buildSystemPrompt(List<Spot> spots) {
  return 'Kamu adalah asisten informasi di aplikasi DiveFriend, aplikasi travel diving Indonesia. '
      'Tugasmu menjawab pertanyaan umum tentang spot selam dan snorkeling di Indonesia, misalnya '
      'gambaran lokasi, musim, jenis biota, dan cara menuju lokasi. '
      'Jawab dalam bahasa Indonesia yang santai dan ringkas, maksimal sekitar enam kalimat. '
      'Jangan memakai tanda titik koma. '
      'Utamakan data spot DiveFriend di bawah ini, dan kalau informasinya tidak ada di sana, katakan terus terang '
      'bahwa kamu tidak punya datanya, jangan mengarang. '
      'Jangan menyebut harga atau jadwal operator selam tertentu seolah-olah nyata. '
      'DILARANG memberi saran medis atau saran keselamatan menyelam, termasuk batas kedalaman, waktu dasar, '
      'dekompresi, kecepatan naik, pengaturan gas atau peralatan, kondisi tubuh, obat, dan apakah suatu penyelaman '
      '"aman". Kalau pertanyaan menyangkut hal itu, tolak dengan sopan dan arahkan pengguna ke instruktur atau '
      'operator selam bersertifikat. Tolak juga topik di luar wisata selam.\n\n'
      'Data spot DiveFriend:\n${buildSpotContext(spots)}';
}

/// Gemini lewat REST (paket http), tanpa paket resmi Google.
/// Endpoint dan header sesuai dokumentasi ai.google.dev: POST .../v1beta/models/{model}:generateContent
/// dengan header x-goog-api-key.
class HttpGeminiService implements GeminiService {
  HttpGeminiService(
    this._client, {
    required this.apiKey,
    this.model = defaultModel,
  });

  /// Nama model, bisa diganti kalau model ini tidak tersedia untuk kunci API.
  static const String defaultModel = 'gemini-3.5-flash-lite';

  /// Hanya sekian giliran terakhir yang dikirim supaya permintaan tidak membengkak.
  static const int _maxTurnsSent = 12;

  final http.Client _client;
  final String apiKey;
  final String model;

  @override
  bool get isConfigured => apiKey.isNotEmpty;

  @override
  Future<String> reply(List<ChatTurn> history, {required String systemPrompt}) async {
    if (!isConfigured) throw const GeminiFailure(GeminiFailureKind.notConfigured);

    final recent = history.length > _maxTurnsSent
        ? history.sublist(history.length - _maxTurnsSent)
        : history;
    final body = jsonEncode({
      'systemInstruction': {
        'parts': [
          {'text': systemPrompt},
        ],
      },
      'contents': [
        for (final turn in recent)
          {
            'role': turn.fromUser ? 'user' : 'model',
            'parts': [
              {'text': turn.text},
            ],
          },
      ],
    });

    final uri = Uri.parse('https://generativelanguage.googleapis.com/v1beta/models/$model:generateContent');
    final http.Response response;
    try {
      response = await _client
          .post(
            uri,
            headers: {'Content-Type': 'application/json', 'x-goog-api-key': apiKey},
            body: body,
          )
          .timeout(const Duration(seconds: 30));
    } on Exception {
      throw const GeminiFailure(GeminiFailureKind.offline);
    }
    return parseGeminiResponse(response.statusCode, response.body);
  }
}

/// Mengubah status dan isi respons Gemini jadi teks jawaban, atau melempar [GeminiFailure].
/// Dipisah dari pemanggilan jaringan supaya bisa dites dengan data contoh.
String parseGeminiResponse(int statusCode, String body) {
  if (statusCode == 429) throw const GeminiFailure(GeminiFailureKind.rateLimited);
  if (statusCode == 400 || statusCode == 401 || statusCode == 403 || statusCode == 404) {
    throw const GeminiFailure(GeminiFailureKind.badKey);
  }
  if (statusCode != 200) throw const GeminiFailure(GeminiFailureKind.server);

  Object? decoded;
  try {
    decoded = jsonDecode(body);
  } on FormatException {
    decoded = null;
  }
  if (decoded is! Map<String, dynamic>) throw const GeminiFailure(GeminiFailureKind.badData);

  final candidates = decoded['candidates'];
  if (candidates is! List || candidates.isEmpty) throw const GeminiFailure(GeminiFailureKind.badData);
  final first = candidates.first;
  final content = first is Map ? first['content'] : null;
  final parts = content is Map ? content['parts'] : null;
  if (parts is! List) throw const GeminiFailure(GeminiFailureKind.badData);

  final text = parts
      .whereType<Map<dynamic, dynamic>>()
      .map((part) => part['text'])
      .whereType<String>()
      .join()
      .trim();
  if (text.isEmpty) throw const GeminiFailure(GeminiFailureKind.badData);
  return text;
}
