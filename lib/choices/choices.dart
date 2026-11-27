import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zero_trust_core/zero_trust_core.dart';

import '../rules/checklist.dart';
import '../rules/finding.dart';

/// What the user decided on this phone: the findings they are fine with,
/// and the checks they looked at themselves.
///
/// One item per phone, sealed with the account's key before it is stored or
/// synced (`app = 'privacy'`, `kind` device). The item's id is the only part
/// the server can read, so it never carries an app's name: the names are
/// inside the sealed part.
class Choices {
  const Choices({
    required this.id,
    this.accepted = const {},
    this.checked = const {},
  });

  factory Choices.fromJson(
    String id,
    Map<String, Object?> json,
    DateTime updatedAt,
  ) => Choices(
    id: id,
    accepted: _strings(json['accepted']),
    checked: _strings(json['checked']),
  );

  /// `device-` and the id the shared core gave this installation.
  final String id;

  /// [Finding.id]s.
  final Set<String> accepted;

  /// Names of [CheckId]s ticked off by hand.
  final Set<String> checked;

  Map<String, Object?> toJson() => {
    'accepted': accepted.toList()..sort(),
    'checked': checked.toList()..sort(),
  };

  Choices copyWith({Set<String>? accepted, Set<String>? checked}) => Choices(
    id: id,
    accepted: accepted ?? this.accepted,
    checked: checked ?? this.checked,
  );

  static Set<String> _strings(Object? value) => {
    if (value is List)
      for (final item in value)
        if (item is String) item,
  };
}

final choicesCollection = ZtCollection<Choices>(
  kind: 'device',
  fromJson: Choices.fromJson,
  toJson: (choices) => choices.toJson(),
  idOf: (choices) => choices.id,
);

/// Where the choices are kept. The real one is the account's encrypted
/// store; tests keep them in memory.
abstract class ChoicesRepository {
  /// The choices of this phone, now and after every change.
  Stream<Choices> watch();

  Future<void> save(Choices choices);
}

class VaultChoicesRepository implements ChoicesRepository {
  VaultChoicesRepository(this._ref);
  final Ref _ref;

  Future<String> get _id async =>
      'device-${await _ref.read(ztDeviceIdProvider.future)}';

  @override
  Stream<Choices> watch() async* {
    final id = await _id;
    final store = await _ref.read(ztLocalStoreProvider.future);
    if (store is ZtLocalStore) {
      yield* choicesCollection
          .watch(store)
          .map(
            (all) => all.firstWhere(
              (choices) => choices.id == id,
              orElse: () => Choices(id: id),
            ),
          );
    } else {
      yield await choicesCollection.get(store, id) ?? Choices(id: id);
    }
  }

  @override
  Future<void> save(Choices choices) async => choicesCollection.save(
    _ref.read(ztSyncControllerProvider.notifier),
    await _ref.read(ztLocalStoreProvider.future),
    choices,
  );
}

final choicesRepositoryProvider = Provider<ChoicesRepository>((ref) {
  // The account's store is closed when the app locks and opened again when
  // it unlocks, and another account has another store: start over each time.
  ref.watch(ztLocalStoreProvider);
  return VaultChoicesRepository(ref);
});

/// This phone's choices. Empty until the first read.
final choicesProvider = StreamProvider<Choices>(
  (ref) => ref.watch(choicesRepositoryProvider).watch(),
);

final choicesControllerProvider = Provider<ChoicesController>((ref) {
  // What was last written belongs to one store; never carry it to another.
  ref.watch(choicesRepositoryProvider);
  return ChoicesController(ref);
});

/// Changes the choices. Each change is written whole, on top of the one
/// before it: two quick taps are two changes, never one lost.
class ChoicesController {
  ChoicesController(this._ref);
  final Ref _ref;

  /// What this controller last wrote. The store reports a write a moment
  /// later, so the next change builds on this, not on what the store said
  /// last.
  Choices? _written;
  Future<void> _last = Future.value();

  Future<void> _change(Choices Function(Choices now) change) {
    final done = _last.then((_) async {
      final Choices now = _written ?? (await _ref.read(choicesProvider.future));
      final next = change(now);
      await _ref.read(choicesRepositoryProvider).save(next);
      _written = next;
    });
    // The next change waits for this one whether or not it worked.
    _last = done.then((_) {}, onError: (_) {});
    return done;
  }

  /// "I'm fine with this" and back.
  Future<void> setAccepted(Finding finding, bool accepted) => _change((now) {
    final next = {...now.accepted};
    accepted ? next.add(finding.id) : next.remove(finding.id);
    return now.copyWith(accepted: next);
  });

  /// Ticks a check the phone cannot read.
  Future<void> setChecked(CheckId id, bool checked) => _change((now) {
    final next = {...now.checked};
    checked ? next.add(id.name) : next.remove(id.name);
    return now.copyWith(checked: next);
  });
}
