import 'package:flutter/material.dart';

import 'package:divefriend/app_services.dart';
import 'package:divefriend/core/validators.dart';
import 'package:divefriend/services/feedback_store.dart';

/// Saran & kesan mata kuliah PAM. Disimpan lokal per pengguna (shared_preferences)
/// dan muncul lagi saat layar dibuka, jadi bisa diubah kapan saja.
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
  bool _saved = false;

  int? get _userId => widget.services.auth.currentUser?.id;

  @override
  void initState() {
    super.initState();
    _loadSaved();
  }

  @override
  void dispose() {
    _impressionController.dispose();
    _suggestionController.dispose();
    super.dispose();
  }

  Future<void> _loadSaved() async {
    final userId = _userId;
    if (userId == null) return;
    final entry = await _store.load(userId);
    if (entry == null || !mounted) return;
    setState(() {
      _impressionController.text = entry.impression;
      _suggestionController.text = entry.suggestion;
      _saved = true;
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final userId = _userId;
    if (userId == null) return;
    final messenger = ScaffoldMessenger.of(context);
    await _store.save(
      userId,
      FeedbackEntry(
        impression: _impressionController.text.trim(),
        suggestion: _suggestionController.text.trim(),
      ),
    );
    if (!mounted) return;
    setState(() {
      _saved = true;
    });
    messenger.showSnackBar(const SnackBar(content: Text('Saran dan kesan tersimpan')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Saran & Kesan')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
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
                child: FilledButton(
                  onPressed: _submit,
                  child: Text(_saved ? 'Perbarui' : 'Simpan'),
                ),
              ),
              if (_saved)
                const Padding(
                  padding: EdgeInsets.only(top: 12),
                  child: Text('Sudah tersimpan di HP ini.', style: TextStyle(fontSize: 12)),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
