import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:zerotrust_privacy/trackers/scan_cache.dart';
import 'package:zerotrust_privacy/trackers/tracker_results.dart';

Uint8List appKey(int fill) => Uint8List(32)..fillRange(0, 32, fill);

ScanMemory someMemory() =>
    ScanMemory(listVersion: '2023-12-05/428', system: 'B1')
      ..apps['com.secret.clinic'] = const AppTrackers(
        lastUpdate: 1700000000000,
        trackerIds: [49, 312],
      )
      ..apps['com.other'] = const AppTrackers(
        lastUpdate: 5,
        trackerIds: [],
        unreadable: true,
      );

void main() {
  late Directory folder;
  setUp(() => folder = Directory.systemTemp.createTempSync('zt_scan_cache'));
  tearDown(() => folder.deleteSync(recursive: true));

  Future<SealedFileScanCache> open(String user, int key) async =>
      SealedFileScanCache(
        SealedFileScanCache.fileIn(folder, user),
        await SealedFileScanCache.keyFrom(appKey(key)),
      );

  test('what is saved comes back, and the file names no app', () async {
    final cache = await open('user-1', 7);
    expect(await cache.load(), isNull);
    await cache.save(someMemory());

    final back = (await (await open('user-1', 7)).load())!;
    expect(back.listVersion, '2023-12-05/428');
    expect(back.system, 'B1');
    expect(back.apps['com.secret.clinic']!.trackerIds, [49, 312]);
    expect(back.apps['com.secret.clinic']!.lastUpdate, 1700000000000);
    expect(back.apps['com.other']!.unreadable, isTrue);

    // Sealed: nothing of it can be read from the file itself.
    final bytes = cache.file.readAsBytesSync();
    final text = latin1.decode(bytes);
    expect(text.contains('clinic'), isFalse);
    expect(text.contains('com.'), isFalse);
    expect(text.contains('2023'), isFalse);
    // No half-written file is left beside it.
    expect(folder.listSync().map((f) => f.uri.pathSegments.last), [
      'zt_privacy_tracker_scans_user-1.sealed',
    ]);
  });

  test('the key is not the account\'s own key', () async {
    final key = await SealedFileScanCache.keyFrom(appKey(7));
    expect(key.length, 32);
    expect(key, isNot(appKey(7)));
    expect(key, isNot(await SealedFileScanCache.keyFrom(appKey(8))));
  });

  test('another key reads nothing, and the apps are simply read '
      'again', () async {
    await (await open('user-1', 7)).save(someMemory());
    expect(await (await open('user-1', 8)).load(), isNull);
  });

  test('a damaged file reads as nothing', () async {
    final cache = await open('user-1', 7);
    await cache.save(someMemory());
    final bytes = cache.file.readAsBytesSync();
    bytes[bytes.length ~/ 2] ^= 0xff;
    cache.file.writeAsBytesSync(bytes);
    expect(await cache.load(), isNull);

    cache.file.writeAsBytesSync([1, 2, 3]);
    expect(await cache.load(), isNull);
    cache.file.writeAsBytesSync([]);
    expect(await cache.load(), isNull);

    // And the next save puts it right.
    await cache.save(someMemory());
    expect((await cache.load())!.apps.length, 2);
  });

  test('a save replaces the one before', () async {
    final cache = await open('user-1', 7);
    await cache.save(someMemory());
    await cache.save(ScanMemory(listVersion: 'next'));
    final back = (await cache.load())!;
    expect(back.listVersion, 'next');
    expect(back.apps, isEmpty);
  });

  test('once closed it reads and writes nothing', () async {
    final cache = await open('user-1', 7);
    await cache.save(someMemory());
    final before = cache.file.readAsBytesSync();
    cache.close();
    expect(await cache.load(), isNull);
    await cache.save(ScanMemory(listVersion: 'after'));
    expect(cache.file.readAsBytesSync(), before);
    // The file is still good for the next unlock.
    expect((await (await open('user-1', 7)).load())!.apps.length, 2);
  });

  test('files other accounts left behind are removed', () async {
    await (await open('user-1', 7)).save(someMemory());
    await (await open('user-2', 9)).save(someMemory());
    File(
      '${folder.path}/zt_privacy_tracker_scans_user-3.sealed.new',
    ).writeAsBytesSync([1]);
    File('${folder.path}/zt_privacy_user-1.db').writeAsBytesSync([1]);

    final mine = SealedFileScanCache.fileIn(folder, 'user-2');
    await SealedFileScanCache.removeOthers(folder, mine);
    expect(folder.listSync().map((f) => f.uri.pathSegments.last).toSet(), {
      'zt_privacy_tracker_scans_user-2.sealed',
      'zt_privacy_user-1.db',
    });
    expect((await (await open('user-2', 9)).load())!.apps.length, 2);

    // A folder that is not there is no error.
    await SealedFileScanCache.removeOthers(
      Directory('${folder.path}/missing'),
      mine,
    );
  });

  test('with no folder nothing is kept, and nothing fails', () async {
    const cache = NoScanCache();
    await cache.save(someMemory());
    expect(await cache.load(), isNull);
  });
}
