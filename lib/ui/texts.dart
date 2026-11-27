import 'package:flutter/material.dart';

import '../l10n/l10n.dart';
import '../rules/checklist.dart';
import '../rules/finding.dart';
import '../rules/rules.dart';

/// A permission the app shows by a plain name.
class WatchedPermission {
  const WatchedPermission(this.permissions, this.icon, this.name);

  /// One line on screen can stand for a few Android permissions.
  final List<String> permissions;
  final IconData icon;
  final String Function(AppL10n l) name;
}

/// The ordinary permissions shown under "By permission" and on an app's
/// page, in the order shown.
final watchedPermissions = <WatchedPermission>[
  WatchedPermission(
    const ['android.permission.ACCESS_BACKGROUND_LOCATION'],
    Icons.share_location_outlined,
    (l) => l.permLocationAlways,
  ),
  WatchedPermission(
    const ['android.permission.ACCESS_FINE_LOCATION'],
    Icons.location_on_outlined,
    (l) => l.permLocationPrecise,
  ),
  WatchedPermission(
    const ['android.permission.ACCESS_COARSE_LOCATION'],
    Icons.location_searching,
    (l) => l.permLocationApprox,
  ),
  WatchedPermission(
    const ['android.permission.CAMERA'],
    Icons.photo_camera_outlined,
    (l) => l.permCamera,
  ),
  WatchedPermission(
    const ['android.permission.RECORD_AUDIO'],
    Icons.mic_none,
    (l) => l.permMicrophone,
  ),
  WatchedPermission(
    const ['android.permission.READ_CONTACTS'],
    Icons.contacts_outlined,
    (l) => l.permContacts,
  ),
  WatchedPermission(
    const ['android.permission.READ_CALENDAR'],
    Icons.event_outlined,
    (l) => l.permCalendar,
  ),
  WatchedPermission(
    const ['android.permission.READ_SMS', 'android.permission.RECEIVE_SMS'],
    Icons.sms_outlined,
    (l) => l.permSms,
  ),
  WatchedPermission(
    const ['android.permission.READ_CALL_LOG'],
    Icons.call_outlined,
    (l) => l.permCallLog,
  ),
  WatchedPermission(
    const ['android.permission.READ_PHONE_STATE'],
    Icons.sim_card_outlined,
    (l) => l.permPhoneState,
  ),
  WatchedPermission(
    const [
      'android.permission.READ_MEDIA_IMAGES',
      'android.permission.READ_MEDIA_VIDEO',
    ],
    Icons.photo_library_outlined,
    (l) => l.permPhotos,
  ),
  WatchedPermission(
    const ['android.permission.READ_EXTERNAL_STORAGE'],
    Icons.folder_outlined,
    (l) => l.permFilesOld,
  ),
  WatchedPermission(
    const [
      'android.permission.BLUETOOTH_CONNECT',
      'android.permission.BLUETOOTH_SCAN',
      'android.permission.NEARBY_WIFI_DEVICES',
    ],
    Icons.devices_other_outlined,
    (l) => l.permNearby,
  ),
  WatchedPermission(
    const ['android.permission.BODY_SENSORS'],
    Icons.monitor_heart_outlined,
    (l) => l.permBodySensors,
  ),
  WatchedPermission(
    const ['android.permission.ACTIVITY_RECOGNITION'],
    Icons.directions_walk,
    (l) => l.permActivity,
  ),
  WatchedPermission(
    const ['android.permission.POST_NOTIFICATIONS'],
    Icons.notifications_none,
    (l) => l.permNotifications,
  ),
];

/// A special access shown under "By permission" and on an app's page. Each
/// is also a kind of finding, which gives it its name and its explanation.
class WatchedAccess {
  const WatchedAccess(this.rule, {this.list, this.permission});

  final Rule rule;

  /// One of Android's lists ([PhoneSnapshot.listed]), or
  final String? list;

  /// a special permission ([PhoneSnapshot.holdsSpecial]).
  final String? permission;
}

const watchedAccess = [
  WatchedAccess(Rule.accessibility, list: 'accessibilityServices'),
  WatchedAccess(Rule.deviceAdmin, list: 'deviceAdmins'),
  WatchedAccess(Rule.notificationAccess, list: 'notificationListeners'),
  WatchedAccess(Rule.allFiles, permission: allFilesPermission),
  WatchedAccess(Rule.overlay, permission: overlayPermission),
  WatchedAccess(Rule.installsApps, permission: installAppsPermission),
  WatchedAccess(Rule.usageAccess, permission: usageAccessPermission),
];

extension RuleTexts on Rule {
  /// The kind of finding, for a heading or a line of the score.
  String kind(AppL10n l) => switch (this) {
    Rule.noScreenLock => l.ruleNoScreenLock,
    Rule.oldSecurityPatch => l.ruleOldSecurityPatch,
    Rule.usbDebugging => l.ruleUsbDebugging,
    Rule.wirelessDebugging => l.ruleWirelessDebugging,
    Rule.developerOptions => l.ruleDeveloperOptions,
    Rule.lockScreenContent => l.ruleLockScreenContent,
    Rule.wifiScanning => l.ruleWifiScanning,
    Rule.bluetoothScanning => l.ruleBluetoothScanning,
    Rule.accessibility => l.ruleAccessibility,
    Rule.deviceAdmin => l.ruleDeviceAdmin,
    Rule.notificationAccess => l.ruleNotificationAccess,
    Rule.backgroundLocation => l.ruleBackgroundLocation,
    Rule.sms => l.ruleSms,
    Rule.callLog => l.ruleCallLog,
    Rule.allFiles => l.ruleAllFiles,
    Rule.overlay => l.ruleOverlay,
    Rule.installsApps => l.ruleInstallsApps,
    Rule.usageAccess => l.ruleUsageAccess,
    Rule.oldTarget => l.ruleOldTarget,
    Rule.notUpdated => l.ruleNotUpdated,
    Rule.unused => l.ruleUnused,
  };

  /// Why it matters and what to do, in a few plain sentences.
  String why(AppL10n l) => switch (this) {
    Rule.noScreenLock => l.whyNoScreenLock,
    Rule.oldSecurityPatch => l.whyOldSecurityPatch,
    Rule.usbDebugging => l.whyUsbDebugging,
    Rule.wirelessDebugging => l.whyWirelessDebugging,
    Rule.developerOptions => l.whyDeveloperOptions,
    Rule.lockScreenContent => l.whyLockScreenContent,
    Rule.wifiScanning => l.whyWifiScanning,
    Rule.bluetoothScanning => l.whyBluetoothScanning,
    Rule.accessibility => l.whyAccessibility,
    Rule.deviceAdmin => l.whyDeviceAdmin,
    Rule.notificationAccess => l.whyNotificationAccess,
    Rule.backgroundLocation => l.whyBackgroundLocation,
    Rule.sms => l.whySms,
    Rule.callLog => l.whyCallLog,
    Rule.allFiles => l.whyAllFiles,
    Rule.overlay => l.whyOverlay,
    Rule.installsApps => l.whyInstallsApps,
    Rule.usageAccess => l.whyUsageAccess,
    Rule.oldTarget => l.whyOldTarget,
    Rule.notUpdated => l.whyNotUpdated,
    Rule.unused => l.whyUnused,
  };

  IconData get icon => switch (this) {
    Rule.noScreenLock => Icons.lock_open_outlined,
    Rule.oldSecurityPatch => Icons.system_update_outlined,
    Rule.usbDebugging => Icons.usb,
    Rule.wirelessDebugging => Icons.wifi_tethering,
    Rule.developerOptions => Icons.developer_mode_outlined,
    Rule.lockScreenContent => Icons.screen_lock_portrait_outlined,
    Rule.wifiScanning => Icons.wifi_find_outlined,
    Rule.bluetoothScanning => Icons.bluetooth_searching,
    Rule.accessibility => Icons.accessibility_new,
    Rule.deviceAdmin => Icons.admin_panel_settings_outlined,
    Rule.notificationAccess => Icons.notifications_active_outlined,
    Rule.backgroundLocation => Icons.share_location_outlined,
    Rule.sms => Icons.sms_outlined,
    Rule.callLog => Icons.call_outlined,
    Rule.allFiles => Icons.folder_open_outlined,
    Rule.overlay => Icons.layers_outlined,
    Rule.installsApps => Icons.install_mobile_outlined,
    Rule.usageAccess => Icons.query_stats,
    Rule.oldTarget => Icons.history,
    Rule.notUpdated => Icons.update_disabled_outlined,
    Rule.unused => Icons.bedtime_outlined,
  };

  /// The system screen where it is changed. App rules without a list of
  /// their own open the app's page in Settings.
  String get screen => switch (this) {
    Rule.noScreenLock => Screens.security,
    Rule.oldSecurityPatch => Screens.systemUpdate,
    Rule.usbDebugging ||
    Rule.wirelessDebugging ||
    Rule.developerOptions => Screens.developer,
    Rule.lockScreenContent => Screens.notifications,
    Rule.wifiScanning || Rule.bluetoothScanning => Screens.location,
    Rule.accessibility => Screens.accessibility,
    Rule.notificationAccess => Screens.notificationAccess,
    Rule.allFiles => Screens.allFiles,
    Rule.installsApps => Screens.installApps,
    Rule.overlay => Screens.overlay,
    Rule.usageAccess => Screens.usageAccess,
    Rule.deviceAdmin ||
    Rule.backgroundLocation ||
    Rule.sms ||
    Rule.callLog ||
    Rule.oldTarget ||
    Rule.notUpdated ||
    Rule.unused => Screens.appDetails,
  };

  /// Whether [screen] opens on one app's own switch when given the app.
  bool get screenTakesApp => switch (this) {
    Rule.allFiles || Rule.installsApps || Rule.overlay => true,
    _ => screen == Screens.appDetails,
  };
}

extension FindingTexts on Finding {
  /// One line that says what was found.
  String title(AppL10n l) {
    final app = label ?? package ?? '';
    return switch (rule) {
      Rule.noScreenLock => l.findingNoScreenLock,
      Rule.oldSecurityPatch => l.findingOldSecurityPatch(detail ?? '?'),
      Rule.usbDebugging => l.findingUsbDebugging,
      Rule.wirelessDebugging => l.findingWirelessDebugging,
      Rule.developerOptions => l.findingDeveloperOptions,
      Rule.lockScreenContent => l.findingLockScreenContent,
      Rule.wifiScanning => l.findingWifiScanning,
      Rule.bluetoothScanning => l.findingBluetoothScanning,
      Rule.accessibility => l.findingAccessibility(app),
      Rule.deviceAdmin => l.findingDeviceAdmin(app),
      Rule.notificationAccess => l.findingNotificationAccess(app),
      Rule.backgroundLocation => l.findingBackgroundLocation(app),
      Rule.sms => l.findingSms(app),
      Rule.callLog => l.findingCallLog(app),
      Rule.allFiles => l.findingAllFiles(app),
      Rule.overlay => l.findingOverlay(app),
      Rule.installsApps => l.findingInstallsApps(app),
      Rule.usageAccess => l.findingUsageAccess(app),
      Rule.oldTarget => l.findingOldTarget(app, detail ?? '?'),
      Rule.notUpdated => l.findingNotUpdated(
        app,
        (int.tryParse(detail ?? '') ?? 730) ~/ 365,
      ),
      Rule.unused => l.findingUnused(app),
    };
  }
}

extension CheckTexts on CheckId {
  String title(AppL10n l) => switch (this) {
    CheckId.screenLock => l.checkScreenLock,
    CheckId.encryption => l.checkEncryption,
    CheckId.securityPatch => l.checkSecurityPatch,
    CheckId.usbDebugging => l.checkUsbDebugging,
    CheckId.wirelessDebugging => l.checkWirelessDebugging,
    CheckId.developerOptions => l.checkDeveloperOptions,
    CheckId.lockScreenContent => l.checkLockScreenContent,
    CheckId.wifiScanning => l.checkWifiScanning,
    CheckId.bluetoothScanning => l.checkBluetoothScanning,
    CheckId.privateDns => l.checkPrivateDns,
    CheckId.vpn => l.checkVpn,
    CheckId.advancedProtection => l.checkAdvancedProtection,
    CheckId.alwaysOnVpn => l.checkAlwaysOnVpn,
    CheckId.advertisingId => l.checkAdvertisingId,
    CheckId.autoReboot => l.checkAutoReboot,
    CheckId.usbPort => l.checkUsbPort,
    CheckId.wifiAutoOff => l.checkWifiAutoOff,
    CheckId.bluetoothAutoOff => l.checkBluetoothAutoOff,
    CheckId.pinScrambling => l.checkPinScrambling,
    CheckId.duressPin => l.checkDuressPin,
    CheckId.networkSensors => l.checkNetworkSensors,
  };

  /// The finding that explains this line, for the lines that can raise one.
  Rule? get rule => switch (this) {
    CheckId.screenLock => Rule.noScreenLock,
    CheckId.securityPatch => Rule.oldSecurityPatch,
    CheckId.usbDebugging => Rule.usbDebugging,
    CheckId.wirelessDebugging => Rule.wirelessDebugging,
    CheckId.developerOptions => Rule.developerOptions,
    CheckId.lockScreenContent => Rule.lockScreenContent,
    CheckId.wifiScanning => Rule.wifiScanning,
    CheckId.bluetoothScanning => Rule.bluetoothScanning,
    _ => null,
  };

  /// Why the line is on the list.
  String why(AppL10n l) => switch (this) {
    CheckId.encryption => l.checkWhyEncryption,
    CheckId.privateDns => l.checkWhyPrivateDns,
    CheckId.vpn => l.checkWhyVpn,
    CheckId.advancedProtection => l.checkWhyAdvancedProtection,
    CheckId.alwaysOnVpn => l.checkWhyAlwaysOnVpn,
    CheckId.advertisingId => l.checkWhyAdvertisingId,
    CheckId.autoReboot => l.checkWhyAutoReboot,
    CheckId.usbPort => l.checkWhyUsbPort,
    CheckId.wifiAutoOff => l.checkWhyWifiAutoOff,
    CheckId.bluetoothAutoOff => l.checkWhyBluetoothAutoOff,
    CheckId.pinScrambling => l.checkWhyPinScrambling,
    CheckId.duressPin => l.checkWhyDuressPin,
    CheckId.networkSensors => l.checkWhyNetworkSensors,
    _ => rule!.why(l),
  };
}

/// A day, written the same way in both languages (2026-11-27).
String dayText(int millisecondsSinceEpoch) {
  final date = DateTime.fromMillisecondsSinceEpoch(millisecondsSinceEpoch);
  String two(int n) => n.toString().padLeft(2, '0');
  return '${date.year}-${two(date.month)}-${two(date.day)}';
}
