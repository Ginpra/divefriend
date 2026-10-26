import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:divefriend/app_services.dart';
import 'package:divefriend/core/anchor_check.dart';
import 'package:divefriend/core/app_theme.dart';
import 'package:divefriend/core/log_chain.dart';
import 'package:divefriend/core/widgets/section_card.dart';
import 'package:divefriend/data/models/chain_anchor.dart';
import 'package:divefriend/services/anchor_store.dart';
import 'package:divefriend/services/blockchain_service.dart';

/// Bukti blockchain untuk logbook. Hash catatan terbaru ditulis ke jaringan publik Sepolia (uji coba),
/// lalu "Cek ke blockchain" membandingkan hash di sana dengan logbook di HP. Karena hash di blockchain
/// tidak bisa diubah, perubahan yang disembunyikan dengan "Segel ulang rantai" tetap ketahuan.
class AnchorScreen extends StatefulWidget {
  const AnchorScreen({super.key, required this.services});

  final AppServices services;

  @override
  State<AnchorScreen> createState() => _AnchorScreenState();
}

class _AnchorScreenState extends State<AnchorScreen> {
  final _store = AnchorStore();
  List<ChainAnchor> _anchors = const [];
  bool _loading = true;
  bool _busy = false;
  String? _message;

  int get _userId => widget.services.auth.currentUser?.id ?? -1;
  BlockchainService? get _blockchain => widget.services.blockchain;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final anchors = await _store.all(_userId);
    if (!mounted) return;
    setState(() {
      _anchors = anchors;
      _loading = false;
    });
    _refreshPending();
  }

  /// Menanyakan ke blockchain apakah jangkar yang masih menunggu sudah masuk blok. Gagal jaringan diabaikan,
  /// nanti dicoba lagi saat layar dibuka atau tombol segarkan ditekan.
  Future<void> _refreshPending() async {
    final blockchain = _blockchain;
    if (blockchain == null || !blockchain.isConfigured) return;
    var changed = false;
    for (final anchor in _anchors.where((anchor) => !anchor.confirmed)) {
      try {
        if (await blockchain.stateOf(anchor.txHash) == TxState.confirmed) {
          await _store.markConfirmed(_userId, anchor.txHash);
          changed = true;
        }
      } catch (_) {
        // Tidak ada internet atau node sedang sibuk, biarkan statusnya Menunggu.
      }
    }
    if (changed) {
      final anchors = await _store.all(_userId);
      if (!mounted) return;
      setState(() {
        _anchors = anchors;
      });
    }
  }

  String _describe(Object error) {
    final text = error.toString();
    final short = text.length > 160 ? '${text.substring(0, 160)}...' : text;
    return 'Gagal: $short';
  }

  Future<void> _anchorNow() async {
    final blockchain = _blockchain;
    if (blockchain == null || !blockchain.isConfigured) return;
    setState(() {
      _busy = true;
      _message = null;
    });
    try {
      final entries = await widget.services.logbook.entries(_userId);
      if (entries.isEmpty) {
        _setMessage('Logbook masih kosong, tambahkan catatan penyelaman dulu.');
        return;
      }
      if (!verifyChain(entries).isValid) {
        _setMessage('Rantai logbook sedang rusak, jadi tidak dijangkarkan. Cek Integritas di Logbook dulu.');
        return;
      }
      final head = entries.last.hash;
      if (_anchors.isNotEmpty && _anchors.last.headHash == head) {
        _setMessage('Logbook yang sekarang sudah dijangkarkan.');
        return;
      }
      final txHash = await blockchain.sendPayload(buildAnchorPayload(head));
      final anchor = ChainAnchor(
        headHash: head,
        entryCount: entries.length,
        txHash: txHash,
        createdAt: DateTime.now().toUtc().toIso8601String(),
      );
      await _store.add(_userId, anchor);
      final anchors = await _store.all(_userId);
      if (!mounted) return;
      setState(() {
        _anchors = anchors;
        _message = 'Terkirim. Konfirmasi di blockchain butuh sekitar setengah menit, lalu tekan segarkan.';
      });
    } catch (error) {
      _setMessage(_describe(error));
    } finally {
      if (mounted) {
        setState(() {
          _busy = false;
        });
      }
    }
  }

  void _setMessage(String message) {
    if (!mounted) return;
    setState(() {
      _message = message;
    });
  }

  Future<void> _verify(ChainAnchor anchor) async {
    final blockchain = _blockchain;
    if (blockchain == null || !blockchain.isConfigured) return;
    setState(() {
      _busy = true;
    });
    String result;
    try {
      final state = await blockchain.stateOf(anchor.txHash);
      if (state == TxState.pending) {
        result = 'Transaksi belum masuk blok. Tunggu sebentar lalu cek lagi.';
      } else if (state == TxState.failed) {
        result = 'Transaksi gagal di blockchain, jadi jangkar ini tidak berlaku. Jangkarkan ulang.';
      } else {
        await _store.markConfirmed(_userId, anchor.txHash);
        final payload = await blockchain.payloadOf(anchor.txHash);
        final entries = await widget.services.logbook.entries(_userId);
        result = _verdictText(verifyAnchor(anchor: anchor, entries: entries, onChainPayload: payload));
      }
    } catch (error) {
      result = _describe(error);
    }
    final anchors = await _store.all(_userId);
    if (!mounted) return;
    setState(() {
      _busy = false;
      _anchors = anchors;
    });
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Hasil pengecekan'),
        content: Text(result),
        actions: [
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(), child: const Text('Tutup')),
        ],
      ),
    );
  }

  String _verdictText(AnchorVerdict verdict) {
    return switch (verdict) {
      AnchorVerdict.verified =>
        'Cocok. Hash di blockchain sama dengan logbook di HP, jadi catatan sampai titik ini tidak berubah.',
      AnchorVerdict.notOnChain => 'Transaksi tidak ditemukan di blockchain.',
      AnchorVerdict.payloadMismatch => 'Isi transaksi di blockchain tidak sama dengan jangkar ini.',
      AnchorVerdict.localChainBroken =>
        'Tidak cocok. Rantai logbook di HP rusak, ada catatan yang diubah tanpa menghitung ulang hash.',
      AnchorVerdict.localHistoryChanged =>
        'Tidak cocok. Logbook di HP berbeda dari saat dijangkarkan (ada catatan yang diubah, disisipkan, '
            'atau dihapus). Kalau perubahan itu memang kamu lakukan, jangkarkan ulang untuk titik baru.',
    };
  }

  Future<void> _copyLink(ChainAnchor anchor) async {
    final blockchain = _blockchain;
    if (blockchain == null) return;
    await Clipboard.setData(ClipboardData(text: blockchain.explorerUrl(anchor.txHash)));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Link Etherscan disalin, buka di browser untuk melihat buktinya.')),
    );
  }

  /// Waktu lokal untuk tampilan, contoh "2026-10-27 14:05".
  String _formatTime(String isoUtc) {
    final time = DateTime.parse(isoUtc).toLocal();
    String two(int value) => value.toString().padLeft(2, '0');
    return '${time.year}-${two(time.month)}-${two(time.day)} ${two(time.hour)}:${two(time.minute)}';
  }

  String _shortHash(String hash) => hash.length <= 14 ? hash : '${hash.substring(0, 8)}...${hash.substring(hash.length - 6)}';

  @override
  Widget build(BuildContext context) {
    final blockchain = _blockchain;
    final configured = blockchain != null && blockchain.isConfigured;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bukti blockchain'),
        actions: [
          IconButton(
            tooltip: 'Segarkan status',
            onPressed: configured && !_busy ? _refreshPending : null,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: EdgeInsets.fromLTRB(AppSpace.lg, AppSpace.lg, AppSpace.lg, AppSpace.lg + bottomInset(context)),
              children: [
                SectionCard(
                  icon: Icons.link,
                  title: 'Jangkar ke blockchain',
                  badge: 'Jaringan uji',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Hash catatan logbook terbaru ditulis ke blockchain publik Ethereum Sepolia. Yang ditulis hanya '
                        'hash, bukan isi catatan. Setelah tercatat di sana, hash itu tidak bisa diubah siapa pun, '
                        'jadi perubahan logbook sesudahnya akan ketahuan walau rantai di HP disegel ulang.',
                        textAlign: TextAlign.justify,
                      ),
                      const SizedBox(height: AppSpace.md),
                      if (!configured)
                        const Text(
                          'Fitur ini belum aktif. Isi sepoliaRpcUrl dan sepoliaPrivateKey di lib/config/secrets.dart.',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: configured && !_busy ? _anchorNow : null,
                          icon: _busy
                              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                              : const Icon(Icons.upload_outlined),
                          label: const Text('Jangkarkan logbook sekarang'),
                        ),
                      ),
                      if (_message != null) ...[
                        const SizedBox(height: AppSpace.sm),
                        Text(_message!, key: const Key('anchor_message')),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: AppSpace.md),
                if (_anchors.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(AppSpace.lg),
                    child: Text('Belum ada jangkar. Tekan tombol di atas untuk membuat yang pertama.', textAlign: TextAlign.center),
                  )
                else
                  for (var i = _anchors.length - 1; i >= 0; i--) _buildAnchorCard(i, _anchors[i], configured),
              ],
            ),
    );
  }

  Widget _buildAnchorCard(int index, ChainAnchor anchor, bool configured) {
    final statusText = anchor.confirmed ? 'Terkonfirmasi' : 'Menunggu';
    final statusColor = anchor.confirmed ? AppColors.tealDeep : const Color(0xFF8A5A00);
    final statusBackground = anchor.confirmed ? AppColors.mintSoft : const Color(0xFFFFF3CC);
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpace.md),
      padding: const EdgeInsets.all(AppSpace.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: AppColors.line),
        boxShadow: AppShadows.soft,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text('Jangkar #${index + 1}', style: Theme.of(context).textTheme.titleMedium),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: statusBackground, borderRadius: BorderRadius.circular(AppRadius.chip)),
                child: Text(
                  statusText,
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: statusColor),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpace.xs),
          Text('${anchor.entryCount} catatan, ${_formatTime(anchor.createdAt)}', style: Theme.of(context).textTheme.bodySmall),
          Text('Transaksi ${_shortHash(anchor.txHash)}', style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: AppSpace.sm),
          Wrap(
            spacing: AppSpace.sm,
            children: [
              OutlinedButton.icon(
                onPressed: configured && !_busy ? () => _verify(anchor) : null,
                icon: const Icon(Icons.verified_outlined),
                label: const Text('Cek ke blockchain'),
              ),
              TextButton.icon(
                onPressed: () => _copyLink(anchor),
                icon: const Icon(Icons.copy),
                label: const Text('Salin link Etherscan'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
