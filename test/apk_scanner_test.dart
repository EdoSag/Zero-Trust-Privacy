import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:zerotrust_privacy/scan/apk_scanner.dart';
import 'package:zerotrust_privacy/scan/tracker_scan.dart';
import 'package:zerotrust_privacy/scan/tracker_signatures.dart';

import 'support/fake_files.dart';

const sdks = [
  TrackerSdk('Tracker One', TrackerKind.analytics, ['com.example.tracker.']),
  TrackerSdk('Ad Kit', TrackerKind.ads, ['net.ads.kit.', 'net.ads.old.']),
  TrackerSdk('Never There', TrackerKind.profiling, ['org.absent.']),
];

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

  test('the starter list is well formed', () {
    final names = <String>{};
    for (final sdk in starterTrackers) {
      expect(names.add(sdk.name), isTrue, reason: 'twice: ${sdk.name}');
      expect(sdk.packages, isNotEmpty);
      for (final package in sdk.packages) {
        // Ends with a dot, so com.example. cannot match com.examples.
        expect(package, endsWith('.'), reason: package);
        expect(package, matches(RegExp(r'^[a-z0-9_.]+$')), reason: package);
      }
    }
    expect(
      starterTrackers.first.prefixes.first,
      'Lcom/google/firebase/analytics/'.codeUnits,
    );
  });

  test('the background scan gives one result per app, in order', () async {
    final one = apk('one.apk', [
      FakeEntry('classes.dex', fakeDex(['Lcom/example/tracker/Client;'])),
    ]);
    final two = apk('two.apk', [
      FakeEntry('classes.dex', fakeDex(['Lcom/example/app/Main;'])),
    ]);
    final scans = await const IsolateTrackerScanner(sdks: sdks).scan([
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

  test('the background scan ends at once with nothing to scan', () async {
    expect(
      await const IsolateTrackerScanner(sdks: sdks).scan([]).toList(),
      isEmpty,
    );
  });
}
