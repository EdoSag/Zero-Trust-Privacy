import 'dart:async';

import 'package:flutter/foundation.dart';

import '../probe/device_probe.dart';
import '../report/phone_test_results.dart';
import '../report/report.dart';
import '../scan/tracker_scan.dart';

/// Runs the steps of the phone test and holds what they found.
class PhoneTestController extends ChangeNotifier {
  PhoneTestController({
    required this.probe,
    required this.scanner,
    required String build,
    DateTime Function()? now,
  }) : results = PhoneTestResults(build: build),
       _now = now ?? DateTime.now;

  final DeviceProbe probe;
  final TrackerScanner scanner;
  final PhoneTestResults results;
  final DateTime Function() _now;

  bool reading = false;
  bool scanning = false;

  StreamSubscription<AppScan>? _scan;
  final Stopwatch _scanClock = Stopwatch();
  Timer? _ticker;
  bool _disposed = false;

  /// The adb command that unlocks deep mode.
  static const deepModeCommand =
      'adb shell pm grant dev.sagron.zerotrustprivacy '
      'android.permission.GET_APP_OPS_STATS';

  bool get hasApps => results.apps != null;

  /// Time the scan has taken so far.
  Duration get scanElapsed => scanning ? _scanClock.elapsed : results.scanTime;

  /// Step 1: everything a normal app may read. Each part stands alone, so
  /// one refusal does not cost the rest.
  Future<void> readPhone() async {
    if (reading) return;
    reading = true;
    results.takenAt = _now();
    _changed();
    await _step('apps', () async => results.apps = await probe.apps());
    await _step('device', () async => results.device = await probe.device());
    await _step(
      'specialAccess',
      () async => results.specialAccess = await probe.specialAccess(),
    );
    await _step('accessAnswers', _readAccessAnswers);
    await _step('usage', () async => results.usage = await probe.usage());
    await _step(
      'deepMode',
      () async => results.deepMode = await probe.deepMode(),
    );
    reading = false;
    _changed();
  }

  /// Steps 2 and 3 again, after the user came back from a system screen or
  /// from the computer.
  Future<void> refreshOptional() async {
    if (reading || !hasApps) return;
    await _step('usage', () async => results.usage = await probe.usage());
    await _step(
      'deepMode',
      () async => results.deepMode = await probe.deepMode(),
    );
    _changed();
  }

  Future<void> _readAccessAnswers() async {
    final apps = results.apps;
    if (apps == null) return;
    final answers = <String, List<AccessAnswer>>{};
    for (final access in SpecialAccess.all) {
      final asking = [
        for (final app in apps)
          if (app.requests(access.permission)) app,
      ];
      final modes = await probe.specialAccessModes([
        for (final app in asking)
          AccessQuery(op: access.op, uid: app.uid, package: app.package),
      ]);
      answers[access.title] = [
        for (var i = 0; i < asking.length; i++)
          AccessAnswer(
            package: asking[i].package,
            grantedFlag: asking[i].holds(access.permission),
            mode: i < modes.length ? modes[i] : 'no answer',
          ),
      ];
    }
    results.accessAnswers = answers;
  }

  Future<void> _step(String name, Future<void> Function() run) async {
    try {
      await run();
      results.errors.remove(name);
    } catch (e) {
      results.errors[name] = e.toString();
    }
  }

  /// Step 4: scans the user's own apps, one at a time, in the background.
  void startScan() {
    final apps = results.apps;
    if (scanning || apps == null) return;
    final targets = [
      for (final app in results.userApps)
        if (app.apkPaths.isNotEmpty) ScanTarget(app.package, app.apkPaths),
    ];
    results
      ..scans.clear()
      ..scanTargets = targets.length
      ..scanTime = Duration.zero
      ..scanFinished = false
      ..errors.remove('scan');
    scanning = true;
    _scanClock
      ..reset()
      ..start();
    // Keeps the seconds on screen moving between two results.
    _ticker = Timer.periodic(
      const Duration(milliseconds: 500),
      (_) => _changed(),
    );
    _scan = scanner
        .scan(targets)
        .listen(
          (scan) {
            results.scans.add(scan);
            _changed();
          },
          onError: (Object error) {
            results.errors['scan'] = error.toString();
            _endScan(finished: false);
          },
          onDone: () => _endScan(finished: true),
        );
    _changed();
  }

  void stopScan() {
    if (!scanning) return;
    _scan?.cancel();
    _endScan(finished: false);
  }

  void _endScan({required bool finished}) {
    if (!scanning) return;
    _scanClock.stop();
    _ticker?.cancel();
    _ticker = null;
    _scan = null;
    scanning = false;
    results
      ..scanTime = _scanClock.elapsed
      ..scanFinished = finished;
    _changed();
  }

  /// Step 5: asks Android to open one of its own screens and records
  /// whether it did.
  Future<ActionResult> open(String screen) async {
    ActionResult result;
    try {
      result = await probe.openSettings(screen);
    } catch (e) {
      result = ActionResult(ok: false, error: e.toString());
    }
    // "Usage access" is a way into step 2, not one of the screens under test.
    if (screen != 'usageAccess') results.screens[screen] = result;
    _changed();
    return result;
  }

  /// The results as text. See [buildReport].
  String report({required bool withNames}) =>
      buildReport(results, withNames: withNames);

  void _changed() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _ticker?.cancel();
    _scan?.cancel();
    super.dispose();
  }
}
