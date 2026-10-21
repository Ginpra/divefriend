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

  Widget _buildResult(int total) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.emoji_events_outlined, size: 64, color: AppColors.orange),
            const SizedBox(height: 12),
            Text(
              'Skormu $_score dari $total',
              key: const Key('quiz_result'),
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            if (_newRecord) const Text('Rekor baru!'),
            const SizedBox(height: 8),
            const Text(
              'Jawaban mengacu pada daftar biota di data spot DiveFriend.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12),
            ),
            const SizedBox(height: 20),
            FilledButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Selesai')),
          ],
        ),
      ),
    );
  }

  Widget _buildQuestion(List<QuizQuestion> questions) {
    final question = questions[_index];
    final isLast = _index + 1 >= questions.length;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          children: [
            Text('Soal ${_index + 1} dari ${questions.length}'),
            const Spacer(),
            Icon(Icons.timer_outlined, size: 18, color: _secondsLeft <= 5 ? Colors.red : AppColors.navy),
            const SizedBox(width: 4),
            Text('$_secondsLeft', key: const Key('quiz_seconds'), style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(value: _secondsLeft / _secondsPerQuestion),
        const SizedBox(height: 20),
        Text(
          question.prompt,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.navy),
        ),
        const SizedBox(height: 16),
        for (var i = 0; i < question.options.length; i++) _buildOption(question, i),
        if (_answered) ...[
          const SizedBox(height: 8),
          Text(
            _chosen == -1
                ? 'Waktu habis. Jawabannya ${question.correctAnswer}.'
                : (_chosen == question.correctIndex
                    ? 'Benar!'
                    : 'Kurang tepat. Jawabannya ${question.correctAnswer}.'),
          ),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: _next,
            child: Text(isLast ? 'Lihat skor' : 'Soal berikutnya'),
          ),
        ],
      ],
    );
  }

  Widget _buildOption(QuizQuestion question, int index) {
    Color? color;
    if (_answered) {
      if (index == question.correctIndex) {
        color = const Color(0xFFC8E6C9);
      } else if (index == _chosen) {
        color = const Color(0xFFFFCDD2);
      }
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: color ?? Colors.white,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: _answered ? null : () => _answer(index),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0x330B2545)),
            ),
            child: Text(question.options[index], style: const TextStyle(fontSize: 16)),
          ),
        ),
      ),
    );
  }
}
