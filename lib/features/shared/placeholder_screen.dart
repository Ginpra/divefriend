import 'package:flutter/material.dart';

import 'package:divefriend/core/widgets/state_message.dart';

/// Layar sementara untuk fitur yang dikerjakan di tahap berikutnya.
class PlaceholderScreen extends StatelessWidget {
  const PlaceholderScreen({super.key, required this.title, required this.stage});

  final String title;
  final int stage;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: StateMessage(
        icon: Icons.construction,
        title: 'Segera hadir',
        message: 'Fitur "$title" dikerjakan di Tahap $stage.',
      ),
    );
  }
}
