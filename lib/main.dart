import 'package:flutter/material.dart';

import 'package:divefriend/core/app_theme.dart';
import 'package:divefriend/data/repositories/dummy_spot_repository.dart';
import 'package:divefriend/data/repositories/spot_repository.dart';
import 'package:divefriend/features/auth/login_screen.dart';

void main() {
  // Satu-satunya tempat sumber data dipilih. Tahap 3 mengganti ini ke repository SQLite.
  runApp(DiveFriendApp(spotRepository: DummySpotRepository()));
}

class DiveFriendApp extends StatelessWidget {
  const DiveFriendApp({super.key, required this.spotRepository});

  final SpotRepository spotRepository;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DiveFriend',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      home: LoginScreen(spotRepository: spotRepository),
    );
  }
}
