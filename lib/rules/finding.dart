/// Every kind of thing the app points out. The order here is the order of
/// the score page: the phone first, then apps, each from heavy to light.
///
/// [points] is what one finding costs; [cap] is the most all findings of
/// that kind can cost together, so that twenty unused apps do not drown a
/// missing screen lock. A phone with nothing to point out scores 100.
enum Rule {
  noScreenLock(25, 25),
  oldSecurityPatch(10, 10),
  usbDebugging(6, 6),
  wirelessDebugging(6, 6),
  developerOptions(2, 2),
  lockScreenContent(4, 4),
  wifiScanning(1, 1),
  bluetoothScanning(1, 1),

  accessibility(6, 12, aboutApp: true),
  deviceAdmin(5, 10, aboutApp: true),
  notificationAccess(5, 10, aboutApp: true),
  backgroundLocation(4, 12, aboutApp: true),
  sms(4, 8, aboutApp: true),
  callLog(4, 8, aboutApp: true),
  allFiles(3, 9, aboutApp: true),
  overlay(2, 6, aboutApp: true),
  installsApps(2, 6, aboutApp: true),
  usageAccess(2, 6, aboutApp: true),
  trackerCode(2, 8, aboutApp: true),
  oldTarget(2, 6, aboutApp: true),
  notUpdated(1, 5, aboutApp: true),
  unused(1, 8, aboutApp: true);

  const Rule(this.points, this.cap, {this.aboutApp = false});

  final int points;
  final int cap;

  /// About one app, as opposed to a setting of the phone.
  final bool aboutApp;
}

/// One thing pointed out: a [rule], and for app rules the app it is about.
class Finding {
  const Finding(this.rule, {this.package, this.label, this.detail});

  final Rule rule;

  /// The app, for an app rule.
  final String? package;

  /// The app's name as the phone shows it.
  final String? label;

  /// A value to show with it: the date of the security update, the Android
  /// version an app was built for, the number of days since an update, the
  /// number of trackers whose code is in an app.
  final String? detail;

  /// Stable between two reads of the phone, so "I'm fine with this" sticks.
  String get id => package == null ? rule.name : '${rule.name}:$package';

  @override
  bool operator ==(Object other) => other is Finding && other.id == id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'Finding($id)';
}
