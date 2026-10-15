import 'package:flutter/material.dart';

/// Profil dengan gambar. Gambar dibaca dari assets/images/profil.jpg bila ada;
/// bila belum ada, tampil ikon cadangan (aplikasi tidak error).
/// Nama dan username masih dummy; diambil dari session di Tahap 2.
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  static const String _profileImageAsset = 'assets/images/profil.jpg';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profil')),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipOval(
              child: SizedBox(
                width: 120,
                height: 120,
                child: Image.asset(
                  _profileImageAsset,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    color: Colors.grey.shade300,
                    child: const Icon(Icons.person, size: 64),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Pengguna Dummy',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            const Text('@pengguna'),
          ],
        ),
      ),
    );
  }
}
