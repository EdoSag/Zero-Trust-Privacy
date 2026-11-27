// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_l10n.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppL10nEn extends AppL10n {
  AppL10nEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'ZT Privacy';

  @override
  String get phoneTestTitle => 'Phone test';

  @override
  String buildLabel(String build) {
    return 'Build $build';
  }

  @override
  String get intro =>
      'This test checks what this phone lets ZT Privacy read. What it reads stays on the phone unless you share it yourself. Run the steps, then send the summary.';

  @override
  String get stepReadTitle => '1. Read the phone';

  @override
  String get stepReadBody =>
      'Lists the installed apps with their permissions, who holds special access, and the settings a privacy check looks at.';

  @override
  String get readButton => 'Read the phone';

  @override
  String get readAgainButton => 'Read again';

  @override
  String get reading => 'Reading…';

  @override
  String appsLine(int total, int user) {
    return '$total apps, $user of them yours';
  }

  @override
  String settingsLine(int ok, int total) {
    return 'Settings read: $ok of $total';
  }

  @override
  String accessListsLine(int ok, int total) {
    return 'Special access lists read: $ok of $total';
  }

  @override
  String networkOffLine(int count) {
    return 'Apps with the network switched off: $count';
  }

  @override
  String stepFailed(String error) {
    return 'This step failed: $error';
  }

  @override
  String get stepUsageTitle => '2. Usage access (optional)';

  @override
  String get stepUsageBody =>
      'Shows when each app was last used and how much data it moved. Switch on ZT Privacy in the list, then come back.';

  @override
  String usageOn(int count) {
    return 'Usage access is on. Apps with a last-used time: $count';
  }

  @override
  String get usageOff => 'Usage access is off.';

  @override
  String get openUsageAccess => 'Open Usage access';

  @override
  String get checkAgain => 'Check again';

  @override
  String get stepDeepTitle => '3. Deep mode (optional, needs a computer)';

  @override
  String get stepDeepBody =>
      'Android hides which app used the camera, microphone or location. A computer can unlock it once. Connect the phone with USB debugging on, run this command, then switch USB debugging off again.';

  @override
  String get copyCommand => 'Copy the command';

  @override
  String get copied => 'Copied';

  @override
  String get deepNotGranted => 'Not unlocked yet.';

  @override
  String deepGrantedWorks(int count) {
    return 'Unlocked, and the history can be read: $count rows.';
  }

  @override
  String get deepGrantedBlocked =>
      'Unlocked, but Android still refused the history. The summary has the details.';

  @override
  String get stepScanTitle => '4. Tracker scan';

  @override
  String get stepScanBody =>
      'Reads the class names inside each of your apps and looks for well-known tracking and advertising kits. This measures how long a full scan takes.';

  @override
  String get scanNeedsApps => 'Read the phone first.';

  @override
  String get startScan => 'Start the scan';

  @override
  String get stopScan => 'Stop';

  @override
  String scanProgress(int done, int total, String seconds) {
    return '$done of $total apps, $seconds s';
  }

  @override
  String scanDone(int done, String seconds, int withKits) {
    return 'Done: $done apps in $seconds s. $withKits contain at least one kit.';
  }

  @override
  String scanErrors(int count) {
    return 'Apps that could not be read: $count';
  }

  @override
  String get stepScreensTitle => '5. Android\'s own screens';

  @override
  String get stepScreensBody =>
      'Checks which system screens ZT Privacy may open for you. Tap each one, then come back.';

  @override
  String get screenPrivacyDashboard => 'Privacy dashboard';

  @override
  String get screenPermissionManager => 'Permission manager';

  @override
  String get screenPrivacy => 'Privacy settings';

  @override
  String get screenAppDetails => 'This app\'s settings';

  @override
  String get screenOpened => 'opened';

  @override
  String get screenRefused => 'refused';

  @override
  String get stepSendTitle => '6. Send the results';

  @override
  String get stepSendBody =>
      'The summary holds counts only and names no app. The full report adds a line for each of your apps, so share it only if you are comfortable with that.';

  @override
  String get shareSummary => 'Share the summary';

  @override
  String get copySummary => 'Copy the summary';

  @override
  String get saveFull => 'Save the full report to Downloads';

  @override
  String savedFull(String name) {
    return 'Saved to Downloads as $name';
  }

  @override
  String actionFailed(String error) {
    return 'That did not work: $error';
  }

  @override
  String stepsMissing(String steps) {
    return 'Not run yet: step $steps. The summary is more useful with them.';
  }

  @override
  String get nothingYet => 'Nothing to send yet. Run step 1 first.';

  @override
  String get settingsTooltip => 'Settings';

  @override
  String get refreshTooltip => 'Read the phone again';

  @override
  String get scoreTitle => 'Privacy score';

  @override
  String get scoreOutOf => 'of 100';

  @override
  String get scoreAllGood => 'Nothing to fix. Well kept.';

  @override
  String scoreToFix(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count things to look at',
      one: '1 thing to look at',
    );
    return '$_temp0';
  }

  @override
  String get scoreExplain => 'How the score is counted';

  @override
  String get phoneOnlyNote =>
      'Everything here is read on this phone and stays on it.';

  @override
  String get fixNext => 'Fix next';

  @override
  String get allFindings => 'Everything to look at';

  @override
  String seeAll(int count) {
    return 'See all $count';
  }

  @override
  String get appsTile => 'Apps and permissions';

  @override
  String appsTileSub(int apps, int findings) {
    return '$apps apps, $findings to look at';
  }

  @override
  String get checklistTile => 'Device checklist';

  @override
  String checklistTileSub(int attention, int manual) {
    return '$attention to fix, $manual to check yourself';
  }

  @override
  String get usageCardTitle => 'See which apps you no longer use';

  @override
  String get usageCardBody =>
      'Switch on Usage access for ZT Privacy, and it can point out apps you have not opened for 90 days that still hold permissions. This stays on the phone.';

  @override
  String get usageCardButton => 'Open Usage access';

  @override
  String readFailed(String error) {
    return 'The phone could not be read: $error';
  }

  @override
  String get tryAgain => 'Try again';

  @override
  String partsFailed(String parts) {
    return 'Some parts could not be read, so they are left out: $parts';
  }

  @override
  String get openSetting => 'Open the setting';

  @override
  String get openAppSettings => 'Open the app\'s settings';

  @override
  String openFailed(String error) {
    return 'That screen did not open: $error';
  }

  @override
  String get acceptButton => 'I\'m fine with this';

  @override
  String get unacceptButton => 'Count it again';

  @override
  String findingCosts(int points) {
    String _temp0 = intl.Intl.pluralLogic(
      points,
      locale: localeName,
      other: 'Takes $points points off the score',
      one: 'Takes 1 point off the score',
    );
    return '$_temp0';
  }

  @override
  String get findingAccepted => 'You are fine with this, so it does not count.';

  @override
  String saveFailed(String error) {
    return 'That could not be saved: $error';
  }

  @override
  String get scoreIntro =>
      'The score starts at 100. Each thing found takes points off, up to a limit for each kind. Things you are fine with cost nothing.';

  @override
  String scoreLine(int open, int points) {
    return '$open found, $points off';
  }

  @override
  String scoreLineAccepted(int count) {
    return '$count you are fine with';
  }

  @override
  String get scoreNoLines => 'Nothing was found, so nothing is taken off.';

  @override
  String get tabByPermission => 'By permission';

  @override
  String get tabByApp => 'By app';

  @override
  String get searchApps => 'Search apps';

  @override
  String get showSystem => 'Show system apps';

  @override
  String get sectionPermissions => 'Permissions';

  @override
  String get sectionSpecial => 'Special access';

  @override
  String heldBy(int holding, int asking) {
    return 'Held by $holding, asked for by $asking';
  }

  @override
  String heldByOnly(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count apps',
      one: '1 app',
      zero: 'No app',
    );
    return '$_temp0';
  }

  @override
  String get noAppHolds => 'No app of yours holds this.';

  @override
  String get noAppsMatch => 'No app matches.';

  @override
  String appToLookAt(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count to look at',
      one: '1 to look at',
    );
    return '$_temp0';
  }

  @override
  String get appSystem => 'Part of the system';

  @override
  String appInstalledFrom(String installer) {
    return 'Installed by $installer';
  }

  @override
  String get appInstalledFromUnknown => 'Android does not say who installed it';

  @override
  String appBuiltFor(String version) {
    return 'Built for Android $version';
  }

  @override
  String appInstalledOn(String date) {
    return 'Installed $date';
  }

  @override
  String appUpdatedOn(String date) {
    return 'Last updated $date';
  }

  @override
  String appLastUsed(String date) {
    return 'Last used $date';
  }

  @override
  String get appNotUsed => 'Not used in the last 90 days';

  @override
  String get appHoldsTitle => 'What it holds';

  @override
  String get appHoldsNothing => 'None of the permissions ZT Privacy watches.';

  @override
  String get appFindingsTitle => 'To look at';

  @override
  String get appNoFindings => 'Nothing to point out.';

  @override
  String get checksRead => 'Read from the phone';

  @override
  String get checksManual => 'To check yourself';

  @override
  String get checksManualHint =>
      'Android does not let an app read these. Open the setting, look, and tick it off.';

  @override
  String get checksGraphene => 'GrapheneOS';

  @override
  String get stateUnknown => 'Android does not say';

  @override
  String get valueOn => 'On';

  @override
  String get valueOff => 'Off';

  @override
  String get stateGood => 'Good';

  @override
  String get stateAttention => 'Worth changing';

  @override
  String get markChecked => 'I checked this';

  @override
  String get settingsPhoneTest => 'Phone test';

  @override
  String get settingsPhoneTestHint =>
      'What Android lets ZT Privacy read on this phone';

  @override
  String get permLocationPrecise => 'Location, precise';

  @override
  String get permLocationApprox => 'Location, approximate';

  @override
  String get permLocationAlways => 'Location, all the time';

  @override
  String get permCamera => 'Camera';

  @override
  String get permMicrophone => 'Microphone';

  @override
  String get permContacts => 'Contacts';

  @override
  String get permCalendar => 'Calendar';

  @override
  String get permSms => 'Text messages';

  @override
  String get permCallLog => 'Call log';

  @override
  String get permPhoneState => 'Phone number and call state';

  @override
  String get permPhotos => 'Photos and videos';

  @override
  String get permFilesOld => 'Files (the old way)';

  @override
  String get permNearby => 'Nearby devices';

  @override
  String get permBodySensors => 'Body sensors';

  @override
  String get permActivity => 'Physical activity';

  @override
  String get permNotifications => 'Notifications';

  @override
  String get ruleNoScreenLock => 'Screen lock';

  @override
  String get findingNoScreenLock => 'The phone has no screen lock';

  @override
  String get whyNoScreenLock =>
      'Anyone who picks up the phone can open everything on it. Set a PIN or a password.';

  @override
  String get ruleOldSecurityPatch => 'Security updates';

  @override
  String findingOldSecurityPatch(String date) {
    return 'Last security update: $date';
  }

  @override
  String get whyOldSecurityPatch =>
      'Security updates close holes that are already known. More than 90 days without one is a long time. Check for a system update. If none is offered, the phone may no longer get them.';

  @override
  String get ruleUsbDebugging => 'USB debugging';

  @override
  String get findingUsbDebugging => 'USB debugging is on';

  @override
  String get whyUsbDebugging =>
      'With USB debugging on, a computer the phone is plugged into can read and change almost everything, once you allow it. Switch it off when you are not using it.';

  @override
  String get ruleWirelessDebugging => 'Wireless debugging';

  @override
  String get findingWirelessDebugging => 'Wireless debugging is on';

  @override
  String get whyWirelessDebugging =>
      'With wireless debugging on, a paired computer on the same Wi-Fi can read and change almost everything on the phone. Switch it off when you are not using it.';

  @override
  String get ruleDeveloperOptions => 'Developer options';

  @override
  String get findingDeveloperOptions => 'Developer options are on';

  @override
  String get whyDeveloperOptions =>
      'Developer options hold switches that weaken the phone\'s protections. If you are not using them, switch them off.';

  @override
  String get ruleLockScreenContent => 'Messages on the lock screen';

  @override
  String get findingLockScreenContent =>
      'Message text shows on the lock screen';

  @override
  String get whyLockScreenContent =>
      'Anyone who sees the locked phone can read your messages and sign-in codes as they arrive. Choose to hide sensitive content on the lock screen.';

  @override
  String get ruleWifiScanning => 'Wi-Fi scanning';

  @override
  String get findingWifiScanning => 'Wi-Fi scanning stays on when Wi-Fi is off';

  @override
  String get whyWifiScanning =>
      'Apps and services can look for Wi-Fi networks even when Wi-Fi is switched off, which can be used to work out where you are.';

  @override
  String get ruleBluetoothScanning => 'Bluetooth scanning';

  @override
  String get findingBluetoothScanning =>
      'Bluetooth scanning stays on when Bluetooth is off';

  @override
  String get whyBluetoothScanning =>
      'Apps and services can look for Bluetooth devices even when Bluetooth is switched off, which can be used to work out where you are.';

  @override
  String get ruleAccessibility => 'Accessibility services';

  @override
  String findingAccessibility(String app) {
    return '$app can read and control the screen';
  }

  @override
  String get whyAccessibility =>
      'An accessibility service can read everything on the screen, including passwords and messages, and tap for you. Keep it only for apps you trust completely, such as a password manager or a screen reader you use.';

  @override
  String get ruleDeviceAdmin => 'Device admin apps';

  @override
  String findingDeviceAdmin(String app) {
    return '$app is a device admin';
  }

  @override
  String get whyDeviceAdmin =>
      'A device admin can change the screen lock rules, lock the phone or erase it, and is harder to uninstall. Keep it only for an app you chose for that job.';

  @override
  String get ruleNotificationAccess => 'Notification access';

  @override
  String findingNotificationAccess(String app) {
    return '$app can read all notifications';
  }

  @override
  String get whyNotificationAccess =>
      'This app can read every notification, including messages and sign-in codes, and dismiss them. Keep it only for apps that need it, such as a watch or a car connection.';

  @override
  String get ruleBackgroundLocation => 'Location all the time';

  @override
  String findingBackgroundLocation(String app) {
    return '$app can see your location all the time';
  }

  @override
  String get whyBackgroundLocation =>
      'This app can see where you are even when you are not using it. Most apps work with \"Only while using the app\".';

  @override
  String get ruleSms => 'Text messages';

  @override
  String findingSms(String app) {
    return '$app can read your text messages';
  }

  @override
  String get whySms =>
      'Text messages often carry sign-in codes. Only your messaging app needs to read them.';

  @override
  String get ruleCallLog => 'Call log';

  @override
  String findingCallLog(String app) {
    return '$app can read your call log';
  }

  @override
  String get whyCallLog =>
      'The call log shows who you speak to and when. Only your phone app needs it.';

  @override
  String get ruleAllFiles => 'All files access';

  @override
  String findingAllFiles(String app) {
    return '$app can read all your files';
  }

  @override
  String get whyAllFiles =>
      'This app can read and change every file in shared storage: photos, downloads, documents. A file manager needs it; most apps do not.';

  @override
  String get ruleOverlay => 'Display over other apps';

  @override
  String findingOverlay(String app) {
    return '$app can draw over other apps';
  }

  @override
  String get whyOverlay =>
      'This app can draw on top of other apps. That can be used to cover what you see or to trick you into tapping.';

  @override
  String get ruleInstallsApps => 'Installing other apps';

  @override
  String findingInstallsApps(String app) {
    return '$app can install other apps';
  }

  @override
  String get whyInstallsApps =>
      'This app can ask to install other apps from outside your app store. Keep it for the store or browser you install from.';

  @override
  String get ruleUsageAccess => 'Usage access';

  @override
  String findingUsageAccess(String app) {
    return '$app can see which apps you use';
  }

  @override
  String get whyUsageAccess =>
      'This app can see which apps you use, when and for how long.';

  @override
  String get ruleOldTarget => 'Built for an old Android';

  @override
  String findingOldTarget(String app, String version) {
    return '$app was built for Android $version';
  }

  @override
  String get whyOldTarget =>
      'Apps built for Android 10 or older skip protections added since, such as limits on reading files and the automatic removal of unused permissions.';

  @override
  String get ruleNotUpdated => 'Not updated for two years';

  @override
  String findingNotUpdated(String app, int years) {
    return '$app has not been updated for over $years years';
  }

  @override
  String get whyNotUpdated =>
      'An app with no updates for two years is probably no longer looked after, so known problems in it stay open.';

  @override
  String get ruleUnused => 'Unused apps with permissions';

  @override
  String findingUnused(String app) {
    return '$app has not been used for 90 days';
  }

  @override
  String get whyUnused =>
      'You have not opened this app for 90 days, and it still holds permissions. Remove it, or take the permissions away.';

  @override
  String get checkScreenLock => 'Screen lock';

  @override
  String get checkEncryption => 'Storage encryption';

  @override
  String get checkWhyEncryption =>
      'Everything stored on the phone is encrypted, and opens only with your screen lock.';

  @override
  String get checkSecurityPatch => 'Security update';

  @override
  String get checkUsbDebugging => 'USB debugging';

  @override
  String get checkWirelessDebugging => 'Wireless debugging';

  @override
  String get checkDeveloperOptions => 'Developer options';

  @override
  String get checkLockScreenContent => 'Message text on the lock screen';

  @override
  String get checkWifiScanning => 'Wi-Fi scanning while Wi-Fi is off';

  @override
  String get checkBluetoothScanning =>
      'Bluetooth scanning while Bluetooth is off';

  @override
  String get checkPrivateDns => 'Private DNS';

  @override
  String get checkWhyPrivateDns =>
      'Private DNS hides the names of the sites you look up from the network you are on, and can block trackers if you pick a filtering service.';

  @override
  String get checkVpn => 'VPN';

  @override
  String get checkWhyVpn =>
      'A VPN hides what you do from the network you are on, and your address from the sites you visit. It moves that trust to the VPN provider.';

  @override
  String get checkAdvancedProtection => 'Advanced Protection';

  @override
  String get checkWhyAdvancedProtection =>
      'Android\'s Advanced Protection switches on its strongest safeguards at once. Worth it if you are at higher risk.';

  @override
  String get checkAlwaysOnVpn =>
      'VPN always on, with nothing allowed outside it';

  @override
  String get checkWhyAlwaysOnVpn =>
      'With \"Always-on VPN\" and \"Block connections without VPN\", nothing leaves the phone outside the VPN, not even for a moment while it reconnects. Android does not let apps read this setting.';

  @override
  String get checkAdvertisingId => 'Advertising ID deleted';

  @override
  String get checkWhyAdvertisingId =>
      'The advertising ID lets apps link what you do across them. Delete it under Settings, Privacy, Ads.';

  @override
  String get checkAutoReboot => 'Auto reboot';

  @override
  String get checkWhyAutoReboot =>
      'GrapheneOS can restart the phone when it has not been unlocked for a while, which puts your data back at rest, fully encrypted. Look under Settings, Security & privacy, Exploit protection.';

  @override
  String get checkUsbPort => 'USB-C port closed while the phone is locked';

  @override
  String get checkWhyUsbPort =>
      'GrapheneOS can refuse new USB connections while the phone is locked. Look under Settings, Security & privacy, Exploit protection.';

  @override
  String get checkWifiAutoOff => 'Wi-Fi switches itself off when not connected';

  @override
  String get checkWhyWifiAutoOff =>
      'GrapheneOS can switch Wi-Fi off after it has had no connection for a while. Look under Settings, Network & internet, Internet, Network preferences.';

  @override
  String get checkBluetoothAutoOff =>
      'Bluetooth switches itself off when not connected';

  @override
  String get checkWhyBluetoothAutoOff =>
      'GrapheneOS can switch Bluetooth off after it has had no connection for a while. Look under Settings, Connected devices, Connection preferences, Bluetooth.';

  @override
  String get checkPinScrambling => 'Scrambled PIN keypad';

  @override
  String get checkWhyPinScrambling =>
      'A keypad with the digits in a new order each time stops someone learning your PIN from where you tap. Look under Settings, Security & privacy, Device unlock.';

  @override
  String get checkDuressPin => 'Duress PIN';

  @override
  String get checkWhyDuressPin =>
      'A second PIN that erases the phone when it is entered. Look under Settings, Security & privacy, Device unlock.';

  @override
  String get checkNetworkSensors => 'Network and Sensors permissions reviewed';

  @override
  String get checkWhyNetworkSensors =>
      'On GrapheneOS every app has a Network and a Sensors permission that you can switch off. Go through your apps and take them away where an app has no need for them.';

  @override
  String findingCostsEach(int points, int cap) {
    return 'Each one takes $points off the score, and all of this kind together $cap at most.';
  }

  @override
  String get acceptedHeading => 'You are fine with these';

  @override
  String get nothingToLookAt => 'Nothing to look at here.';

  @override
  String get aboutThisApp => 'About this app';

  @override
  String get readingPhone => 'Reading the phone…';

  @override
  String get lastUsedNeedsAccess =>
      'Switch on Usage access to see when it was last used';

  @override
  String get lastUsedUnknown => 'Android did not say when it was last used';

  @override
  String get holdersTitle => 'Apps that hold this';
}
