import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zero_trust_core/zero_trust_core.dart';
import 'package:zerotrust_privacy/app/privacy_config.dart';
import 'package:zerotrust_privacy/choices/choices.dart';
import 'package:zerotrust_privacy/l10n/l10n.dart';
import 'package:zerotrust_privacy/phone/phone_providers.dart';
import 'package:zerotrust_privacy/phone/system_screens.dart';
import 'package:zerotrust_privacy/probe/device_probe.dart';
import 'package:zerotrust_privacy/scan/tracker_scan.dart';
import 'package:zerotrust_privacy/trackers/tracker_providers.dart';
import 'package:zerotrust_privacy/ui/widgets.dart';

import 'fake_phone.dart';

/// Logical sizes: a Pixel 10 Pro, and the smallest phone still in use.
const pixel = Size(412, 915);
const smallPhone = Size(320, 568);

const hebrew = Locale('he');

int daysAgo(int days) =>
    DateTime.now().subtract(Duration(days: days)).millisecondsSinceEpoch;

String dateDaysAgo(int days) => DateTime.now()
    .subtract(Duration(days: days))
    .toIso8601String()
    .substring(0, 10);

/// One of the user's apps, installed a year ago and updated a month ago.
InstalledApp userApp(
  String package,
  String label, {
  Map<String, bool> permissions = const {},
  int targetSdk = 35,
  int? lastUpdate,
  int? firstInstall,
  bool system = false,
  String? installer = 'org.example.store',
  int uid = 10100,
}) => InstalledApp(
  package: package,
  label: label,
  system: system,
  enabled: true,
  uid: uid,
  targetSdk: targetSdk,
  firstInstall: firstInstall ?? daysAgo(365),
  lastUpdate: lastUpdate ?? daysAgo(30),
  installer: installer,
  sourceDir: '/data/app/$package/base.apk',
  splitDirs: const [],
  requested: permissions.keys.toList(),
  granted: permissions.values.toList(),
  internetGranted: true,
  otherSensorsGranted: true,
);

const allFiles = 'android.permission.MANAGE_EXTERNAL_STORAGE';

/// The facts of a well kept phone: nothing to point out.
Map<String, String> goodFacts() => {
  'lock.deviceSecure': 'true',
  'encryption.status': 'active, per user',
  'build.securityPatch': dateDaysAgo(20),
  'global.adb_enabled': '0',
  'global.adb_wifi_enabled': '0',
  'global.development_settings_enabled': '0',
  'secure.lock_screen_show_notifications': '1',
  'secure.lock_screen_allow_private_notifications': '0',
  'global.wifi_scan_always_enabled': '0',
  'global.ble_scan_always_enabled': '0',
  'global.private_dns_mode': 'off',
  'network.privateDnsActive': 'false',
  'network.vpnActive': 'true',
};

/// A phone like the one the app was first tried on: GrapheneOS, wireless
/// debugging left on, a VPN, and a handful of apps with something to say.
///
/// Six findings, 22 points: wireless debugging 6, Reader's accessibility
/// service 6, Maps' location all the time 4, Files' all-files access 3, Old
/// Game built for Android 9 (2) and not updated for three years (1).
FakeProbe pixelLikePhone({bool graphene = true}) => FakeProbe()
  ..installed = [
    userApp(
      'com.maps',
      'Maps',
      permissions: {fineLocation: true, backgroundLocation: true},
      uid: 10101,
    ),
    userApp('com.reader', 'Reader', uid: 10102),
    userApp('com.files', 'Files', permissions: {allFiles: false}, uid: 10103),
    userApp(
      'com.game',
      'Old Game',
      targetSdk: 28,
      lastUpdate: daysAgo(3 * 365 + 30),
      firstInstall: daysAgo(4 * 365),
      uid: 10104,
    ),
    userApp('com.notes', 'Notes', permissions: {camera: true}, uid: 10105),
    userApp(
      'android.system',
      'System Thing',
      system: true,
      permissions: {camera: true, fineLocation: true},
      uid: 1000,
    ),
  ]
  ..values = facts({
    ...goodFacts(),
    'global.adb_wifi_enabled': '1',
    'global.development_settings_enabled': '1',
    if (graphene)
      'grapheneos.otherSensorsPermission': 'android.permission.OTHER_SENSORS',
  })
  ..lists = const {
    'accessibilityServices': AccessList(
      ok: true,
      items: ['com.reader/.ReadAloud'],
    ),
  }
  // Android's direct answer: only Files was allowed by the user.
  ..mode = ((query) => query.package == 'com.files' ? 'allowed' : 'default');

List<ProbeValue> facts(Map<String, String> values) => [
  for (final entry in values.entries)
    ProbeValue(id: entry.key, ok: true, value: entry.value),
];

/// Changes one fact of [probe]'s phone, as a trip to Settings would.
void setFact(FakeProbe probe, String id, String value) => probe.values = [
  for (final fact in probe.values)
    if (fact.id != id) fact,
  ProbeValue(id: id, ok: true, value: value),
];

/// The choices kept in memory.
class MemoryChoices implements ChoicesRepository {
  Choices now = const Choices(id: 'device-test');
  Object? failure;
  final _changes = StreamController<Choices>.broadcast();

  @override
  Stream<Choices> watch() async* {
    yield now;
    yield* _changes.stream;
  }

  @override
  Future<void> save(Choices choices) async {
    if (failure != null) throw failure!;
    now = choices;
    _changes.add(choices);
  }
}

/// What a test can look at.
class World {
  World({FakeProbe? probe, TrackerScanner? scanner})
    : probe = probe ?? pixelLikePhone(),
      scanner = scanner ?? InstantScanner();

  final FakeProbe probe;
  final choices = MemoryChoices();

  /// Reads the apps for tracker code. An [InstantScanner] unless the test
  /// gave its own; [found] says what it finds.
  final TrackerScanner scanner;
  final scans = MemoryScanCache();

  /// Web pages the app asked the browser to open.
  final links = <Uri>[];

  /// Tracker names by package, for the [InstantScanner].
  Map<String, List<String>> get found => (scanner as InstantScanner).found;

  List<Override> get overrides => [
    ztAppConfigProvider.overrideWithValue(privacyAppConfig),
    deviceProbeProvider.overrideWithValue(probe),
    choicesRepositoryProvider.overrideWithValue(choices),
    trackerListProvider.overrideWith((ref) async => someTrackers()),
    scanCacheProvider.overrideWith((ref) async => scans),
    trackerScannerProvider.overrideWithValue(scanner),
    // No vault in a test: nothing to keep awake during a scan.
    scanActivityProvider.overrideWithValue(() {}),
    linkOpenerProvider.overrideWithValue((url) async {
      links.add(url);
      return true;
    }),
    // No vault in a test: nothing to keep open while Settings is in front.
    systemScreensProvider.overrideWith((ref) => SystemScreens(probe)),
  ];
}

/// [home] inside the suite's real theme, in [locale].
Widget privacyApp(
  Widget home,
  World world, {
  Locale locale = const Locale('en'),
}) => ProviderScope(
  overrides: world.overrides,
  child: MaterialApp(
    // The suite's real theme: its full-width buttons break rows that a
    // plain theme lets through.
    theme: ZtTheme.light(accent: privacyAccent),
    locale: locale,
    supportedLocales: ZtLanguages.supported,
    localizationsDelegates: const [AppL10n.delegate, ...ZtLanguages.delegates],
    home: home,
  ),
);

/// Shows [home] on a screen [size] wide. The screen is made very tall, so
/// that a whole page is laid out and every widget's place can be checked.
Future<void> show(
  WidgetTester tester,
  Widget home,
  World world, {
  Size size = pixel,
  Locale locale = const Locale('en'),
  double height = 3000,
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = Size(size.width, height);
  addTearDown(tester.view.reset);
  await tester.pumpWidget(privacyApp(home, world, locale: locale));
  await tester.pumpAndSettle();
}

Finder byKey(String name) => find.byKey(Key(name));

/// Every button on screen is inside the screen's width with room at the
/// sides, and big enough to press.
void expectButtonsFit(WidgetTester tester, double width, {int atLeast = 1}) {
  // The buttons with words on them; the arrows and icons of the top bar
  // sit in the bar's own corner.
  final buttons = find.byWidgetPredicate(
    (w) => w is FilledButton || w is OutlinedButton || w is TextButton,
  );
  expect(buttons, findsAtLeastNWidgets(atLeast));
  for (final element in buttons.evaluate()) {
    final rect = tester.getRect(find.byWidget(element.widget));
    final reason = '${element.widget.key} at $rect';
    expect(rect.left, greaterThanOrEqualTo(8), reason: reason);
    expect(rect.right, lessThanOrEqualTo(width - 8), reason: reason);
    expect(rect.width, greaterThan(40), reason: reason);
    expect(rect.height, greaterThanOrEqualTo(40), reason: reason);
  }
}
