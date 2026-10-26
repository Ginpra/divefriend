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

  Future<void> _send() => _sendText(_controller.text);

  Future<void> _sendText(String raw) async {
    final text = raw.trim();
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

  /// Pertanyaan contoh supaya pengguna tidak bingung mau bertanya apa. Ketukan langsung mengirimnya.
  static const List<String> _suggestions = [
    'Spot terbaik untuk pemula',
    'Spot paling dalam',
    'Bandingkan Komodo dan Raja Ampat',
    'Musim terbaik ke Raja Ampat',
    'Biota apa saja di Bunaken',
    'Tips umum sebelum diving',
  ];

  /// Tampilan awal dengan contoh pertanyaan. Dibuat bisa digulir supaya tidak overflow saat keyboard terbuka.
  Widget _buildEmptyState() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpace.xl),
      child: Column(
        children: [
          const SizedBox(height: AppSpace.lg),
          Container(
            width: 88,
            height: 88,
            decoration: const BoxDecoration(gradient: AppGradients.deepSea, shape: BoxShape.circle),
            child: const Icon(Icons.smart_toy_outlined, size: 44, color: AppColors.mint),
          ),
          const SizedBox(height: AppSpace.lg),
          Text('Tanya apa saja', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: AppSpace.sm),
          const Text(
            'Tanya spot terbaik, terdalam, musim, biota, atau tips umum. Pilih salah satu contoh di bawah, atau tulis sendiri.',
            textAlign: TextAlign.center,
            style: TextStyle(height: 1.5, color: AppColors.textMuted),
          ),
          const SizedBox(height: AppSpace.xl),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: AppSpace.sm,
            runSpacing: AppSpace.sm,
            children: [
              for (final suggestion in _suggestions)
                ActionChip(
                  label: Text(suggestion),
                  onPressed: _sending ? null : () => _sendText(suggestion),
                ),
            ],
          ),
        ],
      ),
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
        Padding(
          padding: const EdgeInsets.fromLTRB(AppSpace.lg, 0, AppSpace.lg, AppSpace.xs),
          child: Text(
            'Jawaban dibuat oleh AI dan bisa keliru. Tips keselamatan hanya bersifat umum, instruktur bersertifikat '
            'yang menentukan hal teknisnya. Asisten tidak memberi saran medis.',
            style: Theme.of(context).textTheme.labelSmall!.copyWith(color: AppColors.textMuted),
          ),
        ),
        Expanded(
          child: _turns.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  controller: _scroll,
                  padding: const EdgeInsets.all(AppSpace.md),
                  itemCount: _turns.length + (_sending || failure != null ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index < _turns.length) return _Bubble(turn: _turns[index]);
                    if (failure != null) {
                      return Padding(
                        padding: const EdgeInsets.only(top: AppSpace.sm),
                        child: InlineNotice(
                          icon: Icons.error_outline,
                          message: geminiFailureText(failure),
                          onRetry: _ask,
                        ),
                      );
                    }
                    return const _TypingBubble();
                  },
                ),
        ),
        if (_turns.isNotEmpty)
          SizedBox(
            height: 44,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: AppSpace.md),
              itemCount: _suggestions.length,
              separatorBuilder: (context, index) => const SizedBox(width: AppSpace.sm),
              itemBuilder: (context, index) => ActionChip(
                label: Text(_suggestions[index]),
                onPressed: _sending ? null : () => _sendText(_suggestions[index]),
              ),
            ),
          ),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(AppSpace.md, AppSpace.xs, AppSpace.md, AppSpace.sm),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    minLines: 1,
                    maxLines: 3,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _send(),
                    decoration: InputDecoration(
                      hintText: 'Tulis pertanyaanmu',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppRadius.button),
                        borderSide: const BorderSide(color: AppColors.line),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppRadius.button),
                        borderSide: const BorderSide(color: Color(0x4D0B2545)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppRadius.button),
                        borderSide: const BorderSide(color: AppColors.tealDeep, width: 2),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpace.sm),
                IconButton.filled(
                  tooltip: 'Kirim',
                  style: IconButton.styleFrom(
                    backgroundColor: AppColors.mint,
                    foregroundColor: AppColors.navy,
                    disabledBackgroundColor: const Color(0xFFD5DEE4),
                    minimumSize: const Size(52, 52),
                  ),
                  onPressed: _sending ? null : _send,
                  icon: const Icon(Icons.send_rounded),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// Lingkaran kecil berikon robot di samping jawaban asisten.
class _AssistantAvatar extends StatelessWidget {
  const _AssistantAvatar();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 32,
      height: 32,
      decoration: const BoxDecoration(gradient: AppGradients.deepSea, shape: BoxShape.circle),
      child: const Icon(Icons.smart_toy_outlined, size: 18, color: AppColors.mint),
    );
  }
}

/// Gelembung percakapan. Sudut dekat pengirim dibuat lancip sebagai ekor gelembung.
class _Bubble extends StatelessWidget {
  const _Bubble({required this.turn});

  final ChatTurn turn;

  @override
  Widget build(BuildContext context) {
    final fromUser = turn.fromUser;
    const round = Radius.circular(18);
    const tail = Radius.circular(4);
    final bubble = Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpace.lg, vertical: AppSpace.md),
      constraints: BoxConstraints(maxWidth: MediaQuery.sizeOf(context).width * 0.75),
      decoration: BoxDecoration(
        color: fromUser ? AppColors.navy : AppColors.surface,
        borderRadius: BorderRadius.only(
          topLeft: round,
          topRight: round,
          bottomLeft: fromUser ? round : tail,
          bottomRight: fromUser ? tail : round,
        ),
        border: fromUser ? null : Border.all(color: AppColors.line),
        boxShadow: fromUser ? null : AppShadows.soft,
      ),
      child: Text(
        turn.text,
        style: TextStyle(color: fromUser ? Colors.white : AppColors.textDark, height: 1.4),
      ),
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpace.xs),
      child: Row(
        mainAxisAlignment: fromUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!fromUser) ...[const _AssistantAvatar(), const SizedBox(width: AppSpace.sm)],
          Flexible(child: bubble),
        ],
      ),
    );
  }
}

/// Gelembung "sedang menjawab" selama menunggu balasan Gemini.
class _TypingBubble extends StatelessWidget {
  const _TypingBubble();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpace.xs),
      child: Row(
        children: [
          const _AssistantAvatar(),
          const SizedBox(width: AppSpace.sm),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: AppSpace.lg, vertical: AppSpace.md),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.line),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
                SizedBox(width: AppSpace.sm),
                Text('Asisten sedang menjawab', style: TextStyle(color: AppColors.textMuted)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
