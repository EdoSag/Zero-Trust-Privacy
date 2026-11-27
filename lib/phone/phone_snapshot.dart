import '../probe/device_probe.dart';
import '../report/phone_test_results.dart';

/// Everything the dashboard knows about the phone at one moment. Read
/// fresh each time the app comes to the front; never stored and never sent
/// anywhere, because a list of installed apps says a lot about a person.
class PhoneSnapshot {
  PhoneSnapshot({
    required this.takenAt,
    required this.apps,
    this.facts = const {},
    this.accessLists = const {},
    this.specialAccess = const {},
    this.usage,
    this.errors = const {},
  });

  final DateTime takenAt;
  final List<InstalledApp> apps;

  /// Settings and facts about the phone by id (`global.adb_enabled`,
  /// `lock.deviceSecure` and so on), as DeviceProbe.kt names them.
  final Map<String, ProbeValue> facts;

  /// Lists Android keeps of who holds some access (`accessibilityServices`,
  /// `deviceAdmins`, `notificationListeners`, `keyboards`, `vpnApps`).
  final Map<String, AccessList> accessLists;

  /// For each [SpecialAccess] permission, the apps that really hold it.
  final Map<String, Set<String>> specialAccess;

  /// Null when usage access could not be read at all.
  final UsageReport? usage;

  /// The parts that could not be read, with Android's words.
  final Map<String, String> errors;

  late final Map<String, InstalledApp> byPackage = {
    for (final app in apps) app.package: app,
  };

  /// Apps the user installed, as opposed to the ones that came with the
  /// phone's system.
  late final List<InstalledApp> userApps = [
    for (final app in apps)
      if (!app.system) app,
  ];

  late final Map<String, int> _lastUsed = {
    for (final app in usage?.apps ?? const <AppUsage>[])
      app.package: app.lastUsed,
  };

  /// The text of a fact, or null when Android refused it or has no value.
  String? fact(String id) {
    final value = facts[id];
    if (value == null || !value.ok) return null;
    final text = value.value;
    return text == null || text.isEmpty ? null : text;
  }

  /// A yes/no fact: null when it could not be read.
  bool? flag(String id) => switch (fact(id)) {
    '1' || 'true' => true,
    '0' || 'false' => false,
    _ => null,
  };

  /// GrapheneOS, told by a permission only it has.
  bool get grapheneOs =>
      facts['grapheneos.otherSensorsPermission']?.ok ?? false;

  bool get usageGranted => usage?.granted ?? false;

  /// When the app was last on screen, in milliseconds since 1970. Zero when
  /// Android has no record in the last 90 days; null without usage access.
  int? lastUsed(String package) =>
      usageGranted ? (_lastUsed[package] ?? 0) : null;

  /// The apps named in one of Android's lists. A list names a part of an
  /// app (`com.app/.Service`); only the app matters here.
  Set<String> listed(String list) => {
    for (final item in accessLists[list]?.items ?? const <String>[])
      item.split('/').first,
  };

  bool holdsSpecial(String permission, String package) =>
      specialAccess[permission]?.contains(package) ?? false;
}

/// What Android's direct answer about a special access means, together with
/// the granted flag from the app list. Checked on a Pixel 10 Pro with
/// GrapheneOS on 2026-11-27: "allowed" and "errored" are the user's own
/// choice in Settings, and "default" means "go by the permission's flag".
bool effectiveSpecialAccess({
  required String mode,
  required bool grantedFlag,
}) => switch (mode) {
  'allowed' || 'foreground' => true,
  'default' => grantedFlag,
  _ => false,
};

/// Reads the phone. Only a missing app list is an error: every other part
/// that fails is left empty and named in [PhoneSnapshot.errors].
Future<PhoneSnapshot> readPhone(
  DeviceProbe probe, {
  DateTime Function() now = DateTime.now,
}) async {
  final apps = await probe.apps();
  final errors = <String, String>{};

  Future<T> part<T>(String name, Future<T> Function() read, T empty) async {
    try {
      return await read();
    } catch (e) {
      errors[name] = e.toString();
      return empty;
    }
  }

  final facts = await part('device', probe.device, const <ProbeValue>[]);
  final lists = await part(
    'specialAccess',
    probe.specialAccess,
    const <String, AccessList>{},
  );
  final special = await part('accessAnswers', () async {
    final held = <String, Set<String>>{};
    for (final access in SpecialAccess.all) {
      final asking = [
        for (final app in apps)
          if (app.requests(access.permission)) app,
      ];
      final modes = await probe.specialAccessModes([
        for (final app in asking)
          AccessQuery(op: access.op, uid: app.uid, package: app.package),
      ]);
      held[access.permission] = {
        for (var i = 0; i < asking.length && i < modes.length; i++)
          if (effectiveSpecialAccess(
            mode: modes[i],
            grantedFlag: asking[i].holds(access.permission),
          ))
            asking[i].package,
      };
    }
    return held;
  }, const <String, Set<String>>{});
  final usage = await part<UsageReport?>('usage', probe.usage, null);

  return PhoneSnapshot(
    takenAt: now(),
    apps: apps,
    facts: {for (final fact in facts) fact.id: fact},
    accessLists: lists,
    specialAccess: special,
    usage: usage,
    errors: errors,
  );
}
