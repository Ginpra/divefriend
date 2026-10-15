import 'package:flutter/material.dart';

import 'package:divefriend/app_services.dart';
import 'package:divefriend/core/validators.dart';
import 'package:divefriend/features/auth/register_screen.dart';
import 'package:divefriend/features/home/home_screen.dart';
import 'package:divefriend/services/auth_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key, required this.services});

  final AppServices services;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;
  bool _canUseBiometric = false;

  @override
  void initState() {
    super.initState();
    widget.services.auth.canLoginWithBiometric().then((canUse) {
      if (mounted) setState(() => _canUseBiometric = canUse);
    });
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  void _goHome() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (_) => HomeScreen(services: widget.services),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      await widget.services.auth.login(
        _usernameController.text,
        _passwordController.text,
      );
      if (mounted) _goHome();
    } on AuthException catch (error) {
      if (mounted) _showMessage(error.message);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loginWithBiometric() async {
    final user = await widget.services.auth.loginWithBiometric();
    if (!mounted) return;
    if (user == null) {
      _showMessage('Verifikasi biometrik gagal atau dibatalkan');
      return;
    }
    _goHome();
  }

  void _openRegister() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => RegisterScreen(services: widget.services),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  const Icon(Icons.waves, size: 72, color: Color(0xFF13A89E)),
                  const SizedBox(height: 8),
                  const Text(
                    'DiveFriend',
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 24),
                  TextFormField(
                    controller: _usernameController,
                    decoration: const InputDecoration(labelText: 'Username'),
                    validator: validateRequired,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      suffixIcon: IconButton(
                        tooltip: 'Tampilkan/sembunyikan password',
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility
                              : Icons.visibility_off,
                        ),
                        onPressed: () =>
                            setState(() => _obscurePassword = !_obscurePassword),
                      ),
                    ),
                    validator: validateRequired,
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: _isLoading ? null : _submit,
                      child: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Masuk'),
                    ),
                  ),
                  if (_canUseBiometric)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: OutlinedButton.icon(
                        onPressed: _loginWithBiometric,
                        icon: const Icon(Icons.fingerprint),
                        label: const Text('Masuk dengan biometrik'),
                      ),
                    ),
                  TextButton(
                    onPressed: _openRegister,
                    child: const Text('Belum punya akun? Daftar'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
