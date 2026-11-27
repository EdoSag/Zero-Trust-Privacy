// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_l10n.dart';

// ignore_for_file: type=lint

/// The translations for Hebrew (`he`).
class AppL10nHe extends AppL10n {
  AppL10nHe([String locale = 'he']) : super(locale);

  @override
  String get appTitle => 'ZT Privacy';

  @override
  String get phoneTestTitle => 'בדיקת טלפון';

  @override
  String buildLabel(String build) {
    return 'גרסת בנייה $build';
  }

  @override
  String get intro =>
      'הבדיקה הזו בודקת מה הטלפון הזה מאפשר ל-ZT Privacy לקרוא. מה שנקרא נשאר בטלפון, אלא אם משתפים אותו בעצמך. יש להריץ את השלבים ואז לשלוח את הסיכום.';

  @override
  String get stepReadTitle => '1. קריאת הטלפון';

  @override
  String get stepReadBody =>
      'מציג את האפליקציות המותקנות וההרשאות שלהן, למי יש גישה מיוחדת, ואת ההגדרות שבדיקת פרטיות מסתכלת עליהן.';

  @override
  String get readButton => 'קריאת הטלפון';

  @override
  String get readAgainButton => 'קריאה חוזרת';

  @override
  String get reading => 'קורא…';

  @override
  String appsLine(int total, int user) {
    return '$total אפליקציות, $user מהן שלך';
  }

  @override
  String settingsLine(int ok, int total) {
    return 'הגדרות שנקראו: $ok מתוך $total';
  }

  @override
  String accessListsLine(int ok, int total) {
    return 'רשימות גישה מיוחדת שנקראו: $ok מתוך $total';
  }

  @override
  String networkOffLine(int count) {
    return 'אפליקציות שהרשת כבויה אצלן: $count';
  }

  @override
  String stepFailed(String error) {
    return 'השלב נכשל: $error';
  }

  @override
  String get stepUsageTitle => '2. גישה לנתוני שימוש (לא חובה)';

  @override
  String get stepUsageBody =>
      'מראה מתי כל אפליקציה הייתה בשימוש לאחרונה וכמה נתונים העבירה. מפעילים את ZT Privacy ברשימה וחוזרים לכאן.';

  @override
  String usageOn(int count) {
    return 'הגישה לנתוני שימוש פועלת. אפליקציות עם זמן שימוש אחרון: $count';
  }

  @override
  String get usageOff => 'הגישה לנתוני שימוש כבויה.';

  @override
  String get openUsageAccess => 'פתיחת גישה לנתוני שימוש';

  @override
  String get checkAgain => 'בדיקה חוזרת';

  @override
  String get stepDeepTitle => '3. מצב עמוק (לא חובה, דורש מחשב)';

  @override
  String get stepDeepBody =>
      'אנדרואיד מסתיר איזו אפליקציה השתמשה במצלמה, במיקרופון או במיקום. מחשב יכול לפתוח את זה פעם אחת. מחברים את הטלפון עם ניפוי באגים ב-USB פועל, מריצים את הפקודה הזו, ואז מכבים שוב את ניפוי הבאגים.';

  @override
  String get copyCommand => 'העתקת הפקודה';

  @override
  String get copied => 'הועתק';

  @override
  String get deepNotGranted => 'עדיין לא נפתח.';

  @override
  String deepGrantedWorks(int count) {
    return 'נפתח, ואפשר לקרוא את ההיסטוריה: $count שורות.';
  }

  @override
  String get deepGrantedBlocked =>
      'נפתח, אבל אנדרואיד עדיין סירב לתת את ההיסטוריה. הפרטים נמצאים בסיכום.';

  @override
  String get stepScanTitle => '4. סריקת רכיבי מעקב';

  @override
  String get stepScanBody =>
      'קורא את שמות המחלקות בתוך כל אחת מהאפליקציות שלך ומחפש ערכות מעקב ופרסום מוכרות. כך נמדד כמה זמן לוקחת סריקה מלאה.';

  @override
  String get scanNeedsApps => 'קודם יש לקרוא את הטלפון.';

  @override
  String get startScan => 'התחלת הסריקה';

  @override
  String get stopScan => 'עצירה';

  @override
  String scanProgress(int done, int total, String seconds) {
    return '$done מתוך $total אפליקציות, $seconds שניות';
  }

  @override
  String scanDone(int done, String seconds, int withKits) {
    return 'הסתיים: $done אפליקציות ב-$seconds שניות. ב-$withKits מהן יש לפחות ערכה אחת.';
  }

  @override
  String scanErrors(int count) {
    return 'אפליקציות שלא ניתן היה לקרוא: $count';
  }

  @override
  String get stepScreensTitle => '5. המסכים של אנדרואיד';

  @override
  String get stepScreensBody =>
      'בודק אילו מסכי מערכת ZT Privacy רשאית לפתוח עבורך. מקישים על כל אחד וחוזרים לכאן.';

  @override
  String get screenPrivacyDashboard => 'מרכז הבקרה לפרטיות';

  @override
  String get screenPermissionManager => 'מנהל ההרשאות';

  @override
  String get screenPrivacy => 'הגדרות פרטיות';

  @override
  String get screenAppDetails => 'ההגדרות של האפליקציה הזו';

  @override
  String get screenOpened => 'נפתח';

  @override
  String get screenRefused => 'נדחה';

  @override
  String get stepSendTitle => '6. שליחת התוצאות';

  @override
  String get stepSendBody =>
      'הסיכום מכיל מספרים בלבד ואינו מציין שם של אף אפליקציה. הדוח המלא מוסיף שורה לכל אחת מהאפליקציות שלך, ולכן כדאי לשתף אותו רק אם זה נוח לך.';

  @override
  String get shareSummary => 'שיתוף הסיכום';

  @override
  String get copySummary => 'העתקת הסיכום';

  @override
  String get saveFull => 'שמירת הדוח המלא בתיקיית ההורדות';

  @override
  String savedFull(String name) {
    return 'נשמר בתיקיית ההורדות בשם $name';
  }

  @override
  String actionFailed(String error) {
    return 'זה לא הצליח: $error';
  }

  @override
  String stepsMissing(String steps) {
    return 'עדיין לא הורץ: שלב $steps. הסיכום מועיל יותר איתם.';
  }

  @override
  String get nothingYet => 'אין עדיין מה לשלוח. קודם יש להריץ את שלב 1.';

  @override
  String get settingsTooltip => 'הגדרות';

  @override
  String get refreshTooltip => 'קריאה מחדש של הטלפון';

  @override
  String get scoreTitle => 'ציון פרטיות';

  @override
  String get scoreOutOf => 'מתוך 100';

  @override
  String get scoreAllGood => 'אין מה לתקן. הכול מסודר.';

  @override
  String scoreToFix(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count דברים לבדיקה',
      one: 'דבר אחד לבדיקה',
    );
    return '$_temp0';
  }

  @override
  String get scoreExplain => 'איך הציון מחושב';

  @override
  String get phoneOnlyNote => 'כל מה שכאן נקרא בטלפון הזה ונשאר בו.';

  @override
  String get fixNext => 'מה לתקן קודם';

  @override
  String get allFindings => 'כל מה שכדאי לבדוק';

  @override
  String seeAll(int count) {
    return 'הצגת כל ה-$count';
  }

  @override
  String get appsTile => 'אפליקציות והרשאות';

  @override
  String appsTileSub(int apps, int findings) {
    return '$apps אפליקציות, $findings לבדיקה';
  }

  @override
  String get checklistTile => 'רשימת בדיקה למכשיר';

  @override
  String checklistTileSub(int attention, int manual) {
    return '$attention לתיקון, $manual לבדיקה עצמית';
  }

  @override
  String get usageCardTitle => 'לראות באילו אפליקציות כבר אין שימוש';

  @override
  String get usageCardBody =>
      'אחרי הפעלת \"גישה לנתוני שימוש\" עבור ZT Privacy, האפליקציה תצביע על אפליקציות שלא נפתחו 90 יום ועדיין מחזיקות הרשאות. המידע נשאר בטלפון.';

  @override
  String get usageCardButton => 'פתיחת גישה לנתוני שימוש';

  @override
  String readFailed(String error) {
    return 'לא ניתן היה לקרוא את הטלפון: $error';
  }

  @override
  String get tryAgain => 'ניסיון נוסף';

  @override
  String partsFailed(String parts) {
    return 'חלק מהנתונים לא נקראו ולכן אינם מוצגים: $parts';
  }

  @override
  String get openSetting => 'פתיחת ההגדרה';

  @override
  String get openAppSettings => 'פתיחת הגדרות האפליקציה';

  @override
  String openFailed(String error) {
    return 'המסך לא נפתח: $error';
  }

  @override
  String get acceptButton => 'זה בסדר מבחינתי';

  @override
  String get unacceptButton => 'לספור שוב';

  @override
  String findingCosts(int points) {
    String _temp0 = intl.Intl.pluralLogic(
      points,
      locale: localeName,
      other: 'מוריד $points נקודות מהציון',
      one: 'מוריד נקודה אחת מהציון',
    );
    return '$_temp0';
  }

  @override
  String get findingAccepted => 'סימנת שזה בסדר, ולכן זה לא נספר.';

  @override
  String saveFailed(String error) {
    return 'לא ניתן היה לשמור: $error';
  }

  @override
  String get scoreIntro =>
      'הציון מתחיל ב-100. כל ממצא מוריד נקודות, עד תקרה לכל סוג. דברים שסימנת כבסדר לא מורידים דבר.';

  @override
  String scoreLine(int open, int points) {
    return '$open נמצאו, $points פחות';
  }

  @override
  String scoreLineAccepted(int count) {
    return '$count שסימנת כבסדר';
  }

  @override
  String get scoreNoLines => 'לא נמצא דבר, ולכן לא ירד דבר.';

  @override
  String get tabByPermission => 'לפי הרשאה';

  @override
  String get tabByApp => 'לפי אפליקציה';

  @override
  String get searchApps => 'חיפוש אפליקציות';

  @override
  String get showSystem => 'הצגת אפליקציות מערכת';

  @override
  String get sectionPermissions => 'הרשאות';

  @override
  String get sectionSpecial => 'גישה מיוחדת';

  @override
  String heldBy(int holding, int asking) {
    return 'מוחזקת על ידי $holding, התבקשה על ידי $asking';
  }

  @override
  String heldByOnly(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count אפליקציות',
      one: 'אפליקציה אחת',
      zero: 'אף אפליקציה',
    );
    return '$_temp0';
  }

  @override
  String get noAppHolds => 'אף אפליקציה שלך לא מחזיקה בזה.';

  @override
  String get noAppsMatch => 'אין אפליקציה מתאימה.';

  @override
  String appToLookAt(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count לבדיקה',
      one: 'אחד לבדיקה',
    );
    return '$_temp0';
  }

  @override
  String get appSystem => 'חלק מהמערכת';

  @override
  String appInstalledFrom(String installer) {
    return 'הותקנה על ידי $installer';
  }

  @override
  String get appInstalledFromUnknown => 'אנדרואיד לא מציין מי התקין אותה';

  @override
  String appBuiltFor(String version) {
    return 'נבנתה עבור אנדרואיד $version';
  }

  @override
  String appInstalledOn(String date) {
    return 'הותקנה ב-$date';
  }

  @override
  String appUpdatedOn(String date) {
    return 'עודכנה לאחרונה ב-$date';
  }

  @override
  String appLastUsed(String date) {
    return 'שימוש אחרון ב-$date';
  }

  @override
  String get appNotUsed => 'לא הייתה בשימוש ב-90 הימים האחרונים';

  @override
  String get appHoldsTitle => 'מה היא מחזיקה';

  @override
  String get appHoldsNothing => 'אף אחת מההרשאות ש-ZT Privacy עוקבת אחריהן.';

  @override
  String get appFindingsTitle => 'לבדיקה';

  @override
  String get appNoFindings => 'אין על מה להצביע.';

  @override
  String get checksRead => 'נקרא מהטלפון';

  @override
  String get checksManual => 'לבדיקה עצמית';

  @override
  String get checksManualHint =>
      'אנדרואיד לא מאפשר לאפליקציה לקרוא את אלה. יש לפתוח את ההגדרה, לבדוק ולסמן.';

  @override
  String get checksGraphene => 'GrapheneOS';

  @override
  String get stateUnknown => 'אנדרואיד לא מציין';

  @override
  String get valueOn => 'פועל';

  @override
  String get valueOff => 'כבוי';

  @override
  String get stateGood => 'תקין';

  @override
  String get stateAttention => 'כדאי לשנות';

  @override
  String get markChecked => 'בדקתי את זה';

  @override
  String get settingsPhoneTest => 'בדיקת טלפון';

  @override
  String get settingsPhoneTestHint =>
      'מה אנדרואיד מאפשר ל-ZT Privacy לקרוא בטלפון הזה';

  @override
  String get permLocationPrecise => 'מיקום מדויק';

  @override
  String get permLocationApprox => 'מיקום משוער';

  @override
  String get permLocationAlways => 'מיקום כל הזמן';

  @override
  String get permCamera => 'מצלמה';

  @override
  String get permMicrophone => 'מיקרופון';

  @override
  String get permContacts => 'אנשי קשר';

  @override
  String get permCalendar => 'יומן';

  @override
  String get permSms => 'הודעות טקסט';

  @override
  String get permCallLog => 'יומן שיחות';

  @override
  String get permPhoneState => 'מספר הטלפון ומצב השיחה';

  @override
  String get permPhotos => 'תמונות וסרטונים';

  @override
  String get permFilesOld => 'קבצים (בשיטה הישנה)';

  @override
  String get permNearby => 'מכשירים בקרבת מקום';

  @override
  String get permBodySensors => 'חיישני גוף';

  @override
  String get permActivity => 'פעילות גופנית';

  @override
  String get permNotifications => 'התראות';

  @override
  String get ruleNoScreenLock => 'נעילת מסך';

  @override
  String get findingNoScreenLock => 'בטלפון אין נעילת מסך';

  @override
  String get whyNoScreenLock =>
      'כל מי שמרים את הטלפון יכול לפתוח את כל מה שבו. כדאי להגדיר קוד או סיסמה.';

  @override
  String get ruleOldSecurityPatch => 'עדכוני אבטחה';

  @override
  String findingOldSecurityPatch(String date) {
    return 'עדכון האבטחה האחרון: $date';
  }

  @override
  String get whyOldSecurityPatch =>
      'עדכוני אבטחה סוגרים פרצות שכבר ידועות. יותר מ-90 יום בלי עדכון זה הרבה זמן. כדאי לבדוק אם יש עדכון מערכת. אם לא מוצע עדכון, ייתכן שהטלפון כבר לא מקבל עדכונים.';

  @override
  String get ruleUsbDebugging => 'ניפוי באגים ב-USB';

  @override
  String get findingUsbDebugging => 'ניפוי באגים ב-USB פועל';

  @override
  String get whyUsbDebugging =>
      'כשניפוי באגים ב-USB פועל, מחשב שהטלפון מחובר אליו יכול לקרוא ולשנות כמעט הכול, אחרי אישור שלך. כדאי לכבות כשלא משתמשים בזה.';

  @override
  String get ruleWirelessDebugging => 'ניפוי באגים אלחוטי';

  @override
  String get findingWirelessDebugging => 'ניפוי באגים אלחוטי פועל';

  @override
  String get whyWirelessDebugging =>
      'כשניפוי באגים אלחוטי פועל, מחשב מותאם באותה רשת Wi-Fi יכול לקרוא ולשנות כמעט הכול בטלפון. כדאי לכבות כשלא משתמשים בזה.';

  @override
  String get ruleDeveloperOptions => 'אפשרויות למפתחים';

  @override
  String get findingDeveloperOptions => 'אפשרויות למפתחים פועלות';

  @override
  String get whyDeveloperOptions =>
      'אפשרויות למפתחים כוללות מתגים שמחלישים את הגנות הטלפון. אם אין בהן שימוש, כדאי לכבות.';

  @override
  String get ruleLockScreenContent => 'הודעות במסך הנעילה';

  @override
  String get findingLockScreenContent => 'תוכן ההודעות מוצג במסך הנעילה';

  @override
  String get whyLockScreenContent =>
      'כל מי שרואה את הטלפון הנעול יכול לקרוא הודעות וקודי כניסה ברגע שהם מגיעים. כדאי לבחור להסתיר תוכן רגיש במסך הנעילה.';

  @override
  String get ruleWifiScanning => 'סריקת Wi-Fi';

  @override
  String get findingWifiScanning => 'סריקת Wi-Fi ממשיכה גם כש-Wi-Fi כבוי';

  @override
  String get whyWifiScanning =>
      'אפליקציות ושירותים יכולים לחפש רשתות Wi-Fi גם כש-Wi-Fi כבוי, ואפשר להסיק מזה איפה נמצאים.';

  @override
  String get ruleBluetoothScanning => 'סריקת Bluetooth';

  @override
  String get findingBluetoothScanning =>
      'סריקת Bluetooth ממשיכה גם כש-Bluetooth כבוי';

  @override
  String get whyBluetoothScanning =>
      'אפליקציות ושירותים יכולים לחפש מכשירי Bluetooth גם כש-Bluetooth כבוי, ואפשר להסיק מזה איפה נמצאים.';

  @override
  String get ruleAccessibility => 'שירותי נגישות';

  @override
  String findingAccessibility(String app) {
    return '$app יכולה לקרוא את המסך ולשלוט בו';
  }

  @override
  String get whyAccessibility =>
      'שירות נגישות יכול לקרוא כל מה שעל המסך, כולל סיסמאות והודעות, וללחוץ במקומך. כדאי להשאיר רק לאפליקציות שסומכים עליהן לגמרי, כמו מנהל סיסמאות או קורא מסך שבשימוש.';

  @override
  String get ruleDeviceAdmin => 'אפליקציות לניהול המכשיר';

  @override
  String findingDeviceAdmin(String app) {
    return '$app מנהלת את המכשיר';
  }

  @override
  String get whyDeviceAdmin =>
      'אפליקציה לניהול המכשיר יכולה לשנות את כללי נעילת המסך, לנעול את הטלפון או למחוק אותו, וקשה יותר להסיר אותה. כדאי להשאיר רק לאפליקציה שנבחרה לתפקיד הזה.';

  @override
  String get ruleNotificationAccess => 'גישה להתראות';

  @override
  String findingNotificationAccess(String app) {
    return '$app יכולה לקרוא את כל ההתראות';
  }

  @override
  String get whyNotificationAccess =>
      'האפליקציה יכולה לקרוא כל התראה, כולל הודעות וקודי כניסה, ולסגור אותן. כדאי להשאיר רק לאפליקציות שצריכות את זה, כמו שעון או חיבור לרכב.';

  @override
  String get ruleBackgroundLocation => 'מיקום כל הזמן';

  @override
  String findingBackgroundLocation(String app) {
    return '$app יכולה לראות את המיקום שלך כל הזמן';
  }

  @override
  String get whyBackgroundLocation =>
      'האפליקציה יכולה לראות איפה נמצאים גם כשלא משתמשים בה. רוב האפליקציות עובדות גם עם \"רק בזמן השימוש באפליקציה\".';

  @override
  String get ruleSms => 'הודעות טקסט';

  @override
  String findingSms(String app) {
    return '$app יכולה לקרוא את הודעות הטקסט שלך';
  }

  @override
  String get whySms =>
      'הודעות טקסט כוללות לעיתים קרובות קודי כניסה. רק אפליקציית ההודעות צריכה לקרוא אותן.';

  @override
  String get ruleCallLog => 'יומן שיחות';

  @override
  String findingCallLog(String app) {
    return '$app יכולה לקרוא את יומן השיחות שלך';
  }

  @override
  String get whyCallLog =>
      'יומן השיחות מראה עם מי מדברים ומתי. רק אפליקציית הטלפון צריכה אותו.';

  @override
  String get ruleAllFiles => 'גישה לכל הקבצים';

  @override
  String findingAllFiles(String app) {
    return '$app יכולה לקרוא את כל הקבצים שלך';
  }

  @override
  String get whyAllFiles =>
      'האפליקציה יכולה לקרוא ולשנות כל קובץ באחסון המשותף: תמונות, הורדות, מסמכים. מנהל קבצים צריך את זה; רוב האפליקציות לא.';

  @override
  String get ruleOverlay => 'תצוגה מעל אפליקציות אחרות';

  @override
  String findingOverlay(String app) {
    return '$app יכולה להציג מעל אפליקציות אחרות';
  }

  @override
  String get whyOverlay =>
      'האפליקציה יכולה להציג תוכן מעל אפליקציות אחרות. אפשר לנצל את זה כדי להסתיר את מה שרואים או כדי לגרום ללחיצה בטעות.';

  @override
  String get ruleInstallsApps => 'התקנת אפליקציות אחרות';

  @override
  String findingInstallsApps(String app) {
    return '$app יכולה להתקין אפליקציות אחרות';
  }

  @override
  String get whyInstallsApps =>
      'האפליקציה יכולה לבקש להתקין אפליקציות אחרות מחוץ לחנות האפליקציות. כדאי להשאיר רק לחנות או לדפדפן שמהם מתקינים.';

  @override
  String get ruleUsageAccess => 'גישה לנתוני שימוש';

  @override
  String findingUsageAccess(String app) {
    return '$app יכולה לראות באילו אפליקציות יש שימוש';
  }

  @override
  String get whyUsageAccess =>
      'האפליקציה יכולה לראות באילו אפליקציות משתמשים, מתי ולכמה זמן.';

  @override
  String get ruleOldTarget => 'נבנו עבור אנדרואיד ישן';

  @override
  String findingOldTarget(String app, String version) {
    return '$app נבנתה עבור אנדרואיד $version';
  }

  @override
  String get whyOldTarget =>
      'אפליקציות שנבנו עבור אנדרואיד 10 ומטה מדלגות על הגנות שנוספו מאז, כמו הגבלות על קריאת קבצים והסרה אוטומטית של הרשאות שאינן בשימוש.';

  @override
  String get ruleNotUpdated => 'לא עודכנו שנתיים';

  @override
  String findingNotUpdated(String app, int years) {
    return '$app לא עודכנה יותר מ-$years שנים';
  }

  @override
  String get whyNotUpdated =>
      'אפליקציה שלא עודכנה שנתיים כנראה כבר לא מתוחזקת, ולכן בעיות ידועות בה נשארות פתוחות.';

  @override
  String get ruleUnused => 'אפליקציות ללא שימוש עם הרשאות';

  @override
  String findingUnused(String app) {
    return '$app לא הייתה בשימוש 90 יום';
  }

  @override
  String get whyUnused =>
      'האפליקציה לא נפתחה 90 יום, והיא עדיין מחזיקה הרשאות. כדאי להסיר אותה או לבטל את ההרשאות.';

  @override
  String get checkScreenLock => 'נעילת מסך';

  @override
  String get checkEncryption => 'הצפנת האחסון';

  @override
  String get checkWhyEncryption =>
      'כל מה ששמור בטלפון מוצפן, ונפתח רק עם נעילת המסך שלך.';

  @override
  String get checkSecurityPatch => 'עדכון אבטחה';

  @override
  String get checkUsbDebugging => 'ניפוי באגים ב-USB';

  @override
  String get checkWirelessDebugging => 'ניפוי באגים אלחוטי';

  @override
  String get checkDeveloperOptions => 'אפשרויות למפתחים';

  @override
  String get checkLockScreenContent => 'תוכן הודעות במסך הנעילה';

  @override
  String get checkWifiScanning => 'סריקת Wi-Fi כש-Wi-Fi כבוי';

  @override
  String get checkBluetoothScanning => 'סריקת Bluetooth כש-Bluetooth כבוי';

  @override
  String get checkPrivateDns => 'DNS פרטי';

  @override
  String get checkWhyPrivateDns =>
      'DNS פרטי מסתיר מהרשת שאליה מחוברים את שמות האתרים שמחפשים, ויכול לחסום עוקבים אם בוחרים שירות מסנן.';

  @override
  String get checkVpn => 'VPN';

  @override
  String get checkWhyVpn =>
      'VPN מסתיר מהרשת שאליה מחוברים את מה שעושים, ומהאתרים את הכתובת שלך. האמון עובר לספק ה-VPN.';

  @override
  String get checkAdvancedProtection => 'הגנה מתקדמת';

  @override
  String get checkWhyAdvancedProtection =>
      'ההגנה המתקדמת של אנדרואיד מפעילה בבת אחת את ההגנות החזקות ביותר. כדאי למי שנמצא בסיכון גבוה.';

  @override
  String get checkAlwaysOnVpn => 'VPN פועל תמיד, בלי חיבורים מחוצה לו';

  @override
  String get checkWhyAlwaysOnVpn =>
      'עם \"VPN בחיבור תמידי\" ו\"חסימת חיבורים ללא VPN\", שום דבר לא יוצא מהטלפון מחוץ ל-VPN, גם לא לרגע בזמן התחברות מחדש. אנדרואיד לא מאפשר לאפליקציות לקרוא את ההגדרה הזו.';

  @override
  String get checkAdvertisingId => 'מזהה הפרסום נמחק';

  @override
  String get checkWhyAdvertisingId =>
      'מזהה הפרסום מאפשר לאפליקציות לקשר בין מה שעושים בהן. אפשר למחוק אותו בהגדרות, פרטיות, מודעות.';

  @override
  String get checkAutoReboot => 'הפעלה מחדש אוטומטית';

  @override
  String get checkWhyAutoReboot =>
      'GrapheneOS יכולה להפעיל מחדש את הטלפון כשלא נפתח זמן מה, וכך הנתונים חוזרים להיות מוצפנים במלואם. נמצא בהגדרות, אבטחה ופרטיות, Exploit protection.';

  @override
  String get checkUsbPort => 'שקע USB-C סגור כשהטלפון נעול';

  @override
  String get checkWhyUsbPort =>
      'GrapheneOS יכולה לדחות חיבורי USB חדשים כשהטלפון נעול. נמצא בהגדרות, אבטחה ופרטיות, Exploit protection.';

  @override
  String get checkWifiAutoOff => 'Wi-Fi נכבה מעצמו כשאין חיבור';

  @override
  String get checkWhyWifiAutoOff =>
      'GrapheneOS יכולה לכבות את ה-Wi-Fi אחרי זמן מה בלי חיבור. נמצא בהגדרות, רשת ואינטרנט, אינטרנט, העדפות רשת.';

  @override
  String get checkBluetoothAutoOff => 'Bluetooth נכבה מעצמו כשאין חיבור';

  @override
  String get checkWhyBluetoothAutoOff =>
      'GrapheneOS יכולה לכבות את ה-Bluetooth אחרי זמן מה בלי חיבור. נמצא בהגדרות, מכשירים מחוברים, העדפות חיבור, Bluetooth.';

  @override
  String get checkPinScrambling => 'מקלדת קוד מעורבבת';

  @override
  String get checkWhyPinScrambling =>
      'מקלדת שבה הספרות מסודרות אחרת בכל פעם מונעת ללמוד את הקוד לפי מיקום הלחיצות. נמצא בהגדרות, אבטחה ופרטיות, ביטול נעילת המכשיר.';

  @override
  String get checkDuressPin => 'קוד מצוקה';

  @override
  String get checkWhyDuressPin =>
      'קוד שני שמוחק את הטלפון כשמקלידים אותו. נמצא בהגדרות, אבטחה ופרטיות, ביטול נעילת המכשיר.';

  @override
  String get checkNetworkSensors => 'הרשאות רשת וחיישנים נבדקו';

  @override
  String get checkWhyNetworkSensors =>
      'ב-GrapheneOS לכל אפליקציה יש הרשאת רשת והרשאת חיישנים שאפשר לכבות. כדאי לעבור על האפליקציות ולבטל אותן היכן שאין בהן צורך.';

  @override
  String findingCostsEach(int points, int cap) {
    return 'כל אחד מוריד $points מהציון, וכל הממצאים מהסוג הזה יחד $cap לכל היותר.';
  }

  @override
  String get acceptedHeading => 'סימנת שאלה בסדר';

  @override
  String get nothingToLookAt => 'אין כאן מה לבדוק.';

  @override
  String get aboutThisApp => 'על האפליקציה הזו';

  @override
  String get readingPhone => 'קורא את הטלפון…';

  @override
  String get lastUsedNeedsAccess =>
      'יש להפעיל גישה לנתוני שימוש כדי לראות מתי הייתה בשימוש לאחרונה';

  @override
  String get lastUsedUnknown => 'אנדרואיד לא מסר מתי הייתה בשימוש לאחרונה';

  @override
  String get holdersTitle => 'אפליקציות שמחזיקות בזה';

  @override
  String get trackersTile => 'רכיבי מעקב';

  @override
  String get trackersTileWaiting => 'מתכונן…';

  @override
  String trackersScanning(int done, int total) {
    return 'בודק אפליקציות: $done מתוך $total';
  }

  @override
  String trackersTileSub(int count, int apps) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count מתוך $apps האפליקציות שלך מכילות קוד מעקב',
      one: 'אפליקציה אחת מתוך $apps מכילה קוד מעקב',
      zero: 'לא נמצא קוד מעקב ב-$apps האפליקציות שלך',
    );
    return '$_temp0';
  }

  @override
  String get trackersIntro =>
      'רכיב מעקב הוא קוד שנועד לאסוף מידע עליך או על אופן השימוש שלך באפליקציה. ZT Privacy קורא את שמות הקוד שבתוך כל אפליקציה בטלפון הזה ומשווה אותם לרשימת רכיבי המעקב המוכרים של Exodus Privacy. שום דבר לא נשלח לשום מקום: הרשימה נמצאת בתוך האפליקציה.';

  @override
  String get trackersCaveat =>
      'הבדיקה מראה שהקוד נמצא באפליקציה. היא לא מוכיחה שהקוד פועל, או מה הוא שולח. קוד ששמותיו עורבלו אינו נראה.';

  @override
  String trackersCredit(int count, String date) {
    return 'רשימת רכיבי המעקב: Exodus Privacy, ברישיון Open Database License (ODbL 1.0). $count רכיבי מעקב, הרשומה החדשה ביותר $date.';
  }

  @override
  String get tabByTracker => 'לפי רכיב מעקב';

  @override
  String appTrackerCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'קוד של $count רכיבי מעקב',
      one: 'קוד של רכיב מעקב אחד',
    );
    return '$_temp0';
  }

  @override
  String get appNoTrackers => 'לא נמצא קוד מעקב';

  @override
  String get appNotChecked => 'עדיין לא נבדקה';

  @override
  String get appUnreadable => 'לא ניתן היה לקרוא את הקוד שלה';

  @override
  String get noTrackersAnywhere => 'לא נמצא קוד מעקב באפליקציות האלה.';

  @override
  String get noTrackersYet => 'עד עכשיו לא נמצא קוד מעקב.';

  @override
  String trackerInApps(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'ב-$count אפליקציות',
      one: 'באפליקציה אחת',
    );
    return '$_temp0';
  }

  @override
  String get appTrackersTitle => 'קוד מעקב';

  @override
  String get appTrackersFound => 'מכילה קוד של:';

  @override
  String get appTrackersNone =>
      'לא נמצא באפליקציה הזו קוד של רכיבי מעקב מוכרים.';

  @override
  String get appTrackersNotChecked => 'האפליקציה הזו עדיין לא נבדקה.';

  @override
  String get appTrackersUnreadable =>
      'ZT Privacy לא הצליח לקרוא את הקוד של האפליקציה הזו.';

  @override
  String get kindAds => 'פרסום';

  @override
  String get kindAnalytics => 'ניתוח שימוש';

  @override
  String get kindLocation => 'מיקום';

  @override
  String get kindProfiling => 'בניית פרופיל';

  @override
  String get kindIdentification => 'זיהוי';

  @override
  String get kindCrashReporting => 'דיווח על קריסות';

  @override
  String get kindUnknown => 'הסוג לא צוין';

  @override
  String get trackerAppsTitle => 'אפליקציות שמכילות את הקוד הזה';

  @override
  String get trackerNoApps => 'אף אפליקציה ברשימה לא מכילה אותו כרגע.';

  @override
  String get trackerReadMore => 'לקרוא עליו באתר Exodus Privacy';

  @override
  String get ruleTrackerCode => 'קוד מעקב עם הרשאות';

  @override
  String findingTrackerCode(String app, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$app מכילה קוד של $count רכיבי מעקב ומחזיקה בהרשאות רגישות',
      one: '$app מכילה קוד של רכיב מעקב אחד ומחזיקה בהרשאות רגישות',
    );
    return '$_temp0';
  }

  @override
  String get whyTrackerCode =>
      'האפליקציה הזו מכילה קוד שנועד לפרסום, לניתוח שימוש וכדומה, והיא גם מחזיקה בהרשאה שמלמדת אותה משהו עליך, כמו מיקום, אנשי קשר, מצלמה או מיקרופון. מציאת הקוד לא מוכיחה שהוא פועל או מה הוא שולח. ובכל זאת השילוב שווה בדיקה: אפשר לבטל הרשאות שהאפליקציה לא צריכה, או לחפש אפליקציה בלי הקוד הזה.';

  @override
  String get appIncomplete => 'חלק מהקוד שלה לא נקרא';

  @override
  String get appTrackersIncompleteNone =>
      'לא נמצא קוד מעקב בחלק של האפליקציה שניתן היה לקרוא. את השאר לא ניתן היה לקרוא, ולכן לא ידוע אם האפליקציה נקייה ממנו.';

  @override
  String get appTrackersIncomplete =>
      'חלק מהקוד של האפליקציה לא נקרא, ולכן ייתכן שיש עוד.';
}
