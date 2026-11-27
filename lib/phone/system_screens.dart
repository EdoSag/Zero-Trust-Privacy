import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zero_trust_core/zero_trust_core.dart';

import '../probe/device_probe.dart';
import '../rules/checklist.dart';
import 'phone_providers.dart';

/// Keeps something going while [wait] runs. The app passes the vault's
/// "a system screen is showing" here, so that a trip to Settings and back
/// does not lock the app.
typedef Hold = Future<void> Function(Future<void> Function() wait);

/// Sends the user to one of Android's own screens and takes them back
/// without the app locking in between. Almost everything this app points
/// out is fixed in Settings, so that trip is its main road.
class SystemScreens {
  SystemScreens(this.probe, {Hold? hold, bool watchLifecycle = true})
    : _hold = hold {
    if (hold != null && watchLifecycle) {
      _lifecycle = AppLifecycleListener(onHide: _left, onShow: _returned);
    }
  }

  final DeviceProbe probe;
  final Hold? _hold;
  AppLifecycleListener? _lifecycle;
  Completer<void>? _away;
  Timer? _neverLeft;

  /// How long Android gets to put its screen in front. If the app is still
  /// in front after this, nothing opened and the hold is let go.
  static const leaveWithin = Duration(seconds: 5);

  /// Opens [screen] (a name from [Screens]), on [package]'s own switch when
  /// the screen has one. When Android refuses, the nearest screen that
  /// always exists opens instead: the app's page in Settings, or Settings.
  Future<ActionResult> open(String screen, {String? package}) async {
    _expectToLeave();
    var result = await _try(screen, package);
    if (!result.ok && screen != Screens.appDetails && package != null) {
      // Some screens refuse an app of their own: try the plain screen.
      result = await _try(screen, null);
    }
    if (!result.ok) {
      final fallback = package != null
          ? await _try(Screens.appDetails, package)
          : await _try(Screens.settings, null);
      // The first refusal is the one worth showing.
      if (fallback.ok) result = fallback;
    }
    if (!result.ok) _returned();
    return result;
  }

  /// Hands [text] to another app through Android's share sheet.
  Future<ActionResult> share(String subject, String text) async {
    _expectToLeave();
    ActionResult result;
    try {
      result = await probe.shareText(subject, text);
    } catch (e) {
      result = ActionResult(ok: false, error: e.toString());
    }
    if (!result.ok) _returned();
    return result;
  }

  Future<ActionResult> _try(String screen, String? package) async {
    try {
      return await probe.openSettings(screen, package: package);
    } catch (e) {
      return ActionResult(ok: false, error: e.toString());
    }
  }

  void _expectToLeave() {
    final hold = _hold;
    if (hold == null || _away != null) return;
    final away = _away = Completer<void>();
    unawaited(hold(() => away.future));
    _neverLeft = Timer(leaveWithin, _returned);
  }

  void _left() => _neverLeft?.cancel();

  void _returned() {
    _neverLeft?.cancel();
    _neverLeft = null;
    _away?.complete();
    _away = null;
  }

  void dispose() {
    _lifecycle?.dispose();
    _returned();
  }
}

final systemScreensProvider = Provider<SystemScreens>((ref) {
  final screens = SystemScreens(
    ref.watch(deviceProbeProvider),
    hold: (wait) =>
        ref.read(vaultControllerProvider.notifier).whileShowingSystemUi(wait),
  );
  ref.onDispose(screens.dispose);
  return screens;
});

/// The phone test's view of the phone: the same readings, with its trips to
/// system screens and to the share sheet made through [SystemScreens].
class AwayAwareProbe implements DeviceProbe {
  const AwayAwareProbe(this._screens);
  final SystemScreens _screens;

  DeviceProbe get _probe => _screens.probe;

  @override
  Future<List<InstalledApp>> apps() => _probe.apps();
  @override
  Future<List<ProbeValue>> device() => _probe.device();
  @override
  Future<Map<String, AccessList>> specialAccess() => _probe.specialAccess();
  @override
  Future<List<String>> specialAccessModes(List<AccessQuery> queries) =>
      _probe.specialAccessModes(queries);
  @override
  Future<UsageReport> usage() => _probe.usage();
  @override
  Future<DeepModeReport> deepMode() => _probe.deepMode();
  @override
  Future<String> saveToDownloads(String name, String text) =>
      _probe.saveToDownloads(name, text);

  /// No stand-in screen here: whether Android opens exactly this one is
  /// what the phone test records.
  @override
  Future<ActionResult> openSettings(String screen, {String? package}) async {
    _screens._expectToLeave();
    final result = await _screens._try(screen, package);
    if (!result.ok) _screens._returned();
    return result;
  }

  @override
  Future<ActionResult> shareText(String subject, String text) =>
      _screens.share(subject, text);
}
