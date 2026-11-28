/// What a change is about.
enum ChangeKind {
  /// An app was installed that contains tracker code.
  newAppTrackers,

  /// An update of an app brought code from trackers it did not have.
  trackersAdded,

  /// An update of an app no longer has code from some trackers.
  trackersRemoved,

  /// An update of an app asks for sensitive permissions it did not ask for.
  permissionsAdded,
}

/// One thing that changed in an app since the phone was last looked at.
/// Kept on this phone only, with the scan results.
class Change {
  const Change({
    required this.at,
    required this.kind,
    required this.package,
    required this.label,
    this.trackerIds = const [],
    this.permissions = const [],
  });

  /// Null for an entry this version cannot read (a kind added later).
  static Change? fromJson(Map<String, Object?> json) {
    final kind = ChangeKind.values
        .where((kind) => kind.name == json['k'])
        .firstOrNull;
    final package = json['p'];
    if (kind == null || package is! String) return null;
    return Change(
      at: (json['at'] as num?)?.toInt() ?? 0,
      kind: kind,
      package: package,
      label: json['l'] as String? ?? '',
      trackerIds: [
        for (final id in (json['t'] as List?) ?? const []) (id as num).toInt(),
      ],
      permissions: [
        for (final name in (json['r'] as List?) ?? const [])
          if (name is String) name,
      ],
    );
  }

  /// When it was noticed, in milliseconds since 1970.
  final int at;
  final ChangeKind kind;
  final String package;

  /// The app's name as the phone showed it then; the app may be gone now.
  final String label;

  /// Exodus Privacy's numbers of the trackers that arrived or left.
  final List<int> trackerIds;

  /// Android's names of the permissions an update started asking for.
  final List<String> permissions;

  Map<String, Object?> toJson() => {
    'at': at,
    'k': kind.name,
    'p': package,
    'l': label,
    if (trackerIds.isNotEmpty) 't': trackerIds,
    if (permissions.isNotEmpty) 'r': permissions,
  };
}
