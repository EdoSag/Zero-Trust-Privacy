import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_l10n_en.dart';
import 'app_l10n_he.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppL10n
/// returned by `AppL10n.of(context)`.
///
/// Applications need to include `AppL10n.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_l10n.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppL10n.localizationsDelegates,
///   supportedLocales: AppL10n.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppL10n.supportedLocales
/// property.
abstract class AppL10n {
  AppL10n(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppL10n of(BuildContext context) {
    return Localizations.of<AppL10n>(context, AppL10n)!;
  }

  static const LocalizationsDelegate<AppL10n> delegate = _AppL10nDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('he'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'ZT Privacy'**
  String get appTitle;

  /// No description provided for @phoneTestTitle.
  ///
  /// In en, this message translates to:
  /// **'Phone test'**
  String get phoneTestTitle;

  /// No description provided for @buildLabel.
  ///
  /// In en, this message translates to:
  /// **'Build {build}'**
  String buildLabel(String build);

  /// No description provided for @intro.
  ///
  /// In en, this message translates to:
  /// **'This test checks what this phone lets ZT Privacy read. What it reads stays on the phone unless you share it yourself. Run the steps, then send the summary.'**
  String get intro;

  /// No description provided for @stepReadTitle.
  ///
  /// In en, this message translates to:
  /// **'1. Read the phone'**
  String get stepReadTitle;

  /// No description provided for @stepReadBody.
  ///
  /// In en, this message translates to:
  /// **'Lists the installed apps with their permissions, who holds special access, and the settings a privacy check looks at.'**
  String get stepReadBody;

  /// No description provided for @readButton.
  ///
  /// In en, this message translates to:
  /// **'Read the phone'**
  String get readButton;

  /// No description provided for @readAgainButton.
  ///
  /// In en, this message translates to:
  /// **'Read again'**
  String get readAgainButton;

  /// No description provided for @reading.
  ///
  /// In en, this message translates to:
  /// **'Reading…'**
  String get reading;

  /// No description provided for @appsLine.
  ///
  /// In en, this message translates to:
  /// **'{total} apps, {user} of them yours'**
  String appsLine(int total, int user);

  /// No description provided for @settingsLine.
  ///
  /// In en, this message translates to:
  /// **'Settings read: {ok} of {total}'**
  String settingsLine(int ok, int total);

  /// No description provided for @accessListsLine.
  ///
  /// In en, this message translates to:
  /// **'Special access lists read: {ok} of {total}'**
  String accessListsLine(int ok, int total);

  /// No description provided for @networkOffLine.
  ///
  /// In en, this message translates to:
  /// **'Apps with the network switched off: {count}'**
  String networkOffLine(int count);

  /// No description provided for @stepFailed.
  ///
  /// In en, this message translates to:
  /// **'This step failed: {error}'**
  String stepFailed(String error);

  /// No description provided for @stepUsageTitle.
  ///
  /// In en, this message translates to:
  /// **'2. Usage access (optional)'**
  String get stepUsageTitle;

  /// No description provided for @stepUsageBody.
  ///
  /// In en, this message translates to:
  /// **'Shows when each app was last used and how much data it moved. Switch on ZT Privacy in the list, then come back.'**
  String get stepUsageBody;

  /// No description provided for @usageOn.
  ///
  /// In en, this message translates to:
  /// **'Usage access is on. Apps with a last-used time: {count}'**
  String usageOn(int count);

  /// No description provided for @usageOff.
  ///
  /// In en, this message translates to:
  /// **'Usage access is off.'**
  String get usageOff;

  /// No description provided for @openUsageAccess.
  ///
  /// In en, this message translates to:
  /// **'Open Usage access'**
  String get openUsageAccess;

  /// No description provided for @checkAgain.
  ///
  /// In en, this message translates to:
  /// **'Check again'**
  String get checkAgain;

  /// No description provided for @stepDeepTitle.
  ///
  /// In en, this message translates to:
  /// **'3. Deep mode (optional, needs a computer)'**
  String get stepDeepTitle;

  /// No description provided for @stepDeepBody.
  ///
  /// In en, this message translates to:
  /// **'Android hides which app used the camera, microphone or location. A computer can unlock it once. Connect the phone with USB debugging on, run this command, then switch USB debugging off again.'**
  String get stepDeepBody;

  /// No description provided for @copyCommand.
  ///
  /// In en, this message translates to:
  /// **'Copy the command'**
  String get copyCommand;

  /// No description provided for @copied.
  ///
  /// In en, this message translates to:
  /// **'Copied'**
  String get copied;

  /// No description provided for @deepNotGranted.
  ///
  /// In en, this message translates to:
  /// **'Not unlocked yet.'**
  String get deepNotGranted;

  /// No description provided for @deepGrantedWorks.
  ///
  /// In en, this message translates to:
  /// **'Unlocked, and the history can be read: {count} rows.'**
  String deepGrantedWorks(int count);

  /// No description provided for @deepGrantedBlocked.
  ///
  /// In en, this message translates to:
  /// **'Unlocked, but Android still refused the history. The summary has the details.'**
  String get deepGrantedBlocked;

  /// No description provided for @stepScanTitle.
  ///
  /// In en, this message translates to:
  /// **'4. Tracker scan'**
  String get stepScanTitle;

  /// No description provided for @stepScanBody.
  ///
  /// In en, this message translates to:
  /// **'Reads the class names inside each of your apps and looks for well-known tracking and advertising kits. This measures how long a full scan takes.'**
  String get stepScanBody;

  /// No description provided for @scanNeedsApps.
  ///
  /// In en, this message translates to:
  /// **'Read the phone first.'**
  String get scanNeedsApps;

  /// No description provided for @startScan.
  ///
  /// In en, this message translates to:
  /// **'Start the scan'**
  String get startScan;

  /// No description provided for @stopScan.
  ///
  /// In en, this message translates to:
  /// **'Stop'**
  String get stopScan;

  /// No description provided for @scanProgress.
  ///
  /// In en, this message translates to:
  /// **'{done} of {total} apps, {seconds} s'**
  String scanProgress(int done, int total, String seconds);

  /// No description provided for @scanDone.
  ///
  /// In en, this message translates to:
  /// **'Done: {done} apps in {seconds} s. {withKits} contain at least one kit.'**
  String scanDone(int done, String seconds, int withKits);

  /// No description provided for @scanErrors.
  ///
  /// In en, this message translates to:
  /// **'Apps that could not be read: {count}'**
  String scanErrors(int count);

  /// No description provided for @stepScreensTitle.
  ///
  /// In en, this message translates to:
  /// **'5. Android\'s own screens'**
  String get stepScreensTitle;

  /// No description provided for @stepScreensBody.
  ///
  /// In en, this message translates to:
  /// **'Checks which system screens ZT Privacy may open for you. Tap each one, then come back.'**
  String get stepScreensBody;

  /// No description provided for @screenPrivacyDashboard.
  ///
  /// In en, this message translates to:
  /// **'Privacy dashboard'**
  String get screenPrivacyDashboard;

  /// No description provided for @screenPermissionManager.
  ///
  /// In en, this message translates to:
  /// **'Permission manager'**
  String get screenPermissionManager;

  /// No description provided for @screenPrivacy.
  ///
  /// In en, this message translates to:
  /// **'Privacy settings'**
  String get screenPrivacy;

  /// No description provided for @screenAppDetails.
  ///
  /// In en, this message translates to:
  /// **'This app\'s settings'**
  String get screenAppDetails;

  /// No description provided for @screenOpened.
  ///
  /// In en, this message translates to:
  /// **'opened'**
  String get screenOpened;

  /// No description provided for @screenRefused.
  ///
  /// In en, this message translates to:
  /// **'refused'**
  String get screenRefused;

  /// No description provided for @stepSendTitle.
  ///
  /// In en, this message translates to:
  /// **'6. Send the results'**
  String get stepSendTitle;

  /// No description provided for @stepSendBody.
  ///
  /// In en, this message translates to:
  /// **'The summary holds counts only and names no app. The full report adds a line for each of your apps, so share it only if you are comfortable with that.'**
  String get stepSendBody;

  /// No description provided for @shareSummary.
  ///
  /// In en, this message translates to:
  /// **'Share the summary'**
  String get shareSummary;

  /// No description provided for @copySummary.
  ///
  /// In en, this message translates to:
  /// **'Copy the summary'**
  String get copySummary;

  /// No description provided for @saveFull.
  ///
  /// In en, this message translates to:
  /// **'Save the full report to Downloads'**
  String get saveFull;

  /// No description provided for @savedFull.
  ///
  /// In en, this message translates to:
  /// **'Saved to Downloads as {name}'**
  String savedFull(String name);

  /// No description provided for @actionFailed.
  ///
  /// In en, this message translates to:
  /// **'That did not work: {error}'**
  String actionFailed(String error);

  /// No description provided for @stepsMissing.
  ///
  /// In en, this message translates to:
  /// **'Not run yet: step {steps}. The summary is more useful with them.'**
  String stepsMissing(String steps);

  /// No description provided for @nothingYet.
  ///
  /// In en, this message translates to:
  /// **'Nothing to send yet. Run step 1 first.'**
  String get nothingYet;

  /// No description provided for @settingsTooltip.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTooltip;

  /// No description provided for @refreshTooltip.
  ///
  /// In en, this message translates to:
  /// **'Read the phone again'**
  String get refreshTooltip;

  /// No description provided for @scoreTitle.
  ///
  /// In en, this message translates to:
  /// **'Privacy score'**
  String get scoreTitle;

  /// No description provided for @scoreOutOf.
  ///
  /// In en, this message translates to:
  /// **'of 100'**
  String get scoreOutOf;

  /// No description provided for @scoreAllGood.
  ///
  /// In en, this message translates to:
  /// **'Nothing to fix. Well kept.'**
  String get scoreAllGood;

  /// No description provided for @scoreToFix.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 thing to look at} other{{count} things to look at}}'**
  String scoreToFix(int count);

  /// No description provided for @scoreExplain.
  ///
  /// In en, this message translates to:
  /// **'How the score is counted'**
  String get scoreExplain;

  /// No description provided for @phoneOnlyNote.
  ///
  /// In en, this message translates to:
  /// **'Everything here is read on this phone and stays on it.'**
  String get phoneOnlyNote;

  /// No description provided for @fixNext.
  ///
  /// In en, this message translates to:
  /// **'Fix next'**
  String get fixNext;

  /// No description provided for @allFindings.
  ///
  /// In en, this message translates to:
  /// **'Everything to look at'**
  String get allFindings;

  /// No description provided for @seeAll.
  ///
  /// In en, this message translates to:
  /// **'See all {count}'**
  String seeAll(int count);

  /// No description provided for @appsTile.
  ///
  /// In en, this message translates to:
  /// **'Apps and permissions'**
  String get appsTile;

  /// No description provided for @appsTileSub.
  ///
  /// In en, this message translates to:
  /// **'{apps} apps, {findings} to look at'**
  String appsTileSub(int apps, int findings);

  /// No description provided for @checklistTile.
  ///
  /// In en, this message translates to:
  /// **'Device checklist'**
  String get checklistTile;

  /// No description provided for @checklistTileSub.
  ///
  /// In en, this message translates to:
  /// **'{attention} to fix, {manual} to check yourself'**
  String checklistTileSub(int attention, int manual);

  /// No description provided for @usageCardTitle.
  ///
  /// In en, this message translates to:
  /// **'See which apps you no longer use'**
  String get usageCardTitle;

  /// No description provided for @usageCardBody.
  ///
  /// In en, this message translates to:
  /// **'Switch on Usage access for ZT Privacy, and it can point out apps you have not opened for 90 days that still hold permissions. This stays on the phone.'**
  String get usageCardBody;

  /// No description provided for @usageCardButton.
  ///
  /// In en, this message translates to:
  /// **'Open Usage access'**
  String get usageCardButton;

  /// No description provided for @readFailed.
  ///
  /// In en, this message translates to:
  /// **'The phone could not be read: {error}'**
  String readFailed(String error);

  /// No description provided for @tryAgain.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get tryAgain;

  /// No description provided for @partsFailed.
  ///
  /// In en, this message translates to:
  /// **'Some parts could not be read, so they are left out: {parts}'**
  String partsFailed(String parts);

  /// No description provided for @openSetting.
  ///
  /// In en, this message translates to:
  /// **'Open the setting'**
  String get openSetting;

  /// No description provided for @openAppSettings.
  ///
  /// In en, this message translates to:
  /// **'Open the app\'s settings'**
  String get openAppSettings;

  /// No description provided for @openFailed.
  ///
  /// In en, this message translates to:
  /// **'That screen did not open: {error}'**
  String openFailed(String error);

  /// No description provided for @acceptButton.
  ///
  /// In en, this message translates to:
  /// **'I\'m fine with this'**
  String get acceptButton;

  /// No description provided for @unacceptButton.
  ///
  /// In en, this message translates to:
  /// **'Count it again'**
  String get unacceptButton;

  /// No description provided for @findingCosts.
  ///
  /// In en, this message translates to:
  /// **'{points, plural, =1{Takes 1 point off the score} other{Takes {points} points off the score}}'**
  String findingCosts(int points);

  /// No description provided for @findingAccepted.
  ///
  /// In en, this message translates to:
  /// **'You are fine with this, so it does not count.'**
  String get findingAccepted;

  /// No description provided for @saveFailed.
  ///
  /// In en, this message translates to:
  /// **'That could not be saved: {error}'**
  String saveFailed(String error);

  /// No description provided for @scoreIntro.
  ///
  /// In en, this message translates to:
  /// **'The score starts at 100. Each thing found takes points off, up to a limit for each kind. Things you are fine with cost nothing.'**
  String get scoreIntro;

  /// No description provided for @scoreLine.
  ///
  /// In en, this message translates to:
  /// **'{open} found, {points} off'**
  String scoreLine(int open, int points);

  /// No description provided for @scoreLineAccepted.
  ///
  /// In en, this message translates to:
  /// **'{count} you are fine with'**
  String scoreLineAccepted(int count);

  /// No description provided for @scoreNoLines.
  ///
  /// In en, this message translates to:
  /// **'Nothing was found, so nothing is taken off.'**
  String get scoreNoLines;

  /// No description provided for @tabByPermission.
  ///
  /// In en, this message translates to:
  /// **'By permission'**
  String get tabByPermission;

  /// No description provided for @tabByApp.
  ///
  /// In en, this message translates to:
  /// **'By app'**
  String get tabByApp;

  /// No description provided for @searchApps.
  ///
  /// In en, this message translates to:
  /// **'Search apps'**
  String get searchApps;

  /// No description provided for @showSystem.
  ///
  /// In en, this message translates to:
  /// **'Show system apps'**
  String get showSystem;

  /// No description provided for @sectionPermissions.
  ///
  /// In en, this message translates to:
  /// **'Permissions'**
  String get sectionPermissions;

  /// No description provided for @sectionSpecial.
  ///
  /// In en, this message translates to:
  /// **'Special access'**
  String get sectionSpecial;

  /// No description provided for @heldBy.
  ///
  /// In en, this message translates to:
  /// **'Held by {holding}, asked for by {asking}'**
  String heldBy(int holding, int asking);

  /// No description provided for @heldByOnly.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No app} =1{1 app} other{{count} apps}}'**
  String heldByOnly(int count);

  /// No description provided for @noAppHolds.
  ///
  /// In en, this message translates to:
  /// **'No app of yours holds this.'**
  String get noAppHolds;

  /// No description provided for @noAppsMatch.
  ///
  /// In en, this message translates to:
  /// **'No app matches.'**
  String get noAppsMatch;

  /// No description provided for @appToLookAt.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 to look at} other{{count} to look at}}'**
  String appToLookAt(int count);

  /// No description provided for @appSystem.
  ///
  /// In en, this message translates to:
  /// **'Part of the system'**
  String get appSystem;

  /// No description provided for @appInstalledFrom.
  ///
  /// In en, this message translates to:
  /// **'Installed by {installer}'**
  String appInstalledFrom(String installer);

  /// No description provided for @appInstalledFromUnknown.
  ///
  /// In en, this message translates to:
  /// **'Android does not say who installed it'**
  String get appInstalledFromUnknown;

  /// No description provided for @appBuiltFor.
  ///
  /// In en, this message translates to:
  /// **'Built for Android {version}'**
  String appBuiltFor(String version);

  /// No description provided for @appInstalledOn.
  ///
  /// In en, this message translates to:
  /// **'Installed {date}'**
  String appInstalledOn(String date);

  /// No description provided for @appUpdatedOn.
  ///
  /// In en, this message translates to:
  /// **'Last updated {date}'**
  String appUpdatedOn(String date);

  /// No description provided for @appLastUsed.
  ///
  /// In en, this message translates to:
  /// **'Last used {date}'**
  String appLastUsed(String date);

  /// No description provided for @appNotUsed.
  ///
  /// In en, this message translates to:
  /// **'Not used in the last 90 days'**
  String get appNotUsed;

  /// No description provided for @appHoldsTitle.
  ///
  /// In en, this message translates to:
  /// **'What it holds'**
  String get appHoldsTitle;

  /// No description provided for @appHoldsNothing.
  ///
  /// In en, this message translates to:
  /// **'None of the permissions ZT Privacy watches.'**
  String get appHoldsNothing;

  /// No description provided for @appFindingsTitle.
  ///
  /// In en, this message translates to:
  /// **'To look at'**
  String get appFindingsTitle;

  /// No description provided for @appNoFindings.
  ///
  /// In en, this message translates to:
  /// **'Nothing to point out.'**
  String get appNoFindings;

  /// No description provided for @checksRead.
  ///
  /// In en, this message translates to:
  /// **'Read from the phone'**
  String get checksRead;

  /// No description provided for @checksManual.
  ///
  /// In en, this message translates to:
  /// **'To check yourself'**
  String get checksManual;

  /// No description provided for @checksManualHint.
  ///
  /// In en, this message translates to:
  /// **'Android does not let an app read these. Open the setting, look, and tick it off.'**
  String get checksManualHint;

  /// No description provided for @checksGraphene.
  ///
  /// In en, this message translates to:
  /// **'GrapheneOS'**
  String get checksGraphene;

  /// No description provided for @stateUnknown.
  ///
  /// In en, this message translates to:
  /// **'Android does not say'**
  String get stateUnknown;

  /// No description provided for @valueOn.
  ///
  /// In en, this message translates to:
  /// **'On'**
  String get valueOn;

  /// No description provided for @valueOff.
  ///
  /// In en, this message translates to:
  /// **'Off'**
  String get valueOff;

  /// No description provided for @stateGood.
  ///
  /// In en, this message translates to:
  /// **'Good'**
  String get stateGood;

  /// No description provided for @stateAttention.
  ///
  /// In en, this message translates to:
  /// **'Worth changing'**
  String get stateAttention;

  /// No description provided for @markChecked.
  ///
  /// In en, this message translates to:
  /// **'I checked this'**
  String get markChecked;

  /// No description provided for @settingsPhoneTest.
  ///
  /// In en, this message translates to:
  /// **'Phone test'**
  String get settingsPhoneTest;

  /// No description provided for @settingsPhoneTestHint.
  ///
  /// In en, this message translates to:
  /// **'What Android lets ZT Privacy read on this phone'**
  String get settingsPhoneTestHint;

  /// No description provided for @permLocationPrecise.
  ///
  /// In en, this message translates to:
  /// **'Location, precise'**
  String get permLocationPrecise;

  /// No description provided for @permLocationApprox.
  ///
  /// In en, this message translates to:
  /// **'Location, approximate'**
  String get permLocationApprox;

  /// No description provided for @permLocationAlways.
  ///
  /// In en, this message translates to:
  /// **'Location, all the time'**
  String get permLocationAlways;

  /// No description provided for @permCamera.
  ///
  /// In en, this message translates to:
  /// **'Camera'**
  String get permCamera;

  /// No description provided for @permMicrophone.
  ///
  /// In en, this message translates to:
  /// **'Microphone'**
  String get permMicrophone;

  /// No description provided for @permContacts.
  ///
  /// In en, this message translates to:
  /// **'Contacts'**
  String get permContacts;

  /// No description provided for @permCalendar.
  ///
  /// In en, this message translates to:
  /// **'Calendar'**
  String get permCalendar;

  /// No description provided for @permSms.
  ///
  /// In en, this message translates to:
  /// **'Text messages'**
  String get permSms;

  /// No description provided for @permCallLog.
  ///
  /// In en, this message translates to:
  /// **'Call log'**
  String get permCallLog;

  /// No description provided for @permPhoneState.
  ///
  /// In en, this message translates to:
  /// **'Phone number and call state'**
  String get permPhoneState;

  /// No description provided for @permPhotos.
  ///
  /// In en, this message translates to:
  /// **'Photos and videos'**
  String get permPhotos;

  /// No description provided for @permFilesOld.
  ///
  /// In en, this message translates to:
  /// **'Files (the old way)'**
  String get permFilesOld;

  /// No description provided for @permNearby.
  ///
  /// In en, this message translates to:
  /// **'Nearby devices'**
  String get permNearby;

  /// No description provided for @permBodySensors.
  ///
  /// In en, this message translates to:
  /// **'Body sensors'**
  String get permBodySensors;

  /// No description provided for @permActivity.
  ///
  /// In en, this message translates to:
  /// **'Physical activity'**
  String get permActivity;

  /// No description provided for @permNotifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get permNotifications;

  /// No description provided for @ruleNoScreenLock.
  ///
  /// In en, this message translates to:
  /// **'Screen lock'**
  String get ruleNoScreenLock;

  /// No description provided for @findingNoScreenLock.
  ///
  /// In en, this message translates to:
  /// **'The phone has no screen lock'**
  String get findingNoScreenLock;

  /// No description provided for @whyNoScreenLock.
  ///
  /// In en, this message translates to:
  /// **'Anyone who picks up the phone can open everything on it. Set a PIN or a password.'**
  String get whyNoScreenLock;

  /// No description provided for @ruleOldSecurityPatch.
  ///
  /// In en, this message translates to:
  /// **'Security updates'**
  String get ruleOldSecurityPatch;

  /// No description provided for @findingOldSecurityPatch.
  ///
  /// In en, this message translates to:
  /// **'Last security update: {date}'**
  String findingOldSecurityPatch(String date);

  /// No description provided for @whyOldSecurityPatch.
  ///
  /// In en, this message translates to:
  /// **'Security updates close holes that are already known. More than 90 days without one is a long time. Check for a system update. If none is offered, the phone may no longer get them.'**
  String get whyOldSecurityPatch;

  /// No description provided for @ruleUsbDebugging.
  ///
  /// In en, this message translates to:
  /// **'USB debugging'**
  String get ruleUsbDebugging;

  /// No description provided for @findingUsbDebugging.
  ///
  /// In en, this message translates to:
  /// **'USB debugging is on'**
  String get findingUsbDebugging;

  /// No description provided for @whyUsbDebugging.
  ///
  /// In en, this message translates to:
  /// **'With USB debugging on, a computer the phone is plugged into can read and change almost everything, once you allow it. Switch it off when you are not using it.'**
  String get whyUsbDebugging;

  /// No description provided for @ruleWirelessDebugging.
  ///
  /// In en, this message translates to:
  /// **'Wireless debugging'**
  String get ruleWirelessDebugging;

  /// No description provided for @findingWirelessDebugging.
  ///
  /// In en, this message translates to:
  /// **'Wireless debugging is on'**
  String get findingWirelessDebugging;

  /// No description provided for @whyWirelessDebugging.
  ///
  /// In en, this message translates to:
  /// **'With wireless debugging on, a paired computer on the same Wi-Fi can read and change almost everything on the phone. Switch it off when you are not using it.'**
  String get whyWirelessDebugging;

  /// No description provided for @ruleDeveloperOptions.
  ///
  /// In en, this message translates to:
  /// **'Developer options'**
  String get ruleDeveloperOptions;

  /// No description provided for @findingDeveloperOptions.
  ///
  /// In en, this message translates to:
  /// **'Developer options are on'**
  String get findingDeveloperOptions;

  /// No description provided for @whyDeveloperOptions.
  ///
  /// In en, this message translates to:
  /// **'Developer options hold switches that weaken the phone\'s protections. If you are not using them, switch them off.'**
  String get whyDeveloperOptions;

  /// No description provided for @ruleLockScreenContent.
  ///
  /// In en, this message translates to:
  /// **'Messages on the lock screen'**
  String get ruleLockScreenContent;

  /// No description provided for @findingLockScreenContent.
  ///
  /// In en, this message translates to:
  /// **'Message text shows on the lock screen'**
  String get findingLockScreenContent;

  /// No description provided for @whyLockScreenContent.
  ///
  /// In en, this message translates to:
  /// **'Anyone who sees the locked phone can read your messages and sign-in codes as they arrive. Choose to hide sensitive content on the lock screen.'**
  String get whyLockScreenContent;

  /// No description provided for @ruleWifiScanning.
  ///
  /// In en, this message translates to:
  /// **'Wi-Fi scanning'**
  String get ruleWifiScanning;

  /// No description provided for @findingWifiScanning.
  ///
  /// In en, this message translates to:
  /// **'Wi-Fi scanning stays on when Wi-Fi is off'**
  String get findingWifiScanning;

  /// No description provided for @whyWifiScanning.
  ///
  /// In en, this message translates to:
  /// **'Apps and services can look for Wi-Fi networks even when Wi-Fi is switched off, which can be used to work out where you are.'**
  String get whyWifiScanning;

  /// No description provided for @ruleBluetoothScanning.
  ///
  /// In en, this message translates to:
  /// **'Bluetooth scanning'**
  String get ruleBluetoothScanning;

  /// No description provided for @findingBluetoothScanning.
  ///
  /// In en, this message translates to:
  /// **'Bluetooth scanning stays on when Bluetooth is off'**
  String get findingBluetoothScanning;

  /// No description provided for @whyBluetoothScanning.
  ///
  /// In en, this message translates to:
  /// **'Apps and services can look for Bluetooth devices even when Bluetooth is switched off, which can be used to work out where you are.'**
  String get whyBluetoothScanning;

  /// No description provided for @ruleAccessibility.
  ///
  /// In en, this message translates to:
  /// **'Accessibility services'**
  String get ruleAccessibility;

  /// No description provided for @findingAccessibility.
  ///
  /// In en, this message translates to:
  /// **'{app} can read and control the screen'**
  String findingAccessibility(String app);

  /// No description provided for @whyAccessibility.
  ///
  /// In en, this message translates to:
  /// **'An accessibility service can read everything on the screen, including passwords and messages, and tap for you. Keep it only for apps you trust completely, such as a password manager or a screen reader you use.'**
  String get whyAccessibility;

  /// No description provided for @ruleDeviceAdmin.
  ///
  /// In en, this message translates to:
  /// **'Device admin apps'**
  String get ruleDeviceAdmin;

  /// No description provided for @findingDeviceAdmin.
  ///
  /// In en, this message translates to:
  /// **'{app} is a device admin'**
  String findingDeviceAdmin(String app);

  /// No description provided for @whyDeviceAdmin.
  ///
  /// In en, this message translates to:
  /// **'A device admin can change the screen lock rules, lock the phone or erase it, and is harder to uninstall. Keep it only for an app you chose for that job.'**
  String get whyDeviceAdmin;

  /// No description provided for @ruleNotificationAccess.
  ///
  /// In en, this message translates to:
  /// **'Notification access'**
  String get ruleNotificationAccess;

  /// No description provided for @findingNotificationAccess.
  ///
  /// In en, this message translates to:
  /// **'{app} can read all notifications'**
  String findingNotificationAccess(String app);

  /// No description provided for @whyNotificationAccess.
  ///
  /// In en, this message translates to:
  /// **'This app can read every notification, including messages and sign-in codes, and dismiss them. Keep it only for apps that need it, such as a watch or a car connection.'**
  String get whyNotificationAccess;

  /// No description provided for @ruleBackgroundLocation.
  ///
  /// In en, this message translates to:
  /// **'Location all the time'**
  String get ruleBackgroundLocation;

  /// No description provided for @findingBackgroundLocation.
  ///
  /// In en, this message translates to:
  /// **'{app} can see your location all the time'**
  String findingBackgroundLocation(String app);

  /// No description provided for @whyBackgroundLocation.
  ///
  /// In en, this message translates to:
  /// **'This app can see where you are even when you are not using it. Most apps work with \"Only while using the app\".'**
  String get whyBackgroundLocation;

  /// No description provided for @ruleSms.
  ///
  /// In en, this message translates to:
  /// **'Text messages'**
  String get ruleSms;

  /// No description provided for @findingSms.
  ///
  /// In en, this message translates to:
  /// **'{app} can read your text messages'**
  String findingSms(String app);

  /// No description provided for @whySms.
  ///
  /// In en, this message translates to:
  /// **'Text messages often carry sign-in codes. Only your messaging app needs to read them.'**
  String get whySms;

  /// No description provided for @ruleCallLog.
  ///
  /// In en, this message translates to:
  /// **'Call log'**
  String get ruleCallLog;

  /// No description provided for @findingCallLog.
  ///
  /// In en, this message translates to:
  /// **'{app} can read your call log'**
  String findingCallLog(String app);

  /// No description provided for @whyCallLog.
  ///
  /// In en, this message translates to:
  /// **'The call log shows who you speak to and when. Only your phone app needs it.'**
  String get whyCallLog;

  /// No description provided for @ruleAllFiles.
  ///
  /// In en, this message translates to:
  /// **'All files access'**
  String get ruleAllFiles;

  /// No description provided for @findingAllFiles.
  ///
  /// In en, this message translates to:
  /// **'{app} can read all your files'**
  String findingAllFiles(String app);

  /// No description provided for @whyAllFiles.
  ///
  /// In en, this message translates to:
  /// **'This app can read and change every file in shared storage: photos, downloads, documents. A file manager needs it; most apps do not.'**
  String get whyAllFiles;

  /// No description provided for @ruleOverlay.
  ///
  /// In en, this message translates to:
  /// **'Display over other apps'**
  String get ruleOverlay;

  /// No description provided for @findingOverlay.
  ///
  /// In en, this message translates to:
  /// **'{app} can draw over other apps'**
  String findingOverlay(String app);

  /// No description provided for @whyOverlay.
  ///
  /// In en, this message translates to:
  /// **'This app can draw on top of other apps. That can be used to cover what you see or to trick you into tapping.'**
  String get whyOverlay;

  /// No description provided for @ruleInstallsApps.
  ///
  /// In en, this message translates to:
  /// **'Installing other apps'**
  String get ruleInstallsApps;

  /// No description provided for @findingInstallsApps.
  ///
  /// In en, this message translates to:
  /// **'{app} can install other apps'**
  String findingInstallsApps(String app);

  /// No description provided for @whyInstallsApps.
  ///
  /// In en, this message translates to:
  /// **'This app can ask to install other apps from outside your app store. Keep it for the store or browser you install from.'**
  String get whyInstallsApps;

  /// No description provided for @ruleUsageAccess.
  ///
  /// In en, this message translates to:
  /// **'Usage access'**
  String get ruleUsageAccess;

  /// No description provided for @findingUsageAccess.
  ///
  /// In en, this message translates to:
  /// **'{app} can see which apps you use'**
  String findingUsageAccess(String app);

  /// No description provided for @whyUsageAccess.
  ///
  /// In en, this message translates to:
  /// **'This app can see which apps you use, when and for how long.'**
  String get whyUsageAccess;

  /// No description provided for @ruleOldTarget.
  ///
  /// In en, this message translates to:
  /// **'Built for an old Android'**
  String get ruleOldTarget;

  /// No description provided for @findingOldTarget.
  ///
  /// In en, this message translates to:
  /// **'{app} was built for Android {version}'**
  String findingOldTarget(String app, String version);

  /// No description provided for @whyOldTarget.
  ///
  /// In en, this message translates to:
  /// **'Apps built for Android 10 or older skip protections added since, such as limits on reading files and the automatic removal of unused permissions.'**
  String get whyOldTarget;

  /// No description provided for @ruleNotUpdated.
  ///
  /// In en, this message translates to:
  /// **'Not updated for two years'**
  String get ruleNotUpdated;

  /// No description provided for @findingNotUpdated.
  ///
  /// In en, this message translates to:
  /// **'{app} has not been updated for over {years} years'**
  String findingNotUpdated(String app, int years);

  /// No description provided for @whyNotUpdated.
  ///
  /// In en, this message translates to:
  /// **'An app with no updates for two years is probably no longer looked after, so known problems in it stay open.'**
  String get whyNotUpdated;

  /// No description provided for @ruleUnused.
  ///
  /// In en, this message translates to:
  /// **'Unused apps with permissions'**
  String get ruleUnused;

  /// No description provided for @findingUnused.
  ///
  /// In en, this message translates to:
  /// **'{app} has not been used for 90 days'**
  String findingUnused(String app);

  /// No description provided for @whyUnused.
  ///
  /// In en, this message translates to:
  /// **'You have not opened this app for 90 days, and it still holds permissions. Remove it, or take the permissions away.'**
  String get whyUnused;

  /// No description provided for @checkScreenLock.
  ///
  /// In en, this message translates to:
  /// **'Screen lock'**
  String get checkScreenLock;

  /// No description provided for @checkEncryption.
  ///
  /// In en, this message translates to:
  /// **'Storage encryption'**
  String get checkEncryption;

  /// No description provided for @checkWhyEncryption.
  ///
  /// In en, this message translates to:
  /// **'Everything stored on the phone is encrypted, and opens only with your screen lock.'**
  String get checkWhyEncryption;

  /// No description provided for @checkSecurityPatch.
  ///
  /// In en, this message translates to:
  /// **'Security update'**
  String get checkSecurityPatch;

  /// No description provided for @checkUsbDebugging.
  ///
  /// In en, this message translates to:
  /// **'USB debugging'**
  String get checkUsbDebugging;

  /// No description provided for @checkWirelessDebugging.
  ///
  /// In en, this message translates to:
  /// **'Wireless debugging'**
  String get checkWirelessDebugging;

  /// No description provided for @checkDeveloperOptions.
  ///
  /// In en, this message translates to:
  /// **'Developer options'**
  String get checkDeveloperOptions;

  /// No description provided for @checkLockScreenContent.
  ///
  /// In en, this message translates to:
  /// **'Message text on the lock screen'**
  String get checkLockScreenContent;

  /// No description provided for @checkWifiScanning.
  ///
  /// In en, this message translates to:
  /// **'Wi-Fi scanning while Wi-Fi is off'**
  String get checkWifiScanning;

  /// No description provided for @checkBluetoothScanning.
  ///
  /// In en, this message translates to:
  /// **'Bluetooth scanning while Bluetooth is off'**
  String get checkBluetoothScanning;

  /// No description provided for @checkPrivateDns.
  ///
  /// In en, this message translates to:
  /// **'Private DNS'**
  String get checkPrivateDns;

  /// No description provided for @checkWhyPrivateDns.
  ///
  /// In en, this message translates to:
  /// **'Private DNS hides the names of the sites you look up from the network you are on, and can block trackers if you pick a filtering service.'**
  String get checkWhyPrivateDns;

  /// No description provided for @checkVpn.
  ///
  /// In en, this message translates to:
  /// **'VPN'**
  String get checkVpn;

  /// No description provided for @checkWhyVpn.
  ///
  /// In en, this message translates to:
  /// **'A VPN hides what you do from the network you are on, and your address from the sites you visit. It moves that trust to the VPN provider.'**
  String get checkWhyVpn;

  /// No description provided for @checkAdvancedProtection.
  ///
  /// In en, this message translates to:
  /// **'Advanced Protection'**
  String get checkAdvancedProtection;

  /// No description provided for @checkWhyAdvancedProtection.
  ///
  /// In en, this message translates to:
  /// **'Android\'s Advanced Protection switches on its strongest safeguards at once. Worth it if you are at higher risk.'**
  String get checkWhyAdvancedProtection;

  /// No description provided for @checkAlwaysOnVpn.
  ///
  /// In en, this message translates to:
  /// **'VPN always on, with nothing allowed outside it'**
  String get checkAlwaysOnVpn;

  /// No description provided for @checkWhyAlwaysOnVpn.
  ///
  /// In en, this message translates to:
  /// **'With \"Always-on VPN\" and \"Block connections without VPN\", nothing leaves the phone outside the VPN, not even for a moment while it reconnects. Android does not let apps read this setting.'**
  String get checkWhyAlwaysOnVpn;

  /// No description provided for @checkAdvertisingId.
  ///
  /// In en, this message translates to:
  /// **'Advertising ID deleted'**
  String get checkAdvertisingId;

  /// No description provided for @checkWhyAdvertisingId.
  ///
  /// In en, this message translates to:
  /// **'The advertising ID lets apps link what you do across them. Delete it under Settings, Privacy, Ads.'**
  String get checkWhyAdvertisingId;

  /// No description provided for @checkAutoReboot.
  ///
  /// In en, this message translates to:
  /// **'Auto reboot'**
  String get checkAutoReboot;

  /// No description provided for @checkWhyAutoReboot.
  ///
  /// In en, this message translates to:
  /// **'GrapheneOS can restart the phone when it has not been unlocked for a while, which puts your data back at rest, fully encrypted. Look under Settings, Security & privacy, Exploit protection.'**
  String get checkWhyAutoReboot;

  /// No description provided for @checkUsbPort.
  ///
  /// In en, this message translates to:
  /// **'USB-C port closed while the phone is locked'**
  String get checkUsbPort;

  /// No description provided for @checkWhyUsbPort.
  ///
  /// In en, this message translates to:
  /// **'GrapheneOS can refuse new USB connections while the phone is locked. Look under Settings, Security & privacy, Exploit protection.'**
  String get checkWhyUsbPort;

  /// No description provided for @checkWifiAutoOff.
  ///
  /// In en, this message translates to:
  /// **'Wi-Fi switches itself off when not connected'**
  String get checkWifiAutoOff;

  /// No description provided for @checkWhyWifiAutoOff.
  ///
  /// In en, this message translates to:
  /// **'GrapheneOS can switch Wi-Fi off after it has had no connection for a while. Look under Settings, Network & internet, Internet, Network preferences.'**
  String get checkWhyWifiAutoOff;

  /// No description provided for @checkBluetoothAutoOff.
  ///
  /// In en, this message translates to:
  /// **'Bluetooth switches itself off when not connected'**
  String get checkBluetoothAutoOff;

  /// No description provided for @checkWhyBluetoothAutoOff.
  ///
  /// In en, this message translates to:
  /// **'GrapheneOS can switch Bluetooth off after it has had no connection for a while. Look under Settings, Connected devices, Connection preferences, Bluetooth.'**
  String get checkWhyBluetoothAutoOff;

  /// No description provided for @checkPinScrambling.
  ///
  /// In en, this message translates to:
  /// **'Scrambled PIN keypad'**
  String get checkPinScrambling;

  /// No description provided for @checkWhyPinScrambling.
  ///
  /// In en, this message translates to:
  /// **'A keypad with the digits in a new order each time stops someone learning your PIN from where you tap. Look under Settings, Security & privacy, Device unlock.'**
  String get checkWhyPinScrambling;

  /// No description provided for @checkDuressPin.
  ///
  /// In en, this message translates to:
  /// **'Duress PIN'**
  String get checkDuressPin;

  /// No description provided for @checkWhyDuressPin.
  ///
  /// In en, this message translates to:
  /// **'A second PIN that erases the phone when it is entered. Look under Settings, Security & privacy, Device unlock.'**
  String get checkWhyDuressPin;

  /// No description provided for @checkNetworkSensors.
  ///
  /// In en, this message translates to:
  /// **'Network and Sensors permissions reviewed'**
  String get checkNetworkSensors;

  /// No description provided for @checkWhyNetworkSensors.
  ///
  /// In en, this message translates to:
  /// **'On GrapheneOS every app has a Network and a Sensors permission that you can switch off. Go through your apps and take them away where an app has no need for them.'**
  String get checkWhyNetworkSensors;

  /// No description provided for @findingCostsEach.
  ///
  /// In en, this message translates to:
  /// **'Each one takes {points} off the score, and all of this kind together {cap} at most.'**
  String findingCostsEach(int points, int cap);

  /// No description provided for @acceptedHeading.
  ///
  /// In en, this message translates to:
  /// **'You are fine with these'**
  String get acceptedHeading;

  /// No description provided for @nothingToLookAt.
  ///
  /// In en, this message translates to:
  /// **'Nothing to look at here.'**
  String get nothingToLookAt;

  /// No description provided for @aboutThisApp.
  ///
  /// In en, this message translates to:
  /// **'About this app'**
  String get aboutThisApp;

  /// No description provided for @readingPhone.
  ///
  /// In en, this message translates to:
  /// **'Reading the phone…'**
  String get readingPhone;

  /// No description provided for @lastUsedNeedsAccess.
  ///
  /// In en, this message translates to:
  /// **'Switch on Usage access to see when it was last used'**
  String get lastUsedNeedsAccess;

  /// No description provided for @lastUsedUnknown.
  ///
  /// In en, this message translates to:
  /// **'Android did not say when it was last used'**
  String get lastUsedUnknown;

  /// No description provided for @holdersTitle.
  ///
  /// In en, this message translates to:
  /// **'Apps that hold this'**
  String get holdersTitle;

  /// No description provided for @trackersTile.
  ///
  /// In en, this message translates to:
  /// **'Trackers'**
  String get trackersTile;

  /// No description provided for @trackersTileWaiting.
  ///
  /// In en, this message translates to:
  /// **'Getting ready…'**
  String get trackersTileWaiting;

  /// No description provided for @trackersScanning.
  ///
  /// In en, this message translates to:
  /// **'Checking apps: {done} of {total}'**
  String trackersScanning(int done, int total);

  /// No description provided for @trackersTileSub.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No tracker code found in your {apps} apps} =1{1 of your {apps} apps contains tracker code} other{{count} of your {apps} apps contain tracker code}}'**
  String trackersTileSub(int count, int apps);

  /// No description provided for @trackersIntro.
  ///
  /// In en, this message translates to:
  /// **'A tracker is code made to collect data about you or about how you use an app. ZT Privacy reads the names of the code inside each app on this phone and compares them with Exodus Privacy\'s list of known trackers. Nothing is sent anywhere: the list is inside this app.'**
  String get trackersIntro;

  /// No description provided for @trackersCaveat.
  ///
  /// In en, this message translates to:
  /// **'This shows that the code is in the app. It does not prove that the code runs, or what it sends. Code whose names were scrambled cannot be seen.'**
  String get trackersCaveat;

  /// No description provided for @trackersCredit.
  ///
  /// In en, this message translates to:
  /// **'Tracker list: Exodus Privacy, under the Open Database License (ODbL 1.0). {count} trackers, newest entry {date}.'**
  String trackersCredit(int count, String date);

  /// No description provided for @tabByTracker.
  ///
  /// In en, this message translates to:
  /// **'By tracker'**
  String get tabByTracker;

  /// No description provided for @appTrackerCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Code from 1 tracker} other{Code from {count} trackers}}'**
  String appTrackerCount(int count);

  /// No description provided for @appNoTrackers.
  ///
  /// In en, this message translates to:
  /// **'No tracker code found'**
  String get appNoTrackers;

  /// No description provided for @appNotChecked.
  ///
  /// In en, this message translates to:
  /// **'Not checked yet'**
  String get appNotChecked;

  /// No description provided for @appUnreadable.
  ///
  /// In en, this message translates to:
  /// **'Its code could not be read'**
  String get appUnreadable;

  /// No description provided for @noTrackersAnywhere.
  ///
  /// In en, this message translates to:
  /// **'No tracker code was found in these apps.'**
  String get noTrackersAnywhere;

  /// No description provided for @noTrackersYet.
  ///
  /// In en, this message translates to:
  /// **'No tracker code found so far.'**
  String get noTrackersYet;

  /// No description provided for @trackerInApps.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{In 1 app} other{In {count} apps}}'**
  String trackerInApps(int count);

  /// No description provided for @appTrackersTitle.
  ///
  /// In en, this message translates to:
  /// **'Tracker code'**
  String get appTrackersTitle;

  /// No description provided for @appTrackersFound.
  ///
  /// In en, this message translates to:
  /// **'Contains code from:'**
  String get appTrackersFound;

  /// No description provided for @appTrackersNone.
  ///
  /// In en, this message translates to:
  /// **'No code from known trackers was found in this app.'**
  String get appTrackersNone;

  /// No description provided for @appTrackersNotChecked.
  ///
  /// In en, this message translates to:
  /// **'This app has not been checked yet.'**
  String get appTrackersNotChecked;

  /// No description provided for @appTrackersUnreadable.
  ///
  /// In en, this message translates to:
  /// **'ZT Privacy could not read this app\'s code.'**
  String get appTrackersUnreadable;

  /// No description provided for @kindAds.
  ///
  /// In en, this message translates to:
  /// **'Advertising'**
  String get kindAds;

  /// No description provided for @kindAnalytics.
  ///
  /// In en, this message translates to:
  /// **'Analytics'**
  String get kindAnalytics;

  /// No description provided for @kindLocation.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get kindLocation;

  /// No description provided for @kindProfiling.
  ///
  /// In en, this message translates to:
  /// **'Profiling'**
  String get kindProfiling;

  /// No description provided for @kindIdentification.
  ///
  /// In en, this message translates to:
  /// **'Identification'**
  String get kindIdentification;

  /// No description provided for @kindCrashReporting.
  ///
  /// In en, this message translates to:
  /// **'Crash reporting'**
  String get kindCrashReporting;

  /// No description provided for @kindUnknown.
  ///
  /// In en, this message translates to:
  /// **'Kind not stated'**
  String get kindUnknown;

  /// No description provided for @trackerAppsTitle.
  ///
  /// In en, this message translates to:
  /// **'Apps that contain this code'**
  String get trackerAppsTitle;

  /// No description provided for @trackerNoApps.
  ///
  /// In en, this message translates to:
  /// **'No app on this list contains it now.'**
  String get trackerNoApps;

  /// No description provided for @trackerReadMore.
  ///
  /// In en, this message translates to:
  /// **'Read about it at Exodus Privacy'**
  String get trackerReadMore;

  /// No description provided for @ruleTrackerCode.
  ///
  /// In en, this message translates to:
  /// **'Tracker code with permissions'**
  String get ruleTrackerCode;

  /// No description provided for @findingTrackerCode.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{{app} contains code from 1 tracker and holds sensitive permissions} other{{app} contains code from {count} trackers and holds sensitive permissions}}'**
  String findingTrackerCode(String app, int count);

  /// No description provided for @whyTrackerCode.
  ///
  /// In en, this message translates to:
  /// **'This app contains code made for advertising, analytics or the like, and it also holds a permission that tells it something about you, such as location, contacts, camera or microphone. Finding the code does not prove that it runs or what it sends. The two together are still worth a look: take away the permissions the app does not need, or look for an app without this code.'**
  String get whyTrackerCode;
}

class _AppL10nDelegate extends LocalizationsDelegate<AppL10n> {
  const _AppL10nDelegate();

  @override
  Future<AppL10n> load(Locale locale) {
    return SynchronousFuture<AppL10n>(lookupAppL10n(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'he'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppL10nDelegate old) => false;
}

AppL10n lookupAppL10n(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppL10nEn();
    case 'he':
      return AppL10nHe();
  }

  throw FlutterError(
    'AppL10n.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
