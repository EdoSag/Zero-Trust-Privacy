import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:zero_trust_core/zero_trust_core.dart';

import 'changes.dart';
import 'tracker_results.dart';

/// What earlier scans found, so an app is read again only after it is
/// updated or the tracker list changes, and what was noticed to change
/// from one look at the phone to the next.
class ScanMemory {
  ScanMemory({
    required this.listVersion,
    this.system = '',
    this.baselined = false,
    this.seenAt = 0,
    Map<String, AppTrackers>? apps,
    Map<String, List<String>>? asked,
    Set<String>? fresh,
    List<Change>? changes,
  }) : apps = apps ?? {},
       asked = asked ?? {},
       fresh = fresh ?? {},
       changes = changes ?? [];

  factory ScanMemory.fromJson(Map<String, Object?> json) => ScanMemory(
    listVersion: json['list'] as String? ?? '',
    system: json['system'] as String? ?? '',
    baselined: json['baselined'] == true,
    seenAt: (json['seenAt'] as num?)?.toInt() ?? 0,
    apps: {
      for (final entry in ((json['apps'] as Map?) ?? const {}).entries)
        entry.key as String: AppTrackers.fromJson(
          (entry.value as Map).cast<String, Object?>(),
        ),
    },
    asked: {
      for (final entry in ((json['asked'] as Map?) ?? const {}).entries)
        entry.key as String: [
          for (final name in entry.value as List)
            if (name is String) name,
        ],
    },
    fresh: {
      for (final package in (json['fresh'] as List?) ?? const [])
        if (package is String) package,
    },
    changes: [
      for (final change in (json['changes'] as List?) ?? const [])
        if (Change.fromJson((change as Map).cast<String, Object?>())
            case final change?)
          change,
    ],
  );

  /// The most changes kept; older ones fall off the end of the list.
  static const mostChanges = 200;

  /// [TrackerList.version] the results in [apps] were found with.
  String listVersion;

  /// The build of Android the system's own apps were read on. An update
  /// of the phone replaces them without changing their dates.
  String system;

  /// Scan results by package name.
  final Map<String, AppTrackers> apps;

  /// The phone was looked at once before: from then on an app that is not
  /// in [asked] is a newly installed one.
  bool baselined;

  /// For each of the user's apps, the sensitive permissions it asked for
  /// when the phone was last looked at.
  final Map<String, List<String>> asked;

  /// Newly installed apps whose code was not read yet.
  final Set<String> fresh;

  /// What changed, oldest first.
  final List<Change> changes;

  /// When the user last opened the list of changes.
  int seenAt;

  void addChange(Change change) {
    changes.add(change);
    if (changes.length > mostChanges) {
      changes.removeRange(0, changes.length - mostChanges);
    }
  }

  Map<String, Object?> toJson() => {
    'list': listVersion,
    'system': system,
    'baselined': baselined,
    'seenAt': seenAt,
    'apps': {for (final entry in apps.entries) entry.key: entry.value.toJson()},
    'asked': asked,
    'fresh': fresh.toList(),
    'changes': [for (final change in changes) change.toJson()],
  };
}

/// Where scan results are kept between two runs of the app.
///
/// They stay on this phone. Which apps are installed says a lot about a
/// person, so the results are never put in the account, where they would
/// sync to the server, even encrypted.
abstract class ScanCache {
  /// Null when there is nothing kept, or it cannot be read.
  Future<ScanMemory?> load();
  Future<void> save(ScanMemory memory);
}

/// Keeps nothing: every unlock reads the apps afresh. Stands in when the
/// phone gives the app no folder to keep the file in.
class NoScanCache implements ScanCache {
  const NoScanCache();

  @override
  Future<ScanMemory?> load() async => null;

  @override
  Future<void> save(ScanMemory memory) async {}
}

/// One file in the app's own folder, sealed with a key made from the
/// account's key for this app. Without the vault open it cannot be read.
class SealedFileScanCache implements ScanCache {
  /// Takes [key] as its own and wipes it in [close].
  SealedFileScanCache(this.file, Uint8List key) : _key = key;

  /// The key for the file, from the account's key for this app.
  static Future<Uint8List> keyFrom(List<int> appKey) =>
      Kdf.hkdf(appKey, _purpose);

  /// The file of one account, in [folder].
  static File fileIn(Directory folder, String userId) =>
      File('${folder.path}/$_prefix$userId$_suffix');

  /// Removes what other accounts left in [folder]. Without their keys the
  /// files are noise, and a list of apps should not outlive its account.
  static Future<void> removeOthers(Directory folder, File keep) async {
    try {
      await for (final entry in folder.list()) {
        final name = entry.uri.pathSegments.last;
        if (entry is File &&
            name.startsWith(_prefix) &&
            name != keep.uri.pathSegments.last) {
          await entry.delete();
        }
      }
    } on FileSystemException {
      // Left for the next time the app opens.
    }
  }

  static const _prefix = 'zt_privacy_tracker_scans_';
  static const _suffix = '.sealed';
  static const _purpose = 'zt/privacy/tracker-scans/v1';
  static final _aad = utf8.encode(_purpose);

  final File file;
  final Uint8List _key;
  bool _closed = false;

  @override
  Future<ScanMemory?> load() async {
    if (_closed) return null;
    final key = Uint8List.fromList(_key);
    try {
      if (!file.existsSync()) return null;
      final clear = await SealedBox.open(
        await file.readAsBytes(),
        key,
        aad: _aad,
      );
      return ScanMemory.fromJson(
        (jsonDecode(utf8.decode(clear)) as Map).cast<String, Object?>(),
      );
    } catch (_) {
      // A damaged file, or one in a shape this version does not know: it
      // is only a cache, so the apps are read again.
      return null;
    } finally {
      key.fillRange(0, key.length, 0);
    }
  }

  @override
  Future<void> save(ScanMemory memory) async {
    if (_closed) return;
    // A copy, so that locking half way through does not seal the file with
    // a key that was just wiped.
    final key = Uint8List.fromList(_key);
    try {
      final sealed = await SealedBox.seal(
        utf8.encode(jsonEncode(memory.toJson())),
        key,
        aad: _aad,
      );
      // Written beside the file and moved over it, so a save cut short by
      // the app closing leaves the old file whole.
      final next = File('${file.path}.new');
      await next.writeAsBytes(sealed, flush: true);
      await next.rename(file.path);
    } finally {
      key.fillRange(0, key.length, 0);
    }
  }

  /// Wipes the key from memory. Nothing is read or written after this.
  void close() {
    _closed = true;
    _key.fillRange(0, _key.length, 0);
  }
}
