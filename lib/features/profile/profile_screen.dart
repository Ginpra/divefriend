import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'package:divefriend/app_services.dart';

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
