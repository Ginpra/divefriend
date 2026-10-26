import 'dart:io';

import 'package:flutter/material.dart';

import 'package:divefriend/core/app_theme.dart';
import 'package:divefriend/core/widgets/ocean_decor.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'package:divefriend/app_services.dart';
import 'package:divefriend/features/auth/login_screen.dart';
import 'package:divefriend/features/preferences/preference_screen.dart';
import 'package:divefriend/features/preferences/user_level_badge.dart';
import 'package:divefriend/services/preference_store.dart';
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
  UserPreference? _preference;

  @override
  void initState() {
    super.initState();
    _loadBiometricState();
    _loadPreference();
  }

  Future<void> _loadPreference() async {
    final user = widget.services.auth.currentUser;
    if (user == null) return;
    final loaded = await PreferenceStore().load(user.id);
    if (!mounted) return;
    setState(() => _preference = loaded);
  }

  Future<void> _openPreferences() async {
    await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => PreferenceScreen(services: widget.services),
      ),
    );
    if (!mounted) return;
    await _loadPreference();
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
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          OceanHeader(
            child: Column(
              children: [
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Profil',
                    style: TextStyle(
                      fontFamily: AppFonts.heading,
                      fontSize: 22,
                      color: AppColors.mint,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpace.lg),
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: ClipOval(
                    child: SizedBox(
                      width: 112,
                      height: 112,
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
                const SizedBox(height: AppSpace.md),
                Text(
                  user?.name ?? '-',
                  style: const TextStyle(
                    fontFamily: AppFonts.heading,
                    fontSize: 26,
                    color: Colors.white,
                  ),
                ),
                Text(
                  '@${user?.username ?? '-'}',
                  style: const TextStyle(color: Colors.white),
                ),
                if (_preference != null) ...[
                  const SizedBox(height: AppSpace.md),
                  UserLevelBadge(level: _preference!.level, onDark: true),
                ],
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(AppSpace.xl),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                FilledButton.icon(
                  onPressed: _pickPhoto,
                  icon: const Icon(Icons.photo_library),
                  label: const Text('Ganti foto'),
                ),
                const SizedBox(height: AppSpace.xl),
                Card(
                  clipBehavior: Clip.antiAlias,
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: AppSpace.lg,
                      vertical: AppSpace.xs,
                    ),
                    leading: const CircleAvatar(
                      backgroundColor: AppColors.mintSoft,
                      child: Icon(Icons.auto_awesome, color: AppColors.tealDeep),
                    ),
                    title: const Text('Preferensi selam'),
                    subtitle: Text(
                      _preference == null
                          ? 'Belum diisi. Isi kuesioner agar spot direkomendasikan sesuai levelmu.'
                          : 'Level ${_preference!.level.label}. Ketuk untuk mengisi ulang.',
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: _openPreferences,
                  ),
                ),
                if (_biometricAvailable) ...[
                  const SizedBox(height: AppSpace.xl),
                  Card(
                    child: SwitchListTile(
                      title: const Text('Login biometrik'),
                      subtitle: const Text('Masuk dengan sidik jari/wajah di layar login'),
                      value: _biometricEnabled,
                      onChanged: _toggleBiometric,
                    ),
                  ),
                ],
                const SizedBox(height: AppSpace.xxl),
                const Divider(),
                const SizedBox(height: AppSpace.sm),
                OutlinedButton.icon(
                  onPressed: _deleteAccount,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFFB3261E),
                    side: const BorderSide(color: Color(0xFFB3261E)),
                  ),
                  icon: const Icon(Icons.delete_forever_outlined),
                  label: const Text('Hapus akun'),
                ),
              ],
            ),
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
      color: AppColors.mintSoft,
      child: const Icon(Icons.person, size: 64, color: AppColors.tealDeep),
    );
  }
}
