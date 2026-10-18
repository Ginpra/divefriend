import 'package:flutter/material.dart';

import 'package:divefriend/app_services.dart';
import 'package:divefriend/core/widgets/state_message.dart';
import 'package:divefriend/data/models/spot.dart';
import 'package:divefriend/features/direction/direction_screen.dart';

/// Daftar spot untuk dipilih sebagai tujuan, dibuka dari menu navigasi.
/// (Dari Detail Spot, tombol "Arah ke Spot" langsung membuka layar arah tanpa lewat sini.)
class SpotPickerScreen extends StatelessWidget {
  const SpotPickerScreen({super.key, required this.services});

  final AppServices services;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pilih spot tujuan')),
      body: FutureBuilder<List<Spot>>(
        future: services.spots.getSpots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final spots = snapshot.data;
          if (snapshot.hasError || spots == null) {
            return const StateMessage(
              icon: Icons.error_outline,
              title: 'Daftar spot gagal dimuat',
              message: 'Tutup layar ini lalu coba lagi.',
            );
          }
          return ListView.separated(
            itemCount: spots.length,
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final spot = spots[index];
              return ListTile(
                leading: const Icon(Icons.place_outlined),
                title: Text(spot.name),
                subtitle: Text(spot.region),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => DirectionScreen(spot: spot, services: services),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
