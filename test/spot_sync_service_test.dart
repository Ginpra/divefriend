import 'package:flutter_test/flutter_test.dart';

import 'package:divefriend/data/models/spot.dart';
import 'package:divefriend/data/repositories/spot_repository.dart';
import 'package:divefriend/services/api_failure.dart';
import 'package:divefriend/services/spot_sync_service.dart';
import 'fakes.dart';

Spot _spot(String id, String name) {
  return Spot(
    id: id,
    name: name,
    region: 'Wilayah',
    level: SpotLevel.pemula,
    levelBasis: 'uji',
    types: const [SpotType.scuba],
    tagline: 'uji',
    summary: 'uji',
    sources: const ['uji'],
  );
}

class _ThrowingRepository implements SpotRepository {
  @override
  Future<List<Spot>> getSpots({String query = '', SpotLevel? level}) async => [];

  @override
  Future<void> replaceAll(List<Spot> spots) async {
    throw Exception('disk penuh');
  }
}

void main() {
  late InMemorySpotRepository local;

  setUp(() {
    local = InMemorySpotRepository([_spot('lokal', 'Spot Lokal')]);
  });

  test('tanpa Supabase (belum diatur): data lokal dibiarkan', () async {
    final service = SpotSyncService(remote: null, local: local);

    final result = await service.sync();

    expect(result.status, SyncStatus.notConfigured);
    expect(result.message, 'Supabase belum diatur, memakai data spot lokal.');
    expect((await local.getSpots()).map((s) => s.id), ['lokal']);
  });

  test('berhasil: data online menimpa data lokal (satu arah) dan hasilnya dicatat', () async {
    final remote = FakeSpotRemoteSource(spots: [_spot('b', 'Bravo'), _spot('a', 'Alfa')]);
    final service = SpotSyncService(remote: remote, local: local);
    expect(service.lastResult, isNull);

    final result = await service.sync();

    expect(result.isSuccess, isTrue);
    expect(result.spotCount, 2);
    expect(result.message, 'Data spot disinkronkan dari Supabase (2 spot).');
    expect((await local.getSpots()).map((s) => s.id), ['a', 'b']);
    expect(service.lastResult, same(result));
  });

  test('offline: data lokal tetap utuh', () async {
    final service = SpotSyncService(
      remote: FakeSpotRemoteSource(failure: const ApiFailure(ApiFailureKind.offline)),
      local: local,
    );

    final result = await service.sync();

    expect(result.status, SyncStatus.offline);
    expect(result.message, 'Tidak ada koneksi internet, memakai data spot lokal.');
    expect((await local.getSpots()).map((s) => s.id), ['lokal']);
  });

  test('layanan bermasalah dan data rusak dipetakan ke status masing-masing', () async {
    final server = SpotSyncService(
      remote: FakeSpotRemoteSource(failure: const ApiFailure(ApiFailureKind.server)),
      local: local,
    );
    final bad = SpotSyncService(
      remote: FakeSpotRemoteSource(failure: const ApiFailure(ApiFailureKind.badData)),
      local: local,
    );

    expect((await server.sync()).status, SyncStatus.serviceProblem);
    expect((await bad.sync()).status, SyncStatus.badData);
    expect((await local.getSpots()).length, 1);
  });

  test('daftar kosong dari server TIDAK menghapus data lokal', () async {
    final service = SpotSyncService(remote: FakeSpotRemoteSource(spots: const []), local: local);

    final result = await service.sync();

    expect(result.status, SyncStatus.emptyRemote);
    expect(result.message, contains('cek RLS'));
    expect((await local.getSpots()).map((s) => s.id), ['lokal']);
  });

  test('gagal menyimpan di HP dilaporkan sebagai localError', () async {
    final service = SpotSyncService(
      remote: FakeSpotRemoteSource(spots: [_spot('a', 'Alfa')]),
      local: _ThrowingRepository(),
    );

    expect((await service.sync()).status, SyncStatus.localError);
  });

  test('semua pesan status tidak memakai titik koma', () {
    for (final status in SyncStatus.values) {
      expect(SyncResult(status, spotCount: 3).message.contains(';'), isFalse);
    }
  });
}
