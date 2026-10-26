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
            padding: EdgeInsets.fromLTRB(16, 16, 16, 88 + bottomInset(context)),
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

const List<String> _monthShort = [
  'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des',
];

class _BookingCard extends StatelessWidget {
  const _BookingCard({required this.booking, required this.onCancel});

  final Booking booking;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final clock =
        '${booking.gatheringHour.toString().padLeft(2, '0')}.${booking.gatheringMinute.toString().padLeft(2, '0')}';
    final date = booking.diveDate;
    return Container(
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
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Blok tanggal: tanggal besar di atas, bulan singkat di bawah.
              Container(
                width: 60,
                padding: const EdgeInsets.symmetric(vertical: AppSpace.sm),
                decoration: BoxDecoration(
                  gradient: AppGradients.deepSea,
                  borderRadius: BorderRadius.circular(AppRadius.field),
                ),
                child: Column(
                  children: [
                    Text(
                      '${date.day}',
                      style: const TextStyle(fontFamily: AppFonts.heading, fontSize: 24, color: Colors.white),
                    ),
                    Text(
                      _monthShort[date.month - 1],
                      style: const TextStyle(fontSize: 12, color: AppColors.mintSoft),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpace.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(booking.spotName, style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: AppSpace.xs),
                    Text('Tanggal ${formatDate(booking.diveDate)}', style: Theme.of(context).textTheme.bodySmall),
                    Text('Jam kumpul $clock waktu setempat', style: Theme.of(context).textTheme.bodySmall),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpace.md),
          Row(
            children: [
              _InfoChip(icon: Icons.group_outlined, text: '${booking.people} orang'),
              const SizedBox(width: AppSpace.sm),
              const _InfoChip(icon: Icons.sell_outlined, text: 'Harga simulasi'),
            ],
          ),
          const SizedBox(height: AppSpace.md),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Total ${formatMoney(booking.totalIdr.toDouble(), currencyByCode('IDR'))} (harga simulasi)',
                  style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.navy),
                ),
              ),
              TextButton.icon(
                onPressed: onCancel,
                style: TextButton.styleFrom(foregroundColor: const Color(0xFFB3261E)),
                icon: const Icon(Icons.delete_outline),
                label: const Text('Batalkan'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.mintSoft,
        borderRadius: BorderRadius.circular(AppRadius.chip),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.tealDeep),
          const SizedBox(width: 4),
          Text(text, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.tealDeep)),
        ],
      ),
    );
  }
}
