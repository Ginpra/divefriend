import 'dart:async';

import 'package:flutter/material.dart';

import 'package:divefriend/app_services.dart';
import 'package:divefriend/core/app_theme.dart';
import 'package:divefriend/core/quiz_builder.dart';
import 'package:divefriend/core/widgets/state_message.dart';
import 'package:divefriend/services/quiz_score_store.dart';

/// Kuis tebak biota: 10 soal, 15 detik per soal, skor tertinggi disimpan lokal.
/// Soal dibuat dari kolom biota di data spot (lihat core/quiz_builder.dart).
class QuizScreen extends StatefulWidget {
  const QuizScreen({super.key, required this.services});

  final AppServices services;

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  static const int _secondsPerQuestion = 15;

  final _scores = QuizScoreStore();
  List<QuizQuestion>? _questions;
  Timer? _timer;
  int _index = 0;
  int _score = 0;
  int _secondsLeft = _secondsPerQuestion;
  bool _answered = false;
  int _chosen = -1;
  bool _finished = false;
  bool _newRecord = false;

  int get _userId => widget.services.auth.currentUser?.id ?? -1;

  @override
  void initState() {
    super.initState();
    _prepare();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _prepare() async {
    final spots = await widget.services.spots.getSpots();
    if (!mounted) return;
    final questions = buildQuiz(spots);
    setState(() {
      _questions = questions;
    });
    if (questions.isNotEmpty) _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    _secondsLeft = _secondsPerQuestion;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_answered) return;
      if (_secondsLeft <= 1) {
        _answer(-1);
      } else {
        setState(() {
          _secondsLeft -= 1;
        });
      }
    });
  }

  /// [choice] -1 berarti waktu habis.
  void _answer(int choice) {
    final questions = _questions;
    if (questions == null || _answered) return;
    _timer?.cancel();
    setState(() {
      _answered = true;
      _chosen = choice;
      _secondsLeft = 0;
      if (choice == questions[_index].correctIndex) _score += 1;
    });
  }

  Future<void> _next() async {
    final questions = _questions;
    if (questions == null) return;
    if (_index + 1 >= questions.length) {
      final record = await _scores.saveIfBest(_userId, _score);
      if (!mounted) return;
      setState(() {
        _finished = true;
        _newRecord = record;
      });
      return;
    }
    setState(() {
      _index += 1;
      _answered = false;
      _chosen = -1;
    });
    _startTimer();
  }

  @override
  Widget build(BuildContext context) {
    final questions = _questions;
    return Scaffold(
      appBar: AppBar(title: const Text('Kuis Biota')),
      body: questions == null
          ? const Center(child: CircularProgressIndicator())
          : questions.isEmpty
              ? const StateMessage(
                  icon: Icons.quiz_outlined,
                  title: 'Soal belum bisa dibuat',
                  message: 'Data biota spot belum cukup untuk menyusun kuis.',
                )
              : _finished
                  ? _buildResult(questions.length)
                  : _buildQuestion(questions),
    );
  }

  /// Pesan penutup menurut skor, supaya hasil terasa seperti penilaian bukan sekadar angka.
  String _verdict(int total) {
    final ratio = total == 0 ? 0 : _score / total;
    if (ratio >= 0.8) return 'Penyelam sejati! Pengetahuan biotamu sudah mantap.';
    if (ratio >= 0.5) return 'Lumayan. Makin sering menyelam, makin hafal biotanya.';
    return 'Ayo coba lagi, tiap putaran soalnya diacak ulang.';
  }

  Widget _buildResult(int total) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpace.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: const BoxDecoration(gradient: AppGradients.deepSea, shape: BoxShape.circle),
              child: const Icon(Icons.emoji_events_outlined, size: 60, color: AppColors.mint),
            ),
            const SizedBox(height: AppSpace.lg),
            Text(
              'Skormu $_score dari $total',
              key: const Key('quiz_result'),
              textAlign: TextAlign.center,
              style: const TextStyle(fontFamily: AppFonts.heading, fontSize: 28, color: AppColors.navy),
            ),
            if (_newRecord)
              const Padding(
                padding: EdgeInsets.only(top: AppSpace.sm),
                child: Text('Rekor baru!', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.tealDeep)),
              ),
            const SizedBox(height: AppSpace.sm),
            Text(_verdict(total), textAlign: TextAlign.center),
            const SizedBox(height: AppSpace.sm),
            Text(
              'Jawaban mengacu pada daftar biota di data spot DiveFriend.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: AppSpace.xl),
            FilledButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Selesai')),
          ],
        ),
      ),
    );
  }

  Widget _buildQuestion(List<QuizQuestion> questions) {
    final question = questions[_index];
    final isLast = _index + 1 >= questions.length;
    final urgent = _secondsLeft <= 5;
    return ListView(
      padding: EdgeInsets.fromLTRB(AppSpace.lg, AppSpace.lg, AppSpace.lg, AppSpace.lg + bottomInset(context)),
      children: [
        Row(
          children: [
            Text('Soal ${_index + 1} dari ${questions.length}', style: Theme.of(context).textTheme.titleSmall),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: urgent ? const Color(0xFFFFE1DE) : AppColors.mintSoft,
                borderRadius: BorderRadius.circular(AppRadius.chip),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.timer_outlined, size: 16, color: urgent ? const Color(0xFFB3261E) : AppColors.tealDeep),
                  const SizedBox(width: 4),
                  Text(
                    '$_secondsLeft',
                    key: const Key('quiz_seconds'),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: urgent ? const Color(0xFFB3261E) : AppColors.tealDeep,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpace.sm),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(minHeight: 8, value: _secondsLeft / _secondsPerQuestion),
        ),
        const SizedBox(height: AppSpace.xl),
        Text(question.prompt, style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: AppSpace.lg),
        for (var i = 0; i < question.options.length; i++) _buildOption(question, i),
        if (_answered) ...[
          const SizedBox(height: AppSpace.sm),
          Text(
            _chosen == -1
                ? 'Waktu habis. Jawabannya ${question.correctAnswer}.'
                : (_chosen == question.correctIndex
                    ? 'Benar!'
                    : 'Kurang tepat. Jawabannya ${question.correctAnswer}.'),
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: AppSpace.md),
          FilledButton(
            onPressed: _next,
            child: Text(isLast ? 'Lihat skor' : 'Soal berikutnya'),
          ),
        ],
      ],
    );
  }

  Widget _buildOption(QuizQuestion question, int index) {
    const letters = ['A', 'B', 'C', 'D'];
    var background = AppColors.surface;
    var border = const Color(0x4D0B2545);
    IconData? mark;
    if (_answered) {
      if (index == question.correctIndex) {
        background = const Color(0xFFC8E6C9);
        border = const Color(0xFF2E7D32);
        mark = Icons.check_circle;
      } else if (index == _chosen) {
        background = const Color(0xFFFFCDD2);
        border = const Color(0xFFB3261E);
        mark = Icons.cancel;
      }
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpace.sm),
      child: Material(
        color: background,
        borderRadius: BorderRadius.circular(AppRadius.field),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.field),
          onTap: _answered ? null : () => _answer(index),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: AppSpace.md, vertical: AppSpace.md),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadius.field),
              border: Border.all(color: border),
            ),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(color: AppColors.mintSoft, shape: BoxShape.circle),
                  child: Text(
                    index < letters.length ? letters[index] : '${index + 1}',
                    style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.tealDeep),
                  ),
                ),
                const SizedBox(width: AppSpace.md),
                Expanded(child: Text(question.options[index], style: const TextStyle(fontSize: 16))),
                if (mark != null) Icon(mark, color: border),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
