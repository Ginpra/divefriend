import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:divefriend/data/seed/spots_seed.dart';
import 'package:divefriend/services/gemini_service.dart';

const String _okBody = '''
{"candidates":[{"content":{"role":"model","parts":[{"text":"Musim terbaik April sampai Oktober."}]}}]}
''';

Matcher _failure(GeminiFailureKind kind) {
  return throwsA(isA<GeminiFailure>().having((error) => error.kind, 'kind', kind));
}

void main() {
  group('parseGeminiResponse', () {
    test('mengambil teks jawaban', () {
      expect(parseGeminiResponse(200, _okBody), 'Musim terbaik April sampai Oktober.');
    });

    test('status 429 = batas pemakaian', () {
      expect(() => parseGeminiResponse(429, ''), _failure(GeminiFailureKind.rateLimited));
    });

    test('status 403 = kunci atau model ditolak', () {
      expect(() => parseGeminiResponse(403, ''), _failure(GeminiFailureKind.badKey));
    });

    test('status 500 = masalah layanan', () {
      expect(() => parseGeminiResponse(500, ''), _failure(GeminiFailureKind.server));
    });

    test('isi bukan JSON atau tanpa kandidat = data tidak terbaca', () {
      expect(() => parseGeminiResponse(200, 'bukan json'), _failure(GeminiFailureKind.badData));
      expect(() => parseGeminiResponse(200, '{"candidates":[]}'), _failure(GeminiFailureKind.badData));
    });
  });

  group('HttpGeminiService', () {
    final history = [const ChatTurn(fromUser: true, text: 'Kapan musim terbaik ke Bunaken?')];

    test('mengirim kunci di header, aturan sebagai systemInstruction, dan peran pesan', () async {
      late http.Request captured;
      final client = MockClient((request) async {
        captured = request;
        return http.Response(_okBody, 200);
      });
      final service = HttpGeminiService(client, apiKey: 'kunci-uji');

      final answer = await service.reply(history, systemPrompt: 'aturan uji');

      expect(answer, 'Musim terbaik April sampai Oktober.');
      expect(captured.headers['x-goog-api-key'], 'kunci-uji');
      expect(captured.url.path, contains('${HttpGeminiService.defaultModel}:generateContent'));
      final body = jsonDecode(captured.body) as Map<String, dynamic>;
      expect(jsonEncode(body['systemInstruction']), contains('aturan uji'));
      final contents = body['contents'] as List<dynamic>;
      expect((contents.first as Map<String, dynamic>)['role'], 'user');
    });

    test('hanya 12 giliran terakhir yang dikirim', () async {
      late http.Request captured;
      final client = MockClient((request) async {
        captured = request;
        return http.Response(_okBody, 200);
      });
      final service = HttpGeminiService(client, apiKey: 'k');
      final longHistory = [
        for (var i = 0; i < 20; i++) ChatTurn(fromUser: i.isEven, text: 'pesan $i'),
      ];

      await service.reply(longHistory, systemPrompt: 'x');

      final body = jsonDecode(captured.body) as Map<String, dynamic>;
      expect((body['contents'] as List<dynamic>).length, 12);
    });

    test('tanpa kunci: notConfigured dan tidak memanggil jaringan', () async {
      var called = false;
      final client = MockClient((request) async {
        called = true;
        return http.Response(_okBody, 200);
      });
      final service = HttpGeminiService(client, apiKey: '');

      expect(service.isConfigured, isFalse);
      await expectLater(
        service.reply(history, systemPrompt: 'x'),
        _failure(GeminiFailureKind.notConfigured),
      );
      expect(called, isFalse);
    });

    test('gagal koneksi menjadi offline', () async {
      final client = MockClient((request) async => throw http.ClientException('putus'));
      final service = HttpGeminiService(client, apiKey: 'k');

      await expectLater(service.reply(history, systemPrompt: 'x'), _failure(GeminiFailureKind.offline));
    });
  });

  test('aturan asisten: tips umum boleh, saran medis dan rencana teknis dilarang, data spot ikut', () {
    final prompt = buildSystemPrompt(spotsSeed);

    expect(prompt, contains('tips keselamatan yang bersifat umum'));
    expect(prompt, contains('DILARANG memberi saran medis'));
    expect(prompt, contains('jadwal dekompresi'));
    expect(prompt, contains('instruktur'));
    expect(prompt, contains('Taman Nasional Bunaken'));
  });
}
