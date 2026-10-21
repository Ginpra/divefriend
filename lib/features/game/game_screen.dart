import 'dart:async';

import 'package:flutter/material.dart';

import 'package:divefriend/app_services.dart';
import 'package:divefriend/core/app_theme.dart';
import 'package:divefriend/core/quiz_builder.dart';
import 'package:divefriend/core/widgets/inline_notice.dart';
import 'package:divefriend/core/widgets/section_card.dart';
import 'package:divefriend/data/models/spot.dart';
import 'package:divefriend/features/game/quiz_screen.dart';
import 'package:divefriend/services/quiz_score_store.dart';

/// Menu game: kuis tebak biota dan "goyang untuk biota hari ini".
/// Game goyang memakai sensor akselerometer, dan ada tombol cadangan untuk HP tanpa sensor.
class GameScreen extends StatefulWidget {
  const GameScreen({super.key, required this.services});

  final AppServices services;

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  final _scores = QuizScoreStore();
  StreamSubscription<void>? _shakeSubscription;
  List<Spot> _spots = const [];
  BiotaPick? _pick;
  bool _sensorUnavailable = false;
  int _bestScore = 0;

  int get _userId => widget.services.auth.currentUser?.id ?? -1;

  @override
  void initState() {
    super.initState();
    _loadSpots();
    _loadBestScore();
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
    super.dispose();
  }

  Future<void> _loadSpots() async {
    final spots = await widget.services.spots.getSpots();
    if (!mounted) return;
    setState(() {
      _spots = spots;
    });
  }

  Future<void> _loadBestScore() async {
    final best = await _scores.bestScore(_userId);
    if (!mounted) return;
    setState(() {
      _bestScore = best;
    });
  }

  void _rollBiota() {
    if (!mounted) return;
    setState(() {
      _pick = pickRandomBiota(_spots);
    });
  }

  Future<void> _startQuiz() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => QuizScreen(services: widget.services)),
    );
    _loadBestScore();
  }

  @override
  Widget build(BuildContext context) {
    final pick = _pick;
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
                      : 'Goyangkan HP-mu untuk mengundi satu biota dari spot-spot DiveFriend.',
                  textAlign: TextAlign.justify,
                ),
                const SizedBox(height: 12),
                if (pick == null)
                  const InlineNotice(icon: Icons.waves, message: 'Belum ada biota yang diundi.')
                else
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0x1F13A89E),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          pick.name,
                          key: const Key('biota_name'),
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppColors.navy,
                          ),
                        ),
                        Text('Tercatat di ${pick.spotName}'),
                      ],
                    ),
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
        ],
      ),
    );
  }
}
