import '../probe/device_probe.dart';
import '../scan/tracker_scan.dart';

/// A special access that is not an ordinary permission: Android tracks it
/// as an "app op" with its own on/off state.
class SpecialAccess {
  const SpecialAccess(this.title, this.permission, this.op);

  final String title;
  final String permission;
  final String op;

  static const all = [
    SpecialAccess(
      'Display over other apps',
      'android.permission.SYSTEM_ALERT_WINDOW',
      'android:system_alert_window',
    ),
    SpecialAccess(
      'All files',
      'android.permission.MANAGE_EXTERNAL_STORAGE',
      'android:manage_external_storage',
    ),
    SpecialAccess(
      'Install other apps',
      'android.permission.REQUEST_INSTALL_PACKAGES',
      'android:request_install_packages',
    ),
    SpecialAccess(
      'Usage access',
      'android.permission.PACKAGE_USAGE_STATS',
      'android:get_usage_stats',
    ),
    SpecialAccess(
      'Change system settings',
      'android.permission.WRITE_SETTINGS',
      'android:write_settings',
    ),
  ];
}

/// For one app that asked for a [SpecialAccess]: what the app list's
/// granted flag says, and what Android answers when asked directly.
class AccessAnswer {
  const AccessAnswer({
    required this.package,
    required this.grantedFlag,
    required this.mode,
  });

  final String package;
  final bool grantedFlag;
  final String mode;
}

/// Everything one run of the phone test found. Filled in step by step; a
/// null field is a step not run yet.
class PhoneTestResults {
  PhoneTestResults({required this.build});

  /// The build number of the app, so results can be matched to code.
  final String build;
  DateTime? takenAt;

  List<InstalledApp>? apps;
  List<ProbeValue>? device;
  Map<String, AccessList>? specialAccess;

  /// By [SpecialAccess.title].
  Map<String, List<AccessAnswer>>? accessAnswers;
  UsageReport? usage;
  DeepModeReport? deepMode;

  /// System screens the test tried to open, and whether Android let it.
  final Map<String, ActionResult> screens = {};

  /// Steps that failed as a whole, with the reason.
  final Map<String, String> errors = {};

  final List<AppScan> scans = [];
  int scanTargets = 0;
  Duration scanTime = Duration.zero;
  bool scanFinished = false;

  List<InstalledApp> get userApps => [
    for (final app in apps ?? const <InstalledApp>[])
      if (!app.system) app,
  ];
}
