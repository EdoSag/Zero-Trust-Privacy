import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zerotrust_privacy/phone/phone_providers.dart';
import 'package:zerotrust_privacy/probe/device_probe.dart';
import 'package:zerotrust_privacy/scan/tracker_list.dart';
import 'package:zerotrust_privacy/scan/tracker_scan.dart';
import 'package:zerotrust_privacy/trackers/changes.dart';
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
  DateTime Function() clock = DateTime.now;

  InstantScanner get instant => scanner as InstantScanner;

  late final container = ProviderContainer(
    overrides: [
      deviceProbeProvider.overrideWithValue(probe),
      trackerListProvider.overrideWith((ref) async => list),
      scanCacheProvider.overrideWith((ref) async => locked ? null : cache),
      trackerScannerProvider.overrideWithValue(scanner),
      scanActivityProvider.overrideWithValue(() => activity++),
      scanClockProvider.overrideWithValue(() => clock()),
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
    // One write at the start: which apps there are and what they ask for.
    final saves = scans.cache.saves;
    expect(saves, 1);
    expect(scans.cache.kept!.apps, isEmpty);
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
    expect(scans.cache.saves, saves);

    for (var i = 8; i < 25; i++) {
      scanner.give(apps[i].package);
    }
    await settle();
    expect(scans.cache.saves, saves + 1);
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

  group('what changed', () {
    const location = 'android.permission.ACCESS_FINE_LOCATION';
    const contacts = 'android.permission.READ_CONTACTS';
    const vibrate = 'android.permission.VIBRATE';
    final noon = DateTime.utc(2026, 11, 28, 12);

    InstalledApp updated(InstalledApp app, {Map<String, bool>? permissions}) =>
        userApp(
          app.package,
          app.label,
          lastUpdate: app.lastUpdate + 1000,
          permissions:
              permissions ??
              {
                for (var i = 0; i < app.requested.length; i++)
                  app.requested[i]: app.granted[i],
              },
        );

    List<(ChangeKind, String)> kinds(Scans scans) => [
      for (final change in scans.state.changes) (change.kind, change.package),
    ];

    test('the first look at a phone is the start, not a change', () async {
      final scans = Scans(
        probe: phoneWith([
          userApp('com.maps', 'Maps', permissions: {location: true}),
          notes,
        ]),
      );
      scans.instant.found = {
        'com.maps': ['Ad Network'],
      };
      await scans.open();
      expect(scans.state.changes, isEmpty);
      expect(scans.state.unseenChanges, 0);
      expect(scans.cache.kept!.baselined, isTrue);
      expect(scans.cache.kept!.asked, {
        'com.maps': [location],
        'com.notes': <String>[],
      });
    });

    test('a newly installed app with tracker code is told, one without is '
        'not', () async {
      final scans = Scans(probe: phoneWith([maps]))..clock = () => noon;
      await scans.open();

      scans.instant.found = {
        'com.game': ['Mystery Kit', 'Ad Network'],
      };
      scans.probe.installed = [maps, game, notes];
      await scans.readAgain();

      expect(kinds(scans), [(ChangeKind.newAppTrackers, 'com.game')]);
      final change = scans.state.changes.single;
      expect(change.label, 'Game');
      expect(change.trackerIds, [adNetwork.id, mysteryKit.id]);
      expect(change.at, noon.millisecondsSinceEpoch);
      expect(scans.state.unseenChanges, 1);
      // Kept on the phone, and nothing waits to be read.
      expect(scans.cache.kept!.changes.single.package, 'com.game');
      expect(scans.cache.kept!.fresh, isEmpty);
    });

    test('an update that brings or drops tracker code is told', () async {
      final scans = Scans(probe: phoneWith([maps, notes]));
      scans.instant.found = {
        'com.maps': ['Ad Network', 'App Stats'],
      };
      await scans.open();

      // Maps drops the ad kit and takes a crash reporter; Notes gets
      // statistics.
      scans.instant.found = {
        'com.maps': ['App Stats', 'Crash Catcher'],
        'com.notes': ['App Stats'],
      };
      scans.probe.installed = [updated(maps), updated(notes)];
      await scans.readAgain();

      // Newest first.
      expect(kinds(scans), [
        (ChangeKind.trackersAdded, 'com.notes'),
        (ChangeKind.trackersRemoved, 'com.maps'),
        (ChangeKind.trackersAdded, 'com.maps'),
      ]);
      expect(scans.state.changes[0].trackerIds, [appStats.id]);
      expect(scans.state.changes[1].trackerIds, [adNetwork.id]);
      expect(scans.state.changes[2].trackerIds, [crashCatcher.id]);
    });

    test('an update with the same tracker code is not a change', () async {
      final scans = Scans(probe: phoneWith([maps]));
      scans.instant.found = {
        'com.maps': ['Ad Network'],
      };
      await scans.open();
      scans.probe.installed = [updated(maps)];
      await scans.readAgain();
      expect(scans.instant.scanned, ['com.maps', 'com.maps']);
      expect(scans.state.changes, isEmpty);
    });

    test('an update that starts asking for a sensitive permission is '
        'told', () async {
      final torch = userApp('com.torch', 'Torch', permissions: {vibrate: true});
      final scans = Scans(probe: phoneWith([torch]));
      await scans.open();

      scans.probe.installed = [
        updated(
          torch,
          permissions: {vibrate: true, contacts: false, location: false},
        ),
      ];
      await scans.readAgain();

      expect(kinds(scans), [(ChangeKind.permissionsAdded, 'com.torch')]);
      // In the app's own order of sensitive permissions; asked for is
      // enough, granted or not. An ordinary permission is not told.
      expect(scans.state.changes.single.permissions, [location, contacts]);

      // Told once.
      await scans.readAgain();
      expect(scans.state.changes.length, 1);
      // A permission that is dropped and comes back is told again.
      scans.probe.installed = [torch];
      await scans.readAgain();
      expect(scans.state.changes.length, 1);
      scans.probe.installed = [
        updated(torch, permissions: {contacts: false}),
      ];
      await scans.readAgain();
      expect(scans.state.changes.first.permissions, [contacts]);
    });

    test('a removed app that comes back is a new app again', () async {
      final scans = Scans(probe: phoneWith([maps, game]));
      scans.instant.found = {
        'com.game': ['Ad Network'],
      };
      await scans.open();
      scans.probe.installed = [maps];
      await scans.readAgain();
      scans.probe.installed = [maps, game];
      await scans.readAgain();
      expect(kinds(scans), [(ChangeKind.newAppTrackers, 'com.game')]);
    });

    test('the system\'s own apps are not told about', () async {
      final scans = Scans(probe: phoneWith([maps]));
      await scans.open();
      scans.instant.found = {
        'android.thing': ['Ad Network'],
      };
      scans.probe.installed = [maps, system];
      await scans.readAgain();
      expect(scans.state.changes, isEmpty);
    });

    test('a newer tracker list reads everything again without calling it a '
        'change, and keeps what changed before', () async {
      final cache = MemoryScanCache();
      final first = Scans(probe: phoneWith([maps]), cache: cache);
      await first.open();
      first.instant.found = {
        'com.game': ['Ad Network'],
      };
      first.probe.installed = [maps, game];
      await first.readAgain();
      expect(first.state.changes.length, 1);

      final newer = TrackerList(
        trackers: const [adNetwork, appStats, crashCatcher, mysteryKit],
        newestEntry: '2026-01-01',
        attribution: '',
      );
      final scans = Scans(
        probe: phoneWith([maps, game]),
        cache: cache,
        list: newer,
      );
      // The newer list finds more in Maps: that is the list, not Maps.
      scans.instant.found = {
        'com.maps': ['App Stats'],
        'com.game': ['Ad Network'],
      };
      await scans.open();
      expect(scans.instant.scanned, ['com.maps', 'com.game']);
      expect(kinds(scans), [(ChangeKind.newAppTrackers, 'com.game')]);
    });

    test('an app read only in part is not compared', () async {
      final scans = Scans(probe: phoneWith([maps]));
      scans.instant.found = {
        'com.maps': ['Ad Network'],
      };
      await scans.open();
      scans.instant
        ..found = {}
        ..incomplete = {'com.maps'};
      scans.probe.installed = [updated(maps)];
      await scans.readAgain();
      expect(scans.state.changes, isEmpty);
    });

    test('a new app whose scan was cut short is still told the next '
        'time', () async {
      final cache = MemoryScanCache();
      await Scans(probe: phoneWith([maps]), cache: cache).open();

      final scanner = FakeScanner();
      final cut = Scans(
        probe: phoneWith([maps, game]),
        cache: cache,
        scanner: scanner,
      );
      await cut.open();
      expect(scanner.targets.map((t) => t.package), ['com.game']);
      expect(cache.kept!.fresh, {'com.game'});
      // The app is closed before the reader answers.
      cut.container.dispose();
      await settle();

      final scans = Scans(probe: phoneWith([maps, game]), cache: cache);
      scans.instant.found = {
        'com.game': ['Ad Network'],
      };
      await scans.open();
      expect(kinds(scans), [(ChangeKind.newAppTrackers, 'com.game')]);
    });

    test('opening the list makes nothing new, and it stays so', () async {
      final cache = MemoryScanCache();
      var time = noon;
      final scans = Scans(probe: phoneWith([maps]), cache: cache)
        ..clock = () => time;
      await scans.open();
      scans.instant.found = {
        'com.game': ['Ad Network'],
      };
      scans.probe.installed = [maps, game];
      await scans.readAgain();
      expect(scans.state.unseenChanges, 1);

      scans.container.read(trackerScansProvider.notifier).markChangesSeen();
      await settle();
      expect(scans.state.unseenChanges, 0);
      expect(scans.state.changes.length, 1);
      expect(cache.kept!.seenAt, noon.millisecondsSinceEpoch);

      // The next time the app opens it is still seen.
      final again = Scans(probe: phoneWith([maps, game]), cache: cache)
        ..clock = () => time;
      await again.open();
      expect(again.state.unseenChanges, 0);
      expect(again.state.changes.length, 1);

      // And a later change is new again.
      time = noon.add(const Duration(hours: 1));
      again.instant.found = {
        'com.notes': ['App Stats'],
      };
      again.probe.installed = [maps, game, notes];
      await again.readAgain();
      expect(again.state.unseenChanges, 1);
      expect(again.state.changes.length, 2);
    });

    test('only the newest two hundred are kept', () {
      final memory = ScanMemory(listVersion: 'v');
      for (var i = 0; i < 205; i++) {
        memory.addChange(
          Change(
            at: i,
            kind: ChangeKind.trackersAdded,
            package: 'com.app$i',
            label: 'App $i',
          ),
        );
      }
      expect(memory.changes.length, 200);
      expect(memory.changes.first.at, 5);
      expect(memory.changes.last.at, 204);
    });

    test('changes survive being written and read; an unknown kind is left '
        'out', () {
      final memory =
          ScanMemory(
              listVersion: 'v',
              baselined: true,
              seenAt: 7,
              asked: {
                'com.maps': [location],
              },
              fresh: {'com.game'},
            )
            ..addChange(
              const Change(
                at: 9,
                kind: ChangeKind.permissionsAdded,
                package: 'com.maps',
                label: 'Maps',
                permissions: [location],
              ),
            )
            ..addChange(
              const Change(
                at: 10,
                kind: ChangeKind.trackersAdded,
                package: 'com.maps',
                label: 'Maps',
                trackerIds: [11],
              ),
            );
      final json = memory.toJson();
      (json['changes']! as List).add({'at': 11, 'k': 'somethingNew', 'p': 'x'});
      final back = ScanMemory.fromJson(json);
      expect(back.baselined, isTrue);
      expect(back.seenAt, 7);
      expect(back.asked, {
        'com.maps': [location],
      });
      expect(back.fresh, {'com.game'});
      expect(back.changes.length, 2);
      expect(back.changes[0].permissions, [location]);
      expect(back.changes[1].trackerIds, [11]);
      expect(back.changes[1].label, 'Maps');
    });
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
