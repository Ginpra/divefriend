import 'package:flutter/material.dart';

import 'package:divefriend/app_services.dart';
import 'package:divefriend/core/app_theme.dart';
import 'package:divefriend/data/local/app_database.dart';
import 'package:divefriend/data/repositories/sqlite_spot_repository.dart';
import 'package:divefriend/data/repositories/sqlite_user_repository.dart';
import 'package:divefriend/features/auth/login_screen.dart';
import 'package:divefriend/features/home/home_screen.dart';
import 'package:divefriend/services/auth_service.dart';
import 'package:divefriend/services/biometric_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final spotRepository = SqliteSpotRepository(AppDatabase.instance);
  await spotRepository.ensureSeeded();

  final services = AppServices(
    spots: spotRepository,
    auth: AuthService(SqliteUserRepository(AppDatabase.instance), BiometricService()),
  );

  // Kalau session masih ada, langsung ke Beranda tanpa login ulang.
  final savedUser = await services.auth.restoreSession();
  runApp(DiveFriendApp(services: services, startLoggedIn: savedUser != null));
}

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
