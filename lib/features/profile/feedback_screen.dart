import 'package:flutter/material.dart';

import 'package:divefriend/core/validators.dart';

/// Saran & kesan mata kuliah PAM. Tahap 1: form saja, belum disimpan.
/// Penyimpanan dibuat setelah database lokal siap (Tahap 2).
class FeedbackScreen extends StatefulWidget {
  const FeedbackScreen({super.key});

  @override
  State<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends State<FeedbackScreen> {
  final _formKey = GlobalKey<FormState>();
  final _impressionController = TextEditingController();
  final _suggestionController = TextEditingController();

  @override
  void dispose() {
    _impressionController.dispose();
    _suggestionController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Belum disimpan: penyimpanan menyusul setelah database siap.'),
      ),
    );
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
                  child: const Text('Simpan'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
