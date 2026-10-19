import 'package:divefriend/data/models/spot.dart';

/// Kontrak sumber data spot. UI hanya bergantung pada kelas ini.
/// Tahap 1: DummySpotRepository. Tahap 3: SQLite. Tahap 7: sinkron satu arah dari Supabase.
/// Saat sumber data diganti, layar tidak perlu diubah.
abstract class SpotRepository {
  Future<List<Spot>> getSpots({String query = '', SpotLevel? level});

  /// Mengganti SELURUH data spot lokal dengan [spots] (atomik). Dipakai sinkronisasi satu arah
  /// dari Supabase: online menimpa lokal, tidak pernah sebaliknya.
  Future<void> replaceAll(List<Spot> spots);
}
