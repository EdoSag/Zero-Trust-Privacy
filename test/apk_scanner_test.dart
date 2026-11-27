import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:zerotrust_privacy/scan/apk_scanner.dart';
import 'package:zerotrust_privacy/scan/tracker_list.dart';
import 'package:zerotrust_privacy/scan/tracker_scan.dart';

import 'support/fake_files.dart';

const sdks = [
  Tracker(id: 1, name: 'Tracker One', code: ['com.example.tracker.']),
  Tracker(id: 2, name: 'Ad Kit', code: ['net.ads.kit.', 'net.ads.old.']),
  Tracker(id: 3, name: 'Never There', code: ['org.absent.']),
  // Exodus's three shapes besides a package: one class, a package with no
  // dot at the end, and the end of a class name under any package.
  Tracker(id: 4, name: 'One Class', code: ['com.maker.sdk.Collector']),
  Tracker(id: 5, name: 'No Dot', code: ['com.short']),
  Tracker(id: 6, name: 'Any Package', code: ['.BeaconManager']),
];

Future<List<Tracker>> loadSdks() async => sdks;

void main() {
  late Directory temp;

  setUp(() => temp = Directory.systemTemp.createTempSync('apk_test'));
  tearDown(() => temp.deleteSync(recursive: true));

  String apk(String name, List<FakeEntry> entries) =>
      writeFile(temp, name, fakeZip(entries));

  test('finds kits across several code files and several APK files', () {
    final base = apk('base.apk', [
      FakeEntry('classes.dex', fakeDex(['Lcom/example/app/Main;'])),
      FakeEntry('classes2.dex', fakeDex(['Lcom/example/tracker/Client;'])),
      const FakeEntry('resources.arsc', [1, 2, 3]),
    ]);
    final split = apk('split_feature.apk', [
      FakeEntry('classes.dex', fakeDex(['Lnet/ads/old/Banner;'])),
    ]);
    final result = scanApkFiles([base, split], sdks);
    expect(result.found, {'Tracker One', 'Ad Kit'});
    expect(result.dexFiles, 3);
    expect(result.types, 3);
    expect(result.dexBytes, greaterThan(0));
    expect(result.errors, isEmpty);
  });

  test('an app without the kits comes back clean', () {
    final base = apk('base.apk', [
      FakeEntry('classes.dex', fakeDex(['Lcom/example/app/Main;'])),
    ]);
    final result = scanApkFiles([base], sdks);
    expect(result.found, isEmpty);
    expect(result.dexFiles, 1);
  });

  test('only real code files are read', () {
    final base = apk('base.apk', [
      // Same bytes, but not where Android looks for code.
      FakeEntry('assets/classes.dex', fakeDex(['Lcom/example/tracker/A;'])),
      FakeEntry('classes.dex.bak', fakeDex(['Lcom/example/tracker/A;'])),
    ]);
    final result = scanApkFiles([base], sdks);
    expect(result.found, isEmpty);
    expect(result.dexFiles, 0);
  });

  test('a split with no code is fine', () {
    final split = apk('split_config.en.apk', [
      const FakeEntry('resources.arsc', [1, 2, 3]),
    ]);
    final result = scanApkFiles([split], sdks);
    expect(result.dexFiles, 0);
    expect(result.errors, isEmpty);
  });

  test('a damaged file is reported and the rest is still scanned', () {
    final broken = writeFile(temp, 'broken.apk', List.filled(400, 9));
    final badCode = apk('odd.apk', [
      const FakeEntry('classes.dex', [1, 2, 3, 4]),
      FakeEntry('classes2.dex', fakeDex(['Lnet/ads/kit/Show;'])),
    ]);
    final missing = '${temp.path}/gone.apk';
    final result = scanApkFiles([broken, badCode, missing], sdks);
    expect(result.found, {'Ad Kit'});
    expect(result.errors, hasLength(3));
    expect(result.errors[0], startsWith('broken.apk: '));
    expect(result.errors[1], startsWith('classes.dex: '));
    expect(result.errors[2], startsWith('gone.apk: '));
  });

  test('a signature is matched the way its shape asks', () {
    Set<String> found(List<String> classes) => scanApkFiles([
      apk('app${classes.hashCode}.apk', [
        FakeEntry('classes.dex', fakeDex(classes)),
      ]),
    ], sdks).found;

    // One class: the class itself and the classes inside it.
    expect(found(['Lcom/maker/sdk/Collector;']), {'One Class'});
    expect(found(['Lcom/maker/sdk/Collector\$Job;']), {'One Class'});
    expect(found(['Lcom/maker/sdk/Other;']), isEmpty);
    // No dot at the end: whatever starts with it, as in Exodus.
    expect(found(['Lcom/short/Main;']), {'No Dot'});
    expect(found(['Lcom/shorter/Main;']), {'No Dot'});
    // The start of the name, never the middle of another package.
    expect(found(['Lxcom/short/Main;']), isEmpty);
    expect(found(['Lorg/copy/com/short/Main;']), isEmpty);
    expect(found(['Lorg/copy/net/ads/kit/Show;']), isEmpty);
    // The end of a class name, under any package.
    expect(found(['Lorg/any/where/BeaconManager;']), {'Any Package'});
    expect(found(['Lorg/any/where/BeaconManagers;']), {'Any Package'});
    expect(found(['Lorg/any/where/MyBeaconManager;']), isEmpty);
    expect(found(['LBeaconManager;']), isEmpty);
  });

  test('the background scan gives one result per app, in order', () async {
    final one = apk('one.apk', [
      FakeEntry('classes.dex', fakeDex(['Lcom/example/tracker/Client;'])),
    ]);
    final two = apk('two.apk', [
      FakeEntry('classes.dex', fakeDex(['Lcom/example/app/Main;'])),
    ]);
    final scans = await const IsolateTrackerScanner(loadSdks).scan([
      ScanTarget('app.one', [one]),
      ScanTarget('app.two', [two]),
      ScanTarget('app.gone', ['${temp.path}/gone.apk']),
    ]).toList();
    expect(scans.map((s) => s.package), ['app.one', 'app.two', 'app.gone']);
    expect(scans[0].found, ['Tracker One']);
    expect(scans[0].dexFiles, 1);
    expect(scans[1].found, isEmpty);
    expect(scans[2].errors, hasLength(1));
  });

  test('a scan cancelled before it starts leaves nothing running', () async {
    final asked = Completer<List<Tracker>>();
    final results = <AppScan>[];
    final scan = IsolateTrackerScanner(() => asked.future)
        .scan([
          ScanTarget('app.gone', ['${temp.path}/gone.apk']),
        ])
        .listen(results.add);
    await scan.cancel();
    asked.complete(sdks);
    await Future<void>.delayed(const Duration(milliseconds: 200));
    expect(results, isEmpty);
  });

  test('the background scan ends at once with nothing to scan', () async {
    expect(
      await const IsolateTrackerScanner(loadSdks).scan([]).toList(),
      isEmpty,
    );
  });
}
