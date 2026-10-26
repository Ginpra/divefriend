import 'package:flutter/material.dart';

import 'package:divefriend/core/app_theme.dart';

import 'package:divefriend/app_services.dart';
import 'package:divefriend/core/log_chain.dart';
import 'package:divefriend/core/log_stats.dart';
import 'package:divefriend/core/widgets/section_card.dart';
import 'package:divefriend/core/widgets/state_message.dart';
import 'package:divefriend/data/models/log_entry.dart';
import 'package:divefriend/features/logbook/log_entry_card.dart';
import 'package:divefriend/features/logbook/log_entry_form_screen.dart';
import 'package:divefriend/services/logbook_service.dart';

/// Logbook penyelaman seperti buku catatan dengan CRUD lengkap: lihat daftar, tambah, ubah, dan hapus.
/// Catatan terbaru di atas, ringkasan angka di bagian atas, dan tombol Cek Integritas memeriksa rantai hash.
class LogbookScreen extends StatefulWidget {
  const LogbookScreen({super.key, required this.services});

  final AppServices services;

  @override
  State<LogbookScreen> createState() => _LogbookScreenState();
}

class _LogbookScreenState extends State<LogbookScreen> {
  late Future<List<LogEntry>> _entriesFuture;
  ChainReport? _report;

  int? get _userId => widget.services.auth.currentUser?.id;

  @override
  void initState() {
    super.initState();
    _entriesFuture = _loadEntries();
  }

  Future<List<LogEntry>> _loadEntries() {
    final userId = _userId;
    if (userId == null) return Future.value(const <LogEntry>[]);
    return widget.services.logbook.entries(userId);
  }

  void _reload() {
    setState(() {
      _entriesFuture = _loadEntries();
      _report = null;
    });
  }

  Future<void> _openForm({LogEntry? existing}) async {
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => LogEntryFormScreen(services: widget.services, existing: existing),
      ),
    );
    if (saved == true) _reload();
  }

  Future<bool> _confirm({
    required String title,
    required String message,
    required String confirmLabel,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Batal'),
          ),
          FilledButton(
            key: const Key('confirm_action'),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(confirmLabel),
          ),
        ],
      ),
    );
    return result == true;
  }

  Future<void> _deleteEntry(LogEntry entry) async {
    final userId = _userId;
    if (userId == null) return;
    final confirmed = await _confirm(
      title: 'Hapus catatan #${entry.seq}?',
      message: 'Catatan penyelaman di ${entry.spotName} tanggal ${formatDisplayDate(entry.diveDate)} akan '
          'dihapus permanen. Nomor catatan sesudahnya bergeser otomatis.',
      confirmLabel: 'Hapus',
    );
    if (!confirmed || !mounted) return;
    try {
      await widget.services.logbook.deleteEntry(userId: userId, seq: entry.seq);
    } on LogbookException catch (error) {
      if (mounted) _showMessage(error.message);
      return;
    }
    if (!mounted) return;
    _showMessage('Catatan dihapus.');
    _reload();
  }

  Future<void> _resealChain() async {
    final userId = _userId;
    if (userId == null) return;
    final confirmed = await _confirm(
      title: 'Segel ulang rantai?',
      message: 'Semua catatan yang ada sekarang akan dianggap benar, lalu rantai hash dihitung ulang. '
          'Pakai ini hanya kalau kamu yakin isi catatan sekarang sudah benar.',
      confirmLabel: 'Segel ulang',
    );
    if (!confirmed || !mounted) return;
    await widget.services.logbook.resealChain(userId);
    if (!mounted) return;
    _showMessage('Rantai disegel ulang.');
    _reload();
  }

  Future<void> _verify() async {
    final userId = _userId;
    if (userId == null) return;
    final report = await widget.services.logbook.verify(userId);
    if (!mounted) return;
    setState(() {
      _report = report;
    });
  }

  Future<void> _simulateTampering() async {
    final userId = _userId;
    if (userId == null) return;
    final changed = await widget.services.logbook.simulateTampering(userId);
    if (!mounted) return;
    _showMessage(
      changed
          ? 'Catatan pertama dipalsukan. Tekan Cek Integritas untuk melihat hasilnya.'
          : 'Logbook masih kosong, tidak ada yang bisa dipalsukan.',
    );
    _reload();
  }

  Future<void> _restoreSimulation() async {
    final userId = _userId;
    if (userId == null) return;
    await widget.services.logbook.restoreSimulation(userId);
    if (!mounted) return;
    _showMessage('Simulasi dipulihkan. Catatan kembali seperti semula.');
    _reload();
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  void _onMenuSelected(String value) {
    switch (value) {
      case 'tamper':
        _simulateTampering();
      case 'restore':
        _restoreSimulation();
      case 'reseal':
        _resealChain();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Logbook'),
        actions: [
          PopupMenuButton<String>(
            tooltip: 'Menu demo',
            onSelected: _onMenuSelected,
            itemBuilder: (context) => const [
              PopupMenuItem(value: 'tamper', child: Text('Simulasi pemalsuan (demo)')),
              PopupMenuItem(value: 'restore', child: Text('Pulihkan simulasi')),
              PopupMenuItem(value: 'reseal', child: Text('Segel ulang rantai')),
            ],
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        key: const Key('add_entry'),
        onPressed: _openForm,
        icon: const Icon(Icons.add),
        label: const Text('Catatan baru'),
      ),
      body: FutureBuilder<List<LogEntry>>(
        future: _entriesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return StateMessage(
              icon: Icons.error_outline,
              title: 'Logbook gagal dimuat',
              message: 'Terjadi masalah saat membaca catatan di HP ini.',
              actionLabel: 'Coba lagi',
              onAction: _reload,
            );
          }
          return _buildList(snapshot.data ?? const <LogEntry>[]);
        },
      ),
    );
  }

  Widget _buildList(List<LogEntry> entries) {
    final brokenSeq = _report?.brokenSeq;
    return ListView(
      padding: EdgeInsets.fromLTRB(16, 16, 16, 96 + bottomInset(context)),
      children: [
        if (entries.isNotEmpty) _buildStatsCard(entries),
        _buildIntegrityCard(),
        if (entries.isEmpty)
          const Padding(
            padding: EdgeInsets.only(top: 24),
            child: StateMessage(
              icon: Icons.menu_book_outlined,
              title: 'Logbook masih kosong',
              message: 'Tekan Catatan baru untuk menulis penyelaman pertamamu.',
            ),
          )
        else
          for (final entry in entries.reversed)
            LogEntryCard(
              entry: entry,
              isBroken: entry.seq == brokenSeq,
              onEdit: () => _openForm(existing: entry),
              onDelete: () => _deleteEntry(entry),
            ),
      ],
    );
  }

  Widget _buildStatsCard(List<LogEntry> entries) {
    final stats = computeLogStats(entries);
    return SectionCard(
      icon: Icons.insights_outlined,
      title: 'Ringkasan',
      child: Wrap(
        spacing: 24,
        runSpacing: 8,
        children: [
          _Stat(label: 'Penyelaman', value: '${stats.diveCount}'),
          _Stat(label: 'Total waktu di dasar', value: formatDuration(stats.totalBottomMinutes)),
          _Stat(label: 'Terdalam', value: '${stats.deepestMeters} m'),
          _Stat(label: 'Spot berbeda', value: '${stats.distinctSpots}'),
        ],
      ),
    );
  }

  Widget _buildIntegrityCard() {
    final report = _report;
    final isValid = report?.isValid ?? true;
    final statusColor = isValid ? Colors.green.shade800 : Colors.red.shade700;
    return SectionCard(
      icon: report == null || isValid ? Icons.verified_user_outlined : Icons.gpp_bad_outlined,
      title: 'Integritas catatan',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            report == null
                ? 'Setiap catatan menyimpan hash catatan sebelumnya, jadi kalau satu catatan diubah, '
                    'rantainya putus dan bisa ketahuan. Tekan tombol di bawah untuk memeriksanya.'
                : describeChainReport(report),
            key: const Key('integrity_message'),
            textAlign: TextAlign.justify,
            style: TextStyle(
              height: 1.35,
              fontWeight: report == null ? FontWeight.normal : FontWeight.bold,
              color: report == null ? null : statusColor,
            ),
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            key: const Key('verify_chain'),
            onPressed: _verify,
            icon: const Icon(Icons.fact_check_outlined),
            label: const Text('Cek Integritas'),
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        Text(label, style: const TextStyle(fontSize: 11)),
      ],
    );
  }
}
