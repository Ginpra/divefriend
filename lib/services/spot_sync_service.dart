import 'package:divefriend/data/models/spot.dart';
import 'package:divefriend/data/remote/spot_remote_source.dart';
import 'package:divefriend/data/repositories/spot_repository.dart';
import 'package:divefriend/services/api_failure.dart';

enum SyncStatus {
  /// secrets.dart belum diisi, aplikasi memakai data lokal.
  notConfigured,
  success,
  offline,
  serviceProblem,
  badData,

  /// Server menjawab tapi daftarnya kosong. Biasanya karena kebijakan RLS belum dipasang.
  emptyRemote,

  /// Data online berhasil diambil tapi gagal disimpan di HP.
  localError,
}

class SyncResult {
  const SyncResult(this.status, {this.spotCount = 0});

  final SyncStatus status;
  final int spotCount;

  bool get isSuccess => status == SyncStatus.success;

  /// Kalimat status untuk pengguna.
  String get message {
    return switch (status) {
      SyncStatus.notConfigured => 'Supabase belum diatur, memakai data spot lokal.',
      SyncStatus.success => 'Data spot disinkronkan dari Supabase ($spotCount spot).',
      SyncStatus.offline => 'Tidak ada koneksi internet, memakai data spot lokal.',
      SyncStatus.serviceProblem => 'Supabase tidak bisa diakses (cek URL dan kunci), memakai data spot lokal.',
      SyncStatus.badData => 'Data dari Supabase tidak bisa dibaca, memakai data spot lokal.',
      SyncStatus.emptyRemote =>
        'Tabel spots di Supabase kosong atau tidak bisa dibaca (cek RLS), memakai data spot lokal.',
      SyncStatus.localError => 'Data dari Supabase gagal disimpan di HP, memakai data spot lokal.',
    };
  }
}

/// Sinkronisasi SATU ARAH: data spot dari Supabase (online) menimpa data spot di SQLite (lokal).
/// Tidak pernah mengirim apa pun ke server. Kalau gagal dengan alasan apa pun, data lokal dibiarkan
/// utuh supaya aplikasi tetap jalan saat offline. Daftar kosong dari server tidak pernah dipakai
/// untuk menghapus data lokal.
class SpotSyncService {
  SpotSyncService({required this._remote, required SpotRepository local})
      : _local = local;

  final SpotRemoteSource? _remote;
  final SpotRepository _local;

  /// Hasil sinkronisasi terakhir, null kalau belum pernah dijalankan sejak aplikasi dibuka.
  SyncResult? lastResult;

  Future<SyncResult> sync() async {
    final result = await _run();
    lastResult = result;
    return result;
  }

  Future<SyncResult> _run() async {
    final remote = _remote;
    if (remote == null) return const SyncResult(SyncStatus.notConfigured);

    final List<Spot> spots;
    try {
      spots = await remote.fetchSpots();
    } on ApiFailure catch (failure) {
      return SyncResult(switch (failure.kind) {
        ApiFailureKind.offline => SyncStatus.offline,
        ApiFailureKind.server => SyncStatus.serviceProblem,
        ApiFailureKind.badData => SyncStatus.badData,
      });
    }
    if (spots.isEmpty) return const SyncResult(SyncStatus.emptyRemote);

    try {
      await _local.replaceAll(spots);
    } on Exception {
      return const SyncResult(SyncStatus.localError);
    }
    return SyncResult(SyncStatus.success, spotCount: spots.length);
  }
}
