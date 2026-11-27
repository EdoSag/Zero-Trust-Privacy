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
      'This build checks what this phone lets ZT Privacy read. Nothing leaves the phone: the app has no network permission. Run the steps, then send the summary.';

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
}
