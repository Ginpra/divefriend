import 'package:flutter/material.dart';

import 'package:divefriend/app_services.dart';
import 'package:divefriend/core/app_theme.dart';
import 'package:divefriend/core/currencies.dart';
import 'package:divefriend/core/formatters.dart';
import 'package:divefriend/core/widgets/state_message.dart';
import 'package:divefriend/data/models/booking.dart';
import 'package:divefriend/features/booking/booking_screen.dart';

/// Daftar booking milik pengguna. Booking baru dibuat lewat tombol di bawah, dan booking yang
/// tidak jadi bisa dibatalkan (pengingatnya ikut dibatalkan).
class BookingListScreen extends StatefulWidget {
  const BookingListScreen({super.key, required this.services});

  final AppServices services;

  @override
  State<BookingListScreen> createState() => _BookingListScreenState();
}

class _BookingListScreenState extends State<BookingListScreen> {
  late Future<List<Booking>> _future = _load();

  int get _userId => widget.services.auth.currentUser?.id ?? -1;

  Future<List<Booking>> _load() => widget.services.bookings.forUser(_userId);

  void _reload() {
    setState(() {
      _future = _load();
    });
  }

  Future<void> _newBooking() async {
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(builder: (_) => BookingScreen(services: widget.services)),
    );
    if (saved == true) _reload();
  }

  Future<void> _cancel(Booking booking) async {
    final id = booking.id;
    if (id == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Batalkan booking?'),
        content: Text('Booking ke ${booking.spotName} akan dihapus.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Tidak'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Batalkan'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    await widget.services.bookings.delete(userId: _userId, id: id);
    try {
      await widget.services.notifications.cancelReminder(id);
    } catch (_) {
      // Pengingat yang gagal dibatalkan tidak menghalangi pembatalan booking.
    }
    if (mounted) _reload();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Booking Saya')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _newBooking,
        icon: const Icon(Icons.add),
        label: const Text('Booking baru'),
      ),
      body: FutureBuilder<List<Booking>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return StateMessage(
              icon: Icons.error_outline,
              title: 'Booking gagal dimuat',
              message: 'Terjadi kesalahan saat membaca data.',
              actionLabel: 'Coba lagi',
              onAction: _reload,
            );
          }
          final bookings = snapshot.data ?? const <Booking>[];
          if (bookings.isEmpty) {
            return const StateMessage(
              icon: Icons.event_busy_outlined,
              title: 'Belum ada booking',
              message: 'Tekan Booking baru untuk memesan trip simulasi.',
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 88),
            itemCount: bookings.length,
            separatorBuilder: (context, index) => const SizedBox(height: 10),
            itemBuilder: (context, index) => _BookingCard(
              booking: bookings[index],
              onCancel: () => _cancel(bookings[index]),
            ),
          );
        },
      ),
    );
  }
}

class _BookingCard extends StatelessWidget {
  const _BookingCard({required this.booking, required this.onCancel});

  final Booking booking;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final clock =
        '${booking.gatheringHour.toString().padLeft(2, '0')}.${booking.gatheringMinute.toString().padLeft(2, '0')}';
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              booking.spotName,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.navy),
            ),
            const SizedBox(height: 4),
            Text('Tanggal ${formatDate(booking.diveDate)}, jam kumpul $clock waktu setempat'),
            Text('${booking.people} orang'),
            Text(
              'Total ${formatMoney(booking.totalIdr.toDouble(), currencyByCode('IDR'))} (harga simulasi)',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: onCancel,
                icon: const Icon(Icons.delete_outline),
                label: const Text('Batalkan'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
