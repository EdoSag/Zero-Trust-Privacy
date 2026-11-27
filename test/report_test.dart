import 'package:flutter_test/flutter_test.dart';
import 'package:zerotrust_privacy/probe/device_probe.dart';
import 'package:zerotrust_privacy/report/phone_test_results.dart';
import 'package:zerotrust_privacy/report/report.dart';
import 'package:zerotrust_privacy/scan/tracker_scan.dart';
import 'package:zerotrust_privacy/ui/phone_test_controller.dart';

import 'support/fake_phone.dart';

AppScan scan(
  String package, {
  List<String> found = const [],
  List<String> errors = const [],
  int ms = 10,
  int dexFiles = 1,
}) => AppScan(
  package: package,
  found: found,
  dexFiles: dexFiles,
  dexBytes: 2 * 1024 * 1024,
  types: 1000,
  errors: errors,
  elapsed: Duration(milliseconds: ms),
);

Future<PhoneTestResults> fullResults() async {
  final probe = FakeProbe()
    ..mode = ((query) => query.package == 'com.maps'
        ? 'SecurityException: uid 10100 may not query'
        : 'allowed')
    ..usageReport = UsageReport(
      granted: true,
      apps: [
        AppUsage(
          package: 'com.maps',
          lastUsed: DateTime.utc(2026, 11, 20).millisecondsSinceEpoch,
          foregroundMs: 1,
        ),
        AppUsage(
          package: 'com.camera',
          lastUsed: DateTime.utc(2026, 1, 2).millisecondsSinceEpoch,
          foregroundMs: 1,
        ),
      ],
      wifi: const DataUse(
        ok: true,
        bytesByUid: {10101: 1048576, 10102: 2097152},
      ),
      mobile: const DataUse(ok: false, error: 'SecurityException: no'),
    )
    ..deepReport = DeepModeReport(
      permissionGranted: true,
      attempts: const [
        DeepModeAttempt(
          step: 'plain',
          ok: false,
          error: 'NoSuchMethodException: x',
        ),
        DeepModeAttempt(step: 'exemption', ok: true),
        DeepModeAttempt(step: 'exempted', ok: true),
      ],
      entries: [
        OpUse(
          package: 'com.maps',
          op: 'android:fine_location',
          lastAccess: DateTime.utc(2026, 11, 26, 8).millisecondsSinceEpoch,
          lastReject: 0,
          running: false,
        ),
        const OpUse(
          package: 'com.camera',
          op: 'android:camera',
          lastAccess: 0,
          lastReject: 0,
          running: false,
        ),
      ],
    );
  final controller = PhoneTestController(
    probe: probe,
    scanner: FakeScanner(),
    build: '1001',
    now: () => DateTime.utc(2026, 11, 27, 9),
  );
  await controller.readPhone();
  await controller.open('privacyDashboard');
  final results = controller.results
    ..scans.addAll([
      scan('com.maps', found: ['Ad Kit', 'Tracker One'], ms: 900),
      scan('com.camera', found: ['Ad Kit'], ms: 20),
      scan(
        'com.notes',
        errors: ['base.apk: not a zip file'],
        ms: 5,
        dexFiles: 0,
      ),
    ])
    ..scanTargets = 3
    ..scanTime = const Duration(milliseconds: 1500)
    ..scanFinished = true;
  controller.dispose();
  return results;
}

void main() {
  test('the summary counts and never names an app', () async {
    final report = buildReport(await fullResults(), withNames: false);

    expect(report, startsWith('ZT Privacy phone test, build 1001\n'));
    expect(report, contains('Taken: 2026-11-27T09:00:00.000Z'));
    expect(report, contains('App names: left out'));

    // No package, label, special access holder or installer.
    for (final name in [
      'com.maps',
      'com.camera',
      'com.notes',
      'android.system',
      'Label of',
      'com.reader',
      'com.keys',
      'org.example.store',
    ]) {
      expect(report, isNot(contains(name)), reason: name);
    }

    expect(report, contains('Apps Android showed: 4 (yours 3, system 1)'));
    expect(report, contains('Your apps with a known installer: 2 of 3'));
    expect(report, contains('target below 30): 1'));
    // Holding / asking, the user's apps only.
    expect(report, contains('Location, precise: 1 / 2'));
    expect(report, contains('Location, all the time: 1 / 1'));
    expect(report, contains('Camera: 1 / 1'));
    expect(report, contains('Microphone: 0 / 0'));
  });

  test('settings show their value or Android\'s refusal', () async {
    final report = buildReport(await fullResults(), withNames: false);
    expect(report, contains('build.model: Test Phone'));
    expect(report, contains('global.adb_enabled: 0'));
    expect(
      report,
      contains(
        'secure.always_on_vpn_app: REFUSED SecurityException: not readable',
      ),
    );
    expect(report, contains('Read: 2 of 3'));
  });

  test('the GrapheneOS switches are counted three ways', () async {
    final report = buildReport(await fullResults(), withNames: false);
    expect(report, contains('Apps asking for network: 3'));
    expect(report, contains('  granted flag off: 0'));
    expect(report, contains('  direct check says no: 1'));
    expect(report, contains('Direct Sensors check says yes / no: 3 / 1'));
  });

  test(
    'special access: sizes of the lists, and Android\'s direct answers',
    () async {
      final report = buildReport(await fullResults(), withNames: false);
      expect(report, contains('accessibilityServices: 1\n'));
      expect(report, contains('keyboards: 2\n'));
      expect(report, contains('deviceAdmins: REFUSED SecurityException: no'));
      expect(
        report,
        contains(
          'Display over other apps: asked by 2; answers: '
          'allowed 1, refused 1; granted flag set: 1',
        ),
      );
      expect(report, contains('  first refusal: SecurityException: uid 10100'));
      expect(report, contains('All files: asked by 0; answers: -;'));
    },
  );

  test('usage access, deep mode and system screens', () async {
    final report = buildReport(await fullResults(), withNames: false);
    expect(report, contains('Switched on: yes'));
    expect(report, contains('Apps with a last-used time: 2'));
    // com.camera last used in January, com.notes never.
    expect(report, contains('Your apps not used for 90 days: 2'));
    expect(report, contains('Wi-Fi data: 2 apps, 3.0 MB'));
    expect(report, contains('Mobile data: REFUSED SecurityException: no'));

    expect(report, contains('Permission granted from a computer: yes'));
    expect(report, contains('Step plain: REFUSED NoSuchMethodException: x'));
    expect(report, contains('Step exempted: worked'));
    expect(report, contains('History could be read: yes'));
    expect(report, contains('Rows: 2 for 2 apps'));
    expect(report, contains('by kind: android:fine_location 1'));

    expect(report, contains('privacyDashboard: opened'));
  });

  test('the tracker scan is timed and totalled', () async {
    final report = buildReport(await fullResults(), withNames: false);
    expect(report, contains('Finished: yes'));
    expect(report, contains('Apps scanned: 3 of 3'));
    expect(report, contains('Time on the clock: 1.5 s'));
    expect(
      report,
      contains('Code files: 2, unpacked 6.0 MB, class names 3000'),
    );
    expect(report, contains('Per app: median 20 ms, slowest 900 ms'));
    expect(report, contains('Apps with at least one kit: 2'));
    expect(report, contains('Apps with no code file found: 1'));
    expect(report, contains('Apps with a read error: 1'));
    expect(report, contains('  base.apk: not a zip file'));
    expect(
      report,
      contains('Kits found, by number of apps: Ad Kit 2, Tracker One 1'),
    );
    expect(report, isNot(contains('Slowest apps')));
  });

  test('the full report adds the names', () async {
    final report = buildReport(await fullResults(), withNames: true);
    expect(report, contains('App names: included'));
    expect(report, contains('Installed by: org.example.store 2, (none) 1'));
    expect(report, contains('accessibilityServices: 1 (com.reader/.Service)'));
    expect(
      report,
      contains('  com.maps android:fine_location 2026-11-26T08:00:00.000Z'),
    );
    expect(report, contains('  com.maps: 900 ms, 1 code files, 2.0 MB'));
    expect(
      report,
      contains(
        'com.camera | Label of com.camera | target 28 | from - | '
        'network no | holds: Camera | kits: Ad Kit',
      ),
    );
    expect(
      report,
      contains(
        'com.maps | Label of com.maps | target 35 | from org.example.store | '
        'network yes | holds: Location, precise, Location, all the time | '
        'kits: Ad Kit, Tracker One',
      ),
    );
    // System apps are not listed one by one.
    expect(report, isNot(contains('android.system |')));
  });

  test('a run with only the first step still makes a report', () async {
    final controller = PhoneTestController(
      probe: FakeProbe()..appsFailure = StateError('no list'),
      scanner: FakeScanner(),
      build: 'dev',
    );
    await controller.readPhone();
    final report = controller.report(withNames: false);
    controller.dispose();
    expect(report, contains('== Steps that failed =='));
    expect(report, contains('apps: Bad state: no list'));
    expect(report, isNot(contains('== Apps ==')));
    expect(report, isNot(contains('== Tracker scan ==')));
  });
}
