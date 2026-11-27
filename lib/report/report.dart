import '../probe/device_probe.dart';
import '../scan/tracker_scan.dart';
import 'phone_test_results.dart';

/// Permissions a privacy check cares about most, with a plain name each.
const watchedPermissions = <String, String>{
  'Location, precise': 'android.permission.ACCESS_FINE_LOCATION',
  'Location, approximate': 'android.permission.ACCESS_COARSE_LOCATION',
  'Location, all the time': 'android.permission.ACCESS_BACKGROUND_LOCATION',
  'Camera': 'android.permission.CAMERA',
  'Microphone': 'android.permission.RECORD_AUDIO',
  'Contacts': 'android.permission.READ_CONTACTS',
  'Calendar': 'android.permission.READ_CALENDAR',
  'SMS': 'android.permission.READ_SMS',
  'Call log': 'android.permission.READ_CALL_LOG',
  'Phone state': 'android.permission.READ_PHONE_STATE',
  'Photos and videos': 'android.permission.READ_MEDIA_IMAGES',
  'Files (old style)': 'android.permission.READ_EXTERNAL_STORAGE',
  'Nearby devices': 'android.permission.BLUETOOTH_SCAN',
  'Body sensors': 'android.permission.BODY_SENSORS',
  'Physical activity': 'android.permission.ACTIVITY_RECOGNITION',
  'Notifications': 'android.permission.POST_NOTIFICATIONS',
};

const _internet = 'android.permission.INTERNET';
const _otherSensors = 'android.permission.OTHER_SENSORS';

/// The results as plain text, to send back for reading.
///
/// With [withNames] false, no app is named: only counts. That is the
/// version meant for sharing, because a list of installed apps says a lot
/// about a person. With it true, a line per app is added at the end.
String buildReport(PhoneTestResults results, {required bool withNames}) {
  final out = StringBuffer()
    ..writeln('ZT Privacy phone test, build ${results.build}')
    ..writeln('Taken: ${results.takenAt?.toUtc().toIso8601String() ?? '-'}')
    ..writeln('App names: ${withNames ? 'included' : 'left out'}');

  // Android's refusals are quoted as it worded them, and its wording can
  // name an app or the folder an app is installed in. The summary takes
  // those names out again.
  final clean = withNames ? (String text) => text : _nameRemover(results);

  if (results.errors.isNotEmpty) {
    out.writeln('\n== Steps that failed ==');
    results.errors.forEach(
      (step, error) => out.writeln('$step: ${clean(error)}'),
    );
  }

  final device = results.device;
  if (device != null) {
    out.writeln('\n== Phone and settings ==');
    for (final value in device) {
      out.writeln(
        value.ok
            ? '${value.id}: ${_settingText(value, withNames)}'
            : '${value.id}: REFUSED ${clean(value.error ?? '')}',
      );
    }
    final refused = device.where((v) => !v.ok).length;
    out.writeln('Read: ${device.length - refused} of ${device.length}');
  }

  final apps = results.apps;
  if (apps != null) {
    _writeApps(out, results, apps, withNames);
  }

  final special = results.specialAccess;
  if (special != null) {
    out.writeln('\n== Special access lists ==');
    for (final entry in special.entries) {
      final list = entry.value;
      if (!list.ok) {
        out.writeln('${entry.key}: REFUSED ${clean(list.error ?? '')}');
      } else if (withNames) {
        out.writeln(
          '${entry.key}: ${list.items.length}'
          '${list.items.isEmpty ? '' : ' (${list.items.join(', ')})'}',
        );
      } else {
        out.writeln('${entry.key}: ${list.items.length}');
      }
    }
  }

  final answers = results.accessAnswers;
  if (answers != null) {
    out.writeln('\n== Special access per app (asked Android directly) ==');
    for (final entry in answers.entries) {
      final rows = entry.value;
      final byMode = <String, int>{};
      for (final row in rows) {
        byMode[_modeKey(row.mode)] = (byMode[_modeKey(row.mode)] ?? 0) + 1;
      }
      final flagged = rows.where((r) => r.grantedFlag).length;
      out.writeln(
        '${entry.key}: asked by ${rows.length}; answers: '
        '${byMode.isEmpty ? '-' : _counts(byMode)}; '
        'granted flag set: $flagged',
      );
      final refusal = rows
          .map((r) => r.mode)
          .where((m) => _modeKey(m) == 'refused')
          .firstOrNull;
      if (refusal != null) out.writeln('  first refusal: ${clean(refusal)}');
    }
  }

  final usage = results.usage;
  if (usage != null) {
    _writeUsage(out, results, usage, clean);
  }

  final deep = results.deepMode;
  if (deep != null) {
    _writeDeepMode(out, results, deep, withNames, clean);
  }

  if (results.screens.isNotEmpty) {
    out.writeln('\n== System screens ==');
    results.screens.forEach(
      (screen, result) => out.writeln(
        result.ok
            ? '$screen: opened'
            : '$screen: REFUSED ${clean(result.error ?? '')}',
      ),
    );
  }

  if (results.scans.isNotEmpty || results.scanTargets > 0) {
    _writeScan(out, results, withNames, clean);
  }

  if (withNames && apps != null) {
    _writePerApp(out, results, apps);
  }
  return out.toString();
}

/// Settings whose value is the name of an app (or a list of them): the
/// keyboard, the accessibility services, the password manager and so on.
const _settingsNamingApps = {
  'secure.always_on_vpn_app',
  'secure.default_input_method',
  'secure.enabled_accessibility_services',
  'secure.enabled_notification_listeners',
  'secure.autofill_service',
  'secure.credential_service',
  'secure.voice_interaction_service',
  'secure.assistant',
  'secure.nfc_payment_default_component',
};

/// Settings whose value is an address the user chose. A private DNS name
/// can hold a personal account id, so the summary only says it is set.
const _settingsNamingServers = {
  'global.private_dns_specifier',
  'network.privateDnsServer',
};

/// What the report shows for one setting. The summary never shows the name
/// of an app or of a server: only whether the setting is set, and for a
/// list, how long it is.
String _settingText(ProbeValue value, bool withNames) {
  final text = value.value;
  if (text == null || text.isEmpty) return '(empty)';
  if (withNames) return text;
  if (_settingsNamingServers.contains(value.id)) return 'set';
  if (_settingsNamingApps.contains(value.id)) {
    final count = text.split(':').where((part) => part.isNotEmpty).length;
    return 'set ($count)';
  }
  return text;
}

/// Takes the name of every app the phone test saw out of a text.
String Function(String) _nameRemover(PhoneTestResults results) {
  final names = <String>{
    for (final app in results.apps ?? const <InstalledApp>[]) app.package,
    for (final app in results.usage?.apps ?? const <AppUsage>[]) app.package,
    for (final row in results.deepMode?.entries ?? const <OpUse>[]) row.package,
    for (final list in (results.specialAccess ?? const {}).values)
      for (final item in list.items) item.split('/').first,
    for (final rows in (results.accessAnswers ?? const {}).values)
      for (final row in rows) row.package,
  };
  // A name without a dot ("android") is also an ordinary word in Android's
  // messages and names no app the user chose. The longest names go first,
  // so that "com.shop.pay" is not left as "(app).pay".
  final ordered = names.where((name) => name.contains('.')).toList()
    ..sort((a, b) => b.length.compareTo(a.length));
  if (ordered.isEmpty) return (text) => text;
  final pattern = RegExp(ordered.map(RegExp.escape).join('|'));
  return (text) => text.replaceAll(pattern, '(app)');
}

void _writeApps(
  StringBuffer out,
  PhoneTestResults results,
  List<InstalledApp> apps,
  bool withNames,
) {
  final user = results.userApps;
  out
    ..writeln('\n== Apps ==')
    ..writeln(
      'Apps Android showed: ${apps.length} '
      '(yours ${user.length}, system ${apps.length - user.length})',
    )
    ..writeln('Switched off: ${apps.where((a) => !a.enabled).length}')
    ..writeln(
      'Your apps with a known installer: '
      '${user.where((a) => a.installer != null).length} of ${user.length}',
    );
  if (withNames) {
    final installers = <String, int>{};
    for (final app in user) {
      final key = app.installer ?? '(none)';
      installers[key] = (installers[key] ?? 0) + 1;
    }
    out.writeln('Installed by: ${_counts(installers)}');
  }
  out
    ..writeln(
      'Your apps built for Android 10 or older (target below 30): '
      '${user.where((a) => a.targetSdk < 30).length}',
    )
    ..writeln(
      'Apps with no permission list at all: '
      '${apps.where((a) => a.requested.isEmpty).length}',
    )
    ..writeln('\n== Permissions (your apps: holding / asking) ==');
  for (final entry in watchedPermissions.entries) {
    final asking = user.where((a) => a.requests(entry.value)).length;
    final holding = user.where((a) => a.holds(entry.value)).length;
    out.writeln('${entry.key}: $holding / $asking');
  }

  // Three ways the same question could show up. Which of them move when a
  // GrapheneOS switch is turned off is what the test is here to learn.
  final askNetwork = apps.where((a) => a.requests(_internet)).toList();
  out
    ..writeln('\n== GrapheneOS Network and Sensors switches ==')
    ..writeln('Apps asking for network: ${askNetwork.length}')
    ..writeln(
      '  granted flag off: '
      '${askNetwork.where((a) => !a.holds(_internet)).length}',
    )
    ..writeln(
      '  direct check says no: '
      '${askNetwork.where((a) => !a.internetGranted).length}',
    )
    ..writeln(
      'Apps listing the Sensors permission: '
      '${apps.where((a) => a.requests(_otherSensors)).length}',
    )
    ..writeln(
      '  of those, granted flag off: '
      '${apps.where((a) => a.requests(_otherSensors) && !a.holds(_otherSensors)).length}',
    )
    ..writeln(
      'Direct Sensors check says yes / no: '
      '${apps.where((a) => a.otherSensorsGranted).length} / '
      '${apps.where((a) => !a.otherSensorsGranted).length}',
    );
}

void _writeUsage(
  StringBuffer out,
  PhoneTestResults results,
  UsageReport usage,
  String Function(String) clean,
) {
  out
    ..writeln('\n== Usage access ==')
    ..writeln('Switched on: ${_yesNo(usage.granted)}');
  if (!usage.granted) return;
  if (usage.appsError != null) {
    out.writeln('Last-used times: REFUSED ${clean(usage.appsError!)}');
  } else {
    final lastUsed = {for (final app in usage.apps) app.package: app.lastUsed};
    final taken = results.takenAt ?? DateTime.now();
    final limit = taken
        .subtract(const Duration(days: 90))
        .millisecondsSinceEpoch;
    final stale = results.userApps
        .where((app) => (lastUsed[app.package] ?? 0) < limit)
        .length;
    out
      ..writeln('Apps with a last-used time: ${usage.apps.length}')
      ..writeln('Your apps not used for 90 days: $stale');
  }
  for (final (name, use) in [('Wi-Fi', usage.wifi), ('Mobile', usage.mobile)]) {
    out.writeln(
      use.ok
          ? '$name data: ${use.bytesByUid.length} apps, '
                '${_megabytes(use.bytesByUid.values.fold(0, (a, b) => a + b))} MB'
          : '$name data: REFUSED ${clean(use.error ?? '')}',
    );
  }
}

void _writeDeepMode(
  StringBuffer out,
  PhoneTestResults results,
  DeepModeReport deep,
  bool withNames,
  String Function(String) clean,
) {
  out
    ..writeln('\n== Deep mode (who used camera, microphone, location) ==')
    ..writeln(
      'Permission granted from a computer: ${_yesNo(deep.permissionGranted)}',
    );
  for (final attempt in deep.attempts) {
    out.writeln(
      attempt.ok
          ? 'Step ${attempt.step}: worked'
          : 'Step ${attempt.step}: REFUSED ${clean(attempt.error ?? '')}',
    );
  }
  out.writeln('History could be read: ${_yesNo(deep.works)}');
  if (deep.entries.isEmpty) return;
  final byOp = <String, int>{};
  for (final entry in deep.entries) {
    if (entry.lastAccess > 0) byOp[entry.op] = (byOp[entry.op] ?? 0) + 1;
  }
  out
    ..writeln(
      'Rows: ${deep.entries.length} for '
      '${deep.entries.map((e) => e.package).toSet().length} apps',
    )
    ..writeln('Apps with a last use, by kind: ${_counts(byOp)}');
  if (withNames) {
    final recent = [...deep.entries.where((e) => e.lastAccess > 0)]
      ..sort((a, b) => b.lastAccess.compareTo(a.lastAccess));
    for (final entry in recent.take(15)) {
      out.writeln(
        '  ${entry.package} ${entry.op} '
        '${DateTime.fromMillisecondsSinceEpoch(entry.lastAccess, isUtc: true).toIso8601String()}',
      );
    }
  }
}

void _writeScan(
  StringBuffer out,
  PhoneTestResults results,
  bool withNames,
  String Function(String) clean,
) {
  final scans = results.scans;
  final times = [for (final scan in scans) scan.elapsed.inMicroseconds]..sort();
  final byKit = <String, int>{};
  for (final scan in scans) {
    for (final kit in scan.found) {
      byKit[kit] = (byKit[kit] ?? 0) + 1;
    }
  }
  final failed = scans.where((s) => s.errors.isNotEmpty).toList();
  out
    ..writeln('\n== Tracker scan ==')
    ..writeln('Finished: ${_yesNo(results.scanFinished)}')
    ..writeln('Apps scanned: ${scans.length} of ${results.scanTargets}')
    ..writeln(
      'Time on the clock: ${_seconds(results.scanTime.inMicroseconds)} s',
    )
    ..writeln(
      'Code files: ${scans.fold(0, (a, s) => a + s.dexFiles)}, '
      'unpacked ${_megabytes(scans.fold(0, (a, s) => a + s.dexBytes))} MB, '
      'class names ${scans.fold(0, (a, s) => a + s.types)}',
    );
  if (times.isNotEmpty) {
    out.writeln(
      'Per app: median ${_milliseconds(times[times.length ~/ 2])} ms, '
      'slowest ${_milliseconds(times.last)} ms',
    );
  }
  out
    ..writeln(
      'Apps with at least one kit: '
      '${scans.where((s) => s.found.isNotEmpty).length}',
    )
    ..writeln(
      'Apps with no code file found: ${scans.where((s) => s.dexFiles == 0).length}',
    )
    ..writeln('Apps with a read error: ${failed.length}');
  for (final scan in failed.take(5)) {
    out.writeln('  ${clean(scan.errors.first)}');
  }
  if (byKit.isNotEmpty) {
    out.writeln('Kits found, by number of apps: ${_counts(byKit)}');
  }
  if (withNames && scans.isNotEmpty) {
    final slowest = [...scans]..sort((a, b) => b.elapsed.compareTo(a.elapsed));
    out.writeln('Slowest apps:');
    for (final scan in slowest.take(5)) {
      out.writeln(
        '  ${scan.package}: ${_milliseconds(scan.elapsed.inMicroseconds)} ms, '
        '${scan.dexFiles} code files, ${_megabytes(scan.dexBytes)} MB',
      );
    }
  }
}

void _writePerApp(
  StringBuffer out,
  PhoneTestResults results,
  List<InstalledApp> apps,
) {
  final scans = {for (final scan in results.scans) scan.package: scan};
  out.writeln('\n== Per app (your apps) ==');
  final sorted = [...results.userApps]
    ..sort((a, b) => a.package.compareTo(b.package));
  for (final app in sorted) {
    final holds = [
      for (final entry in watchedPermissions.entries)
        if (app.holds(entry.value)) entry.key,
    ];
    final scan = scans[app.package];
    out.writeln(
      '${app.package} | ${app.label} | target ${app.targetSdk} | '
      'from ${app.installer ?? '-'} | '
      'network ${_yesNo(app.internetGranted)} | '
      'holds: ${holds.isEmpty ? '-' : holds.join(', ')}'
      '${scan == null ? '' : ' | kits: ${scan.found.isEmpty ? '-' : scan.found.join(', ')}'}',
    );
  }
}

/// Android's answer about a special access, reduced to a few words. A
/// refusal carries its own long text, so those are counted together.
String _modeKey(String mode) =>
    const {
      'allowed',
      'ignored',
      'default',
      'errored',
      'foreground',
    }.contains(mode)
    ? mode
    : 'refused';

String _counts(Map<String, int> counts) {
  final entries = counts.entries.toList()
    ..sort((a, b) {
      final byCount = b.value.compareTo(a.value);
      return byCount != 0 ? byCount : a.key.compareTo(b.key);
    });
  return entries.map((e) => '${e.key} ${e.value}').join(', ');
}

String _yesNo(bool value) => value ? 'yes' : 'no';

String _megabytes(int bytes) => (bytes / (1024 * 1024)).toStringAsFixed(1);

String _seconds(int microseconds) => (microseconds / 1e6).toStringAsFixed(1);

String _milliseconds(int microseconds) =>
    (microseconds / 1000).toStringAsFixed(0);

/// A short version of [AppScan] totals for the screen.
({int withKits, int errors}) scanTotals(List<AppScan> scans) => (
  withKits: scans.where((s) => s.found.isNotEmpty).length,
  errors: scans.where((s) => s.errors.isNotEmpty).length,
);
