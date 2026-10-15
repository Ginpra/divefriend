import 'package:flutter/material.dart';

import 'package:divefriend/core/validators.dart';

/// Tahap 1: tampilan + validasi form saja. Penyimpanan ke tabel users di Tahap 2.
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  String? _validateConfirm(String? value) {
    if (value != _passwordController.text) {
      return 'Konfirmasi password tidak sama';
    }
    return null;
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final navigator = Navigator.of(context);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Form valid. Akun asli dibuat di Tahap 2.')),
    );
    navigator.pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Daftar')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Nama lengkap'),
                validator: validateRequired,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _usernameController,
                decoration: const InputDecoration(labelText: 'Username'),
                validator: validateRequired,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Password',
                  helperText: 'Minimal $minPasswordLength karakter',
                ),
                validator: validateNewPassword,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _confirmController,
                obscureText: true,
                decoration:
                    const InputDecoration(labelText: 'Konfirmasi password'),
                validator: _validateConfirm,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _submit,
                  child: const Text('Daftar'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
