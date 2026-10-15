import 'package:flutter/material.dart';

import 'package:divefriend/app_services.dart';
import 'package:divefriend/core/widgets/disclaimer_banner.dart';
import 'package:divefriend/core/widgets/state_message.dart';
import 'package:divefriend/data/models/spot.dart';
import 'package:divefriend/features/home/spot_card.dart';
import 'package:divefriend/features/navigation/app_drawer.dart';
import 'package:divefriend/features/spot/spot_detail_screen.dart';

/// Beranda: daftar spot + pencarian + filter level.
/// Layar ini hanya bicara ke SpotRepository, tidak tahu data berasal dari mana.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.services});

  final AppServices services;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _searchController = TextEditingController();
  SpotLevel? _selectedLevel;
  late Future<List<Spot>> _spotsFuture;

  @override
  void initState() {
    super.initState();
    _spotsFuture = _fetchSpots();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<List<Spot>> _fetchSpots() {
    return widget.services.spots.getSpots(
      query: _searchController.text,
      level: _selectedLevel,
    );
  }

    void _reload() {
    setState(() {
      _spotsFuture = _fetchSpots();
    });
  }

  void _selectLevel(SpotLevel? level) {
    setState(() {
      _selectedLevel = level;
      _spotsFuture = _fetchSpots();
    });
  }

  void _openDetail(Spot spot) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => SpotDetailScreen(spot: spot)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('DiveFriend')),
      drawer: AppDrawer(services: widget.services),
      body: Column(
        children: [
          const DisclaimerBanner(),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: TextField(
              controller: _searchController,
              onChanged: (_) => _reload(),
              decoration: const InputDecoration(
                hintText: 'Cari nama spot atau wilayah',
                prefixIcon: Icon(Icons.search),
              ),
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                _buildChip(label: 'Semua', level: null),
                for (final level in SpotLevel.values)
                  _buildChip(label: level.label, level: level),
              ],
            ),
          ),
          Expanded(
            child: FutureBuilder<List<Spot>>(
              future: _spotsFuture,
              builder: _buildList,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChip({required String label, required SpotLevel? level}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: ChoiceChip(
        label: Text(label),
        selected: _selectedLevel == level,
        onSelected: (_) => _selectLevel(level),
      ),
    );
  }

  Widget _buildList(BuildContext context, AsyncSnapshot<List<Spot>> snapshot) {
    if (snapshot.connectionState == ConnectionState.waiting) {
      return const Center(child: CircularProgressIndicator());
    }
    if (snapshot.hasError) {
      return StateMessage(
        icon: Icons.error_outline,
        title: 'Gagal memuat spot',
        message: 'Terjadi kesalahan saat mengambil data.',
        actionLabel: 'Coba lagi',
        onAction: _reload,
      );
    }
    final spots = snapshot.data ?? const <Spot>[];
    if (spots.isEmpty) {
      return const StateMessage(
        icon: Icons.search_off,
        title: 'Spot tidak ditemukan',
        message: 'Coba kata kunci atau filter level yang lain.',
      );
    }
    return ListView.builder(
      itemCount: spots.length,
      itemBuilder: (context, index) {
        final spot = spots[index];
        return SpotCard(spot: spot, onTap: () => _openDetail(spot));
      },
    );
  }
}
