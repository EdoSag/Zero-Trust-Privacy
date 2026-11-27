import 'package:flutter/services.dart';

/// An installed app, as Android describes it to another app.
class InstalledApp {
  const InstalledApp({
    required this.package,
    required this.label,
    required this.system,
    required this.enabled,
    required this.uid,
    required this.targetSdk,
    required this.firstInstall,
    required this.lastUpdate,
    required this.installer,
    required this.sourceDir,
    required this.splitDirs,
    required this.requested,
    required this.granted,
    required this.internetGranted,
    required this.otherSensorsGranted,
  });

  factory InstalledApp.fromMap(Map<Object?, Object?> map) => InstalledApp(
    package: map['package'] as String? ?? '',
    label: map['label'] as String? ?? '',
    system: map['system'] as bool? ?? false,
    enabled: map['enabled'] as bool? ?? true,
    uid: (map['uid'] as num?)?.toInt() ?? -1,
    targetSdk: (map['targetSdk'] as num?)?.toInt() ?? 0,
    firstInstall: (map['firstInstall'] as num?)?.toInt() ?? 0,
    lastUpdate: (map['lastUpdate'] as num?)?.toInt() ?? 0,
    installer: map['installer'] as String?,
    sourceDir: map['sourceDir'] as String?,
    splitDirs: _strings(map['splitDirs']),
    requested: _strings(map['requested']),
    granted: (map['granted'] as List?)?.cast<bool>() ?? const [],
    internetGranted: map['internetGranted'] as bool? ?? false,
    otherSensorsGranted: map['otherSensorsGranted'] as bool? ?? false,
  );

  final String package;
  final String label;

  /// Came with the phone's system, as opposed to installed by the user.
  final bool system;
  final bool enabled;
  final int uid;
  final int targetSdk;

  /// Milliseconds since 1970.
  final int firstInstall;
  final int lastUpdate;

  /// The store or app that installed it, when Android says.
  final String? installer;
  final String? sourceDir;
  final List<String> splitDirs;

  /// Every permission the app asks for, and whether it holds each one.
  final List<String> requested;
  final List<bool> granted;

  final bool internetGranted;
  final bool otherSensorsGranted;

  /// The app's APK files: the base file and any splits.
  List<String> get apkPaths => [
    if (sourceDir != null) sourceDir!,
    ...splitDirs,
  ];

  bool requests(String permission) => requested.contains(permission);

  bool holds(String permission) {
    final index = requested.indexOf(permission);
    return index >= 0 && index < granted.length && granted[index];
  }
}

/// One setting or fact read from the phone: its value, or why Android
/// refused to give it.
class ProbeValue {
  const ProbeValue({
    required this.id,
    required this.ok,
    this.value,
    this.error,
  });

  factory ProbeValue.fromMap(Map<Object?, Object?> map) => ProbeValue(
    id: map['id'] as String? ?? '',
    ok: map['ok'] as bool? ?? false,
    value: map['value'] as String?,
    error: map['error'] as String?,
  );

  final String id;
  final bool ok;
  final String? value;
  final String? error;
}

/// A list Android keeps of who holds some special access (accessibility
/// services, keyboards, device admin apps and so on).
class AccessList {
  const AccessList({required this.ok, required this.items, this.error});

  factory AccessList.fromMap(Map<Object?, Object?> map) => AccessList(
    ok: map['ok'] as bool? ?? false,
    items: _strings(map['items']),
    error: map['error'] as String?,
  );

  final bool ok;
  final List<String> items;
  final String? error;
}

/// When an app was last used, from Android's usage access.
class AppUsage {
  const AppUsage({
    required this.package,
    required this.lastUsed,
    required this.foregroundMs,
  });

  final String package;
  final int lastUsed;
  final int foregroundMs;
}

/// Bytes moved per app on Wi-Fi or on mobile data.
class DataUse {
  const DataUse({required this.ok, this.bytesByUid = const {}, this.error});

  factory DataUse.fromMap(Map<Object?, Object?>? map) {
    if (map == null) return const DataUse(ok: false);
    final uids = (map['uids'] as List?) ?? const [];
    final bytes = (map['bytes'] as List?) ?? const [];
    return DataUse(
      ok: map['ok'] as bool? ?? false,
      bytesByUid: {
        for (var i = 0; i < uids.length && i < bytes.length; i++)
          (uids[i] as num).toInt(): (bytes[i] as num).toInt(),
      },
      error: map['error'] as String?,
    );
  }

  final bool ok;
  final Map<int, int> bytesByUid;
  final String? error;
}

/// What "Usage access" gives once the user has switched it on.
class UsageReport {
  const UsageReport({
    required this.granted,
    this.apps = const [],
    this.appsError,
    this.wifi = const DataUse(ok: false),
    this.mobile = const DataUse(ok: false),
  });

  factory UsageReport.fromMap(Map<Object?, Object?> map) => UsageReport(
    granted: map['granted'] as bool? ?? false,
    apps: [
      for (final app in (map['apps'] as List?) ?? const [])
        AppUsage(
          package: (app as Map)['package'] as String? ?? '',
          lastUsed: (app['lastUsed'] as num?)?.toInt() ?? 0,
          foregroundMs: (app['foregroundMs'] as num?)?.toInt() ?? 0,
        ),
    ],
    appsError: map['appsError'] as String?,
    wifi: DataUse.fromMap(map['wifi'] as Map<Object?, Object?>?),
    mobile: DataUse.fromMap(map['mobile'] as Map<Object?, Object?>?),
  );

  final bool granted;
  final List<AppUsage> apps;
  final String? appsError;
  final DataUse wifi;
  final DataUse mobile;
}

/// One step of the attempt to read which app used the camera, microphone or
/// location.
class DeepModeAttempt {
  const DeepModeAttempt({required this.step, required this.ok, this.error});

  final String step;
  final bool ok;
  final String? error;
}

/// One app's last use of one kind of access.
class OpUse {
  const OpUse({
    required this.package,
    required this.op,
    required this.lastAccess,
    required this.lastReject,
    required this.running,
  });

  final String package;
  final String op;

  /// Milliseconds since 1970; zero or less when never.
  final int lastAccess;
  final int lastReject;
  final bool running;
}

/// How far "deep mode" got.
class DeepModeReport {
  const DeepModeReport({
    required this.permissionGranted,
    this.attempts = const [],
    this.entries = const [],
  });

  factory DeepModeReport.fromMap(Map<Object?, Object?> map) => DeepModeReport(
    permissionGranted: map['permissionGranted'] as bool? ?? false,
    attempts: [
      for (final attempt in (map['attempts'] as List?) ?? const [])
        DeepModeAttempt(
          step: (attempt as Map)['step'] as String? ?? '',
          ok: attempt['ok'] as bool? ?? false,
          error: attempt['error'] as String?,
        ),
    ],
    entries: [
      for (final entry in (map['entries'] as List?) ?? const [])
        OpUse(
          package: (entry as Map)['package'] as String? ?? '',
          op: entry['op'] as String? ?? '',
          lastAccess: (entry['lastAccess'] as num?)?.toInt() ?? 0,
          lastReject: (entry['lastReject'] as num?)?.toInt() ?? 0,
          running: entry['running'] as bool? ?? false,
        ),
    ],
  );

  final bool permissionGranted;
  final List<DeepModeAttempt> attempts;
  final List<OpUse> entries;

  /// Android answered the call without an error. That alone shows nothing:
  /// without the grant it answers with an empty list (seen on a Pixel 10 Pro
  /// with GrapheneOS, 2026-11-27).
  bool get answered => attempts.any((a) => a.ok && a.step != 'exemption');

  /// Rows about apps other than this one.
  int get rowsAboutOthers =>
      entries.where((e) => e.package != ownPackage).length;

  /// The history of other apps could really be read.
  bool get works => answered && rowsAboutOthers > 0;

  static const ownPackage = 'dev.sagron.zerotrustprivacy';
}

/// Whether Android opened a screen, or did something, when asked.
class ActionResult {
  const ActionResult({required this.ok, this.error});

  factory ActionResult.fromMap(Map<Object?, Object?>? map) => ActionResult(
    ok: map?['ok'] as bool? ?? false,
    error: map?['error'] as String?,
  );

  final bool ok;
  final String? error;
}

/// A special access to ask Android about for one app.
class AccessQuery {
  const AccessQuery({
    required this.op,
    required this.uid,
    required this.package,
  });

  final String op;
  final int uid;
  final String package;
}

/// What this app can read from the phone. The real one talks to Android;
/// tests use a made-up phone.
abstract class DeviceProbe {
  Future<List<InstalledApp>> apps();
  Future<List<ProbeValue>> device();
  Future<Map<String, AccessList>> specialAccess();

  /// For each query, in order: `allowed`, `ignored`, `default`, `errored`,
  /// or Android's refusal.
  Future<List<String>> specialAccessModes(List<AccessQuery> queries);
  Future<UsageReport> usage();
  Future<DeepModeReport> deepMode();
  Future<ActionResult> openSettings(String screen, {String? package});
  Future<ActionResult> shareText(String subject, String text);

  /// Returns where the file was saved.
  Future<String> saveToDownloads(String name, String text);
}

/// Talks to DeviceProbe.kt and AppOpsReader.kt.
class ChannelDeviceProbe implements DeviceProbe {
  const ChannelDeviceProbe();

  static const _channel = MethodChannel('zt_privacy/probe');

  @override
  Future<List<InstalledApp>> apps() async {
    final list = await _channel.invokeListMethod<Map<Object?, Object?>>('apps');
    return [for (final map in list ?? const []) InstalledApp.fromMap(map)];
  }

  @override
  Future<List<ProbeValue>> device() async {
    final list = await _channel.invokeListMethod<Map<Object?, Object?>>(
      'device',
    );
    return [for (final map in list ?? const []) ProbeValue.fromMap(map)];
  }

  @override
  Future<Map<String, AccessList>> specialAccess() async {
    final map = await _channel.invokeMapMethod<String, Map<Object?, Object?>>(
      'specialAccess',
    );
    return {
      for (final entry in (map ?? const {}).entries)
        entry.key: AccessList.fromMap(entry.value),
    };
  }

  @override
  Future<List<String>> specialAccessModes(List<AccessQuery> queries) async {
    if (queries.isEmpty) return const [];
    final list = await _channel.invokeListMethod<String>('specialAccessModes', {
      'requests': [
        for (final query in queries)
          {'op': query.op, 'uid': query.uid, 'package': query.package},
      ],
    });
    return list ?? const [];
  }

  @override
  Future<UsageReport> usage() async {
    final map = await _channel.invokeMapMethod<Object?, Object?>('usage');
    return UsageReport.fromMap(map ?? const {});
  }

  @override
  Future<DeepModeReport> deepMode() async {
    final map = await _channel.invokeMapMethod<Object?, Object?>('appOps');
    return DeepModeReport.fromMap(map ?? const {});
  }

  @override
  Future<ActionResult> openSettings(String screen, {String? package}) async {
    final map = await _channel.invokeMapMethod<Object?, Object?>(
      'openSettings',
      {'screen': screen, 'package': package},
    );
    return ActionResult.fromMap(map);
  }

  @override
  Future<ActionResult> shareText(String subject, String text) async {
    final map = await _channel.invokeMapMethod<Object?, Object?>('shareText', {
      'subject': subject,
      'text': text,
    });
    return ActionResult.fromMap(map);
  }

  @override
  Future<String> saveToDownloads(String name, String text) async {
    final uri = await _channel.invokeMethod<String>('saveToDownloads', {
      'name': name,
      'text': text,
    });
    return uri ?? '';
  }
}

List<String> _strings(Object? value) =>
    (value as List?)?.cast<String>() ?? const [];
