import 'dart:typed_data';

/// A tracking or advertising kit that apps build in, known by the Java
/// packages its code lives in.
class TrackerSdk {
  const TrackerSdk(this.name, this.kind, this.packages);

  final String name;
  final TrackerKind kind;

  /// Java package prefixes, for example `com.example.tracker.`.
  final List<String> packages;

  /// [packages] the way class names are written inside an app's code:
  /// `Lcom/example/tracker/`, as bytes.
  List<Uint8List> get prefixes => [
    for (final package in packages)
      Uint8List.fromList('L${package.replaceAll('.', '/')}'.codeUnits),
  ];
}

enum TrackerKind { ads, analytics, crashReporting, profiling }

/// A starter list of widely used kits, written by hand from their public
/// package names. It is here to measure how long a scan of the whole phone
/// takes. The full list the finished app will carry (Exodus Privacy's) comes
/// in a later step, once its licence is confirmed.
const starterTrackers = <TrackerSdk>[
  TrackerSdk('Google Firebase Analytics', TrackerKind.analytics, [
    'com.google.firebase.analytics.',
    'com.google.android.gms.measurement.',
  ]),
  TrackerSdk('Google AdMob', TrackerKind.ads, ['com.google.android.gms.ads.']),
  TrackerSdk('Google Crashlytics', TrackerKind.crashReporting, [
    'com.google.firebase.crashlytics.',
    'com.crashlytics.',
  ]),
  TrackerSdk('Google Tag Manager', TrackerKind.analytics, [
    'com.google.android.gms.tagmanager.',
  ]),
  TrackerSdk('Facebook Analytics', TrackerKind.analytics, [
    'com.facebook.appevents.',
  ]),
  TrackerSdk('Facebook Ads', TrackerKind.ads, ['com.facebook.ads.']),
  TrackerSdk('AppsFlyer', TrackerKind.profiling, ['com.appsflyer.']),
  TrackerSdk('Adjust', TrackerKind.profiling, ['com.adjust.sdk.']),
  TrackerSdk('Branch', TrackerKind.profiling, ['io.branch.']),
  TrackerSdk('Kochava', TrackerKind.profiling, ['com.kochava.']),
  TrackerSdk('Singular', TrackerKind.profiling, ['com.singular.sdk.']),
  TrackerSdk('Amplitude', TrackerKind.analytics, ['com.amplitude.']),
  TrackerSdk('Mixpanel', TrackerKind.analytics, ['com.mixpanel.']),
  TrackerSdk('Segment', TrackerKind.analytics, ['com.segment.analytics.']),
  TrackerSdk('Flurry', TrackerKind.analytics, ['com.flurry.']),
  TrackerSdk('Braze', TrackerKind.profiling, ['com.braze.', 'com.appboy.']),
  TrackerSdk('CleverTap', TrackerKind.profiling, ['com.clevertap.']),
  TrackerSdk('OneSignal', TrackerKind.profiling, ['com.onesignal.']),
  TrackerSdk('Adobe Experience', TrackerKind.analytics, [
    'com.adobe.marketing.mobile.',
  ]),
  TrackerSdk('Comscore', TrackerKind.analytics, ['com.comscore.']),
  TrackerSdk('Yandex AppMetrica', TrackerKind.analytics, [
    'com.yandex.metrica.',
    'io.appmetrica.analytics.',
  ]),
  TrackerSdk('Huawei Analytics', TrackerKind.analytics, [
    'com.huawei.hms.analytics.',
  ]),
  TrackerSdk('Microsoft App Center', TrackerKind.crashReporting, [
    'com.microsoft.appcenter.',
  ]),
  TrackerSdk('Sentry', TrackerKind.crashReporting, ['io.sentry.']),
  TrackerSdk('Bugsnag', TrackerKind.crashReporting, ['com.bugsnag.']),
  TrackerSdk('Instabug', TrackerKind.crashReporting, ['com.instabug.']),
  TrackerSdk('New Relic', TrackerKind.analytics, ['com.newrelic.']),
  TrackerSdk('Datadog', TrackerKind.analytics, ['com.datadog.android.']),
  TrackerSdk('AppLovin', TrackerKind.ads, ['com.applovin.']),
  TrackerSdk('Unity Ads', TrackerKind.ads, ['com.unity3d.ads.']),
  TrackerSdk('ironSource', TrackerKind.ads, ['com.ironsource.']),
  TrackerSdk('Vungle', TrackerKind.ads, ['com.vungle.']),
  TrackerSdk('InMobi', TrackerKind.ads, ['com.inmobi.']),
  TrackerSdk('Chartboost', TrackerKind.ads, ['com.chartboost.']),
  TrackerSdk('Pangle', TrackerKind.ads, ['com.bytedance.sdk.openadsdk.']),
  TrackerSdk('Moat', TrackerKind.ads, ['com.moat.']),
];
