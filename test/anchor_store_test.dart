import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:divefriend/data/models/chain_anchor.dart';
import 'package:divefriend/services/anchor_store.dart';

ChainAnchor sampleAnchor(String txHash) {
  return ChainAnchor(
    headHash: 'a' * 64,
    entryCount: 2,
    txHash: txHash,
    createdAt: '2026-10-27T00:00:00.000Z',
  );
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('jangkar disimpan berurutan dan terbaca kembali', () async {
    final store = AnchorStore();
    await store.add(1, sampleAnchor('0x1'));
    await store.add(1, sampleAnchor('0x2'));

    final anchors = await store.all(1);

    expect(anchors.map((anchor) => anchor.txHash), ['0x1', '0x2']);
    expect(anchors.first.confirmed, isFalse);
    expect(anchors.first.entryCount, 2);
  });

  test('markConfirmed hanya mengubah transaksi yang dimaksud', () async {
    final store = AnchorStore();
    await store.add(1, sampleAnchor('0x1'));
    await store.add(1, sampleAnchor('0x2'));

    await store.markConfirmed(1, '0x2');

    final anchors = await store.all(1);
    expect(anchors[0].confirmed, isFalse);
    expect(anchors[1].confirmed, isTrue);
  });

  test('data tiap pengguna terpisah dan clear menghapusnya', () async {
    final store = AnchorStore();
    await store.add(1, sampleAnchor('0x1'));
    await store.add(2, sampleAnchor('0x2'));

    await store.clear(1);

    expect(await store.all(1), isEmpty);
    expect((await store.all(2)).length, 1);
  });
}
