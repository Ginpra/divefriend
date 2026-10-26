import 'package:flutter/material.dart';

import 'package:divefriend/app_services.dart';
import 'package:divefriend/core/app_theme.dart';
import 'package:divefriend/core/level_classifier.dart';
import 'package:divefriend/features/preferences/user_level_badge.dart';
import 'package:divefriend/services/preference_store.dart';

/// Kuesioner preferensi selam. Jawabannya diklasifikasi oleh model k-NN (lihat
/// core/level_classifier.dart) menjadi level Pemula, Menengah, atau Lanjutan, lalu disimpan.
/// Bisa dibuka kapan saja, jawaban lama otomatis terisi supaya mudah diperbarui.
/// Menutup layar dengan hasil true berarti preferensi baru saja disimpan.
class PreferenceScreen extends StatefulWidget {
  const PreferenceScreen({super.key, required this.services});

  final AppServices services;

  @override
  State<PreferenceScreen> createState() => _PreferenceScreenState();
}

class _PreferenceScreenState extends State<PreferenceScreen> {
  final _store = PreferenceStore();
  final List<int?> _answers = List<int?>.filled(levelQuestions.length, null);
  final Set<String> _interests = {};
  bool _loading = true;
  bool _saving = false;
  UserPreference? _result;
  LevelPrediction? _prediction;

  @override
  void initState() {
    super.initState();
    _loadExisting();
  }

  Future<void> _loadExisting() async {
    final user = widget.services.auth.currentUser;
    UserPreference? saved;
    if (user != null) saved = await _store.load(user.id);
    if (!mounted) return;
    setState(() {
      if (saved != null && saved.answers.length == _answers.length) {
        for (var i = 0; i < _answers.length; i++) {
          _answers[i] = saved.answers[i];
        }
        _interests.addAll(saved.interests);
      }
      _loading = false;
    });
  }

  bool get _complete => _answers.every((answer) => answer != null);

  Future<void> _submit() async {
    final user = widget.services.auth.currentUser;
    if (user == null || !_complete) return;
    setState(() => _saving = true);
    final answers = [for (final answer in _answers) answer!];
    final prediction = classifyLevel(answers);
    final preference = UserPreference(
      answers: answers,
      interests: Set<String>.of(_interests),
      level: prediction.level,
      confidence: prediction.confidence,
    );
    await _store.save(user.id, preference);
    if (!mounted) return;
    setState(() {
      _saving = false;
      _result = preference;
      _prediction = prediction;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Preferensi Selam')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : (_result != null ? _buildResult() : _buildForm()),
    );
  }

  Widget _buildForm() {
    return ListView(
      padding: EdgeInsets.fromLTRB(AppSpace.lg, AppSpace.lg, AppSpace.lg, AppSpace.lg + bottomInset(context)),
      children: [
        const Text(
          'Jawab lima pertanyaan singkat dan pilih minatmu. Model klasifikasi di dalam aplikasi '
          '(bukan chatbot) akan menentukan levelmu, lalu spot yang cocok muncul di filter Rekomendasi.',
          textAlign: TextAlign.justify,
          style: TextStyle(height: 1.5),
        ),
        const SizedBox(height: AppSpace.lg),
        for (var i = 0; i < levelQuestions.length; i++) _buildQuestion(i),
        _buildInterests(),
        const SizedBox(height: AppSpace.sm),
        FilledButton(
          onPressed: (_complete && !_saving) ? _submit : null,
          child: _saving
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Tentukan level saya'),
        ),
        if (!_complete)
          const Padding(
            padding: EdgeInsets.only(top: AppSpace.sm),
            child: Text(
              'Jawab semua pertanyaan dulu untuk melanjutkan.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: AppColors.textMuted),
            ),
          ),
        const SizedBox(height: AppSpace.lg),
      ],
    );
  }

  Widget _buildQuestion(int index) {
    final question = levelQuestions[index];
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpace.lg),
      padding: const EdgeInsets.all(AppSpace.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: AppColors.line),
        boxShadow: AppShadows.soft,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Pertanyaan ${index + 1} dari ${levelQuestions.length}',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.tealDeep,
            ),
          ),
          const SizedBox(height: AppSpace.xs),
          Text(
            question.text,
            style: const TextStyle(
              fontFamily: AppFonts.heading,
              fontSize: 18,
              height: 1.25,
              color: AppColors.navy,
            ),
          ),
          const SizedBox(height: AppSpace.md),
          for (var option = 0; option < question.options.length; option++)
            _OptionTile(
              label: question.options[option],
              selected: _answers[index] == option,
              onTap: () => setState(() => _answers[index] = option),
            ),
        ],
      ),
    );
  }

  Widget _buildInterests() {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpace.lg),
      padding: const EdgeInsets.all(AppSpace.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: AppColors.line),
        boxShadow: AppShadows.soft,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Minatmu (boleh lebih dari satu)',
            style: TextStyle(
              fontFamily: AppFonts.heading,
              fontSize: 18,
              color: AppColors.navy,
            ),
          ),
          const SizedBox(height: AppSpace.md),
          Wrap(
            spacing: AppSpace.sm,
            runSpacing: AppSpace.sm,
            children: [
              for (final entry in interestLabels.entries)
                FilterChip(
                  label: Text(entry.value),
                  selected: _interests.contains(entry.key),
                  onSelected: (selected) => setState(() {
                    if (selected) {
                      _interests.add(entry.key);
                    } else {
                      _interests.remove(entry.key);
                    }
                  }),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildResult() {
    final result = _result!;
    final prediction = _prediction;
    final percent = (result.confidence * 100).round();
    final neighbors = prediction == null
        ? ''
        : prediction.neighborLevels.map((level) => level.label).join(', ');
    return ListView(
      padding: EdgeInsets.fromLTRB(AppSpace.xl, AppSpace.xl, AppSpace.xl, AppSpace.xl + bottomInset(context)),
      children: [
        const SizedBox(height: AppSpace.lg),
        const Center(
          child: CircleAvatar(
            radius: 44,
            backgroundColor: AppColors.mintSoft,
            child: Icon(Icons.workspace_premium, size: 48, color: AppColors.tealDeep),
          ),
        ),
        const SizedBox(height: AppSpace.lg),
        const Text(
          'Hasil klasifikasimu',
          textAlign: TextAlign.center,
          style: TextStyle(color: AppColors.textMuted),
        ),
        const SizedBox(height: AppSpace.sm),
        Center(child: UserLevelBadge(level: result.level, large: true)),
        const SizedBox(height: AppSpace.lg),
        Text(
          'Keyakinan model sekitar $percent%.',
          textAlign: TextAlign.center,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: AppSpace.md),
        if (prediction?.ruleNote != null)
          Text(
            prediction!.ruleNote!,
            textAlign: TextAlign.justify,
            style: const TextStyle(height: 1.5),
          )
        else
          Text(
            'Model k-NN membandingkan jawabanmu dengan $trainingSampleCount profil contoh, lalu '
            'mengambil $knnNeighbors profil yang paling mirip. Ketiganya berlevel: $neighbors.',
            textAlign: TextAlign.justify,
            style: const TextStyle(height: 1.5),
          ),
        const SizedBox(height: AppSpace.md),
        const Text(
          'Level ini hanya estimasi untuk menyaring rekomendasi spot, bukan sertifikasi, dan '
          'bukan pengganti arahan instruktur selam bersertifikat.',
          textAlign: TextAlign.justify,
          style: TextStyle(fontSize: 12, height: 1.5, color: AppColors.textMuted),
        ),
        const SizedBox(height: AppSpace.xl),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text('Lihat spot rekomendasi'),
        ),
        const SizedBox(height: AppSpace.md),
        OutlinedButton(
          onPressed: () => setState(() {
            _result = null;
            _prediction = null;
          }),
          child: const Text('Isi ulang'),
        ),
      ],
    );
  }
}

class _OptionTile extends StatelessWidget {
  const _OptionTile({required this.label, required this.selected, required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppRadius.field),
      side: BorderSide(
        color: selected ? AppColors.tealDeep : AppColors.line,
        width: selected ? 2 : 1,
      ),
    );
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpace.sm),
      child: Material(
        color: selected ? AppColors.mintSoft : AppColors.surface,
        shape: shape,
        child: InkWell(
          customBorder: shape,
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpace.md, vertical: 14),
            child: Row(
              children: [
                Icon(
                  selected ? Icons.check_circle : Icons.circle_outlined,
                  color: selected ? AppColors.tealDeep : AppColors.textMuted,
                ),
                const SizedBox(width: AppSpace.md),
                Expanded(child: Text(label, style: const TextStyle(height: 1.35))),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
