import 'package:flutter/material.dart';

import 'package:divefriend/app_services.dart';
import 'package:divefriend/core/booking_math.dart';
import 'package:divefriend/core/currencies.dart';
import 'package:divefriend/core/formatters.dart';
import 'package:divefriend/core/time_zones.dart';
import 'package:divefriend/core/widgets/inline_notice.dart';
import 'package:divefriend/data/models/booking.dart';
import 'package:divefriend/data/models/exchange_rates.dart';
import 'package:divefriend/data/models/spot.dart';
import 'package:divefriend/features/spot/gathering_time_card.dart';
import 'package:divefriend/services/api_failure.dart';
import 'package:divefriend/services/notification_service.dart';

String formatDate(DateTime date) {
  final day = date.day.toString().padLeft(2, '0');
  final month = date.month.toString().padLeft(2, '0');
  return '$day/$month/${date.year}';
}

/// Booking trip dalam tiga langkah: tanggal dan jam kumpul, jumlah orang, ringkasan.
/// Ini simulasi tanpa pembayaran. Kalau pengguna memilih pengingat, notifikasi lokal dijadwalkan
/// mundur dari jam kumpul. Layar ditutup dengan hasil true kalau pesanan tersimpan.
class BookingScreen extends StatefulWidget {
  const BookingScreen({super.key, required this.services, this.spot});

  final AppServices services;

  /// Kosong kalau dibuka dari daftar booking, pengguna memilih spot di langkah pertama.
  final Spot? spot;

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  int _step = 0;
  Spot? _spot;
  List<Spot> _spots = const [];
  DateTime? _date;
  TimeOfDay _time = defaultGatheringTime;
  int _people = 1;
  ReminderOption _reminder = ReminderOption.hourBefore;
  bool _saving = false;
  Future<ExchangeRates>? _ratesFuture;

  @override
  void initState() {
    super.initState();
    _spot = widget.spot;
    if (widget.spot == null) _loadSpots();
  }

  Future<void> _loadSpots() async {
    final spots = await widget.services.spots.getSpots();
    if (!mounted) return;
    setState(() {
      _spots = spots;
    });
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _pickDate() async {
    final today = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _date ?? today,
      firstDate: DateTime(today.year, today.month, today.day),
      lastDate: DateTime(today.year + 1, today.month, today.day),
    );
    if (picked == null) return;
    setState(() {
      _date = picked;
    });
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(context: context, initialTime: _time);
    if (picked == null) return;
    setState(() {
      _time = picked;
    });
  }

  void _next() {
    if (_step == 0) {
      if (_spot == null) return _showMessage('Pilih spot dulu ya.');
      if (_date == null) return _showMessage('Pilih tanggal selam dulu ya.');
    }
    if (_step == 2) {
      _confirm();
      return;
    }
    setState(() {
      _step += 1;
      if (_step == 2) _ratesFuture = widget.services.rates.fetchLatest();
    });
  }

  void _back() {
    if (_step == 0) return;
    setState(() {
      _step -= 1;
    });
  }

  Future<void> _confirm() async {
    final spot = _spot;
    final date = _date;
    final user = widget.services.auth.currentUser;
    final price = spot?.priceEstimateIdr;
    if (spot == null || date == null || user == null) return;
    if (price == null) return _showMessage('Harga simulasi belum ditetapkan untuk spot ini.');

    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    setState(() {
      _saving = true;
    });

    final gatheringMinutes = _time.hour * 60 + _time.minute;
    final int id;
    try {
      id = await widget.services.bookings.add(
        Booking(
          userId: user.id,
          spotId: spot.id,
          spotName: spot.name,
          diveDate: date,
          gatheringMinutes: gatheringMinutes,
          people: _people,
          priceIdrPerPerson: price,
          createdAt: DateTime.now(),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _saving = false;
      });
      messenger.showSnackBar(const SnackBar(content: Text('Booking gagal disimpan, coba lagi.')));
      return;
    }

    var message = 'Booking tersimpan.';
    final zone = zoneFromLabel(spot.timeZoneLabel);
    final reminderAt = zone == null
        ? null
        : reminderTime(
            diveDate: date,
            gatheringMinutes: gatheringMinutes,
            zone: zone,
            option: _reminder,
          );
    if (reminderAt != null && zone != null) {
      message = await _scheduleReminder(
        id: id,
        spot: spot,
        zone: zone,
        gatheringMinutes: gatheringMinutes,
        at: reminderAt,
      );
    }

    messenger.showSnackBar(SnackBar(content: Text(message)));
    navigator.pop(true);
  }

  /// Menjadwalkan pengingat dan mengembalikan kalimat hasilnya untuk pengguna.
  Future<String> _scheduleReminder({
    required int id,
    required Spot spot,
    required TimeZoneId zone,
    required int gatheringMinutes,
    required DateTime at,
  }) async {
    final clock = formatClock(DateTime.utc(2000, 1, 1, gatheringMinutes ~/ 60, gatheringMinutes % 60));
    try {
      final result = await widget.services.notifications.scheduleReminder(
        id: id,
        title: 'Pengingat trip ke ${spot.name}',
        body: 'Jam kumpul pukul $clock ${zone.label}. Siapkan perlengkapanmu.',
        at: at,
      );
      return switch (result) {
        ReminderResult.scheduled => 'Booking tersimpan dan pengingat dijadwalkan.',
        ReminderResult.tooLate => 'Booking tersimpan, tetapi waktu pengingat sudah lewat jadi tidak dijadwalkan.',
        ReminderResult.permissionDenied => 'Booking tersimpan, tetapi izin notifikasi ditolak jadi pengingat tidak aktif.',
      };
    } catch (_) {
      return 'Booking tersimpan, tetapi pengingat gagal dijadwalkan.';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Booking Trip')),
      body: Stepper(
        currentStep: _step,
        controlsBuilder: _buildControls,
        steps: [
          Step(
            title: const Text('Tanggal dan jam kumpul'),
            isActive: _step >= 0,
            content: _buildStepOne(),
          ),
          Step(
            title: const Text('Jumlah orang'),
            isActive: _step >= 1,
            content: _buildStepTwo(),
          ),
          Step(
            title: const Text('Ringkasan'),
            isActive: _step >= 2,
            content: _buildStepThree(),
          ),
        ],
      ),
    );
  }

  Widget _buildControls(BuildContext context, ControlsDetails details) {
    final isLast = _step == 2;
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Row(
        children: [
          FilledButton(
            onPressed: _saving ? null : _next,
            child: Text(isLast ? 'Konfirmasi booking' : 'Lanjut'),
          ),
          const SizedBox(width: 8),
          if (_step > 0)
            TextButton(onPressed: _saving ? null : _back, child: const Text('Kembali')),
        ],
      ),
    );
  }

  Widget _buildStepOne() {
    final spot = widget.spot;
    final date = _date;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (spot != null)
          Text(spot.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold))
        else
          DropdownButton<Spot>(
            isExpanded: true,
            hint: const Text('Pilih spot'),
            value: _spot,
            items: [
              for (final item in _spots) DropdownMenuItem(value: item, child: Text(item.name)),
            ],
            onChanged: (value) => setState(() => _spot = value),
          ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: _pickDate,
          icon: const Icon(Icons.calendar_month),
          label: Text(date == null ? 'Pilih tanggal selam' : formatDate(date)),
        ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: _pickTime,
          icon: const Icon(Icons.schedule),
          label: Text('Jam kumpul ${_time.hour.toString().padLeft(2, '0')}.${_time.minute.toString().padLeft(2, '0')} waktu setempat'),
        ),
        const SizedBox(height: 8),
        const Text(
          'Jam kumpul adalah jam peserta berkumpul di titik keberangkatan sebelum trip dimulai.',
          style: TextStyle(fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildStepTwo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            IconButton.outlined(
              tooltip: 'Kurangi',
              onPressed: _people > 1 ? () => setState(() => _people -= 1) : null,
              icon: const Icon(Icons.remove),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                '$_people',
                key: const Key('people_count'),
                style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
              ),
            ),
            IconButton.outlined(
              tooltip: 'Tambah',
              onPressed: _people < maxPeoplePerBooking ? () => setState(() => _people += 1) : null,
              icon: const Icon(Icons.add),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text('Maksimal $maxPeoplePerBooking orang per pesanan.', style: const TextStyle(fontSize: 12)),
      ],
    );
  }

  Widget _buildStepThree() {
    final spot = _spot;
    final date = _date;
    if (spot == null || date == null) {
      return const Text('Lengkapi langkah pertama dulu.');
    }
    final price = spot.priceEstimateIdr;
    final zone = zoneFromLabel(spot.timeZoneLabel);
    final gatheringMinutes = _time.hour * 60 + _time.minute;

    String gatheringText = 'zona waktu spot tidak diketahui';
    if (zone != null) {
      final local = DateTime.utc(2000, 1, 1, _time.hour, _time.minute);
      final londonWall = utcToWall(
        TimeZoneId.london,
        gatheringInstantUtc(diveDate: date, gatheringMinutes: gatheringMinutes, zone: zone),
      );
      final londonZone = zoneLabelAt(
        TimeZoneId.london,
        gatheringInstantUtc(diveDate: date, gatheringMinutes: gatheringMinutes, zone: zone),
      );
      gatheringText = '${formatClock(local)} ${zone.label} (${formatClock(londonWall)} $londonZone di London)';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SummaryRow(label: 'Spot', value: spot.name),
        _SummaryRow(label: 'Tanggal', value: formatDate(date)),
        _SummaryRow(label: 'Jam kumpul', value: gatheringText),
        _SummaryRow(label: 'Peserta', value: '$_people orang'),
        const Divider(height: 24),
        if (price == null)
          const Text('Harga simulasi belum ditetapkan untuk spot ini.')
        else
          _buildPrices(price),
        const Divider(height: 24),
        const Text('Pengingat'),
        DropdownButton<ReminderOption>(
          isExpanded: true,
          value: _reminder,
          items: [
            for (final option in ReminderOption.values)
              DropdownMenuItem(value: option, child: Text(option.label)),
          ],
          onChanged: (value) {
            if (value != null) setState(() => _reminder = value);
          },
        ),
        const SizedBox(height: 8),
        const Text(
          'Ini booking simulasi untuk tugas, tanpa pembayaran dan tidak dikirim ke operator selam mana pun.',
          style: TextStyle(fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildPrices(int pricePerPerson) {
    final total = pricePerPerson * _people;
    return FutureBuilder<ExchangeRates>(
      future: _ratesFuture,
      builder: (context, snapshot) {
        final rates = snapshot.data;
        final waiting = snapshot.connectionState == ConnectionState.waiting;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Expanded(child: Text('Total (harga simulasi)')),
                Text(
                  formatMoney(total.toDouble(), currencyByCode('IDR')),
                  key: const Key('booking_total_idr'),
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            Text(
              '$_people orang x ${formatMoney(pricePerPerson.toDouble(), currencyByCode('IDR'))}',
              style: const TextStyle(fontSize: 12),
            ),
            const SizedBox(height: 6),
            for (final code in priceCurrencyCodes.where((code) => code != 'IDR'))
              _SummaryRow(
                label: currencyByCode(code).name,
                value: waiting
                    ? 'memuat'
                    : _convertedText(rates, total, code),
              ),
            if (snapshot.hasError)
              InlineNotice(
                icon: Icons.cloud_off,
                message: failureText(snapshot.error!, 'kurs'),
              ),
          ],
        );
      },
    );
  }

  String _convertedText(ExchangeRates? rates, int totalIdr, String code) {
    final converted = rates?.convert(totalIdr.toDouble(), 'IDR', code);
    return converted == null ? 'tidak tersedia' : formatMoney(converted, currencyByCode(code));
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 110, child: Text(label, style: const TextStyle(fontWeight: FontWeight.w600))),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
