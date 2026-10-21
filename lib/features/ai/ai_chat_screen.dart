import 'package:flutter/material.dart';

import 'package:divefriend/app_services.dart';
import 'package:divefriend/core/app_theme.dart';
import 'package:divefriend/core/widgets/disclaimer_banner.dart';
import 'package:divefriend/core/widgets/inline_notice.dart';
import 'package:divefriend/core/widgets/state_message.dart';
import 'package:divefriend/services/gemini_service.dart';

/// Kalimat untuk pengguna sesuai alasan asisten gagal menjawab.
String geminiFailureText(GeminiFailureKind kind) {
  return switch (kind) {
    GeminiFailureKind.notConfigured => 'Kunci Gemini belum diisi di aplikasi.',
    GeminiFailureKind.offline => 'Tidak ada koneksi internet, pertanyaan belum bisa dikirim.',
    GeminiFailureKind.rateLimited =>
      'Batas pemakaian asisten sedang tercapai. Tunggu sebentar lalu coba lagi.',
    GeminiFailureKind.badKey => 'Kunci API atau nama model tidak diterima oleh layanan Gemini.',
    GeminiFailureKind.server => 'Layanan asisten sedang bermasalah. Coba lagi beberapa saat lagi.',
    GeminiFailureKind.badData => 'Asisten tidak memberi jawaban yang bisa dibaca. Coba ubah pertanyaanmu.',
  };
}

/// Chat dengan asisten AI (Gemini lewat REST). Asisten hanya memberi informasi umum seputar spot selam
/// dan dilarang memberi saran medis atau keselamatan (aturannya ada di buildSystemPrompt).
class AiChatScreen extends StatefulWidget {
  const AiChatScreen({super.key, required this.services});

  final AppServices services;

  @override
  State<AiChatScreen> createState() => _AiChatScreenState();
}

class _AiChatScreenState extends State<AiChatScreen> {
  final _controller = TextEditingController();
  final _scroll = ScrollController();
  final List<ChatTurn> _turns = [];
  bool _sending = false;
  GeminiFailureKind? _failure;

  @override
  void dispose() {
    _controller.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _scrollToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) _scroll.jumpTo(_scroll.position.maxScrollExtent);
    });
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _sending) return;
    _controller.clear();
    setState(() {
      _turns.add(ChatTurn(fromUser: true, text: text));
    });
    await _ask();
  }

  /// Meminta jawaban untuk percakapan saat ini. Dipakai juga oleh tombol Coba lagi.
  Future<void> _ask() async {
    setState(() {
      _sending = true;
      _failure = null;
    });
    _scrollToEnd();
    try {
      final spots = await widget.services.spots.getSpots();
      final answer = await widget.services.gemini.reply(
        _turns,
        systemPrompt: buildSystemPrompt(spots),
      );
      if (!mounted) return;
      setState(() {
        _turns.add(ChatTurn(fromUser: false, text: answer));
        _sending = false;
      });
    } on GeminiFailure catch (failure) {
      if (!mounted) return;
      setState(() {
        _failure = failure.kind;
        _sending = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _failure = GeminiFailureKind.server;
        _sending = false;
      });
    }
    _scrollToEnd();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Asisten AI')),
      body: widget.services.gemini.isConfigured ? _buildChat() : _buildNotConfigured(),
    );
  }

  Widget _buildNotConfigured() {
    return const StateMessage(
      icon: Icons.key_off_outlined,
      title: 'Asisten belum aktif',
      message: 'Isi geminiApiKey di lib/config/secrets.dart lalu jalankan ulang aplikasi.',
    );
  }

  Widget _buildChat() {
    final failure = _failure;
    return Column(
      children: [
        const DisclaimerBanner(),
        const Padding(
          padding: EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: Text(
            'Jawaban dibuat oleh AI dan bisa keliru. Asisten tidak memberi saran medis atau keselamatan menyelam.',
            style: TextStyle(fontSize: 11),
          ),
        ),
        Expanded(
          child: _turns.isEmpty
              ? const StateMessage(
                  icon: Icons.smart_toy_outlined,
                  title: 'Tanya apa saja',
                  message: 'Contoh: kapan musim terbaik ke Raja Ampat, atau biota apa yang ada di Bunaken?',
                )
              : ListView.builder(
                  controller: _scroll,
                  padding: const EdgeInsets.all(12),
                  itemCount: _turns.length + (_sending || failure != null ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index < _turns.length) return _Bubble(turn: _turns[index]);
                    if (failure != null) {
                      return Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: InlineNotice(
                          icon: Icons.error_outline,
                          message: geminiFailureText(failure),
                          onRetry: _ask,
                        ),
                      );
                    }
                    return const Padding(
                      padding: EdgeInsets.all(8),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
                      ),
                    );
                  },
                ),
        ),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    minLines: 1,
                    maxLines: 3,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _send(),
                    decoration: const InputDecoration(hintText: 'Tulis pertanyaanmu'),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  tooltip: 'Kirim',
                  onPressed: _sending ? null : _send,
                  icon: const Icon(Icons.send),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _Bubble extends StatelessWidget {
  const _Bubble({required this.turn});

  final ChatTurn turn;

  @override
  Widget build(BuildContext context) {
    final fromUser = turn.fromUser;
    return Align(
      alignment: fromUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.all(12),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.8),
        decoration: BoxDecoration(
          color: fromUser ? AppColors.navy : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: fromUser ? null : Border.all(color: const Color(0x1F0B2545)),
        ),
        child: Text(
          turn.text,
          style: TextStyle(color: fromUser ? Colors.white : AppColors.textDark, height: 1.35),
        ),
      ),
    );
  }
}
