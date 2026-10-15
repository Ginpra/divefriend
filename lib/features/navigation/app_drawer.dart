import 'package:flutter/material.dart';

import 'package:divefriend/core/app_theme.dart';
import 'package:divefriend/data/repositories/spot_repository.dart';
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
  const AppDrawer({super.key, required this.spotRepository});

  final SpotRepository spotRepository;

  static const List<_FutureFeature> _futureFeatures = [
    _FutureFeature(Icons.currency_exchange, 'Konversi', 4),
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

  void _logout(BuildContext context) {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute<void>(
        builder: (_) => LoginScreen(spotRepository: spotRepository),
      ),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          Container(
            color: AppColors.navy,
            padding: const EdgeInsets.fromLTRB(16, 48, 16, 16),
            child: const Row(
              children: [
                Icon(Icons.waves, color: Colors.white, size: 36),
                SizedBox(width: 12),
                Text(
                  'DiveFriend',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          ListTile(
            leading: const Icon(Icons.home),
            title: const Text('Beranda'),
            onTap: () => Navigator.of(context).pop(),
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
            onTap: () => _openPage(context, const ProfileScreen()),
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
