import 'dart:async';

import 'package:zerotrust_privacy/probe/device_probe.dart';
import 'package:zerotrust_privacy/scan/tracker_scan.dart';

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
