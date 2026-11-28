import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zerotrust_privacy/phone/phone_providers.dart';
import 'package:zerotrust_privacy/probe/device_probe.dart';
import 'package:zerotrust_privacy/scan/tracker_list.dart';
import 'package:zerotrust_privacy/scan/tracker_scan.dart';
import 'package:zerotrust_privacy/trackers/scan_cache.dart';
import 'package:zerotrust_privacy/trackers/tracker_providers.dart';
import 'package:zerotrust_privacy/trackers/tracker_results.dart';

import 'support/app.dart';
import 'support/fake_phone.dart';

/// Lets everything that is waiting on a made-up answer run.
Future<void> settle() async {
  for (var i = 0; i < 20; i++) {
    await Future<void>.delayed(Duration.zero);
  }
}

FakeProbe phoneWith(List<InstalledApp> apps, {String build = 'BUILD.1'}) =>
    FakeProbe()
      ..installed = apps
      ..values = facts({...goodFacts(), 'build.display': build})
      ..lists = const {};

/// The app, as far as the scan is concerned.
class Scans {
  Scans({
    required this.probe,
    TrackerScanner? scanner,
    MemoryScanCache? cache,
    TrackerList? list,
    this.locked = false,
  }) : scanner = scanner ?? InstantScanner(),
       cache = cache ?? MemoryScanCache(),
       list = list ?? someTrackers();

  final FakeProbe probe;
  final TrackerScanner scanner;
  final MemoryScanCache cache;
  final TrackerList list;
  final bool locked;
  int activity = 0;

  InstantScanner get instant => scanner as InstantScanner;

  late final container = ProviderContainer(
    overrides: [
      deviceProbeProvider.overrideWithValue(probe),
      trackerListProvider.overrideWith((ref) async => list),
      scanCacheProvider.overrideWith((ref) async => locked ? null : cache),
      trackerScannerProvider.overrideWithValue(scanner),
      scanActivityProvider.overrideWithValue(() => activity++),
    ],
  );

  final states = <TrackerScanState>[];

  /// Opens the app: the phone is read and the scan follows.
  Future<void> open() async {
    addTearDown(container.dispose);
    container.listen(
      trackerScansProvider,
      (_, next) => states.add(next),
      fireImmediately: true,
    );
    await container.read(phoneProvider.future);
    await settle();
  }

  /// Back from somewhere else: the phone is read again.
  Future<void> readAgain() async {
    await container.read(phoneProvider.notifier).refresh();
    await settle();
  }

  TrackerScanState get state => container.read(trackerScansProvider);

  List<String>? namesIn(String package) {
    final app = container.read(phoneProvider).value!.byPackage[package]!;
    return state.results?.of(app)?.map((tracker) => tracker.name).toList();
  }
}

void main() {
  final maps = userApp('com.maps', 'Maps');
  final notes = userApp('com.notes', 'Notes');
  final game = userApp('com.game', 'Game');
  final system = userApp('android.thing', 'System Thing', system: true);

  test('a first run reads every app, the user\'s own first', () async {
    final scans = Scans(probe: phoneWith([system, maps, notes]));
    scans.instant.found = {
      'com.maps': ['App Stats', 'Ad Network'],
      'android.thing': ['Crash Catcher'],
    };
    await scans.open();

    expect(scans.instant.scanned, ['com.maps', 'com.notes', 'android.thing']);
    expect(scans.state.scanning, isFalse);
    expect((scans.state.done, scans.state.total), (3, 3));
    // By name, whatever order the reader found them in.
    expect(scans.namesIn('com.maps'), ['Ad Network', 'App Stats']);
    expect(scans.namesIn('com.notes'), isEmpty);
    expect(scans.namesIn('android.thing'), ['Crash Catcher']);
    // Kept for the next time, under the list they were found with.
    expect(scans.cache.kept!.listVersion, someTrackers().version);
    expect(scans.cache.kept!.apps['com.maps']!.trackerIds, [11, 12]);
    // Every app read counted as activity, so the app does not lock.
    expect(scans.activity, 3);
  });

  test('what was read before is not read again', () async {
    final cache = MemoryScanCache();
    final first = Scans(probe: phoneWith([maps, notes]), cache: cache);
    first.instant.found = {
      'com.maps': ['Ad Network'],
    };
    await first.open();
    final saves = cache.saves;

    final second = Scans(probe: phoneWith([maps, notes]), cache: cache);
    await second.open();
    expect(second.instant.scanned, isEmpty);
    expect(second.namesIn('com.maps'), ['Ad Network']);
    expect(second.state.scanning, isFalse);
    expect(cache.saves, saves);

    // Reading the phone again changes nothing either.
    await second.readAgain();
    expect(second.instant.scanned, isEmpty);
  });

  test('an updated app is read again, a new one is read, a removed one is '
      'forgotten', () async {
    final scans = Scans(probe: phoneWith([maps, notes]));
    scans.instant.found = {
      'com.maps': ['Ad Network'],
      'com.notes': ['App Stats'],
    };
    await scans.open();
    scans.instant.scanned.clear();

    // Maps was updated and lost its ad kit; Notes was removed; Game is new.
    scans.instant.found = {
      'com.game': ['Mystery Kit'],
    };
    scans.probe.installed = [
      userApp('com.maps', 'Maps', lastUpdate: maps.lastUpdate + 1000),
      game,
    ];
    await scans.readAgain();

    expect(scans.instant.scanned, ['com.maps', 'com.game']);
    expect(scans.namesIn('com.maps'), isEmpty);
    expect(scans.namesIn('com.game'), ['Mystery Kit']);
    expect(scans.cache.kept!.apps.keys, ['com.maps', 'com.game']);
  });

  test('an app that was only removed is forgotten without a scan', () async {
    final scans = Scans(probe: phoneWith([maps, notes]));
    await scans.open();
    scans.instant.scanned.clear();

    scans.probe.installed = [maps];
    await scans.readAgain();
    expect(scans.instant.scanned, isEmpty);
    expect(scans.cache.kept!.apps.keys, ['com.maps']);
  });

  test('a newer tracker list reads everything again', () async {
    final cache = MemoryScanCache();
    await Scans(probe: phoneWith([maps]), cache: cache).open();

    final newer = TrackerList(
      trackers: const [adNetwork, appStats, crashCatcher, mysteryKit],
      newestEntry: '2026-01-01',
      attribution: '',
    );
    final scans = Scans(probe: phoneWith([maps]), cache: cache, list: newer);
    await scans.open();
    expect(scans.instant.scanned, ['com.maps']);
    expect(cache.kept!.listVersion, newer.version);
  });

  test('a list that only corrects one signature reads everything '
      'again', () async {
    final cache = MemoryScanCache();
    await Scans(probe: phoneWith([maps]), cache: cache).open();

    // The same trackers, the same date, one code name put right.
    final corrected = TrackerList(
      trackers: const [
        Tracker(
          id: 11,
          name: 'Ad Network',
          code: ['com.adnetwork.sdk.'],
          kinds: {TrackerKind.ads},
        ),
        appStats,
        crashCatcher,
        mysteryKit,
      ],
      newestEntry: '2023-12-05',
      attribution: '',
    );
    expect(corrected.version, isNot(someTrackers().version));
    final scans = Scans(
      probe: phoneWith([maps]),
      cache: cache,
      list: corrected,
    );
    await scans.open();
    expect(scans.instant.scanned, ['com.maps']);
  });

  test('an app read only in part is kept as such, with what was '
      'found', () async {
    final scans = Scans(probe: phoneWith([maps, notes]));
    scans.instant
      ..incomplete = {'com.maps', 'com.notes'}
      ..found = {
        'com.maps': ['Ad Network'],
      };
    await scans.open();

    expect(scans.namesIn('com.maps'), ['Ad Network']);
    expect(scans.namesIn('com.notes'), isEmpty);
    final kept = scans.cache.kept!.apps;
    expect(kept['com.maps']!.incomplete, isTrue);
    expect(kept['com.notes']!.incomplete, isTrue);
    expect(kept['com.notes']!.unreadable, isFalse);
    // And it comes back from the file that way.
    expect(
      ScanMemory.fromJson(
        scans.cache.kept!.toJson(),
      ).apps['com.notes']!.incomplete,
      isTrue,
    );
  });

  test('an update of the phone reads its own apps again, not the '
      'user\'s', () async {
    final cache = MemoryScanCache();
    await Scans(probe: phoneWith([maps, system]), cache: cache).open();

    final scans = Scans(
      probe: phoneWith([maps, system], build: 'BUILD.2'),
      cache: cache,
    );
    await scans.open();
    expect(scans.instant.scanned, ['android.thing']);
    expect(cache.kept!.system, 'BUILD.2');
  });

  test('an app whose code cannot be read is "not known", and is not tried '
      'again', () async {
    final scans = Scans(probe: phoneWith([maps, notes]));
    scans.instant.unreadable = {'com.maps'};
    await scans.open();

    expect(scans.namesIn('com.maps'), isNull);
    final app = scans.container
        .read(phoneProvider)
        .value!
        .byPackage['com.maps']!;
    expect(scans.state.results!.scanOf(app)!.unreadable, isTrue);
    expect(scans.namesIn('com.notes'), isEmpty);

    scans.instant.scanned.clear();
    await scans.readAgain();
    expect(scans.instant.scanned, isEmpty);
  });

  test('an app Android gives no files for is marked without a scan', () async {
    final hidden = InstalledApp(
      package: 'com.hidden',
      label: 'Hidden',
      system: false,
      enabled: true,
      uid: 10200,
      targetSdk: 35,
      firstInstall: 1,
      lastUpdate: 2,
      installer: null,
      sourceDir: null,
      splitDirs: const [],
      requested: const [],
      granted: const [],
      internetGranted: true,
      otherSensorsGranted: true,
    );
    final scans = Scans(probe: phoneWith([hidden, maps]));
    await scans.open();
    expect(scans.instant.scanned, ['com.maps']);
    expect(scans.namesIn('com.hidden'), isNull);
    expect(scans.cache.kept!.apps['com.hidden']!.unreadable, isTrue);
  });

  test('progress is told app by app; results are given out now and then, '
      'and kept on the way', () async {
    final apps = [
      for (var i = 0; i < 30; i++)
        userApp('com.app${i.toString().padLeft(2, '0')}', 'App $i'),
    ];
    final scanner = FakeScanner();
    final scans = Scans(probe: phoneWith(apps), scanner: scanner);
    await scans.open();

    expect(scans.state.scanning, isTrue);
    expect((scans.state.done, scans.state.total), (0, 30));
    expect(scanner.targets.length, 30);
    expect(scanner.targets.first.paths, ['/data/app/com.app00/base.apk']);

    final first = scans.state.results;
    for (var i = 0; i < 7; i++) {
      scanner.give(apps[i].package, found: ['Ad Network']);
    }
    await settle();
    expect(scans.state.done, 7);
    // The same results object: the score is not worked out again yet.
    expect(scans.state.results, same(first));
    scanner.give(apps[7].package);
    await settle();
    expect(scans.state.results, isNot(same(first)));
    expect(scans.namesIn('com.app00'), ['Ad Network']);
    expect(scans.cache.saves, 0);

    for (var i = 8; i < 25; i++) {
      scanner.give(apps[i].package);
    }
    await settle();
    expect(scans.cache.saves, 1);
    expect(scans.cache.kept!.apps.length, 25);

    for (var i = 25; i < 30; i++) {
      scanner.give(apps[i].package);
    }
    await scanner.finish();
    await settle();
    expect(scans.state.scanning, isFalse);
    expect(scans.cache.kept!.apps.length, 30);
  });

  test('one scan at a time: a phone read during a scan is looked at when '
      'it ends', () async {
    final scanner = FakeScanner();
    final scans = Scans(probe: phoneWith([maps, notes]), scanner: scanner);
    await scans.open();
    final running = scanner.controller;
    expect(scanner.targets.map((t) => t.package), ['com.maps', 'com.notes']);

    scans.probe.installed = [maps, notes, game];
    await scans.readAgain();
    // Still the first scan.
    expect(scanner.controller, same(running));

    scanner
      ..give('com.maps')
      ..give('com.notes');
    await scanner.finish();
    await settle();
    // Now the app that arrived in between.
    expect(scanner.controller, isNot(same(running)));
    expect(scanner.targets.map((t) => t.package), ['com.game']);
    expect(scans.state.scanning, isTrue);
  });

  test('a reader that stops early leaves the rest marked, not tried for '
      'ever', () async {
    final scanner = FakeScanner();
    final scans = Scans(probe: phoneWith([maps, notes]), scanner: scanner);
    await scans.open();
    final running = scanner.controller;

    scanner.give('com.maps', found: ['Ad Network']);
    scanner.controller!.addError(StateError('out of memory'));
    await scanner.finish();
    await settle();

    expect(scans.state.scanning, isFalse);
    expect(scans.namesIn('com.maps'), ['Ad Network']);
    expect(scans.namesIn('com.notes'), isNull);
    expect(scans.cache.kept!.apps['com.notes']!.unreadable, isTrue);
    await scans.readAgain();
    expect(scanner.controller, same(running));
  });

  test('results that cannot be written cost nothing but a second '
      'reading', () async {
    final scans = Scans(probe: phoneWith([maps]));
    scans.cache.failure = StateError('disk full');
    scans.instant.found = {
      'com.maps': ['Ad Network'],
    };
    await scans.open();
    expect(scans.namesIn('com.maps'), ['Ad Network']);
    expect(scans.cache.kept, isNull);
  });

  test('while the app is locked nothing is read', () async {
    final scans = Scans(probe: phoneWith([maps]), locked: true);
    await scans.open();
    expect(scans.instant.scanned, isEmpty);
    expect(scans.state.results, isNull);
    expect(scans.state.scanning, isFalse);
  });

  test('closing the app in the middle stops the reader', () async {
    final scanner = FakeScanner();
    final scans = Scans(probe: phoneWith([maps]), scanner: scanner);
    await scans.open();
    expect(scanner.cancelled, isFalse);
    scans.container.dispose();
    await settle();
    expect(scanner.cancelled, isTrue);
  });

  test('a made-up tracker name the list does not know is left out', () async {
    final scans = Scans(probe: phoneWith([maps]));
    scans.instant.found = {
      'com.maps': ['Ad Network', 'Not On The List'],
    };
    await scans.open();
    expect(scans.namesIn('com.maps'), ['Ad Network']);
  });

  test('kept results survive being written and read', () {
    final memory = ScanMemory(listVersion: 'v', system: 'BUILD.1')
      ..apps['com.maps'] = const AppTrackers(lastUpdate: 5, trackerIds: [1, 2])
      ..apps['com.x'] = const AppTrackers(
        lastUpdate: 6,
        trackerIds: [],
        unreadable: true,
      );
    final back = ScanMemory.fromJson(memory.toJson());
    expect(back.listVersion, 'v');
    expect(back.system, 'BUILD.1');
    expect(back.apps['com.maps']!.lastUpdate, 5);
    expect(back.apps['com.maps']!.trackerIds, [1, 2]);
    expect(back.apps['com.x']!.unreadable, isTrue);
  });
}
