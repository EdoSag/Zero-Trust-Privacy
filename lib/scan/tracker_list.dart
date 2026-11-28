import 'dart:convert';

import 'package:flutter/services.dart';

/// What a tracking kit is for, in Exodus Privacy's words.
enum TrackerKind {
  ads,
  analytics,
  location,
  profiling,
  identification,
  crashReporting,
}

/// A kit that app makers build into their apps and that reports to its own
/// company: advertising, statistics, location, crash reports. It is known
/// by the Java packages its code lives in.
class Tracker {
  const Tracker({
    required this.id,
    required this.name,
    required this.code,
    this.kinds = const {},
    this.website = '',
  });

  factory Tracker.fromJson(Map<String, Object?> json) => Tracker(
    id: (json['id']! as num).toInt(),
    name: json['name']! as String,
    code: (json['code']! as List).cast<String>(),
    kinds: {
      for (final kind in (json['kinds'] as List?) ?? const [])
        TrackerKind.values.byName(kind as String),
    },
    website: json['website'] as String? ?? '',
  );

  /// Exodus Privacy's number for it. Stays the same when a name changes.
  final int id;
  final String name;

  /// Empty when the list does not say what the kit is for.
  final Set<TrackerKind> kinds;
  final String website;

  /// Names its code goes by: mostly the start of a Java package
  /// (`com.example.tracker.`), now and then the end of a class name
  /// (`.TrackerManager`).
  final List<String> code;

  /// Reports crashes and nothing else: worth knowing, not worth a warning.
  bool get onlyCrashReporting =>
      kinds.length == 1 && kinds.contains(TrackerKind.crashReporting);
}

/// How one name from [Tracker.code] is looked for among the class names in
/// an app's code, which are written `Lcom/example/tracker/Client;`.
class CodeSignature {
  CodeSignature(String name)
    : anywhere = name.startsWith('.'),
      bytes = Uint8List.fromList(
        (name.startsWith('.')
                ? name.replaceAll('.', '/')
                : 'L${name.replaceAll('.', '/')}')
            .codeUnits,
      );

  /// A name that starts with a dot is the end of a class name and may sit
  /// under any package. Every other name must be the start of the class
  /// name, so `com.ads.` does not match `xcom.ads.` or a package that only
  /// has it in the middle.
  ///
  /// Exodus's own tools look for every name anywhere. Being stricter here
  /// misses a kit whose package was renamed, which a scan of names cannot
  /// follow in any case, and avoids false alarms.
  final bool anywhere;

  /// The name as bytes, ready to compare with a class name in an app.
  final Uint8List bytes;
}

/// The tracker list the app carries. It is Exodus Privacy's database, under
/// the Open Database License, cut down to what the scan and the screens
/// use. See assets/trackers/NOTICE.md and tool/build_tracker_list.dart.
class TrackerList {
  TrackerList({
    required this.trackers,
    required this.newestEntry,
    required this.attribution,
  }) : assert(
         trackers.map((t) => t.name).toSet().length == trackers.length,
         'tracker names must differ: scan results go by name',
       );

  factory TrackerList.fromJson(String text) {
    final json = jsonDecode(text) as Map<String, Object?>;
    return TrackerList(
      trackers: [
        for (final tracker in json['trackers']! as List)
          Tracker.fromJson((tracker as Map).cast<String, Object?>()),
      ],
      newestEntry: json['newestEntry'] as String? ?? '',
      attribution: json['attribution'] as String? ?? '',
    );
  }

  static const asset = 'assets/trackers/exodus_trackers.json';

  static Future<TrackerList> load(AssetBundle bundle) async =>
      TrackerList.fromJson(await bundle.loadString(asset));

  final List<Tracker> trackers;

  /// The date of the newest tracker in the list, `2023-12-05`.
  final String newestEntry;

  /// The credit the database's licence asks for.
  final String attribution;

  /// Changes whenever what a scan looks for does, so results found with
  /// an older list are looked for again. It carries a fingerprint of every
  /// tracker's number, name and code names: a list that only corrects one
  /// signature has the same date and the same count.
  late final String version =
      '$newestEntry/${trackers.length}/${_fingerprint()}';

  /// FNV-1a over the definitions, as eight hex digits.
  String _fingerprint() {
    var hash = 0x811c9dc5;
    void add(String text) {
      for (final unit in text.codeUnits) {
        hash = ((hash ^ unit) * 0x01000193) & 0xffffffff;
      }
      // A mark between two texts, so "ab" + "c" differs from "a" + "bc".
      hash = ((hash ^ 0xff) * 0x01000193) & 0xffffffff;
    }

    for (final tracker in trackers) {
      add('${tracker.id}');
      add(tracker.name);
      tracker.code.forEach(add);
    }
    return hash.toRadixString(16).padLeft(8, '0');
  }

  late final Map<int, Tracker> byId = {for (final t in trackers) t.id: t};
  late final Map<String, Tracker> byName = {
    for (final t in trackers) t.name: t,
  };
}
