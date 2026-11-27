import 'dart:async';

import 'package:zerotrust_privacy/probe/device_probe.dart';
import 'package:zerotrust_privacy/scan/tracker_list.dart';
import 'package:zerotrust_privacy/scan/tracker_scan.dart';
import 'package:zerotrust_privacy/trackers/scan_cache.dart';

const fineLocation = 'android.permission.ACCESS_FINE_LOCATION';
const backgroundLocation = 'android.permission.ACCESS_BACKGROUND_LOCATION';
const camera = 'android.permission.CAMERA';
const internet = 'android.permission.INTERNET';
const overlay = 'android.permission.SYSTEM_ALERT_WINDOW';

InstalledApp app(
  String package, {
  bool system = false,
  Map<String, bool> permissions = const {},
  bool internetGranted = true,
  bool otherSensorsGranted = true,
  String? installer = 'org.example.store',
  int targetSdk = 35,
  int uid = 10100,
  String? sourceDir,
}) => InstalledApp(
  package: package,
  label: 'Label of $package',
  system: system,
  enabled: true,
  uid: uid,
  targetSdk: targetSdk,
  firstInstall: 0,
  lastUpdate: 0,
  installer: installer,
  sourceDir: sourceDir ?? '/data/app/$package/base.apk',
  splitDirs: const [],
  requested: permissions.keys.toList(),
  granted: permissions.values.toList(),
  internetGranted: internetGranted,
  otherSensorsGranted: otherSensorsGranted,
);

/// A small made-up phone: three of the user's apps and one system app.
List<InstalledApp> somePhone() => [
  app(
    'com.maps',
    permissions: {
      fineLocation: true,
      backgroundLocation: true,
      internet: true,
      overlay: false,
    },
    uid: 10101,
  ),
  app(
    'com.camera',
    permissions: {camera: true, fineLocation: false, internet: true},
    internetGranted: false,
    targetSdk: 28,
    installer: null,
    uid: 10102,
  ),
  app('com.notes', otherSensorsGranted: false, uid: 10103),
  app(
    'android.system',
    system: true,
    permissions: {camera: true, internet: true, overlay: true},
    uid: 1000,
  ),
];

/// Stands in for the phone. Each answer can be replaced or made to fail.
class FakeProbe implements DeviceProbe {
  List<InstalledApp> installed = somePhone();
  Object? appsFailure;
  List<ProbeValue> values = const [
    ProbeValue(id: 'build.model', ok: true, value: 'Test Phone'),
    ProbeValue(id: 'global.adb_enabled', ok: true, value: '0'),
    ProbeValue(
      id: 'secure.always_on_vpn_app',
      ok: false,
      error: 'SecurityException: not readable',
    ),
  ];
  Map<String, AccessList> lists = const {
    'accessibilityServices': AccessList(
      ok: true,
      items: ['com.reader/.Service'],
    ),
    'keyboards': AccessList(
      ok: true,
      items: ['com.keys/.Ime', 'com.other/.Ime'],
    ),
    'deviceAdmins': AccessList(
      ok: false,
      items: [],
      error: 'SecurityException: no',
    ),
  };
  String Function(AccessQuery query) mode = (_) => 'allowed';
  UsageReport usageReport = const UsageReport(granted: false);
  DeepModeReport deepReport = const DeepModeReport(
    permissionGranted: false,
    attempts: [
      DeepModeAttempt(
        step: 'plain',
        ok: false,
        error: 'NoSuchMethodException: x',
      ),
    ],
  );
  Map<String, ActionResult> screens = {};
  final List<String> opened = [];

  /// Every screen asked for, with the app it was asked to open on.
  final List<(String, String?)> openedWith = [];
  final List<String> shared = [];
  final Map<String, String> saved = {};
  final List<AccessQuery> asked = [];

  @override
  Future<List<InstalledApp>> apps() async {
    if (appsFailure != null) throw appsFailure!;
    return installed;
  }

  @override
  Future<List<ProbeValue>> device() async => values;

  @override
  Future<Map<String, AccessList>> specialAccess() async => lists;

  @override
  Future<List<String>> specialAccessModes(List<AccessQuery> queries) async {
    asked.addAll(queries);
    return [for (final query in queries) mode(query)];
  }

  @override
  Future<UsageReport> usage() async => usageReport;

  @override
  Future<DeepModeReport> deepMode() async => deepReport;

  @override
  Future<ActionResult> openSettings(String screen, {String? package}) async {
    opened.add(screen);
    openedWith.add((screen, package));
    return screens[screen] ?? const ActionResult(ok: true);
  }

  @override
  Future<ActionResult> shareText(String subject, String text) async {
    shared.add(text);
    return const ActionResult(ok: true);
  }

  @override
  Future<String> saveToDownloads(String name, String text) async {
    saved[name] = text;
    return 'content://downloads/$name';
  }
}

/// A scanner the test drives by hand: it hands out results when told to.
class FakeScanner implements TrackerScanner {
  StreamController<AppScan>? controller;
  List<ScanTarget> targets = const [];
  bool cancelled = false;

  @override
  Stream<AppScan> scan(List<ScanTarget> targets) {
    this.targets = targets;
    cancelled = false;
    return (controller = StreamController<AppScan>(
      onCancel: () => cancelled = true,
    )).stream;
  }

  void give(
    String package, {
    List<String> found = const [],
    List<String> errors = const [],
    int milliseconds = 10,
    int dexFiles = 1,
  }) => controller!.add(
    AppScan(
      package: package,
      found: found,
      dexFiles: dexFiles,
      dexBytes: 1024 * 1024,
      types: 500,
      errors: errors,
      elapsed: Duration(milliseconds: milliseconds),
    ),
  );

  Future<void> finish() => controller!.close();
}

/// A short tracker list of made-up kits, one of each sort the screens
/// treat differently.
const adNetwork = Tracker(
  id: 11,
  name: 'Ad Network',
  code: ['com.adnetwork.'],
  kinds: {TrackerKind.ads},
  website: 'https://adnetwork.example',
);
const appStats = Tracker(
  id: 12,
  name: 'App Stats',
  code: ['com.appstats.'],
  kinds: {TrackerKind.analytics, TrackerKind.profiling},
);
const crashCatcher = Tracker(
  id: 13,
  name: 'Crash Catcher',
  code: ['com.crashcatcher.'],
  kinds: {TrackerKind.crashReporting},
);
const mysteryKit = Tracker(id: 14, name: 'Mystery Kit', code: ['com.mystery.']);

TrackerList someTrackers() => TrackerList(
  trackers: const [adNetwork, appStats, crashCatcher, mysteryKit],
  newestEntry: '2023-12-05',
  attribution: 'Made up for tests',
);

/// A scanner that answers at once from [found]: tracker names by package.
/// An app that is not named has no tracker code.
class InstantScanner implements TrackerScanner {
  Map<String, List<String>> found = {};

  /// Packages whose code cannot be read.
  Set<String> unreadable = {};

  /// Packages with one part read and another that failed.
  Set<String> incomplete = {};

  /// Every package asked for, in order, over all scans.
  final List<String> scanned = [];

  @override
  Stream<AppScan> scan(List<ScanTarget> targets) {
    scanned.addAll([for (final target in targets) target.package]);
    return Stream.fromIterable([
      for (final target in targets)
        AppScan(
          package: target.package,
          found: found[target.package] ?? const [],
          dexFiles: unreadable.contains(target.package) ? 0 : 1,
          dexBytes: 1024,
          types: 10,
          errors: unreadable.contains(target.package)
              ? const ['base.apk: Permission denied']
              : incomplete.contains(target.package)
              ? const ['classes2.dex: too large to read']
              : const [],
          elapsed: const Duration(milliseconds: 1),
        ),
    ]);
  }
}

/// Scan results kept in memory, as the sealed file would keep them.
class MemoryScanCache implements ScanCache {
  ScanMemory? kept;
  int saves = 0;
  Object? failure;

  @override
  Future<ScanMemory?> load() async =>
      kept == null ? null : ScanMemory.fromJson(kept!.toJson());

  @override
  Future<void> save(ScanMemory memory) async {
    if (failure != null) throw failure!;
    saves++;
    kept = ScanMemory.fromJson(memory.toJson());
  }
}
