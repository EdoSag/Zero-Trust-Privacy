import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:zerotrust_privacy/scan/tracker_list.dart';

/// The list the app really ships, read from the repository.
TrackerList shipped() =>
    TrackerList.fromJson(File(TrackerList.asset).readAsStringSync());

void main() {
  test('the shipped list reads and says where it is from', () {
    final list = shipped();
    expect(list.trackers.length, greaterThan(400));
    expect(list.newestEntry, matches(RegExp(r'^\d{4}-\d\d-\d\d$')));
    expect(list.attribution, contains('Exodus Privacy'));
    expect(list.attribution, contains('ODbL'));
    expect(
      list.version,
      startsWith('${list.newestEntry}/${list.trackers.length}/'),
    );

    final raw =
        jsonDecode(File(TrackerList.asset).readAsStringSync())
            as Map<String, Object?>;
    expect(raw['license'], 'ODbL-1.0');
    // The licence's notice travels with the file.
    expect(
      File('assets/trackers/NOTICE.md').readAsStringSync(),
      contains('Open Database License'),
    );
  });

  test('every tracker can be found by a scan and told apart', () {
    final list = shipped();
    expect(list.byId.length, list.trackers.length);
    expect(list.byName.length, list.trackers.length);
    for (final tracker in list.trackers) {
      expect(tracker.name.trim(), tracker.name);
      expect(tracker.name, isNotEmpty);
      expect(tracker.code, isNotEmpty, reason: tracker.name);
      for (final name in tracker.code) {
        // Exodus ignores shorter ones; a short name would match half the
        // apps on a phone.
        expect(name.length, greaterThan(3), reason: '${tracker.name}: $name');
        expect(
          name,
          matches(RegExp(r'^[A-Za-z0-9_.$-]+$')),
          reason: '${tracker.name}: $name',
        );
        // At least two parts, so a signature is never a whole top-level
        // domain such as "com.".
        expect(
          name.split('.').where((part) => part.isNotEmpty).length,
          greaterThan(name.startsWith('.') ? 0 : 1),
          reason: '${tracker.name}: $name',
        );
      }
    }
  });

  test('well-known kits are in it under the names people know', () {
    final list = shipped();
    Tracker named(String name) => list.byName[name]!;
    expect(named('Google Firebase Analytics').kinds, {TrackerKind.analytics});
    expect(named('Google AdMob').kinds, contains(TrackerKind.ads));
    expect(named('Google CrashLytics').onlyCrashReporting, isTrue);
    expect(named('Google AdMob').onlyCrashReporting, isFalse);
    // No stated kind is not "only crash reporting".
    expect(
      const Tracker(id: 1, name: 'x', code: ['a.b.']).onlyCrashReporting,
      isFalse,
    );
  });

  test('a signature becomes the bytes a class name is compared with', () {
    final package = CodeSignature('com.example.tracker.');
    expect(package.anywhere, isFalse);
    expect(String.fromCharCodes(package.bytes), 'Lcom/example/tracker/');
    final ending = CodeSignature('.TrackerManager');
    expect(ending.anywhere, isTrue);
    expect(String.fromCharCodes(ending.bytes), '/TrackerManager');
  });

  test('the version follows the definitions, not only their number', () {
    TrackerList list(List<String> code, {String name = 'Kit', int id = 1}) =>
        TrackerList(
          trackers: [Tracker(id: id, name: name, code: code)],
          newestEntry: '2023-12-05',
          attribution: '',
        );
    final version = list(['com.kit.']).version;
    expect(version, list(['com.kit.']).version);
    expect(version, startsWith('2023-12-05/1/'));
    expect(list(['com.kit.sdk.']).version, isNot(version));
    expect(list(['com.kit.', 'com.other.']).version, isNot(version));
    expect(list(['com.kit.'], name: 'Kit 2').version, isNot(version));
    expect(list(['com.kit.'], id: 2).version, isNot(version));
    // Where one name ends and the next begins counts too.
    expect(list(['com.a', 'b.']).version, isNot(list(['com.ab', '.']).version));
  });

  test('two trackers with one name are refused', () {
    expect(
      () => TrackerList(
        trackers: const [
          Tracker(id: 1, name: 'Same', code: ['a.b.']),
          Tracker(id: 2, name: 'Same', code: ['c.d.']),
        ],
        newestEntry: '2026-01-01',
        attribution: '',
      ),
      throwsA(isA<AssertionError>()),
    );
  });
}
