import '../phone/phone_snapshot.dart';
import 'finding.dart';
import 'rules.dart';

/// How one line of the device checklist stands.
enum CheckState {
  /// Read from the phone, and as it should be.
  good,

  /// Read from the phone, and worth changing. Has a [DeviceCheck.rule].
  attention,

  /// Read from the phone, shown for information: no right or wrong.
  info,

  /// Android would not say.
  unknown,

  /// Android does not let an app read it: the user looks and ticks it off.
  manual,
}

/// The lines of the device checklist. The order is the order on screen.
enum CheckId {
  screenLock(Screens.security),
  encryption(Screens.security),
  securityPatch(Screens.systemUpdate),
  usbDebugging(Screens.developer),
  wirelessDebugging(Screens.developer),
  developerOptions(Screens.developer),
  lockScreenContent(Screens.notifications),
  wifiScanning(Screens.location),
  bluetoothScanning(Screens.location),
  privateDns(Screens.network),
  vpn(Screens.vpn),
  advancedProtection(Screens.security),

  alwaysOnVpn(Screens.vpn, manual: true),
  advertisingId(Screens.ads, manual: true, stockOnly: true),

  autoReboot(Screens.security, manual: true, grapheneOnly: true),
  usbPort(Screens.security, manual: true, grapheneOnly: true),
  wifiAutoOff(Screens.wifi, manual: true, grapheneOnly: true),
  bluetoothAutoOff(Screens.bluetooth, manual: true, grapheneOnly: true),
  pinScrambling(Screens.security, manual: true, grapheneOnly: true),
  duressPin(Screens.security, manual: true, grapheneOnly: true),
  networkSensors(Screens.apps, manual: true, grapheneOnly: true);

  const CheckId(
    this.screen, {
    this.manual = false,
    this.grapheneOnly = false,
    this.stockOnly = false,
  });

  /// The system screen where it is changed.
  final String screen;
  final bool manual;
  final bool grapheneOnly;

  /// Only on phones with Google's services built in.
  final bool stockOnly;
}

/// System screens, by the action Android opens them with.
abstract final class Screens {
  static const security = 'android.settings.SECURITY_SETTINGS';
  static const systemUpdate = 'android.settings.SYSTEM_UPDATE_SETTINGS';
  static const developer = 'android.settings.APPLICATION_DEVELOPMENT_SETTINGS';
  static const notifications = 'android.settings.NOTIFICATION_SETTINGS';
  static const location = 'android.settings.LOCATION_SOURCE_SETTINGS';
  static const network = 'android.settings.WIRELESS_SETTINGS';
  static const vpn = 'android.settings.VPN_SETTINGS';
  static const wifi = 'android.settings.WIFI_SETTINGS';
  static const bluetooth = 'android.settings.BLUETOOTH_SETTINGS';
  static const apps = 'android.settings.MANAGE_APPLICATIONS_SETTINGS';
  static const ads = 'com.google.android.gms.settings.ADS_PRIVACY';
  static const accessibility = 'android.settings.ACCESSIBILITY_SETTINGS';
  static const notificationAccess =
      'android.settings.ACTION_NOTIFICATION_LISTENER_SETTINGS';
  static const usageAccess = 'android.settings.USAGE_ACCESS_SETTINGS';
  static const allFiles =
      'android.settings.MANAGE_APP_ALL_FILES_ACCESS_PERMISSION';
  static const overlay = 'android.settings.action.MANAGE_OVERLAY_PERMISSION';
  static const installApps = 'android.settings.MANAGE_UNKNOWN_APP_SOURCES';

  /// The app's own page in Settings. Always there, so it is the fallback.
  static const appDetails = 'appDetails';

  /// All of Settings: the fallback for a phone screen that will not open.
  static const settings = 'android.settings.SETTINGS';
}

/// One line of the checklist as it stands on this phone.
class DeviceCheck {
  const DeviceCheck(this.id, this.state, {this.value, this.rule});

  final CheckId id;
  final CheckState state;

  /// What was read, to show next to it (a date, a server name).
  final String? value;

  /// The finding this line raises while it needs attention.
  final Rule? rule;
}

/// The checklist for this phone: what could be read, then what the user is
/// asked to look at, with the GrapheneOS lines only on GrapheneOS.
List<DeviceCheck> deviceChecks(PhoneSnapshot phone) {
  DeviceCheck yesIsGood(CheckId id, String fact, Rule rule) =>
      switch (phone.flag(fact)) {
        true => DeviceCheck(id, CheckState.good),
        false => DeviceCheck(id, CheckState.attention, rule: rule),
        null => DeviceCheck(id, CheckState.unknown),
      };
  // A setting Android leaves empty until it is first switched on.
  DeviceCheck yesIsBad(CheckId id, String fact, Rule rule) =>
      phone.facts[fact]?.ok != true
      ? DeviceCheck(id, CheckState.unknown)
      : (phone.flag(fact) ?? false)
      ? DeviceCheck(id, CheckState.attention, rule: rule)
      : DeviceCheck(id, CheckState.good);

  final debugging =
      (phone.flag('global.adb_enabled') ?? false) ||
      (phone.flag('global.adb_wifi_enabled') ?? false);
  final patch = securityPatchDate(phone);
  final patchText = phone.fact('build.securityPatch');
  final encryption = phone.fact('encryption.status');
  final dnsMode = phone.fact('global.private_dns_mode');
  final dnsServer =
      phone.fact('network.privateDnsServer') ??
      phone.fact('global.private_dns_specifier');
  final dnsActive = phone.flag('network.privateDnsActive');
  final showsOnLockScreen =
      phone.flag('secure.lock_screen_show_notifications') != false;

  final checks = <DeviceCheck>[
    yesIsGood(CheckId.screenLock, 'lock.deviceSecure', Rule.noScreenLock),
    DeviceCheck(
      CheckId.encryption,
      encryption == null
          ? CheckState.unknown
          : encryption.startsWith('active')
          ? CheckState.good
          : CheckState.info,
      value: encryption,
    ),
    DeviceCheck(
      CheckId.securityPatch,
      patch == null
          ? CheckState.unknown
          : securityPatchIsOld(phone)
          ? CheckState.attention
          : CheckState.good,
      value: patchText,
      rule: securityPatchIsOld(phone) ? Rule.oldSecurityPatch : null,
    ),
    yesIsBad(CheckId.usbDebugging, 'global.adb_enabled', Rule.usbDebugging),
    yesIsBad(
      CheckId.wirelessDebugging,
      'global.adb_wifi_enabled',
      Rule.wirelessDebugging,
    ),
    // With debugging on, the debugging line carries the finding; this one
    // is then only shown as it is.
    switch (yesIsBad(
      CheckId.developerOptions,
      'global.development_settings_enabled',
      Rule.developerOptions,
    )) {
      final check when check.state == CheckState.attention && debugging =>
        const DeviceCheck(
          CheckId.developerOptions,
          CheckState.info,
          value: 'on',
        ),
      final check => check,
    },
    phone.facts['secure.lock_screen_allow_private_notifications']?.ok != true
        ? const DeviceCheck(CheckId.lockScreenContent, CheckState.unknown)
        : (phone.flag('secure.lock_screen_allow_private_notifications') ??
                  false) &&
              showsOnLockScreen
        ? const DeviceCheck(
            CheckId.lockScreenContent,
            CheckState.attention,
            rule: Rule.lockScreenContent,
          )
        : const DeviceCheck(CheckId.lockScreenContent, CheckState.good),
    yesIsBad(
      CheckId.wifiScanning,
      'global.wifi_scan_always_enabled',
      Rule.wifiScanning,
    ),
    yesIsBad(
      CheckId.bluetoothScanning,
      'global.ble_scan_always_enabled',
      Rule.bluetoothScanning,
    ),
    DeviceCheck(
      CheckId.privateDns,
      dnsActive == null && dnsMode == null
          ? CheckState.unknown
          : CheckState.info,
      value: (dnsActive ?? false) || dnsMode == 'hostname'
          ? (dnsServer ?? 'on')
          : 'off',
    ),
    DeviceCheck(
      CheckId.vpn,
      phone.flag('network.vpnActive') == null
          ? CheckState.unknown
          : CheckState.info,
      value: (phone.flag('network.vpnActive') ?? false) ? 'on' : 'off',
    ),
    DeviceCheck(
      CheckId.advancedProtection,
      phone.flag('advancedProtection.enabled') == null
          ? CheckState.unknown
          : CheckState.info,
      value: (phone.flag('advancedProtection.enabled') ?? false) ? 'on' : 'off',
    ),
  ];

  return [
    // Advanced Protection only exists from Android 16.
    for (final check in checks)
      if (!(check.id == CheckId.advancedProtection &&
          check.state == CheckState.unknown))
        check,
    for (final id in CheckId.values)
      if (id.manual &&
          (!id.grapheneOnly || phone.grapheneOs) &&
          (!id.stockOnly || !phone.grapheneOs))
        DeviceCheck(id, CheckState.manual),
  ];
}
