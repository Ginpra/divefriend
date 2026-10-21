import 'package:divefriend/data/models/app_user.dart';
import 'package:divefriend/data/models/booking.dart';
import 'package:divefriend/app_services.dart';
import 'package:divefriend/data/models/exchange_rates.dart';
import 'package:divefriend/data/models/geo_point.dart';
import 'package:divefriend/data/models/log_entry.dart';
import 'package:divefriend/data/models/sea_conditions.dart';
import 'package:divefriend/data/models/spot.dart';
import 'package:divefriend/data/remote/spot_remote_source.dart';
import 'package:divefriend/data/repositories/booking_repository.dart';
import 'package:divefriend/data/repositories/logbook_repository.dart';
import 'package:divefriend/data/repositories/spot_repository.dart';
import 'package:divefriend/data/repositories/user_repository.dart';
import 'package:divefriend/services/api_failure.dart';
import 'package:divefriend/services/biometric_service.dart';
import 'package:divefriend/services/auth_service.dart';
import 'package:divefriend/services/exchange_rate_service.dart';
import 'package:divefriend/services/gemini_service.dart';
import 'package:divefriend/services/location_service.dart';
import 'package:divefriend/services/logbook_service.dart';
import 'package:divefriend/services/map_launcher.dart';
import 'package:divefriend/services/marine_service.dart';
import 'package:divefriend/services/notification_service.dart';
import 'package:divefriend/services/sensor_service.dart';
import 'package:divefriend/services/spot_sync_service.dart';

/// Penyimpanan pengguna di memori, dipakai tes agar tidak butuh SQLite asli.
class InMemoryUserRepository implements UserRepository {
  final List<AppUser> _users = [];
  int _nextId = 1;

  @override
  Future<AppUser?> findByUsername(String username) async {
    for (final user in _users) {
      if (user.username == username) return user;
    }
    return null;
  }

  @override
  Future<AppUser?> findById(int id) async {
    for (final user in _users) {
      if (user.id == id) return user;
    }
    return null;
  }

  @override
  Future<AppUser> create({
    required String name,
    required String username,
    required String passwordHash,
    required String salt,
  }) async {
    final user = AppUser(
      id: _nextId++,
      name: name,
      username: username,
      passwordHash: passwordHash,
      salt: salt,
    );
    _users.add(user);
    return user;
  }

  @override
  Future<void> updatePhotoPath(int id, String? photoPath) async {
    final index = _users.indexWhere((user) => user.id == id);
    if (index != -1) _users[index] = _users[index].withPhoto(photoPath);
  }

  @override
  Future<void> delete(int id) async {
    _users.removeWhere((user) => user.id == id);
  }
}

/// Spot di memori (urut nama, seperti SQLite), dipakai tes layar.
class InMemorySpotRepository implements SpotRepository {
  InMemorySpotRepository(List<Spot> spots)
      : _spots = [...spots]..sort((a, b) => a.name.compareTo(b.name));

  List<Spot> _spots;

  @override
  Future<void> replaceAll(List<Spot> spots) async {
    _spots = [...spots]..sort((a, b) => a.name.compareTo(b.name));
  }

  @override
  Future<List<Spot>> getSpots({String query = '', SpotLevel? level}) async {
    final normalizedQuery = query.trim().toLowerCase();
    return _spots.where((spot) {
      final matchesLevel = level == null || spot.level == level;
      final matchesQuery = normalizedQuery.isEmpty ||
          spot.name.toLowerCase().contains(normalizedQuery) ||
          spot.region.toLowerCase().contains(normalizedQuery);
      return matchesLevel && matchesQuery;
    }).toList();
  }
}

/// Biometrik palsu: hasilnya bisa diatur dari tes.
class FakeBiometric extends BiometricService {
  FakeBiometric({this.available = true, this.succeeds = true});

  final bool available;
  final bool succeeds;

  @override
  Future<bool> isAvailable() async => available;

  @override
  Future<bool> authenticate(String reason) async => succeeds;
}

/// Kurs contoh: angka diambil dari respons nyata Frankfurter tanggal 2026-10-16.
const ExchangeRates sampleRates = ExchangeRates(
  date: '2026-10-16',
  perEuro: {
    'EUR': 1.0,
    'IDR': 20290.28,
    'USD': 1.1253,
    'SGD': 1.4395,
    'JPY': 177.82,
    'AUD': 1.6171,
  },
);

/// Layanan kurs palsu: langsung memberi [sampleRates], atau melempar [failure] kalau diisi.
class FakeRateService implements ExchangeRateService {
  FakeRateService({this.failure});

  final ApiFailure? failure;

  @override
  Future<ExchangeRates> fetchLatest({bool forceRefresh = false}) async {
    final error = failure;
    if (error != null) throw error;
    return sampleRates;
  }
}

/// Layanan gelombang palsu: memberi [conditions], atau melempar [failure] kalau diisi.
class FakeMarineService implements MarineService {
  FakeMarineService({
    this.conditions = const SeaConditions(
      currentWaveHeightM: 0.6,
      maxWaveHeightTodayM: 0.9,
    ),
    this.failure,
  });

  final SeaConditions conditions;
  final ApiFailure? failure;

  @override
  Future<SeaConditions> fetchToday({
    required double latitude,
    required double longitude,
  }) async {
    final error = failure;
    if (error != null) throw error;
    return conditions;
  }
}

/// Layanan posisi palsu: mengirim [points] satu per satu, atau langsung error kalau [error] diisi.
class FakeLocationService implements LocationService {
  FakeLocationService({this.points = const [], this.error});

  final List<GeoPoint> points;
  final Object? error;
  final List<LocationFailureKind> openedSettings = [];

  @override
  Stream<GeoPoint> positions() {
    final failure = error;
    if (failure != null) return Stream<GeoPoint>.error(failure);
    return Stream<GeoPoint>.fromIterable(points);
  }

  @override
  Future<void> openSettings(LocationFailureKind kind) async {
    openedSettings.add(kind);
  }
}

/// Sensor palsu: mengirim [headingValues] satu per satu, atau error kalau [hasCompass] false.
class FakeSensorService implements SensorService {
  FakeSensorService({this.headingValues = const [], this.hasCompass = true});

  final List<double> headingValues;
  final bool hasCompass;

  @override
  Stream<double> headings() {
    if (!hasCompass) return Stream<double>.error(StateError('tidak ada sensor'));
    return Stream<double>.fromIterable(headingValues);
  }

  @override
  Stream<void> shakes() => const Stream<void>.empty();
}

/// Pembuka peta palsu: mencatat titik dan rute yang diminta dibuka.
class FakeMapLauncher implements MapLauncher {
  FakeMapLauncher({this.succeeds = true});

  final bool succeeds;
  final List<GeoPoint> opened = [];
  final List<({String? origin, String destination})> routes = [];

  @override
  Future<bool> open(GeoPoint point) async {
    opened.add(point);
    return succeeds;
  }

  @override
  Future<bool> openDirections({String? origin, required String destination}) async {
    routes.add((origin: origin, destination: destination));
    return succeeds;
  }
}

/// Semua layanan palsu sekaligus, supaya tes layar cukup menulis bagian yang berbeda.
AppServices buildTestServices({
  required AuthService auth,
  ExchangeRateService? rates,
  MarineService? marine,
  LocationService? location,
  SensorService? sensors,
  MapLauncher? maps,
  LogbookService? logbook,
  SpotRemoteSource? spotRemote,
  List<Spot>? spots,
  BookingRepository? bookings,
  NotificationService? notifications,
  GeminiService? gemini,
}) {
  final spotRepository = InMemorySpotRepository(spots ?? const []);
  return AppServices(
    spots: spotRepository,
    auth: auth,
    rates: rates ?? FakeRateService(),
    marine: marine ?? FakeMarineService(),
    location: location ?? FakeLocationService(),
    sensors: sensors ?? FakeSensorService(),
    maps: maps ?? FakeMapLauncher(),
    logbook: logbook ?? LogbookService(InMemoryLogbookRepository()),
    sync: SpotSyncService(remote: spotRemote, local: spotRepository),
    bookings: bookings ?? InMemoryBookingRepository(),
    notifications: notifications ?? FakeNotificationService(),
    gemini: gemini ?? FakeGeminiService(),
  );
}

/// Penyimpanan logbook di memori, dipakai tes agar tidak butuh SQLite asli.
class InMemoryLogbookRepository implements LogbookRepository {
  final List<LogEntry> _entries = [];

  @override
  Future<List<LogEntry>> entriesFor(int userId) async {
    final mine = _entries.where((entry) => entry.userId == userId).toList();
    mine.sort((a, b) => a.seq.compareTo(b.seq));
    return mine;
  }

  @override
  Future<void> replaceAll(int userId, List<LogEntry> entries) async {
    _entries.removeWhere((entry) => entry.userId == userId);
    _entries.addAll(entries);
  }

  @override
  Future<void> rewriteNotesWithoutRehash(int userId, int seq, String notes) async {
    final index = _entries.indexWhere((entry) => entry.userId == userId && entry.seq == seq);
    if (index == -1) return;
    _entries[index] = _entries[index].withNotes(notes);
  }

  /// Hanya untuk tes: mengganti satu catatan mentah-mentah (misalnya memutus rantai).
  void replaceEntry(int userId, int seq, LogEntry replacement) {
    final index = _entries.indexWhere((entry) => entry.userId == userId && entry.seq == seq);
    _entries[index] = replacement;
  }

  /// Hanya untuk tes: menghapus satu catatan mentah-mentah, meniru penghapusan langsung di database.
  void removeEntry(int userId, int seq) {
    _entries.removeWhere((entry) => entry.userId == userId && entry.seq == seq);
  }
}

/// Sumber spot online palsu: memberi [spots], atau melempar [failure] kalau diisi.
class FakeSpotRemoteSource implements SpotRemoteSource {
  FakeSpotRemoteSource({this.spots = const [], this.failure});

  final List<Spot> spots;
  final ApiFailure? failure;
  int calls = 0;

  @override
  Future<List<Spot>> fetchSpots() async {
    calls++;
    final error = failure;
    if (error != null) throw error;
    return spots;
  }
}


/// Pesanan di memori, dipakai tes agar tidak butuh SQLite asli.
class InMemoryBookingRepository implements BookingRepository {
  final List<Booking> _bookings = [];
  int _nextId = 1;

  @override
  Future<int> add(Booking booking) async {
    final id = _nextId++;
    _bookings.add(
      Booking(
        id: id,
        userId: booking.userId,
        spotId: booking.spotId,
        spotName: booking.spotName,
        diveDate: booking.diveDate,
        gatheringMinutes: booking.gatheringMinutes,
        people: booking.people,
        priceIdrPerPerson: booking.priceIdrPerPerson,
        createdAt: booking.createdAt,
      ),
    );
    return id;
  }

  @override
  Future<List<Booking>> forUser(int userId) async {
    return _bookings.where((booking) => booking.userId == userId).toList().reversed.toList();
  }

  @override
  Future<void> delete({required int userId, required int id}) async {
    _bookings.removeWhere((booking) => booking.userId == userId && booking.id == id);
  }

  @override
  Future<void> deleteAllForUser(int userId) async {
    _bookings.removeWhere((booking) => booking.userId == userId);
  }
}

/// Pengingat palsu: mencatat jadwal dan pembatalan yang diminta.
class FakeNotificationService implements NotificationService {
  FakeNotificationService({this.result = ReminderResult.scheduled});

  final ReminderResult result;
  final List<({int id, String title, DateTime at})> scheduled = [];
  final List<int> cancelled = [];

  @override
  Future<ReminderResult> scheduleReminder({
    required int id,
    required String title,
    required String body,
    required DateTime at,
  }) async {
    scheduled.add((id: id, title: title, at: at));
    return result;
  }

  @override
  Future<void> cancelReminder(int id) async {
    cancelled.add(id);
  }
}

/// Asisten AI palsu: menjawab dengan [answer] atau melempar [failure].
class FakeGeminiService implements GeminiService {
  FakeGeminiService({this.answer = 'Jawaban contoh', this.failure, this.configured = true});

  final String answer;
  final GeminiFailure? failure;
  final bool configured;
  final List<String> prompts = [];

  @override
  bool get isConfigured => configured;

  @override
  Future<String> reply(List<ChatTurn> history, {required String systemPrompt}) async {
    prompts.add(systemPrompt);
    final error = failure;
    if (error != null) throw error;
    return answer;
  }
}
