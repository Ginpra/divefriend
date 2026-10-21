import 'package:flutter/material.dart';

import 'package:divefriend/app_services.dart';
import 'package:divefriend/features/auth/login_screen.dart';
import 'package:divefriend/features/home/home_screen.dart';
import 'package:divefriend/features/navigation/features_screen.dart';
import 'package:divefriend/features/profile/feedback_screen.dart';
import 'package:divefriend/features/profile/profile_screen.dart';

/// Kerangka utama setelah login dengan bottom navigation, sesuai syarat tugas:
/// Beranda, Fitur (semua menu lain), Profil (ada foto), Saran & Kesan, dan Logout.
/// Logout bukan halaman: menekannya memunculkan konfirmasi lalu kembali ke layar login.
class MainShell extends StatefulWidget {
  const MainShell({super.key, required this.services});

  final AppServices services;

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  static const int _logoutIndex = 4;

  int _index = 0;

  // IndexedStack menyimpan semua halaman sekaligus, jadi pencarian dan posisi gulir Beranda tidak hilang
  // saat pengguna berpindah tab.
  late final List<Widget> _pages = [
    HomeScreen(services: widget.services),
    FeaturesScreen(services: widget.services),
    ProfileScreen(services: widget.services),
    FeedbackScreen(services: widget.services),
  ];

  Future<void> _confirmLogout() async {
    final navigator = Navigator.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Keluar dari akun?'),
        content: const Text('Kamu perlu login lagi untuk memakai DiveFriend.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await widget.services.auth.logout();
    navigator.pushAndRemoveUntil(
      MaterialPageRoute<void>(builder: (_) => LoginScreen(services: widget.services)),
      (route) => false,
    );
  }

  void _select(int index) {
    if (index == _logoutIndex) {
      _confirmLogout();
      return;
    }
    setState(() {
      _index = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _index, children: _pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: _select,
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Beranda'),
          NavigationDestination(icon: Icon(Icons.apps_outlined), selectedIcon: Icon(Icons.apps), label: 'Fitur'),
          NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: 'Profil'),
          NavigationDestination(icon: Icon(Icons.rate_review_outlined), selectedIcon: Icon(Icons.rate_review), label: 'Saran'),
          NavigationDestination(icon: Icon(Icons.logout), label: 'Logout'),
        ],
      ),
    );
  }
}
