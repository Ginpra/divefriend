import 'package:flutter/material.dart';

import 'package:divefriend/app_services.dart';
import 'package:divefriend/core/app_theme.dart';
import 'package:divefriend/core/level_classifier.dart';
import 'package:divefriend/core/widgets/disclaimer_banner.dart';
import 'package:divefriend/core/widgets/ocean_decor.dart';
import 'package:divefriend/core/widgets/state_message.dart';
import 'package:divefriend/data/models/spot.dart';
import 'package:divefriend/features/home/spot_card.dart';
import 'package:divefriend/features/preferences/preference_screen.dart';
import 'package:divefriend/features/spot/spot_detail_screen.dart';
import 'package:divefriend/services/preference_store.dart';
import 'package:divefriend/services/spot_sync_service.dart';

/// Beranda: daftar spot + pencarian + filter level.
/// Layar ini hanya bicara ke SpotRepository, tidak tahu data berasal dari mana. Saat dibuka pertama
/// kali ia menyinkronkan data spot dari Supabase (satu arah, online ke lokal), dan tombol refresh
/// di bar atas menjalankannya lagi.
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
  SyncResult? _syncResult;
  bool _syncing = false;
  UserPreference? _preference;
  bool _preferenceLoaded = false;
  bool _recommendMode = false;
  Map<String, SpotRecommendation> _recommendations = const {};

  @override
  void initState() {
    super.initState();
    _spotsFuture = _fetchSpots();
    _loadPreference();
    // Sinkronisasi otomatis hanya sekali per pembukaan aplikasi, kalau sudah pernah hasilnya dipakai ulang.
    final previous = widget.services.sync.lastResult;
    if (previous == null) {
      _syncing = true;
      _runSync();
    } else {
      _syncResult = previous;
    }
  }

  Future<void> _runSync() async {
    final result = await widget.services.sync.sync();
    if (!mounted) return;
    setState(() {
      _syncing = false;
      _syncResult = result;
      if (result.isSuccess) _spotsFuture = _fetchSpots();
    });
  }

  void _syncAgain() {
    setState(() {
      _syncing = true;
    });
    _runSync();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<List<Spot>> _fetchSpots() async {
    final preference = _preference;
    if (_recommendMode && preference != null) {
      final all = await widget.services.spots.getSpots(query: _searchController.text);
      final recommendations = recommendSpots(
        spots: all,
        userLevel: preference.level,
        interests: preference.interests,
      );
      _recommendations = {for (final item in recommendations) item.spot.id: item};
      return [for (final item in recommendations) item.spot];
    }
    _recommendations = const {};
    return widget.services.spots.getSpots(
      query: _searchController.text,
      level: _selectedLevel,
    );
  }

  Future<void> _loadPreference() async {
    final user = widget.services.auth.currentUser;
    UserPreference? loaded;
    if (user != null) loaded = await PreferenceStore().load(user.id);
    if (!mounted) return;
    setState(() {
      _preference = loaded;
      _preferenceLoaded = true;
      if (loaded == null) _recommendMode = false;
      if (_recommendMode) _spotsFuture = _fetchSpots();
    });
  }

  void _reload() {
    setState(() {
      _spotsFuture = _fetchSpots();
    });
  }

  void _selectLevel(SpotLevel? level) {
    setState(() {
      _selectedLevel = level;
      _recommendMode = false;
      _spotsFuture = _fetchSpots();
    });
  }

  Future<void> _selectRecommend() async {
    if (_preference == null) {
      await _openPreferences();
      return;
    }
    setState(() {
      _recommendMode = true;
      _selectedLevel = null;
      _spotsFuture = _fetchSpots();
    });
  }

  Future<void> _openPreferences() async {
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => PreferenceScreen(services: widget.services),
      ),
    );
    if (!mounted) return;
    await _loadPreference();
    if (!mounted) return;
    if (saved == true && _preference != null) {
      setState(() {
        _recommendMode = true;
        _selectedLevel = null;
        _spotsFuture = _fetchSpots();
      });
    }
  }

  void _openDetail(Spot spot) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => SpotDetailScreen(spot: spot, services: widget.services),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<List<Spot>>(
        future: _spotsFuture,
        builder: (context, snapshot) => CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: _buildHeader()),
            ..._buildResultSlivers(snapshot),
            const SliverToBoxAdapter(child: SizedBox(height: AppSpace.lg)),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        OceanHeader(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'DiveFriend',
                      style: TextStyle(
                        fontFamily: AppFonts.heading,
                        fontSize: 18,
                        color: AppColors.mint,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Sinkronkan data spot',
                    onPressed: _syncing ? null : _syncAgain,
                    style: IconButton.styleFrom(
                      foregroundColor: Colors.white,
                      disabledForegroundColor: Colors.white54,
                    ),
                    icon: const Icon(Icons.sync),
                  ),
                ],
              ),
              const SizedBox(height: AppSpace.sm),
              const Text(
                'Ke mana laut membawamu selanjutnya?',
                style: TextStyle(
                  fontFamily: AppFonts.heading,
                  fontSize: 28,
                  height: 1.15,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: AppSpace.lg),
              TextField(
                controller: _searchController,
                onChanged: (_) => _reload(),
                decoration: const InputDecoration(
                  hintText: 'Cari nama spot atau wilayah',
                  prefixIcon: Icon(Icons.search),
                ),
              ),
            ],
          ),
        ),
        const DisclaimerBanner(),
        _buildPreferenceNotice(),
        const Padding(
          padding: EdgeInsets.fromLTRB(AppSpace.lg, AppSpace.md, AppSpace.lg, 0),
          child: Text(
            'Jelajahi menurut level',
            style: TextStyle(fontFamily: AppFonts.heading, fontSize: 20, color: AppColors.navy),
          ),
        ),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: AppSpace.md, vertical: AppSpace.sm),
          child: Row(
            children: [
              _buildChip(label: 'Semua', level: null),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpace.xs),
                child: ChoiceChip(
                  avatar: const Icon(Icons.auto_awesome, size: 18, color: AppColors.navy),
                  label: const Text('Rekomendasi'),
                  selected: _recommendMode,
                  onSelected: (_) => _selectRecommend(),
                ),
              ),
              for (final level in SpotLevel.values)
                _buildChip(label: level.label, level: level),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(AppSpace.lg, 0, AppSpace.lg, AppSpace.xs),
          child: Text(
            _syncing ? 'Menyinkronkan data spot...' : (_syncResult?.message ?? ''),
            key: const Key('sync_status'),
            style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
          ),
        ),
      ],
    );
  }

  Widget _buildPreferenceNotice() {
    final preference = _preference;
    if (!_preferenceLoaded) return const SizedBox.shrink();
    final String message;
    final String actionLabel;
    if (preference == null) {
      message = 'Atur preferensi selammu supaya DiveFriend bisa merekomendasikan spot yang pas '
          'dengan levelmu.';
      actionLabel = 'Isi preferensi';
    } else if (_recommendMode) {
      message = 'Rekomendasi untuk level ${preference.level.label}, disusun otomatis dari '
          'jawaban preferensimu.';
      actionLabel = 'Ubah preferensi';
    } else {
      return const SizedBox.shrink();
    }
    return Container(
      margin: const EdgeInsets.fromLTRB(AppSpace.lg, AppSpace.sm, AppSpace.lg, 0),
      padding: const EdgeInsets.fromLTRB(AppSpace.md, AppSpace.md, AppSpace.md, AppSpace.xs),
      decoration: BoxDecoration(
        color: AppColors.mintSoft,
        borderRadius: BorderRadius.circular(AppRadius.field),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.auto_awesome, size: 20, color: AppColors.tealDeep),
              const SizedBox(width: AppSpace.sm),
              Expanded(
                child: Text(
                  message,
                  textAlign: TextAlign.justify,
                  style: const TextStyle(fontSize: 13, height: 1.4, color: AppColors.navy),
                ),
              ),
            ],
          ),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(onPressed: _openPreferences, child: Text(actionLabel)),
          ),
        ],
      ),
    );
  }

  Widget _buildChip({required String label, required SpotLevel? level}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpace.xs),
      child: ChoiceChip(
        label: Text(label),
        selected: !_recommendMode && _selectedLevel == level,
        onSelected: (_) => _selectLevel(level),
      ),
    );
  }

  List<Widget> _buildResultSlivers(AsyncSnapshot<List<Spot>> snapshot) {
    if (snapshot.connectionState == ConnectionState.waiting) {
      return const [
        SliverFillRemaining(
          hasScrollBody: false,
          child: Center(child: CircularProgressIndicator()),
        ),
      ];
    }
    if (snapshot.hasError) {
      return [
        SliverFillRemaining(
          hasScrollBody: false,
          child: StateMessage(
            icon: Icons.error_outline,
            title: 'Gagal memuat spot',
            message: 'Terjadi kesalahan saat mengambil data.',
            actionLabel: 'Coba lagi',
            onAction: _reload,
          ),
        ),
      ];
    }
    final spots = snapshot.data ?? const <Spot>[];
    if (spots.isEmpty) {
      return const [
        SliverFillRemaining(
          hasScrollBody: false,
          child: StateMessage(
            icon: Icons.search_off,
            title: 'Spot tidak ditemukan',
            message: 'Coba kata kunci atau filter level yang lain.',
          ),
        ),
      ];
    }
    return [
      SliverList.builder(
        itemCount: spots.length,
        itemBuilder: (context, index) {
          final spot = spots[index];
          final recommendation = _recommendations[spot.id];
          return SpotCard(
            spot: spot,
            note: recommendation == null ? null : 'Cocok ${recommendation.percent}%',
            onTap: () => _openDetail(spot),
          );
        },
      ),
    ];
  }
}
