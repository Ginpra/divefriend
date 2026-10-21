import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:divefriend/app_services.dart';
import 'package:divefriend/core/app_theme.dart';
import 'package:divefriend/core/quiz_builder.dart';
import 'package:divefriend/core/widgets/section_card.dart';
import 'package:divefriend/data/models/spot.dart';
import 'package:divefriend/features/game/quiz_screen.dart';
import 'package:divefriend/services/biota_store.dart';
import 'package:divefriend/services/quiz_score_store.dart';

/// Menu game: kuis tebak biota dan "goyang untuk biota hari ini".
/// Tiap goyangan mengundi satu biota. Hasil terakhir dan koleksi biota yang pernah ditemukan
/// tersimpan, jadi tidak hilang saat layar ditutup. Ada tombol cadangan untuk HP tanpa sensor.
class GameScreen extends StatefulWidget {
  const GameScreen({super.key, required this.services});

  final AppServices services;

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> with SingleTickerProviderStateMixin {
  final _scores = QuizScoreStore();
  final _biotaStore = BiotaStore();
  late final AnimationController _wiggle = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 600),
  );
  StreamSubscription<void>? _shakeSubscription;
  List<Spot> _spots = const [];
  BiotaPick? _pick;
  Set<String> _found = const {};
  bool _lastWasNew = false;
  bool _sensorUnavailable = false;
  int _bestScore = 0;

  int get _userId => widget.services.auth.currentUser?.id ?? -1;

  @override
  void initState() {
    super.initState();
    _loadSaved();
    _shakeSubscription = widget.services.sensors.shakes().listen(
      (_) => _rollBiota(),
      onError: (Object error) {
        if (mounted) setState(() => _sensorUnavailable = true);
      },
    );
  }

  @override
  void dispose() {
    _shakeSubscription?.cancel();
    _wiggle.dispose();
    super.dispose();
  }

  Future<void> _loadSaved() async {
    final spots = await widget.services.spots.getSpots();
    final best = await _scores.bestScore(_userId);
    final last = await _biotaStore.last(_userId);
    final found = await _biotaStore.found(_userId);
    if (!mounted) return;
    setState(() {
      _spots = spots;
      _bestScore = best;
      _pick = last;
      _found = found;
    });
  }

  Future<void> _loadBestScore() async {
    final best = await _scores.bestScore(_userId);
    if (!mounted) return;
    setState(() {
      _bestScore = best;
    });
  }

  Future<void> _rollBiota() async {
    if (!mounted || _spots.isEmpty) return;
    final pick = pickRandomBiota(_spots);
    if (pick == null) return;
    HapticFeedback.mediumImpact();
    _wiggle.forward(from: 0);
    final isNew = await _biotaStore.record(_userId, pick);
    final found = await _biotaStore.found(_userId);
    if (!mounted) return;
    setState(() {
      _pick = pick;
      _found = found;
      _lastWasNew = isNew;
    });
  }

  Future<void> _startQuiz() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => QuizScreen(services: widget.services)),
    );
    _loadBestScore();
  }

  Widget _buildFish() {
    return AnimatedBuilder(
      animation: _wiggle,
      builder: (context, child) {
        // Ikon bergoyang ke kiri dan kanan lalu mereda, seperti ikut tergoyang.
        final angle = math.sin(_wiggle.value * math.pi * 6) * 0.35 * (1 - _wiggle.value);
        return Transform.rotate(angle: angle, child: child);
      },
      child: const Icon(Icons.set_meal, size: 64, color: AppColors.teal),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pick = _pick;
    final total = countBiota(_spots);
    return Scaffold(
      appBar: AppBar(title: const Text('Game')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SectionCard(
            icon: Icons.quiz_outlined,
            title: 'Kuis tebak biota',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '10 soal, waktu 15 detik per soal. Tebak biota yang tercatat di tiap spot.',
                  textAlign: TextAlign.justify,
                ),
                const SizedBox(height: 8),
                Text('Skor tertinggimu: $_bestScore', key: const Key('best_score')),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(onPressed: _startQuiz, child: const Text('Mulai kuis')),
                ),
              ],
            ),
          ),
          SectionCard(
            icon: Icons.vibration,
            title: 'Goyang untuk biota hari ini',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _sensorUnavailable
                      ? 'Sensor goyang tidak bisa dipakai di HP ini, gunakan tombol di bawah.'
                      : 'Goyangkan HP-mu dengan cukup kuat untuk mengundi satu biota. Makin banyak yang kamu temukan, makin lengkap koleksimu.',
                  textAlign: TextAlign.justify,
                ),
                const SizedBox(height: 12),
                Center(child: _buildFish()),
                const SizedBox(height: 8),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 350),
                  transitionBuilder: (child, animation) => ScaleTransition(scale: animation, child: child),
                  child: pick == null
                      ? const Text('Belum ada biota yang diundi.', key: ValueKey('no_biota'))
                      : _buildResult(pick),
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: _spots.isEmpty ? null : _rollBiota,
                    icon: const Icon(Icons.casino_outlined),
                    label: const Text('Undi tanpa goyang'),
                  ),
                ),
              ],
            ),
          ),
          SectionCard(
            icon: Icons.collections_bookmark_outlined,
            title: 'Koleksi biota',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Ditemukan ${_found.length} dari $total',
                  key: const Key('biota_progress'),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                LinearProgressIndicator(value: total == 0 ? 0 : (_found.length / total).clamp(0.0, 1.0)),
                const SizedBox(height: 10),
                if (_found.isEmpty)
                  const Text('Belum ada biota di koleksi. Goyangkan HP untuk memulai.')
                else
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      for (final key in (_found.toList()..sort()))
                        Chip(
                          label: Text(key.split('|').first, style: const TextStyle(fontSize: 12)),
                          visualDensity: VisualDensity.compact,
                        ),
                    ],
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResult(BiotaPick pick) {
    return Container(
      key: ValueKey('${pick.name}|${pick.spotName}'),
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0x1F13A89E),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_lastWasNew)
            const Text('Biota baru di koleksimu!', style: TextStyle(color: AppColors.orange, fontWeight: FontWeight.bold)),
          Text(
            pick.name,
            key: const Key('biota_name'),
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.navy),
          ),
          Text('Tercatat di ${pick.spotName}'),
        ],
      ),
    );
  }
}
