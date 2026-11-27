import 'package:flutter_test/flutter_test.dart';
import 'package:zerotrust_privacy/probe/device_probe.dart';
import 'package:zerotrust_privacy/ui/phone_test_controller.dart';

import 'support/fake_phone.dart';

void main() {
  late FakeProbe probe;
  late FakeScanner scanner;
  late PhoneTestController controller;

  setUp(() {
    probe = FakeProbe();
    scanner = FakeScanner();
    controller = PhoneTestController(
      probe: probe,
      scanner: scanner,
      build: '1001',
      now: () => DateTime.utc(2026, 11, 27, 9),
    );
  });

  tearDown(() => controller.dispose());

  test('reading the phone fills every part', () async {
    await controller.readPhone();
    final results = controller.results;
    expect(results.apps, hasLength(4));
    expect(results.userApps.map((a) => a.package), [
      'com.maps',
      'com.camera',
      'com.notes',
    ]);
    expect(results.device, hasLength(3));
    expect(results.specialAccess, hasLength(3));
    expect(results.usage!.granted, isFalse);
    expect(results.deepMode!.permissionGranted, isFalse);
    expect(results.takenAt, DateTime.utc(2026, 11, 27, 9));
    expect(results.errors, isEmpty);
    expect(controller.reading, isFalse);
  });

  test('special access is asked only for the apps that requested it', () async {
    probe.mode = (query) => query.package == 'com.maps' ? 'ignored' : 'allowed';
    await controller.readPhone();
    final overlayAnswers =
        controller.results.accessAnswers!['Display over other apps']!;
    expect(overlayAnswers.map((a) => a.package), [
      'com.maps',
      'android.system',
    ]);
    expect(overlayAnswers.map((a) => a.mode), ['ignored', 'allowed']);
    expect(overlayAnswers.map((a) => a.grantedFlag), [false, true]);
    expect(controller.results.accessAnswers!['All files'], isEmpty);
    // Asked with the op and the app's own uid.
    expect(probe.asked.first.op, 'android:system_alert_window');
    expect(probe.asked.first.uid, 10101);
  });

  test('one part failing does not cost the others', () async {
    probe.appsFailure = StateError('no app list');
    await controller.readPhone();
    expect(controller.results.apps, isNull);
    expect(controller.results.errors['apps'], contains('no app list'));
    expect(controller.results.device, hasLength(3));
    expect(controller.hasApps, isFalse);

    // And a later good run clears the failure.
    probe.appsFailure = null;
    await controller.readPhone();
    expect(controller.results.errors, isEmpty);
    expect(controller.hasApps, isTrue);
  });

  test(
    'coming back from settings picks up usage access and deep mode',
    () async {
      await controller.readPhone();
      probe
        ..usageReport = const UsageReport(
          granted: true,
          apps: [AppUsage(package: 'com.maps', lastUsed: 5, foregroundMs: 9)],
        )
        ..deepReport = const DeepModeReport(
          permissionGranted: true,
          attempts: [DeepModeAttempt(step: 'plain', ok: true)],
          entries: [
            OpUse(
              package: 'com.maps',
              op: 'android:fine_location',
              lastAccess: 100,
              lastReject: 0,
              running: false,
            ),
          ],
        );
      await controller.refreshOptional();
      expect(controller.results.usage!.granted, isTrue);
      expect(controller.results.deepMode!.works, isTrue);
    },
  );

  test('nothing is refreshed before the phone was read', () async {
    probe.usageReport = const UsageReport(granted: true);
    await controller.refreshOptional();
    expect(controller.results.usage, isNull);
  });

  test('the scan covers the user\'s apps, not the system\'s', () async {
    await controller.readPhone();
    controller.startScan();
    expect(controller.scanning, isTrue);
    expect(scanner.targets.map((t) => t.package), [
      'com.maps',
      'com.camera',
      'com.notes',
    ]);
    expect(scanner.targets.first.paths, ['/data/app/com.maps/base.apk']);
    expect(controller.results.scanTargets, 3);

    scanner.give('com.maps', found: ['Ad Kit']);
    await pumpEventQueue();
    expect(controller.results.scans, hasLength(1));
    expect(controller.results.scanFinished, isFalse);

    scanner
      ..give('com.camera')
      ..give('com.notes');
    await scanner.finish();
    await pumpEventQueue();
    expect(controller.scanning, isFalse);
    expect(controller.results.scans, hasLength(3));
    expect(controller.results.scanFinished, isTrue);
  });

  test(
    'stopping the scan keeps what was found and says it was not finished',
    () async {
      await controller.readPhone();
      controller.startScan();
      scanner.give('com.maps');
      await pumpEventQueue();
      controller.stopScan();
      expect(scanner.cancelled, isTrue);
      expect(controller.scanning, isFalse);
      expect(controller.results.scans, hasLength(1));
      expect(controller.results.scanFinished, isFalse);

      // A second scan starts from nothing.
      controller.startScan();
      expect(controller.results.scans, isEmpty);
      controller.stopScan();
    },
  );

  test('a scan cannot start before the phone was read', () {
    controller.startScan();
    expect(controller.scanning, isFalse);
    expect(scanner.controller, isNull);
  });

  test('a scan that breaks is reported', () async {
    await controller.readPhone();
    controller.startScan();
    scanner.controller!.addError(StateError('isolate died'));
    await pumpEventQueue();
    expect(controller.scanning, isFalse);
    expect(controller.results.errors['scan'], contains('isolate died'));
    expect(controller.results.scanFinished, isFalse);
  });

  test('opening a system screen records whether Android allowed it', () async {
    probe.screens['privacyDashboard'] = const ActionResult(
      ok: false,
      error: 'SecurityException: denied',
    );
    await controller.open('privacyDashboard');
    await controller.open('privacy');
    await controller.open('usageAccess');
    expect(controller.results.screens['privacyDashboard']!.ok, isFalse);
    expect(controller.results.screens['privacy']!.ok, isTrue);
    // Usage access is the way into step 2, not a screen under test.
    expect(controller.results.screens.containsKey('usageAccess'), isFalse);
    expect(probe.opened, ['privacyDashboard', 'privacy', 'usageAccess']);
  });
}
