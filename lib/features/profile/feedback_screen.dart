import 'package:flutter/material.dart';

import 'package:divefriend/app_services.dart';
import 'package:divefriend/core/app_theme.dart';
import 'package:divefriend/core/widgets/ocean_decor.dart';
import 'package:divefriend/core/formatters.dart';
import 'package:divefriend/core/validators.dart';
import 'package:divefriend/services/feedback_store.dart';

/// Saran & kesan mata kuliah PAM. Setiap kiriman masuk ke riwayat di bawah formulir
/// (disimpan lokal per pengguna), dan tiap catatan bisa dihapus.
class FeedbackScreen extends StatefulWidget {
  const FeedbackScreen({super.key, required this.services, this._store});

  final AppServices services;
  final FeedbackStore? _store;

  @override
  State<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends State<FeedbackScreen> {
  final _formKey = GlobalKey<FormState>();
  final _impressionController = TextEditingController();
  final _suggestionController = TextEditingController();
  late final FeedbackStore _store = widget._store ?? FeedbackStore();
  List<FeedbackEntry> _history = const [];

  int? get _userId => widget.services.auth.currentUser?.id;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  @override
  void dispose() {
    _impressionController.dispose();
    _suggestionController.dispose();
    super.dispose();
  }

  Future<void> _loadHistory() async {
    final userId = _userId;
    if (userId == null) return;
    final history = await _store.history(userId);
    if (!mounted) return;
    setState(() {
      _history = history;
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final userId = _userId;
    if (userId == null) return;
    final messenger = ScaffoldMessenger.of(context);
    await _store.add(
      userId,
      impression: _impressionController.text.trim(),
      suggestion: _suggestionController.text.trim(),
    );
    _impressionController.clear();
    _suggestionController.clear();
    await _loadHistory();
    messenger.showSnackBar(const SnackBar(content: Text('Saran dan kesan tersimpan')));
  }

  Future<void> _delete(FeedbackEntry entry) async {
    final userId = _userId;
    if (userId == null) return;
    await _store.remove(userId, entry.id);
    await _loadHistory();
  }

  String _formatStamp(DateTime time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '${formatDate(time)} $hour.$minute';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          const OceanHeader(
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Saran & Kesan',
                style: TextStyle(fontFamily: AppFonts.heading, fontSize: 30, color: Colors.white),
              ),
            ),
          ),
          Expanded(
            child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Form(
            key: _formKey,
            child: Column(
              children: [
                TextFormField(
                  controller: _impressionController,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    labelText: 'Kesan mata kuliah PAM',
                    alignLabelWithHint: true,
                  ),
                  validator: validateRequired,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _suggestionController,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    labelText: 'Saran mata kuliah PAM',
                    alignLabelWithHint: true,
                  ),
                  validator: validateRequired,
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(onPressed: _submit, child: const Text('Simpan')),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),
          const Text(
            'Riwayat',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.navy),
          ),
          const SizedBox(height: 8),
          if (_history.isEmpty)
            const Text('Belum ada catatan. Yang kamu simpan akan muncul di sini.')
          else
            for (final entry in _history)
              Card(
                key: ValueKey('feedback_${entry.id}'),
                margin: const EdgeInsets.only(bottom: 10),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 10, 4, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(_formatStamp(entry.createdAt), style: const TextStyle(fontSize: 12)),
                          ),
                          IconButton(
                            tooltip: 'Hapus catatan',
                            onPressed: () => _delete(entry),
                            icon: const Icon(Icons.delete_outline),
                          ),
                        ],
                      ),
                      const Text('Kesan', style: TextStyle(fontWeight: FontWeight.bold)),
                      Padding(
                        padding: const EdgeInsets.only(right: 10, bottom: 8),
                        child: Text(entry.impression),
                      ),
                      const Text('Saran', style: TextStyle(fontWeight: FontWeight.bold)),
                      Padding(
                        padding: const EdgeInsets.only(right: 10),
                        child: Text(entry.suggestion),
                      ),
                    ],
                  ),
                ),
              ),
        ],
            ),
          ),
        ],
      ),
    );
  }
}
