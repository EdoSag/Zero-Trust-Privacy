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
  /// **'This build checks what this phone lets ZT Privacy read. Nothing leaves the phone: the app has no network permission. Run the steps, then send the summary.'**
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

  /// No description provided for @nothingYet.
  ///
  /// In en, this message translates to:
  /// **'Nothing to send yet. Run step 1 first.'**
  String get nothingYet;
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
