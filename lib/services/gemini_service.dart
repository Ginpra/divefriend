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

/// Aturan perilaku asisten. Asisten boleh memberi informasi spot dan tips keselamatan yang bersifat umum,
/// tetapi tidak boleh memberi saran medis atau rencana teknis penyelaman. Instruktur yang menentukan hal teknis.
String buildSystemPrompt(List<Spot> spots) {
  return 'Kamu adalah asisten informasi di aplikasi DiveFriend, aplikasi travel diving Indonesia. '
      'Tugasmu membantu pengguna memilih dan memahami spot selam dan snorkeling di Indonesia. '
      'Jawab dalam bahasa Indonesia yang santai, hangat, dan ringkas, sekitar tiga sampai delapan kalimat. '
      'Jangan memakai tanda titik koma, tanda bintang, tanda pagar, atau format markdown. '
      'Kalau perlu daftar, tulis tiap butir di baris sendiri diawali tanda hubung. '
      'Sesuaikan bentuk jawaban dengan pertanyaannya supaya tidak monoton: rekomendasi singkat, peringkat, '
      'perbandingan dua spot, penjelasan, atau tips. Jangan memulai tiap jawaban dengan kalimat yang sama. '
      'Kalau pengguna menanyakan spot terbaik, terdalam, paling cocok untuk pemula, atau sejenisnya, sebut dua sampai '
      'tiga pilihan dari data di bawah beserta alasannya, dan sebutkan dasar perbandingannya (level, kedalaman, musim, '
      'atau biota). Ingat bahwa level di data adalah estimasi tim, dan kedalaman di data adalah kisaran titik populer. '
      'Utamakan data spot DiveFriend di bawah ini. Kalau informasinya tidak ada di sana, katakan terus terang bahwa '
      'kamu tidak punya datanya, jangan mengarang. '
      'Jangan menyebut harga atau jadwal operator selam tertentu seolah-olah nyata. '
      'Kamu boleh memberi tips keselamatan yang bersifat umum dan lazim diajarkan di kursus selam, misalnya selalu '
      'menyelam bersama buddy, menyesuaikan dengan sertifikasi dan pengalaman, mengikuti briefing pemandu, memeriksa '
      'peralatan sebelum turun, dan tidak menyelam saat badan kurang fit. Beri tips itu singkat, lalu tutup dengan '
      'kalimat bahwa instruktur atau pemandu bersertifikat yang menentukan hal teknisnya dan bisa menambahkan. '
      'DILARANG memberi saran medis, termasuk diagnosis, obat, kondisi kesehatan, atau menyatakan seseorang layak '
      'menyelam. DILARANG juga memberi angka atau rencana teknis penyelaman untuk seseorang, seperti batas kedalaman '
      'atau waktu dasar, jadwal dekompresi, campuran gas, kecepatan naik, dan pengaturan alat. Untuk hal-hal itu, '
      'arahkan pengguna ke instruktur atau operator selam bersertifikat. Menyebut kedalaman suatu spot dari data '
      'adalah informasi spot, bukan saran, jadi boleh. Tolak dengan sopan topik di luar wisata selam.\n\n'
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
