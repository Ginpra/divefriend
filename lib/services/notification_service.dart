import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

enum ReminderResult { scheduled, tooLate, permissionDenied }

/// Kontrak pengingat. Layar hanya bergantung pada kelas ini, jadi tes bisa memakai versi palsu.
abstract class NotificationService {
  /// Menjadwalkan satu pengingat pada saat [at]. [id] dipakai lagi untuk membatalkannya.
  Future<ReminderResult> scheduleReminder({
    required int id,
    required String title,
    required String body,
    required DateTime at,
  });

  Future<void> cancelReminder(int id);
}

/// Notifikasi lokal terjadwal lewat flutter_local_notifications (tanpa server dan tanpa Firebase).
/// Memakai mode jadwal "inexact" supaya tidak butuh izin alarm tepat waktu, jadi pengingat bisa
/// terlambat beberapa menit saat HP sedang hemat daya.
class LocalNotificationService implements NotificationService {
  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  bool _ready = false;

  Future<void> _prepare() async {
    if (_ready) return;
    tz_data.initializeTimeZones();
    await _plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      ),
    );
    _ready = true;
  }

  @override
  Future<ReminderResult> scheduleReminder({
    required int id,
    required String title,
    required String body,
    required DateTime at,
  }) async {
    if (!at.isAfter(DateTime.now())) return ReminderResult.tooLate;
    await _prepare();

    final android = _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    final allowed = await android?.requestNotificationsPermission();
    if (allowed == false) return ReminderResult.permissionDenied;

    // Titik waktunya sudah pasti (milidetik sejak 1970), zona yang dipakai TZDateTime tidak mengubahnya.
    final scheduledDate = tz.TZDateTime.fromMillisecondsSinceEpoch(tz.local, at.millisecondsSinceEpoch);
    await _plugin.zonedSchedule(
      id: id,
      title: title,
      body: body,
      scheduledDate: scheduledDate,
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'divefriend_reminder',
          'Pengingat jadwal selam',
          channelDescription: 'Pengingat jam kumpul trip selam',
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
    );
    return ReminderResult.scheduled;
  }

  @override
  Future<void> cancelReminder(int id) async {
    await _prepare();
    await _plugin.cancel(id: id);
  }
}
