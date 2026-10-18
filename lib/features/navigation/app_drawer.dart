import 'package:flutter/material.dart';

import 'package:divefriend/app_services.dart';
import 'package:divefriend/core/app_theme.dart';
import 'package:divefriend/features/converter/converter_screen.dart';
import 'package:divefriend/features/direction/spot_picker_screen.dart';
import 'package:divefriend/features/auth/login_screen.dart';
import 'package:divefriend/features/profile/feedback_screen.dart';
import 'package:divefriend/features/profile/profile_screen.dart';
import 'package:divefriend/features/shared/placeholder_screen.dart';

class _FutureFeature {
  const _FutureFeature(this.icon, this.title, this.stage);

  final IconData icon;
  final String title;
  final int stage;
}

/// Menu navigasi utama: fitur mendatang, Profil, Saran & Kesan, Logout.
class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key, required this.services});

  final AppServices services;

  static const List<_FutureFeature> _futureFeatures = [
    _FutureFeature(Icons.menu_book, 'Logbook', 6),
    _FutureFeature(Icons.sports_esports, 'Game', 9),
    _FutureFeature(Icons.smart_toy, 'Asisten AI', 9),
    _FutureFeature(Icons.event_available, 'Booking', 8),
    _FutureFeature(Icons.shopping_bag, 'Produk', 8),
  ];

  void _openPage(BuildContext context, Widget page) {
    final navigator = Navigator.of(context);
    navigator.pop();
    navigator.push(MaterialPageRoute<void>(builder: (_) => page));
  }

  Future<void> _logout(BuildContext context) async {
    final navigator = Navigator.of(context);
    await services.auth.logout();
    navigator.pushAndRemoveUntil(
      MaterialPageRoute<void>(builder: (_) => LoginScreen(services: services)),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = services.auth.currentUser;

    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          Container(
            color: AppColors.navy,
            padding: const EdgeInsets.fromLTRB(16, 48, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.waves, color: Colors.white, size: 36),
                const SizedBox(height: 8),
                Text(
                  user?.name ?? 'DiveFriend',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (user != null)
                  Text(
                    '@${user.username}',
                    style: const TextStyle(color: Colors.white70),
                  ),
              ],
            ),
          ),
          ListTile(
            leading: const Icon(Icons.home),
            title: const Text('Beranda'),
            onTap: () => Navigator.of(context).pop(),
          ),
          ListTile(
            leading: const Icon(Icons.explore),
            title: const Text('Arah ke Spot'),
            onTap: () => _openPage(context, SpotPickerScreen(services: services)),
          ),
          ListTile(
            leading: const Icon(Icons.currency_exchange),
            title: const Text('Konversi'),
            onTap: () => _openPage(context, ConverterScreen(services: services)),
          ),
          for (final feature in _futureFeatures)
            ListTile(
              leading: Icon(feature.icon),
              title: Text(feature.title),
              onTap: () => _openPage(
                context,
                PlaceholderScreen(title: feature.title, stage: feature.stage),
              ),
            ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.person),
            title: const Text('Profil'),
            onTap: () => _openPage(context, ProfileScreen(services: services)),
          ),
          ListTile(
            leading: const Icon(Icons.rate_review),
            title: const Text('Saran & Kesan'),
            onTap: () => _openPage(context, const FeedbackScreen()),
          ),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Logout'),
            onTap: () => _logout(context),
          ),
        ],
      ),
    );
  }
}
