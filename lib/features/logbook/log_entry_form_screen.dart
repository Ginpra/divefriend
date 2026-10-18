import 'package:flutter/material.dart';

import 'package:divefriend/app_services.dart';
import 'package:divefriend/core/validators.dart';
import 'package:divefriend/core/widgets/section_card.dart';
import 'package:divefriend/data/models/spot.dart';
import 'package:divefriend/services/logbook_service.dart';

/// Form catatan penyelaman baru. Setelah disimpan, catatan tidak bisa diubah atau dihapus
/// karena sudah menjadi bagian dari rantai hash. Menutup layar dengan hasil true kalau tersimpan.
class LogEntryFormScreen extends StatefulWidget {
  const LogEntryFormScreen({super.key, required this.services});

  final AppServices services;

  @override
  State<LogEntryFormScreen> createState() => _LogEntryFormScreenState();
}

class _LogEntryFormScreenState extends State<LogEntryFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _depthController = TextEditingController();
  final _timeController = TextEditingController();
  final _notesController = TextEditingController();
  DateTime _date = DateTime.now();
  Spot? _spot;
  String? _spotError;
  bool _saving = false;

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
      _spot = picked;
      _spotError = null;
    });
  }

  Future<void> _save() async {
    final formValid = _formKey.currentState!.validate();
    final spot = _spot;
    if (spot == null) {
      setState(() {
        _spotError = 'Pilih spot selam dulu';
      });
    }
    final user = widget.services.auth.currentUser;
    if (!formValid || spot == null || user == null) return;

    setState(() {
      _saving = true;
    });
    await widget.services.logbook.addEntry(
      userId: user.id,
      diveDate: _date,
      spotId: spot.id,
      spotName: spot.name,
      maxDepthM: int.parse(_depthController.text.trim()),
      bottomTimeMin: int.parse(_timeController.text.trim()),
      notes: _notesController.text,
    );
    if (!mounted) return;
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final spotError = _spotError;
    return Scaffold(
      appBar: AppBar(title: const Text('Catatan penyelaman baru')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const SectionCard(
              icon: Icons.lock_outline,
              title: 'Catatan tidak bisa diubah',
              child: Text(
                'Setiap catatan menyimpan hash catatan sebelumnya, sehingga seluruh logbook membentuk rantai. '
                'Karena itu catatan yang sudah disimpan tidak bisa diubah atau dihapus. Periksa isinya dulu '
                'sebelum menyimpan.',
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
              label: Text(_spot?.name ?? 'Pilih spot selam'),
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
              child: const Text('Simpan catatan'),
            ),
          ],
        ),
      ),
    );
  }
}
