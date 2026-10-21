import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'package:divefriend/app_services.dart';
import 'package:divefriend/features/auth/login_screen.dart';
import 'package:divefriend/services/account_deleter.dart';

/// Profil: foto (dipilih dari galeri, disimpan di folder app, path-nya di SQLite)
/// dan saklar login biometrik.
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key, required this.services});

  final AppServices services;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _biometricAvailable = false;
  bool _biometricEnabled = false;

  @override
  void initState() {
    super.initState();
    _loadBiometricState();
  }

  Future<void> _loadBiometricState() async {
    final auth = widget.services.auth;
    final available = await auth.isBiometricAvailable();
    final enabled = await auth.isBiometricEnabled();
    if (!mounted) return;
    setState(() {
      _biometricAvailable = available;
      _biometricEnabled = enabled;
    });
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _pickPhoto() async {
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 800,
      imageQuality: 80,
    );
    if (picked == null) return;

    // Salin ke folder app dengan nama unik, supaya foto tetap ada walau file asli dihapus
    // dan gambar lama tidak tertahan di cache.
    final folder = await getApplicationDocumentsDirectory();
    final newPath = p.join(
      folder.path,
      'profile_${DateTime.now().millisecondsSinceEpoch}.jpg',
    );
    await File(picked.path).copy(newPath);

    final oldPath = widget.services.auth.currentUser?.photoPath;
    await widget.services.auth.setPhoto(newPath);
    if (oldPath != null) {
      final oldFile = File(oldPath);
      if (await oldFile.exists()) await oldFile.delete();
    }
    if (mounted) setState(() {});
  }

  Future<void> _toggleBiometric(bool turnOn) async {
    final auth = widget.services.auth;
    if (turnOn) {
      final success = await auth.enableBiometric();
      if (!success) {
        _showMessage('Verifikasi biometrik gagal atau dibatalkan');
        return;
      }
    } else {
      await auth.disableBiometric();
    }
    if (mounted) setState(() => _biometricEnabled = turnOn);
  }

  /// Meminta konfirmasi, lalu menghapus akun beserta seluruh datanya dan kembali ke layar login.
  Future<void> _deleteAccount() async {
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Hapus akun?'),
        content: const Text(
          'Akun beserta semua datanya akan dihapus permanen dari HP ini: foto profil, logbook, booking dan pengingatnya, '
          'saran dan kesan, skor kuis, serta koleksi biota. Tindakan ini tidak bisa dibatalkan.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Batal'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Ya, hapus akun'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await AccountDeleter(widget.services).deleteCurrentAccount();
    } catch (_) {
      messenger.showSnackBar(const SnackBar(content: Text('Akun gagal dihapus, coba lagi.')));
      return;
    }
    messenger.showSnackBar(const SnackBar(content: Text('Akun dan seluruh datanya sudah dihapus.')));
    navigator.pushAndRemoveUntil(
      MaterialPageRoute<void>(builder: (_) => LoginScreen(services: widget.services)),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = widget.services.auth.currentUser;
    final photoPath = user?.photoPath;

    return Scaffold(
      appBar: AppBar(title: const Text('Profil')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Center(
            child: ClipOval(
              child: SizedBox(
                width: 120,
                height: 120,
                child: photoPath == null
                    ? const _PhotoPlaceholder()
                    : Image.file(
                        File(photoPath),
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            const _PhotoPlaceholder(),
                      ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: Text(
              user?.name ?? '-',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ),
          Center(child: Text('@${user?.username ?? '-'}')),
          const SizedBox(height: 16),
          Center(
            child: FilledButton.icon(
              onPressed: _pickPhoto,
              icon: const Icon(Icons.photo_library),
              label: const Text('Ganti foto'),
            ),
          ),
          if (_biometricAvailable) ...[
            const SizedBox(height: 24),
            SwitchListTile(
              title: const Text('Login biometrik'),
              subtitle: const Text('Masuk dengan sidik jari/wajah di layar login'),
              value: _biometricEnabled,
              onChanged: _toggleBiometric,
            ),
          ],
          const SizedBox(height: 32),
          const Divider(),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: _deleteAccount,
            style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
            icon: const Icon(Icons.delete_forever_outlined),
            label: const Text('Hapus akun'),
          ),
        ],
      ),
    );
  }
}

class _PhotoPlaceholder extends StatelessWidget {
  const _PhotoPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.grey.shade300,
      child: const Icon(Icons.person, size: 64),
    );
  }
}
