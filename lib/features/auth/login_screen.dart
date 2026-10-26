import 'package:flutter/material.dart';

import 'package:divefriend/app_services.dart';
import 'package:divefriend/core/app_theme.dart';
import 'package:divefriend/core/validators.dart';
import 'package:divefriend/core/widgets/app_logo.dart';
import 'package:divefriend/core/widgets/ocean_decor.dart';
import 'package:divefriend/features/auth/register_screen.dart';
import 'package:divefriend/features/navigation/main_shell.dart';
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
        builder: (_) => MainShell(services: widget.services),
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
      body: SingleChildScrollView(
        child: Column(
          children: [
            Stack(
              children: [
                const OceanHeader(
                  bottomRadius: 0,
                  bottomPadding: 56,
                  child: Column(
                    children: [
                      SizedBox(height: AppSpace.lg),
                      AppLogo(size: 88),
                      SizedBox(height: AppSpace.md),
                      Text(
                        'DiveFriend',
                        style: TextStyle(
                          fontFamily: AppFonts.heading,
                          fontSize: 38,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(height: AppSpace.sm),
                      Text(
                        'Temukan spot selam di perairan Indonesia, lengkap dengan kondisi laut dan harga simulasi.',
                        textAlign: TextAlign.center,
                        style: TextStyle(height: 1.5, color: Colors.white),
                      ),
                    ],
                  ),
                ),
                const Positioned(left: 0, right: 0, bottom: 0, child: WaveEdge()),
              ],
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(AppSpace.xl, 0, AppSpace.xl, AppSpace.xl),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    TextFormField(
                      controller: _usernameController,
                      decoration: const InputDecoration(
                        labelText: 'Username',
                        prefixIcon: Icon(Icons.person_outline),
                      ),
                      validator: validateRequired,
                    ),
                    const SizedBox(height: AppSpace.lg),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      decoration: InputDecoration(
                        labelText: 'Password',
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          tooltip: 'Tampilkan/sembunyikan password',
                          icon: Icon(
                            _obscurePassword ? Icons.visibility : Icons.visibility_off,
                          ),
                          onPressed: () =>
                              setState(() => _obscurePassword = !_obscurePassword),
                        ),
                      ),
                      validator: validateRequired,
                    ),
                    const SizedBox(height: AppSpace.xl),
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
                        padding: const EdgeInsets.only(top: AppSpace.md),
                        child: SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: _loginWithBiometric,
                            icon: const Icon(Icons.fingerprint),
                            label: const Text('Masuk dengan biometrik'),
                          ),
                        ),
                      ),
                    const SizedBox(height: AppSpace.sm),
                    TextButton(
                      onPressed: _openRegister,
                      child: const Text('Belum punya akun? Daftar'),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
