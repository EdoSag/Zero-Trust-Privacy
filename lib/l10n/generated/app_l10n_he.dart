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
      'הגרסה הזו בודקת מה הטלפון מאפשר ל-ZT Privacy לקרוא. שום דבר לא יוצא מהטלפון: לאפליקציה אין הרשאת רשת. מריצים את השלבים ואז שולחים את הסיכום.';

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
}
