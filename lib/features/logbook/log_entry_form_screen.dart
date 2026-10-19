import 'package:flutter/material.dart';

import 'package:divefriend/app_services.dart';
import 'package:divefriend/core/validators.dart';
import 'package:divefriend/core/widgets/section_card.dart';
import 'package:divefriend/data/models/log_entry.dart';
import 'package:divefriend/data/models/spot.dart';
import 'package:divefriend/services/logbook_service.dart';

/// Form catatan penyelaman. Kalau [existing] kosong berarti catatan baru, kalau diisi berarti
/// mengubah catatan itu. Menutup layar dengan hasil true kalau tersimpan.
class LogEntryFormScreen extends StatefulWidget {
  const LogEntryFormScreen({super.key, required this.services, this.existing});

  final AppServices services;
  final LogEntry? existing;

  @override
  State<LogEntryFormScreen> createState() => _LogEntryFormScreenState();
}

class _LogEntryFormScreenState extends State<LogEntryFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _depthController;
  late final TextEditingController _timeController;
  late final TextEditingController _notesController;
  late DateTime _date;
  String? _spotId;
  String? _spotName;
  String? _spotError;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    _depthController = TextEditingController(text: existing?.maxDepthM.toString() ?? '');
    _timeController = TextEditingController(text: existing?.bottomTimeMin.toString() ?? '');
    _notesController = TextEditingController(text: existing?.notes ?? '');
    _date = existing == null ? DateTime.now() : (DateTime.tryParse(existing.diveDate) ?? DateTime.now());
    _spotId = existing?.spotId;
    _spotName = existing?.spotName;
  }

  @override
  void dispose() {
    _depthController.dispose();
    _timeController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked == null) return;
    setState(() {
      _date = picked;
    });
  }

  Future<void> _pickSpot() async {
    final spots = await widget.services.spots.getSpots();
    if (!mounted) return;
    final picked = await showModalBottomSheet<Spot>(
      context: context,
      builder: (sheetContext) => ListView(
        children: [
          for (final spot in spots)
            ListTile(
              title: Text(spot.name),
              subtitle: Text(spot.region),
              onTap: () => Navigator.of(sheetContext).pop(spot),
            ),
        ],
      ),
    );
    if (picked == null) return;
    setState(() {
      _spotId = picked.id;
      _spotName = picked.name;
      _spotError = null;
    });
  }

  Future<void> _save() async {
    final formValid = _formKey.currentState!.validate();
    final spotId = _spotId;
    final spotName = _spotName;
    if (spotId == null || spotName == null) {
      setState(() {
        _spotError = 'Pilih spot selam dulu';
      });
    }
    final user = widget.services.auth.currentUser;
    if (!formValid || spotId == null || spotName == null || user == null) return;

    setState(() {
      _saving = true;
    });
    final depth = int.parse(_depthController.text.trim());
    final bottomTime = int.parse(_timeController.text.trim());
    try {
      final existing = widget.existing;
      if (existing == null) {
        await widget.services.logbook.addEntry(
          userId: user.id,
          diveDate: _date,
          spotId: spotId,
          spotName: spotName,
          maxDepthM: depth,
          bottomTimeMin: bottomTime,
          notes: _notesController.text,
        );
      } else {
        await widget.services.logbook.updateEntry(
          userId: user.id,
          seq: existing.seq,
          diveDate: _date,
          spotId: spotId,
          spotName: spotName,
          maxDepthM: depth,
          bottomTimeMin: bottomTime,
          notes: _notesController.text,
        );
      }
    } on LogbookException catch (error) {
      if (!mounted) return;
      setState(() {
        _saving = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.message)));
      return;
    }
    if (!mounted) return;
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final spotError = _spotError;
    final existing = widget.existing;
    return Scaffold(
      appBar: AppBar(
        title: Text(existing == null ? 'Catatan penyelaman baru' : 'Ubah catatan #${existing.seq}'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const SectionCard(
              icon: Icons.link,
              title: 'Rantai hash',
              child: Text(
                'Catatan boleh diubah atau dihapus kapan saja. Setiap perubahan dari aplikasi otomatis '
                'menyegel ulang rantai hash, jadi rantai hanya dinyatakan rusak kalau data diubah di luar '
                'aplikasi. Penyelaman diurutkan menurut tanggal, jadi nomornya bisa bergeser.',
                textAlign: TextAlign.justify,
                style: TextStyle(fontSize: 12, height: 1.4),
              ),
            ),
            OutlinedButton.icon(
              key: const Key('pick_date'),
              onPressed: _pickDate,
              icon: const Icon(Icons.event),
              label: Text('Tanggal: ${formatDisplayDate(formatIsoDate(_date))}'),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              key: const Key('pick_spot'),
              onPressed: _pickSpot,
              icon: const Icon(Icons.place_outlined),
              label: Text(_spotName ?? 'Pilih spot selam'),
            ),
            if (spotError != null)
              Padding(
                padding: const EdgeInsets.only(top: 6, left: 12),
                child: Text(
                  spotError,
                  style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.error),
                ),
              ),
            const SizedBox(height: 12),
            TextFormField(
              key: const Key('field_depth'),
              controller: _depthController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Kedalaman maksimum (meter)'),
              validator: validateDepthMeters,
            ),
            const SizedBox(height: 12),
            TextFormField(
              key: const Key('field_time'),
              controller: _timeController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Lama di dasar (menit)'),
              validator: validateBottomTimeMinutes,
            ),
            const SizedBox(height: 12),
            TextFormField(
              key: const Key('field_notes'),
              controller: _notesController,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'Catatan (boleh kosong)',
                alignLabelWithHint: true,
              ),
              validator: validateLogNotes,
            ),
            const SizedBox(height: 20),
            FilledButton(
              key: const Key('save_entry'),
              onPressed: _saving ? null : _save,
              child: Text(existing == null ? 'Simpan catatan' : 'Simpan perubahan'),
            ),
          ],
        ),
      ),
    );
  }
}
