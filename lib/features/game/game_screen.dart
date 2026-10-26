import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:divefriend/app_services.dart';
import 'package:divefriend/core/app_theme.dart';
import 'package:divefriend/core/encounter_grade.dart';
import 'package:divefriend/core/quiz_builder.dart';
import 'package:divefriend/core/widgets/section_card.dart';
import 'package:divefriend/data/models/spot.dart';
import 'package:divefriend/features/game/grade_style.dart';
import 'package:divefriend/features/game/quiz_screen.dart';
import 'package:divefriend/services/biota_store.dart';
import 'package:divefriend/services/quiz_score_store.dart';

/// Menu game: kuis tebak biota dan "goyang untuk biota hari ini".
/// Tiap goyangan mengundi satu biota dengan grade acak (Biasa sampai Legendaris). Grade tinggi
/// keluar dengan percikan warna, Legendaris berlatar emas. Hasil terakhir, koleksi, dan grade terbaik
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
  // Satu animasi untuk dua efek: ikan bergoyang di awal, percikan menyebar sampai akhir.
  late final AnimationController _reveal = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1500),
  );
  StreamSubscription<void>? _shakeSubscription;
  List<Spot> _spots = const [];
  BiotaPick? _pick;
  Set<String> _found = const {};
  Map<String, EncounterGrade> _grades = const {};
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
    _reveal.dispose();
    super.dispose();
  }

  Future<void> _loadSaved() async {
    final spots = await widget.services.spots.getSpots();
    final best = await _scores.bestScore(_userId);
    final last = await _biotaStore.last(_userId);
    final found = await _biotaStore.found(_userId);
    final grades = await _biotaStore.bestGrades(_userId);
    if (!mounted) return;
    setState(() {
      _spots = spots;
      _bestScore = best;
      _pick = last;
      _found = found;
      _grades = grades;
    });
  }

  Future<void> _loadBestScore() async {
    final best = await _scores.bestScore(_userId);
    if (!mounted) return;
    setState(() {
      _bestScore = best;
    });
  }

  /// Getaran makin kuat untuk grade yang makin tinggi.
  Future<void> _vibrate(EncounterGrade grade) => switch (grade) {
        EncounterGrade.biasa => HapticFeedback.lightImpact(),
        EncounterGrade.legendaris => HapticFeedback.heavyImpact(),
        _ => HapticFeedback.mediumImpact(),
      };

  Future<void> _rollBiota() async {
    if (!mounted || _spots.isEmpty) return;
    final pick = pickRandomBiota(_spots);
    if (pick == null) return;
    _vibrate(pick.grade);
    _reveal.forward(from: 0);
    final isNew = await _biotaStore.record(_userId, pick);
    final found = await _biotaStore.found(_userId);
    final grades = await _biotaStore.bestGrades(_userId);
    if (!mounted) return;
    setState(() {
      _pick = pick;
      _found = found;
      _grades = grades;
      _lastWasNew = isNew;
    });
  }

  Future<void> _startQuiz() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => QuizScreen(services: widget.services)),
    );
    _loadBestScore();
  }

  EncounterGrade _gradeOf(String key) => _grades[key] ?? EncounterGrade.biasa;

  @override
  Widget build(BuildContext context) {
    final total = countBiota(_spots);
    return Scaffold(
      appBar: AppBar(title: const Text('Game')),
      body: ListView(
        padding: EdgeInsets.fromLTRB(AppSpace.lg, AppSpace.lg, AppSpace.lg, AppSpace.lg + bottomInset(context)),
        children: [
          _buildHero(total),
          const SizedBox(height: AppSpace.lg),
          _buildQuizCard(),
          _buildShakeCard(),
          _buildCollectionCard(total),
        ],
      ),
    );
  }

  Widget _buildHero(int total) {
    final legendary = _grades.values.where((grade) => grade == EncounterGrade.legendaris).length;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpace.lg, vertical: AppSpace.xl),
      decoration: BoxDecoration(
        gradient: AppGradients.deepSea,
        borderRadius: BorderRadius.circular(AppRadius.card),
        boxShadow: AppShadows.soft,
      ),
      child: Row(
        children: [
          _StatTile(value: '$_bestScore', label: 'Skor kuis'),
          _StatTile(value: '${_found.length}/$total', label: 'Koleksi'),
          _StatTile(value: '$legendary', label: 'Legendaris'),
        ],
      ),
    );
  }

  Widget _buildQuizCard() {
    return SectionCard(
      icon: Icons.quiz_outlined,
      title: 'Kuis tebak biota',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '10 soal, waktu 15 detik per soal. Tebak biota yang tercatat di tiap spot.',
            textAlign: TextAlign.justify,
          ),
          const SizedBox(height: AppSpace.sm),
          Text('Skor tertinggimu: $_bestScore', key: const Key('best_score')),
          const SizedBox(height: AppSpace.md),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _startQuiz,
              icon: const Icon(Icons.play_arrow_rounded),
              label: const Text('Mulai kuis'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShakeCard() {
    return SectionCard(
      icon: Icons.vibration,
      title: 'Goyang untuk biota hari ini',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _sensorUnavailable
                ? 'Sensor goyang tidak bisa dipakai di HP ini, gunakan tombol di bawah.'
                : 'Goyangkan HP-mu dengan cukup kuat untuk mengundi satu biota. Makin tinggi gradenya, makin meriah efeknya.',
            textAlign: TextAlign.justify,
          ),
          const SizedBox(height: AppSpace.md),
          _buildStage(),
          const SizedBox(height: AppSpace.sm),
          Text(
            'Grade hanyalah hadiah keberuntungan di game ini, bukan tingkat kelangkaan biota yang sebenarnya.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
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
    );
  }

  /// Panggung hasil undian. Warna latar dan percikan mengikuti grade, Legendaris diberi cahaya emas.
  Widget _buildStage() {
    final pick = _pick;
    final grade = pick?.grade ?? EncounterGrade.biasa;
    final legendary = pick != null && grade == EncounterGrade.legendaris;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: AppSpace.lg, vertical: AppSpace.xl),
      decoration: BoxDecoration(
        gradient: pick == null ? null : grade.stageGradient,
        color: pick == null ? AppColors.mintSoft : null,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(
          color: pick == null ? AppColors.line : grade.color,
          width: legendary ? 2.5 : 1.5,
        ),
        boxShadow: legendary
            ? const [BoxShadow(color: Color(0x80F5B301), blurRadius: 24, spreadRadius: 2)]
            : const [],
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: IgnorePointer(
              child: AnimatedBuilder(
                animation: _reveal,
                builder: (context, child) => CustomPaint(
                  painter: _SparklePainter(
                    progress: _reveal.value,
                    color: grade.color,
                    count: pick == null ? 0 : grade.sparkleCount,
                    reach: legendary ? 150 : 100,
                    originY: 40,
                  ),
                ),
              ),
            ),
          ),
          Column(
            children: [
              _buildFish(pick == null ? AppColors.teal : grade.color),
              const SizedBox(height: AppSpace.md),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 350),
                transitionBuilder: (child, animation) => ScaleTransition(scale: animation, child: child),
                child: pick == null
                    ? const Text('Belum ada biota yang diundi.', key: ValueKey('no_biota'))
                    : _buildResult(pick),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFish(Color color) {
    return SizedBox(
      height: 80,
      child: AnimatedBuilder(
        animation: _reveal,
        builder: (context, child) {
          // Ikan bergoyang ke kiri dan kanan di 40 persen awal animasi lalu mereda.
          final t = (_reveal.value / 0.4).clamp(0.0, 1.0);
          final angle = math.sin(t * math.pi * 6) * 0.35 * (1 - t);
          return Transform.rotate(angle: angle, child: child);
        },
        child: Icon(Icons.set_meal, size: 72, color: color),
      ),
    );
  }

  Widget _buildResult(BiotaPick pick) {
    final grade = pick.grade;
    return Column(
      key: ValueKey('${pick.name}|${pick.spotName}|${grade.index}'),
      mainAxisSize: MainAxisSize.min,
      children: [
        Wrap(
          alignment: WrapAlignment.center,
          spacing: AppSpace.sm,
          runSpacing: AppSpace.xs,
          children: [
            _Pill(
              icon: grade.icon,
              text: grade.label,
              background: grade.color,
              foreground: grade == EncounterGrade.legendaris ? AppColors.navy : Colors.white,
            ),
            if (_lastWasNew)
              const _Pill(
                icon: Icons.fiber_new_outlined,
                text: 'Baru di koleksi',
                background: AppColors.orange,
                foreground: AppColors.navy,
              ),
          ],
        ),
        const SizedBox(height: AppSpace.sm),
        Text(
          pick.name,
          key: const Key('biota_name'),
          textAlign: TextAlign.center,
          style: const TextStyle(fontFamily: AppFonts.heading, fontSize: 26, color: AppColors.navy),
        ),
        const SizedBox(height: AppSpace.xs),
        Text(
          'Tercatat di ${pick.spotName}',
          textAlign: TextAlign.center,
          style: const TextStyle(color: AppColors.navy),
        ),
      ],
    );
  }

  Widget _buildCollectionCard(int total) {
    final keys = _found.toList()
      ..sort((a, b) {
        final byGrade = _gradeOf(b).index.compareTo(_gradeOf(a).index);
        return byGrade != 0 ? byGrade : a.compareTo(b);
      });
    return SectionCard(
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
          const SizedBox(height: AppSpace.sm),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              minHeight: 8,
              value: total == 0 ? 0 : (_found.length / total).clamp(0.0, 1.0),
            ),
          ),
          const SizedBox(height: AppSpace.md),
          Wrap(
            spacing: AppSpace.sm,
            runSpacing: AppSpace.sm,
            children: [
              for (final grade in EncounterGrade.values.reversed)
                _Pill(
                  icon: grade.icon,
                  text: '${grade.label} ${_found.where((key) => _gradeOf(key) == grade).length}',
                  background: grade.softColor,
                  foreground: grade.textColor,
                ),
            ],
          ),
          const SizedBox(height: AppSpace.md),
          if (keys.isEmpty)
            const Text('Belum ada biota di koleksi. Goyangkan HP untuk memulai.')
          else
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final key in keys)
                  _CollectionChip(name: key.split('|').first, grade: _gradeOf(key)),
              ],
            ),
        ],
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(fontFamily: AppFonts.heading, fontSize: 26, color: Colors.white),
          ),
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(fontSize: 12, color: Color(0xFFD8F7F0))),
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({
    required this.icon,
    required this.text,
    required this.background,
    required this.foreground,
  });

  final IconData icon;
  final String text;
  final Color background;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(AppRadius.chip)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: foreground),
          const SizedBox(width: 4),
          Text(text, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: foreground)),
        ],
      ),
    );
  }
}

class _CollectionChip extends StatelessWidget {
  const _CollectionChip({required this.name, required this.grade});

  final String name;
  final EncounterGrade grade;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: grade.softColor,
        borderRadius: BorderRadius.circular(AppRadius.chip),
        border: Border.all(color: grade.color),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (grade != EncounterGrade.biasa) ...[
            Icon(grade.icon, size: 13, color: grade.textColor),
            const SizedBox(width: 4),
          ],
          Text(name, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: grade.textColor)),
        ],
      ),
    );
  }
}

/// Percikan bulat yang menyebar dari ikan lalu memudar. Posisinya dihitung dari urutan percikan,
/// tanpa angka acak, jadi gambar tiap frame stabil.
class _SparklePainter extends CustomPainter {
  const _SparklePainter({
    required this.progress,
    required this.color,
    required this.count,
    required this.reach,
    required this.originY,
  });

  final double progress;
  final Color color;
  final int count;
  final double reach;
  final double originY;

  @override
  void paint(Canvas canvas, Size size) {
    if (count == 0 || progress <= 0 || progress >= 1) return;
    final eased = Curves.easeOutCubic.transform(progress);
    final paint = Paint()..color = color.withValues(alpha: 1 - progress);
    final origin = Offset(size.width / 2, originY);
    for (var i = 0; i < count; i++) {
      final angle = 2 * math.pi * i / count;
      final distance = reach * eased * (i.isEven ? 1.0 : 0.65);
      final center = origin + Offset(math.cos(angle), math.sin(angle)) * distance;
      canvas.drawCircle(center, i.isEven ? 4 : 2.5, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _SparklePainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.color != color ||
        oldDelegate.count != count ||
        oldDelegate.reach != reach;
  }
}
