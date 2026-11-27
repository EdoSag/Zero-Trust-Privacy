import '../phone/phone_snapshot.dart';
import '../probe/device_probe.dart';
import 'finding.dart';

const _backgroundLocation = 'android.permission.ACCESS_BACKGROUND_LOCATION';
const _readSms = 'android.permission.READ_SMS';
const _receiveSms = 'android.permission.RECEIVE_SMS';
const _callLog = 'android.permission.READ_CALL_LOG';
const allFilesPermission = 'android.permission.MANAGE_EXTERNAL_STORAGE';
const overlayPermission = 'android.permission.SYSTEM_ALERT_WINDOW';
const installAppsPermission = 'android.permission.REQUEST_INSTALL_PACKAGES';
const usageAccessPermission = 'android.permission.PACKAGE_USAGE_STATS';

/// Permissions that let an app learn something about its user. An app that
/// holds one of these and is no longer used is worth a look.
const sensitivePermissions = [
  'android.permission.ACCESS_FINE_LOCATION',
  'android.permission.ACCESS_COARSE_LOCATION',
  _backgroundLocation,
  'android.permission.CAMERA',
  'android.permission.RECORD_AUDIO',
  'android.permission.READ_CONTACTS',
  'android.permission.READ_CALENDAR',
  _readSms,
  _receiveSms,
  _callLog,
  'android.permission.READ_PHONE_STATE',
  'android.permission.READ_MEDIA_IMAGES',
  'android.permission.READ_MEDIA_VIDEO',
  'android.permission.READ_EXTERNAL_STORAGE',
  'android.permission.BODY_SENSORS',
  'android.permission.ACTIVITY_RECOGNITION',
];

const securityPatchMaxAge = Duration(days: 90);
const unusedAfter = Duration(days: 90);
const notUpdatedAfter = Duration(days: 730);

/// Apps built for Android 10 or older skip protections added since
/// (scoped storage, one-time permissions, auto-reset).
const oldestCurrentTarget = 30;

const _ownPackage = DeepModeReport.ownPackage;

/// Everything worth pointing out on this phone, in the order of [Rule].
List<Finding> findFindings(PhoneSnapshot phone) =>
    [..._phoneFindings(phone), ..._appFindings(phone)]..sort(_byRuleThenName);

int _byRuleThenName(Finding a, Finding b) {
  final rule = a.rule.index.compareTo(b.rule.index);
  if (rule != 0) return rule;
  return (a.label ?? '').toLowerCase().compareTo((b.label ?? '').toLowerCase());
}

/// The date of the phone's last security update, when Android gives one.
DateTime? securityPatchDate(PhoneSnapshot phone) {
  final text = phone.fact('build.securityPatch');
  return text == null ? null : DateTime.tryParse(text);
}

/// More than 90 whole days since the last security update.
bool securityPatchIsOld(PhoneSnapshot phone) {
  final patch = securityPatchDate(phone);
  return patch != null &&
      phone.takenAt.difference(patch).inDays > securityPatchMaxAge.inDays;
}

List<Finding> _phoneFindings(PhoneSnapshot phone) {
  final usb = phone.flag('global.adb_enabled') ?? false;
  final wireless = phone.flag('global.adb_wifi_enabled') ?? false;
  return [
    if (phone.flag('lock.deviceSecure') == false)
      const Finding(Rule.noScreenLock),
    if (securityPatchIsOld(phone))
      Finding(Rule.oldSecurityPatch, detail: phone.fact('build.securityPatch')),
    if (usb) const Finding(Rule.usbDebugging),
    if (wireless) const Finding(Rule.wirelessDebugging),
    // Said once: with debugging on, developer options are on by definition.
    if (!usb &&
        !wireless &&
        (phone.flag('global.development_settings_enabled') ?? false))
      const Finding(Rule.developerOptions),
    if ((phone.flag('secure.lock_screen_allow_private_notifications') ??
            false) &&
        phone.flag('secure.lock_screen_show_notifications') != false)
      const Finding(Rule.lockScreenContent),
    if (phone.flag('global.wifi_scan_always_enabled') ?? false)
      const Finding(Rule.wifiScanning),
    if (phone.flag('global.ble_scan_always_enabled') ?? false)
      const Finding(Rule.bluetoothScanning),
  ];
}

List<Finding> _appFindings(PhoneSnapshot phone) {
  final accessibility = phone.listed('accessibilityServices');
  final admins = phone.listed('deviceAdmins');
  final listeners = phone.listed('notificationListeners');
  final smsApps = phone.listed('defaultSms');
  final dialers = phone.listed('defaultDialer');
  // Apps that work without ever being opened: no "unused" for these.
  final alwaysOn = {
    ...accessibility,
    ...admins,
    ...listeners,
    ...phone.listed('keyboards'),
    ...smsApps,
    ...dialers,
    ...phone.listed('defaultBrowser'),
    ...phone.listed('defaultHome'),
  };
  final now = phone.takenAt.millisecondsSinceEpoch;
  final out = <Finding>[];

  for (final app in phone.userApps) {
    if (!app.enabled || app.package == _ownPackage) continue;
    Finding finding(Rule rule, {String? detail}) =>
        Finding(rule, package: app.package, label: app.label, detail: detail);
    bool special(String permission) =>
        phone.holdsSpecial(permission, app.package);

    if (accessibility.contains(app.package)) {
      out.add(finding(Rule.accessibility));
    }
    if (admins.contains(app.package)) out.add(finding(Rule.deviceAdmin));
    if (listeners.contains(app.package)) {
      out.add(finding(Rule.notificationAccess));
    }
    if (app.holds(_backgroundLocation)) {
      out.add(finding(Rule.backgroundLocation));
    }
    // The app chosen for text messages or calls needs them to work.
    if ((app.holds(_readSms) || app.holds(_receiveSms)) &&
        !smsApps.contains(app.package)) {
      out.add(finding(Rule.sms));
    }
    if (app.holds(_callLog) && !dialers.contains(app.package)) {
      out.add(finding(Rule.callLog));
    }
    if (special(allFilesPermission)) out.add(finding(Rule.allFiles));
    if (special(overlayPermission)) out.add(finding(Rule.overlay));
    if (special(installAppsPermission)) out.add(finding(Rule.installsApps));
    if (special(usageAccessPermission)) out.add(finding(Rule.usageAccess));
    if (app.targetSdk > 0 && app.targetSdk < oldestCurrentTarget) {
      out.add(finding(Rule.oldTarget, detail: androidVersionOf(app.targetSdk)));
    }
    if (app.lastUpdate > 0 &&
        now - app.lastUpdate > notUpdatedAfter.inMilliseconds) {
      out.add(
        finding(
          Rule.notUpdated,
          detail: '${(now - app.lastUpdate) ~/ Duration.millisecondsPerDay}',
        ),
      );
    }

    final lastUsed = phone.lastUsed(app.package);
    final installedLongAgo =
        app.firstInstall > 0 &&
        now - app.firstInstall > unusedAfter.inMilliseconds;
    if (lastUsed != null &&
        installedLongAgo &&
        now - lastUsed > unusedAfter.inMilliseconds &&
        !alwaysOn.contains(app.package) &&
        (sensitivePermissions.any(app.holds) ||
            special(allFilesPermission) ||
            special(overlayPermission) ||
            special(usageAccessPermission))) {
      out.add(finding(Rule.unused));
    }
  }
  return out;
}

/// The Android version an app was built for, from its target SDK level.
String androidVersionOf(int sdk) => switch (sdk) {
  <= 0 => '?',
  < 21 => '4',
  21 || 22 => '5',
  23 => '6',
  24 || 25 => '7',
  26 || 27 => '8',
  28 => '9',
  29 => '10',
  30 => '11',
  31 => '12',
  32 => '12L',
  _ => '${sdk - 20}',
};
