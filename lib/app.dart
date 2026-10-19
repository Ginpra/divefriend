import 'package:flutter/material.dart';

import 'package:divefriend/app_services.dart';
import 'package:divefriend/core/app_theme.dart';
import 'package:divefriend/features/auth/login_screen.dart';
import 'package:divefriend/features/home/home_screen.dart';

/// Widget akar aplikasi. Dipisah dari main.dart supaya tes bisa memakainya tanpa ikut memuat
/// lib/config/secrets.dart (file rahasia yang tidak ikut di-commit).
class DiveFriendApp extends StatelessWidget {
  const DiveFriendApp({
    super.key,
    required this.services,
    this.startLoggedIn = false,
  });

  final AppServices services;
  final bool startLoggedIn;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DiveFriend',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      home: startLoggedIn
          ? HomeScreen(services: services)
          : LoginScreen(services: services),
    );
  }
}
