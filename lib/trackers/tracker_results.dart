import '../probe/device_probe.dart';
import '../scan/tracker_list.dart';

/// What a scan found in one version of one app.
class AppTrackers {
  const AppTrackers({
    required this.lastUpdate,
    required this.trackerIds,
    this.unreadable = false,
  });

  factory AppTrackers.fromJson(Map<String, Object?> json) => AppTrackers(
    lastUpdate: (json['u'] as num?)?.toInt() ?? 0,
    trackerIds: [
      for (final id in (json['t'] as List?) ?? const []) (id as num).toInt(),
    ],
    unreadable: json['x'] == true,
  );

  /// [InstalledApp.lastUpdate] of the version that was scanned. An update
  /// changes it, and the app is scanned again.
  final int lastUpdate;

  /// Exodus Privacy's numbers of the kits found.
  final List<int> trackerIds;

  /// None of the app's code could be read, so nothing is known about it.
  final bool unreadable;

  Map<String, Object?> toJson() => {
    'u': lastUpdate,
    't': trackerIds,
    if (unreadable) 'x': true,
  };
}

/// What is known so far about tracker code in the apps on this phone.
class TrackerResults {
  const TrackerResults({required this.list, required this.apps});

  final TrackerList list;

  /// By package name.
  final Map<String, AppTrackers> apps;

  /// The scan of this very version of [app], or null when it has not been
  /// scanned yet.
  AppTrackers? scanOf(InstalledApp app) {
    final scan = apps[app.package];
    return scan != null && scan.lastUpdate == app.lastUpdate ? scan : null;
  }

  /// The kits whose code is in [app], by name. Null when the app has not
  /// been scanned yet or could not be read: "not known", never "none".
  List<Tracker>? of(InstalledApp app) {
    final scan = scanOf(app);
    if (scan == null || scan.unreadable) return null;
    return [
      for (final id in scan.trackerIds)
        if (list.byId[id] case final tracker?) tracker,
    ]..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
  }
}
