import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:zero_trust_core/zero_trust_core.dart';

import '../phone/phone_providers.dart';
import '../phone/phone_snapshot.dart';
import '../probe/device_probe.dart';
import '../rules/rules.dart';
import '../scan/tracker_list.dart';
import '../scan/tracker_scan.dart';
import 'changes.dart';
import 'scan_cache.dart';
import 'tracker_results.dart';

/// Exodus Privacy's list, read once from the app's own files.
final trackerListProvider = FutureProvider<TrackerList>(
  (ref) => TrackerList.load(rootBundle),
);

/// Reads apps in the background. Tests put a made-up scanner here.
final trackerScannerProvider = Provider<TrackerScanner>(
  (ref) => IsolateTrackerScanner(
    () async => (await ref.read(trackerListProvider.future)).trackers,
  ),
);

/// Where results are kept on this phone: null while the app is locked.
/// A new one for every unlock and every account.
final scanCacheProvider = FutureProvider<ScanCache?>((ref) async {
  final unlocked = ref.watch(
    vaultControllerProvider.select((s) => s is VaultUnlocked ? s.appKey : null),
  );
  if (unlocked == null) return null;
  // Copied before any await: locking wipes the vault's own buffer.
  final appKey = Uint8List.fromList(unlocked);
  SealedFileScanCache? cache;
  var disposed = false;
  ref.onDispose(() {
    disposed = true;
    cache?.close();
  });
  final userId = ref.watch(accountServiceProvider).currentUserId;
  try {
    if (userId == null) return null;
    final key = await SealedFileScanCache.keyFrom(appKey);
    try {
      final folder = await getApplicationSupportDirectory();
      await folder.create(recursive: true);
      final file = SealedFileScanCache.fileIn(folder, userId);
      await SealedFileScanCache.removeOthers(folder, file);
      final opened = SealedFileScanCache(file, key);
      if (disposed) {
        opened.close();
        return null;
      }
      return cache = opened;
    } on Object {
      // No folder to keep results in: the apps are still read, and read
      // again after the next unlock.
      key.fillRange(0, key.length, 0);
      return disposed ? null : const NoScanCache();
    }
  } finally {
    appKey.fillRange(0, appKey.length, 0);
  }
});

/// Called for every app a scan finishes. A first scan takes minutes with
/// nobody touching the screen; while the app is in front its progress
/// counts as activity, so the app does not lock half way and start over.
final scanActivityProvider = Provider<void Function()>(
  (ref) => () {
    if (WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed) {
      ref.read(vaultControllerProvider.notifier).touch();
    }
  },
);

/// The time, for the date on a change. Tests set their own.
final scanClockProvider = Provider<DateTime Function()>((ref) => DateTime.now);

/// Where the scan of the phone's apps stands.
class TrackerScanState {
  const TrackerScanState({
    this.results,
    this.done = 0,
    this.total = 0,
    this.scanning = false,
    this.starting = false,
    this.changes = const [],
    this.seenAt = 0,
  });

  /// What is known so far. Null until the list and the kept results are
  /// read (and while the app is locked).
  final TrackerResults? results;

  /// The list and the kept results are being read: [results] follow in a
  /// moment. The score waits for them, so it does not start high and drop.
  final bool starting;

  /// Apps read in the scan that is running or just ended, and how many it
  /// set out to read.
  final int done;
  final int total;
  final bool scanning;

  /// What changed in the apps from one look at the phone to the next,
  /// newest first.
  final List<Change> changes;

  /// When the user last opened the list of changes.
  final int seenAt;

  /// Changes noticed since the user last opened the list.
  int get unseenChanges => changes.where((c) => c.at > seenAt).length;
}

/// Reads the apps that were not read yet, one at a time in the background,
/// whenever the phone is read: after a first install that is every app,
/// later only what was installed or updated since. What an install or an
/// update changed is noted on the way.
///
/// Results and changes are kept in [ScanCache] and never leave the phone.
class TrackerScans extends Notifier<TrackerScanState> {
  /// A new [TrackerResults] is given out after this many apps, so that the
  /// score is worked out a few dozen times in a long scan, not hundreds.
  static const publishEvery = 8;

  /// Results are written to the phone after this many apps, so a scan that
  /// is cut short does not start from nothing.
  static const saveEvery = 25;

  _ScanRun? _run;

  @override
  TrackerScanState build() {
    final lists = ref.watch(trackerListProvider);
    final caches = ref.watch(scanCacheProvider);
    final scanner = ref.watch(trackerScannerProvider);
    _run = null;
    // While one of them is being read again its old value is still there:
    // after a lock that is a cache that was just closed.
    if (lists.isLoading || caches.isLoading) {
      return const TrackerScanState(starting: true);
    }
    final list = lists.value;
    final cache = caches.value;
    // Locked, or the list could not be read: nothing to do.
    if (list == null || cache == null) return const TrackerScanState();

    // One run for each unlock: locking closes the cache and ends the run.
    final run = _run = _ScanRun(
      list: list,
      cache: cache,
      scanner: scanner,
      tell: (next) => state = next,
      activity: ref.read(scanActivityProvider),
      clock: ref.read(scanClockProvider),
    );
    ref.onDispose(run.stop);
    ref.listen(phoneProvider, (_, next) {
      final phone = next.value;
      if (phone != null) run.look(phone);
    });
    unawaited(run.open(ref.read(phoneProvider).value));
    return const TrackerScanState(starting: true);
  }

  /// The user has the list of changes in front of them: none is new now.
  void markChangesSeen() => _run?.markSeen();
}

class _ScanRun {
  _ScanRun({
    required this.list,
    required this.cache,
    required this.scanner,
    required this.tell,
    required this.activity,
    required this.clock,
  });

  final TrackerList list;
  final ScanCache cache;
  final TrackerScanner scanner;
  final void Function(TrackerScanState next) tell;
  final void Function() activity;
  final DateTime Function() clock;

  ScanMemory? _memory;
  PhoneSnapshot? _phone;
  StreamSubscription<AppScan>? _scan;
  Map<String, int> _waiting = const {};
  int _done = 0;
  int _total = 0;
  bool _lookAgain = false;
  bool _stopped = false;
  Future<void> _saved = Future.value();

  /// The results last given out. Kept until [_publish] is asked for new
  /// ones, so the score is not worked out again for every app.
  TrackerResults? _given;

  void stop() {
    _stopped = true;
    _scan?.cancel();
    _scan = null;
  }

  Future<void> open(PhoneSnapshot? phone) async {
    _phone ??= phone;
    ScanMemory? kept;
    try {
      kept = await cache.load();
    } on Object {
      // Nothing kept that can be read: the apps are read again.
    }
    if (_stopped) return;
    final memory = kept ?? ScanMemory(listVersion: list.version);
    if (memory.listVersion != list.version) {
      // Results found with another list say nothing about this one. What
      // changed so far, and what is known about the apps, stays.
      memory.apps.clear();
      memory.listVersion = list.version;
    }
    _memory = memory;
    _publish(results: true);
    final latest = _phone;
    if (latest != null) look(latest);
  }

  /// Tells the app where things stand. [results] gives out a new
  /// [TrackerResults], which makes the score work itself out again.
  void _publish({bool results = false}) {
    final memory = _memory;
    if (memory == null || _stopped) return;
    if (results || _given == null) {
      _given = TrackerResults(list: list, apps: Map.unmodifiable(memory.apps));
    }
    tell(
      TrackerScanState(
        results: _given,
        done: _done,
        total: _total,
        scanning: _scan != null,
        changes: List.unmodifiable(memory.changes.reversed),
        seenAt: memory.seenAt,
      ),
    );
  }

  void markSeen() {
    final memory = _memory;
    if (memory == null || _stopped) return;
    final newest = memory.changes.lastOrNull?.at ?? 0;
    if (newest <= memory.seenAt) return;
    memory.seenAt = newest;
    _save();
    _publish();
  }

  void _note(
    ChangeKind kind,
    InstalledApp app, {
    List<int> trackerIds = const [],
    List<String> permissions = const [],
  }) {
    final memory = _memory;
    if (memory == null) return;
    final now = clock().millisecondsSinceEpoch;
    memory.addChange(
      Change(
        // Never at or before the moment the list was last opened, even if
        // the phone's clock was set back: it would not show as new.
        at: now > memory.seenAt ? now : memory.seenAt + 1,
        kind: kind,
        package: app.package,
        label: app.label,
        trackerIds: trackerIds,
        permissions: permissions,
      ),
    );
  }

  /// Compares what the user's apps ask for with the last look. True when
  /// anything was written down.
  bool _lookAtPermissions(PhoneSnapshot phone, ScanMemory memory) {
    var changed = false;
    final wasBaselined = memory.baselined;
    final mine = <String>{};
    for (final app in phone.userApps) {
      mine.add(app.package);
      final asks = [
        for (final permission in permissionsToWatchFor)
          if (app.requests(permission)) permission,
      ];
      final before = memory.asked[app.package];
      if (before == null) {
        // Not there at the last look: installed since, unless this is the
        // first look of all. Its code is read before anything is said.
        if (wasBaselined) memory.fresh.add(app.package);
      } else {
        final added = [
          for (final permission in asks)
            if (!before.contains(permission)) permission,
        ];
        if (added.isNotEmpty) {
          _note(ChangeKind.permissionsAdded, app, permissions: added);
        }
        if (added.isEmpty && before.length == asks.length) continue;
      }
      memory.asked[app.package] = asks;
      changed = true;
    }
    // A removed app is forgotten: installed again, it is a new app.
    final before = memory.asked.length + memory.fresh.length;
    memory.asked.removeWhere((package, _) => !mine.contains(package));
    memory.fresh.removeWhere((package) => !mine.contains(package));
    if (!wasBaselined) {
      memory.baselined = true;
      changed = true;
    }
    return changed || memory.asked.length + memory.fresh.length != before;
  }

  /// Starts a scan of the apps of [phone] that were not read yet.
  void look(PhoneSnapshot phone) {
    _phone = phone;
    final memory = _memory;
    if (memory == null || _stopped) return;
    if (_scan != null) {
      // One scan at a time: this phone is looked at when it ends.
      _lookAgain = true;
      return;
    }

    final installed = phone.byPackage;
    var changed = _lookAtPermissions(phone, memory);
    final system = phone.fact('build.display') ?? '';
    if (memory.system != system) {
      // The phone was updated: its own apps were replaced under the same
      // dates, so they are read again.
      memory.apps.removeWhere(
        (package, _) => installed[package]?.system ?? false,
      );
      memory.system = system;
      changed = true;
    }
    // An app that was removed is forgotten.
    final before = memory.apps.length;
    memory.apps.removeWhere((package, _) => !installed.containsKey(package));
    changed = changed || memory.apps.length != before;

    bool isWaiting(InstalledApp app) =>
        memory.apps[app.package]?.lastUpdate != app.lastUpdate;
    final waiting = [
      // The user's own apps first: they are what the score is about.
      for (final app in phone.userApps)
        if (isWaiting(app)) app,
      for (final app in phone.apps)
        if (app.system && isWaiting(app)) app,
    ];
    final targets = <ScanTarget>[];
    final queued = <String, int>{};
    for (final app in waiting) {
      if (app.apkPaths.isEmpty) {
        // Android did not say where the app's files are.
        memory.apps[app.package] = AppTrackers(
          lastUpdate: app.lastUpdate,
          trackerIds: const [],
          unreadable: true,
        );
        memory.fresh.remove(app.package);
        changed = true;
      } else {
        targets.add(ScanTarget(app.package, app.apkPaths));
        queued[app.package] = app.lastUpdate;
      }
    }

    if (targets.isEmpty) {
      if (changed) {
        _save();
        _publish(results: true);
      }
      return;
    }

    _waiting = queued;
    _done = 0;
    _total = targets.length;
    _scan = scanner
        .scan(targets)
        .listen(
          _took,
          // One app that breaks the reader does not end the scan; what was
          // left unread is marked in [_ended].
          onError: (Object _) {},
          onDone: _ended,
        );
    if (changed) _save();
    _publish(results: changed);
  }

  void _took(AppScan scan) {
    final memory = _memory;
    final lastUpdate = _waiting.remove(scan.package);
    if (memory == null || lastUpdate == null || _stopped) return;
    final before = memory.apps[scan.package];
    final found = AppTrackers(
      lastUpdate: lastUpdate,
      trackerIds: [
        for (final name in scan.found)
          if (list.byName[name] case final tracker?) tracker.id,
      ]..sort(),
      unreadable: scan.dexFiles == 0 && scan.errors.isNotEmpty,
      // A file or a part of the code that failed while others were read:
      // kept, so the app is never shown as free of tracker code.
      incomplete: scan.dexFiles > 0 && scan.errors.isNotEmpty,
    );
    memory.apps[scan.package] = found;
    final noted = _noteWhatChanged(memory, before, found, scan.package);
    _done++;
    if (noted || _done % TrackerScans.saveEvery == 0) _save();
    _publish(results: _done % TrackerScans.publishEvery == 0);
    activity();
  }

  /// Writes down what the reading of one of the user's apps shows to have
  /// changed. True when something was written down.
  bool _noteWhatChanged(
    ScanMemory memory,
    AppTrackers? before,
    AppTrackers found,
    String package,
  ) {
    final app = _phone?.byPackage[package];
    final isNew = memory.fresh.remove(package);
    if (app == null || app.system || found.unreadable) return false;
    if (isNew) {
      if (found.trackerIds.isEmpty) return false;
      _note(ChangeKind.newAppTrackers, app, trackerIds: found.trackerIds);
      return true;
    }
    // An update: compared with the version before, when both were read
    // whole. A part that could not be read would look like code that left.
    if (before == null ||
        before.unreadable ||
        before.incomplete ||
        found.incomplete) {
      return false;
    }
    final added = [
      for (final id in found.trackerIds)
        if (!before.trackerIds.contains(id)) id,
    ];
    final removed = [
      for (final id in before.trackerIds)
        if (!found.trackerIds.contains(id)) id,
    ];
    if (added.isNotEmpty) {
      _note(ChangeKind.trackersAdded, app, trackerIds: added);
    }
    if (removed.isNotEmpty) {
      _note(ChangeKind.trackersRemoved, app, trackerIds: removed);
    }
    return added.isNotEmpty || removed.isNotEmpty;
  }

  void _ended() {
    _scan = null;
    final memory = _memory;
    if (memory == null || _stopped) return;
    // The reader stopped before these: marked, so that an app that breaks
    // it is not tried again and again. Its next update is a new try.
    for (final entry in _waiting.entries) {
      memory.apps[entry.key] = AppTrackers(
        lastUpdate: entry.value,
        trackerIds: const [],
        unreadable: true,
      );
      memory.fresh.remove(entry.key);
    }
    _waiting = const {};
    _save();
    _publish(results: true);
    if (_lookAgain) {
      _lookAgain = false;
      final phone = _phone;
      if (phone != null) look(phone);
    }
  }

  /// Writes what is known. One write at a time, and a write that fails
  /// costs only a second reading of the apps.
  void _save() {
    final memory = _memory;
    if (memory == null) return;
    final copy = ScanMemory.fromJson(memory.toJson());
    _saved = _saved.then((_) => cache.save(copy)).catchError((Object _) {});
  }
}

final trackerScansProvider = NotifierProvider<TrackerScans, TrackerScanState>(
  TrackerScans.new,
);

/// What is known about tracker code, for the score and the lists. Changes
/// a few times in a scan, not with every app.
final trackerResultsProvider = Provider<TrackerResults?>(
  (ref) => ref.watch(trackerScansProvider.select((state) => state.results)),
);
