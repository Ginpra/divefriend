import 'package:flutter/material.dart';

import 'package:divefriend/app_services.dart';
import 'package:divefriend/core/log_chain.dart';
import 'package:divefriend/core/widgets/section_card.dart';
import 'package:divefriend/core/widgets/state_message.dart';
import 'package:divefriend/data/models/log_entry.dart';
import 'package:divefriend/features/logbook/log_entry_card.dart';
import 'package:divefriend/features/logbook/log_entry_form_screen.dart';

/// Logbook penyelaman seperti buku catatan. Catatan terbaru di atas, tombol Cek Integritas
/// memeriksa seluruh rantai hash, dan catatan baru hanya bisa ditambah (tidak bisa diubah atau dihapus).
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

  Future<void> _addEntry() async {
    final added = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => LogEntryFormScreen(services: widget.services),
      ),
    );
    if (added == true) _reload();
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
    if (value == 'tamper') {
      _simulateTampering();
    } else {
      _restoreSimulation();
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
            ],
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        key: const Key('add_entry'),
        onPressed: _addEntry,
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
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
      children: [
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
            LogEntryCard(entry: entry, isBroken: entry.seq == brokenSeq),
      ],
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
