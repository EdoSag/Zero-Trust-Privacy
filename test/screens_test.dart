import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zerotrust_privacy/choices/choices.dart';
import 'package:zerotrust_privacy/probe/device_probe.dart';
import 'package:zerotrust_privacy/rules/checklist.dart';
import 'package:zerotrust_privacy/ui/apps_page.dart';
import 'package:zerotrust_privacy/ui/checklist_page.dart';
import 'package:zerotrust_privacy/ui/privacy_home.dart';
import 'package:zerotrust_privacy/ui/score_page.dart';
import 'package:zerotrust_privacy/ui/widgets.dart';

import 'support/app.dart';
import 'support/fake_phone.dart';

/// The keys of the dashboard's parts, top to bottom.
const dashboardParts = [
  'home-score',
  'finding-wirelessDebugging',
  'finding-accessibility:com.reader',
  'finding-backgroundLocation:com.maps',
  'finding-allFiles:com.files',
  'home-see-all',
  'home-usage',
  'home-apps',
  'home-trackers',
  'home-checklist',
];

Future<void> backFromSettings(WidgetTester tester) async {
  tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
  await tester.pumpAndSettle();
}

void main() {
  late World world;
  setUp(() => world = World());

  group('dashboard', () {
    testWidgets('shows the score, what to fix next and the lists', (
      tester,
    ) async {
      await show(tester, const PrivacyHome(), world);

      expect(tester.widget<Text>(byKey('home-score-value')).data, '78');
      expect(find.text('6 things to look at'), findsOneWidget);
      expect(find.text('Wireless debugging is on'), findsOneWidget);
      expect(find.text('Reader can read and control the screen'), findsOne);
      expect(find.text('See all 6'), findsOneWidget);
      expect(find.text('5 apps, 5 to look at'), findsOneWidget);
      // Developer options ride along with wireless debugging: one to fix.
      // Seven GrapheneOS lines and the VPN line to look at by hand.
      expect(find.text('1 to fix, 8 to check yourself'), findsOneWidget);

      // Top to bottom, in this order, each one inside the screen.
      var bottom = 0.0;
      for (final part in dashboardParts) {
        final rect = tester.getRect(byKey(part));
        expect(rect.top, greaterThanOrEqualTo(bottom), reason: part);
        expect(rect.left, greaterThanOrEqualTo(0), reason: part);
        expect(rect.right, lessThanOrEqualTo(pixel.width), reason: part);
        bottom = rect.bottom;
      }
      // The heaviest finding shows what it costs at the far end of its row.
      final row = tester.getRect(byKey('finding-wirelessDebugging'));
      final cost = tester.getRect(
        find.descendant(
          of: byKey('finding-wirelessDebugging'),
          matching: find.text('−6'),
        ),
      );
      expect(cost.center.dx, greaterThan(row.center.dx + 100));
      expectButtonsFit(tester, pixel.width, atLeast: 2);
    });

    for (final locale in const [Locale('en'), hebrew]) {
      testWidgets('fits a small phone with large text ($locale)', (
        tester,
      ) async {
        tester.platformDispatcher.textScaleFactorTestValue = 1.5;
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        await show(
          tester,
          const PrivacyHome(),
          world,
          size: smallPhone,
          locale: locale,
          // Narrow and with large text the page is long.
          height: 4500,
        );
        expect(tester.takeException(), isNull);
        for (final part in dashboardParts) {
          final rect = tester.getRect(byKey(part));
          expect(rect.left, greaterThanOrEqualTo(0), reason: part);
          expect(rect.right, lessThanOrEqualTo(smallPhone.width), reason: part);
        }
        expectButtonsFit(tester, smallPhone.width, atLeast: 2);
      });
    }

    testWidgets('in Hebrew the page is mirrored', (tester) async {
      await show(tester, const PrivacyHome(), world, locale: hebrew);
      expect(find.text('ציון פרטיות'), findsOneWidget);
      expect(find.text('ניפוי באגים אלחוטי פועל'), findsOneWidget);
      // The score starts at the right; what a finding costs is at the left.
      expect(
        tester.getRect(byKey('home-score-value')).center.dx,
        greaterThan(pixel.width / 2),
      );
      final cost = tester.getRect(
        find.descendant(
          of: byKey('finding-wirelessDebugging'),
          matching: find.text('−6'),
        ),
      );
      expect(cost.center.dx, lessThan(pixel.width / 2 - 100));
    });

    testWidgets('a phone with nothing to fix says so', (tester) async {
      world = World(
        probe: FakeProbe()
          ..installed = [userApp('com.notes', 'Notes')]
          ..values = facts(goodFacts())
          ..lists = const {}
          ..usageReport = const UsageReport(granted: true),
      );
      await show(tester, const PrivacyHome(), world);
      expect(tester.widget<Text>(byKey('home-score-value')).data, '100');
      expect(find.text('Nothing to fix. Well kept.'), findsOneWidget);
      expect(find.text('Fix next'), findsNothing);
      // Usage access is on: no need to ask for it.
      expect(byKey('home-usage'), findsNothing);
    });

    testWidgets('asks for usage access and opens its screen', (tester) async {
      await show(tester, const PrivacyHome(), world);
      await tester.tap(byKey('home-usage-open'));
      await tester.pumpAndSettle();
      expect(world.probe.opened, [Screens.usageAccess]);

      // Switched on in Settings: back in the app the card is gone.
      world.probe.usageReport = const UsageReport(granted: true);
      await backFromSettings(tester);
      expect(byKey('home-usage'), findsNothing);
    });

    testWidgets('a phone that cannot be read offers to try again', (
      tester,
    ) async {
      world.probe.appsFailure = 'SecurityException: no list';
      await show(tester, const PrivacyHome(), world);
      expect(find.textContaining('SecurityException: no list'), findsOne);
      expectButtonsFit(tester, pixel.width);

      world.probe.appsFailure = null;
      await tester.tap(byKey('home-retry'));
      await tester.pumpAndSettle();
      expect(tester.widget<Text>(byKey('home-score-value')).data, '78');
    });

    testWidgets('names the parts Android would not give', (tester) async {
      world.probe.mode = (_) => throw StateError('refused');
      await show(tester, const PrivacyHome(), world);
      expect(find.textContaining('accessAnswers'), findsOneWidget);
      // Files' all-files access could not be read, so it is not claimed.
      expect(tester.widget<Text>(byKey('home-score-value')).data, '81');
    });
  });

  group('a finding', () {
    Future<void> openFinding(WidgetTester tester, String id) async {
      await show(tester, const PrivacyHome(), world);
      await tester.tap(byKey('finding-$id'));
      await tester.pumpAndSettle();
    }

    testWidgets('explains itself and leads to its setting', (tester) async {
      await openFinding(tester, 'wirelessDebugging');
      expect(find.text('Wireless debugging is on'), findsOneWidget);
      expect(find.textContaining('a paired computer on the same'), findsOne);
      expect(find.text('Takes 6 points off the score'), findsOneWidget);

      // Title, then the way to the setting, then "I'm fine with this":
      // both buttons the full width of the page, one under the other.
      final title = tester.getRect(byKey('finding-title'));
      final open = tester.getRect(byKey('finding-open'));
      final accept = tester.getRect(byKey('finding-accept'));
      expect(open.top, greaterThan(title.bottom));
      expect(accept.top, greaterThanOrEqualTo(open.bottom));
      for (final button in [open, accept]) {
        expect(button.left, 16);
        expect(button.right, pixel.width - 16);
        expect(button.height, greaterThanOrEqualTo(48));
      }

      await tester.tap(byKey('finding-open'));
      await tester.pumpAndSettle();
      expect(world.probe.openedWith, [(Screens.developer, null)]);
    });

    testWidgets('about an app opens on that app', (tester) async {
      await openFinding(tester, 'allFiles:com.files');
      expect(find.text('Files can read all your files'), findsOneWidget);
      // One of several of its kind: says what each costs and the limit.
      expect(find.textContaining('takes 3 off the score'), findsOneWidget);
      await tester.tap(byKey('finding-open'));
      await tester.pumpAndSettle();
      expect(world.probe.openedWith, [(Screens.allFiles, 'com.files')]);
    });

    testWidgets('with no list of its own opens the app in Settings', (
      tester,
    ) async {
      await openFinding(tester, 'backgroundLocation:com.maps');
      expect(find.text("Open the app's settings"), findsOneWidget);
      await tester.tap(byKey('finding-open'));
      await tester.pumpAndSettle();
      expect(world.probe.openedWith, [(Screens.appDetails, 'com.maps')]);
    });

    testWidgets('falls back when Android will not open the screen', (
      tester,
    ) async {
      world.probe.screens = {
        Screens.allFiles: const ActionResult(ok: false, error: 'no such'),
      };
      await openFinding(tester, 'allFiles:com.files');
      await tester.tap(byKey('finding-open'));
      await tester.pumpAndSettle();
      // On the app, then without it, then the app's own page.
      expect(world.probe.openedWith, [
        (Screens.allFiles, 'com.files'),
        (Screens.allFiles, null),
        (Screens.appDetails, 'com.files'),
      ]);
      expect(find.textContaining('did not open'), findsNothing);
    });

    testWidgets('says so when nothing opens', (tester) async {
      world.probe.screens = {
        Screens.developer: const ActionResult(ok: false, error: 'refused'),
        Screens.settings: const ActionResult(ok: false, error: 'also'),
      };
      await openFinding(tester, 'wirelessDebugging');
      await tester.tap(byKey('finding-open'));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      expect(find.text('That screen did not open: refused'), findsOneWidget);
      // Gone by itself after a few seconds.
      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();
      expect(find.text('That screen did not open: refused'), findsNothing);
    });

    testWidgets('"I\'m fine with this" stops it counting, and back again', (
      tester,
    ) async {
      await openFinding(tester, 'wirelessDebugging');
      await tester.tap(byKey('finding-accept'));
      await tester.pumpAndSettle();
      expect(world.choices.now.accepted, {'wirelessDebugging'});
      expect(
        find.text('You are fine with this, so it does not count.'),
        findsOneWidget,
      );
      expect(find.text('Count it again'), findsOneWidget);

      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(tester.widget<Text>(byKey('home-score-value')).data, '84');
      expect(find.text('5 things to look at'), findsOneWidget);
      expect(byKey('finding-wirelessDebugging'), findsNothing);
      // The checklist has nothing left to fix either.
      expect(find.text('0 to fix, 8 to check yourself'), findsOneWidget);

      // It is still listed, under the ones the user is fine with.
      await tester.tap(byKey('home-see-all'));
      await tester.pumpAndSettle();
      final heading = tester.getRect(find.text('You are fine with these'));
      final accepted = tester.getRect(byKey('finding-wirelessDebugging'));
      expect(accepted.top, greaterThanOrEqualTo(heading.bottom));
      await tester.tap(byKey('finding-wirelessDebugging'));
      await tester.pumpAndSettle();
      await tester.tap(byKey('finding-accept'));
      await tester.pumpAndSettle();
      expect(world.choices.now.accepted, isEmpty);
    });

    testWidgets('says so when the choice cannot be saved', (tester) async {
      world.choices.failure = 'no room';
      await openFinding(tester, 'wirelessDebugging');
      await tester.tap(byKey('finding-accept'));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      expect(find.text('That could not be saved: no room'), findsOneWidget);
      expect(find.text("I'm fine with this"), findsOneWidget);
      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();
    });

    testWidgets('fixed in Settings: the page closes and the score rises', (
      tester,
    ) async {
      await openFinding(tester, 'wirelessDebugging');
      setFact(world.probe, 'global.adb_wifi_enabled', '0');
      setFact(world.probe, 'global.development_settings_enabled', '0');
      await backFromSettings(tester);
      expect(byKey('finding-title'), findsNothing);
      expect(tester.widget<Text>(byKey('home-score-value')).data, '84');
    });

    testWidgets('leads on to the app it is about', (tester) async {
      await openFinding(tester, 'accessibility:com.reader');
      await tester.tap(byKey('finding-app'));
      await tester.pumpAndSettle();
      expect(find.text('com.reader'), findsOneWidget);
      expect(find.text('Installed by org.example.store'), findsOneWidget);
    });
  });

  group('score page', () {
    testWidgets('lists every point taken off', (tester) async {
      world.choices.now = const Choices(
        id: 'device-test',
        accepted: {'allFiles:com.files'},
      );
      await show(tester, const ScorePage(), world);
      expect(tester.widget<Text>(byKey('score-page-value')).data, '81');

      Finder inLine(String rule, String text) => find.descendant(
        of: byKey('score-line-$rule'),
        matching: find.textContaining(text),
      );
      expect(inLine('wirelessDebugging', '1 found, 6 off'), findsOneWidget);
      expect(inLine('wirelessDebugging', '−6'), findsOneWidget);
      expect(inLine('oldTarget', '−2'), findsOneWidget);
      // Accepted: still listed, costs nothing.
      expect(inLine('allFiles', '0 found, 0 off'), findsOneWidget);
      expect(inLine('allFiles', '1 you are fine with'), findsOneWidget);
      // Nothing found of this kind: no line.
      expect(byKey('score-line-noScreenLock'), findsNothing);

      // In the order of weight: the phone first, then apps.
      final tops = [
        for (final rule in [
          'wirelessDebugging',
          'accessibility',
          'backgroundLocation',
          'allFiles',
          'oldTarget',
          'notUpdated',
        ])
          tester.getRect(byKey('score-line-$rule')).top,
      ];
      expect(tops, [...tops]..sort());
      // The points sit at the far end of the row.
      final row = tester.getRect(byKey('score-line-accessibility'));
      expect(
        tester.getRect(inLine('accessibility', '−6')).center.dx,
        greaterThan(row.center.dx + 100),
      );

      await tester.tap(byKey('score-line-accessibility'));
      await tester.pumpAndSettle();
      expect(byKey('finding-accessibility:com.reader'), findsOneWidget);
      expect(
        find.textContaining('can read everything on the screen'),
        findsOne,
      );
    });

    testWidgets('with nothing found says nothing is taken off', (tester) async {
      world = World(
        probe: FakeProbe()
          ..installed = []
          ..values = facts(goodFacts())
          ..lists = const {},
      );
      await show(tester, const ScorePage(), world);
      expect(tester.widget<Text>(byKey('score-page-value')).data, '100');
      expect(find.textContaining('nothing is taken off'), findsOneWidget);
    });
  });

  group('apps and permissions', () {
    testWidgets('by permission: who holds what', (tester) async {
      await show(tester, const AppsPage(), world);
      Finder inRow(String key, String text) =>
          find.descendant(of: byKey(key), matching: find.text(text));
      expect(inRow('access-accessibility', '1 app'), findsOneWidget);
      expect(inRow('access-allFiles', '1 app'), findsOneWidget);
      expect(inRow('access-deviceAdmin', 'No app'), findsOneWidget);
      expect(
        inRow(
          'permission-android.permission.CAMERA',
          'Held by 1, asked for by 1',
        ),
        findsOneWidget,
      );
      // Special access first, then the ordinary permissions.
      expect(
        tester.getRect(byKey('access-usageAccess')).bottom,
        lessThanOrEqualTo(
          tester
              .getRect(
                byKey(
                  'permission-android.permission.ACCESS_BACKGROUND_LOCATION',
                ),
              )
              .top,
        ),
      );

      await tester.tap(byKey('permission-android.permission.CAMERA'));
      await tester.pumpAndSettle();
      expect(byKey('app-com.notes'), findsOneWidget);
      expect(byKey('app-android.system'), findsNothing);
      await tester.pageBack();
      await tester.pumpAndSettle();

      // With system apps the system's camera use shows too.
      await tester.tap(byKey('show-system'));
      await tester.pumpAndSettle();
      expect(
        inRow(
          'permission-android.permission.CAMERA',
          'Held by 2, asked for by 2',
        ),
        findsOneWidget,
      );
      await tester.tap(byKey('access-accessibility'));
      await tester.pumpAndSettle();
      expect(
        find.textContaining('can read everything on the screen'),
        findsOne,
      );
      expect(byKey('app-com.reader'), findsOneWidget);
    });

    testWidgets('by app: the ones to look at first, search, system apps', (
      tester,
    ) async {
      await show(tester, const AppsPage(), world);
      await tester.tap(find.text('By app'));
      await tester.pumpAndSettle();

      // Old Game has two things to look at, so it leads; Notes, with
      // nothing, comes last.
      final order = [
        for (final package in [
          'com.game',
          'com.files',
          'com.maps',
          'com.reader',
          'com.notes',
        ])
          tester.getRect(byKey('app-$package')).top,
      ];
      expect(order, [...order]..sort());
      expect(
        find.descendant(
          of: byKey('app-com.game'),
          matching: find.text('2 to look at'),
        ),
        findsOneWidget,
      );
      expect(byKey('app-android.system'), findsNothing);

      await tester.tap(byKey('show-system'));
      await tester.pumpAndSettle();
      expect(byKey('app-android.system'), findsOneWidget);

      await tester.enterText(byKey('app-search'), 'map');
      await tester.pumpAndSettle();
      expect(byKey('app-com.maps'), findsOneWidget);
      expect(byKey('app-com.game'), findsNothing);
      await tester.enterText(byKey('app-search'), 'zzz');
      await tester.pumpAndSettle();
      expect(find.text('No app matches.'), findsOneWidget);
    });

    testWidgets('one app: where it came from and what it holds', (
      tester,
    ) async {
      world.probe.usageReport = UsageReport(
        granted: true,
        apps: [
          AppUsage(
            package: 'com.maps',
            lastUsed: daysAgo(3),
            foregroundMs: 1000,
          ),
        ],
      );
      await show(tester, const AppsPage(), world);
      await tester.tap(find.text('By app'));
      await tester.pumpAndSettle();
      await tester.tap(byKey('app-com.maps'));
      await tester.pumpAndSettle();

      expect(find.text('Installed by org.example.store'), findsOneWidget);
      expect(find.text('Built for Android 15'), findsOneWidget);
      expect(find.text('Last used ${dateDaysAgo(3)}'), findsOneWidget);
      expect(byKey('finding-backgroundLocation:com.maps'), findsOneWidget);
      expect(find.text('Location, all the time'), findsOneWidget);
      expect(find.text('Location, precise'), findsOneWidget);
      expect(find.text('Camera'), findsNothing);

      final button = tester.getRect(byKey('app-open-settings'));
      expect(button.left, 16);
      expect(button.right, pixel.width - 16);
      await tester.tap(byKey('app-open-settings'));
      await tester.pumpAndSettle();
      expect(world.probe.openedWith, [(Screens.appDetails, 'com.maps')]);
    });

    testWidgets('a refused usage history is not shown as "not used"', (
      tester,
    ) async {
      world.probe.usageReport = const UsageReport(
        granted: true,
        appsError: 'IllegalStateException: no stats',
      );
      await show(tester, const PrivacyHome(), world);
      // Same score as with no usage access at all: nothing counts as unused.
      expect(tester.widget<Text>(byKey('home-score-value')).data, '78');
      expect(
        tester.widget<Paragraph>(byKey('home-parts-failed')).text,
        contains('usage'),
      );
      await tester.tap(byKey('home-apps'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('By app'));
      await tester.pumpAndSettle();
      await tester.tap(byKey('app-com.notes'));
      await tester.pumpAndSettle();
      expect(
        tester.widget<Paragraph>(byKey('app-last-used')).text,
        'Android did not say when it was last used',
      );
    });

    testWidgets('an app that loses a permission leaves that list', (
      tester,
    ) async {
      await show(tester, const PrivacyHome(), world);
      await tester.tap(byKey('home-apps'));
      await tester.pumpAndSettle();
      await tester.tap(byKey('permission-android.permission.CAMERA'));
      await tester.pumpAndSettle();
      expect(byKey('app-com.notes'), findsOneWidget);
      await tester.tap(byKey('app-com.notes'));
      await tester.pumpAndSettle();
      await tester.tap(byKey('app-open-settings'));
      await tester.pumpAndSettle();

      // In Android's settings the camera is taken away from the app.
      world.probe.installed = [
        for (final app in world.probe.installed)
          if (app.package == 'com.notes')
            userApp(
              'com.notes',
              'Notes',
              permissions: {camera: false},
              uid: 10105,
            )
          else
            app,
      ];
      await backFromSettings(tester);
      await tester.pageBack();
      await tester.pumpAndSettle();

      expect(find.text('Apps that hold this'), findsOneWidget);
      expect(byKey('app-com.notes'), findsNothing);
      expect(find.text('No app of yours holds this.'), findsOneWidget);
    });

    testWidgets('one app without usage access says what is missing', (
      tester,
    ) async {
      await show(tester, const AppsPage(), world);
      await tester.tap(find.text('By app'));
      await tester.pumpAndSettle();
      await tester.tap(byKey('app-com.notes'));
      await tester.pumpAndSettle();
      expect(
        tester.widget<Paragraph>(byKey('app-last-used')).text,
        contains('Usage access'),
      );
      expect(find.text('Nothing to point out.'), findsOneWidget);
    });

    for (final locale in const [Locale('en'), hebrew]) {
      testWidgets('fits a small phone with large text ($locale)', (
        tester,
      ) async {
        tester.platformDispatcher.textScaleFactorTestValue = 1.5;
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        await show(
          tester,
          const AppsPage(),
          world,
          size: smallPhone,
          locale: locale,
        );
        expect(tester.takeException(), isNull);
        await tester.tap(byKey('access-allFiles'));
        await tester.pumpAndSettle();
        await tester.tap(byKey('app-com.files'));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expectButtonsFit(tester, smallPhone.width);
      });
    }
  });

  group('device checklist', () {
    Finder inRow(String id, String text) => find.descendant(
      of: byKey('check-$id'),
      matching: find.textContaining(text),
    );

    testWidgets('shows what was read, then what to check by hand', (
      tester,
    ) async {
      await show(tester, const ChecklistPage(), world);
      expect(inRow('screenLock', 'Good'), findsOneWidget);
      expect(inRow('securityPatch', dateDaysAgo(20)), findsOneWidget);
      expect(inRow('wirelessDebugging', 'Worth changing'), findsOneWidget);
      expect(inRow('usbDebugging', 'Good'), findsOneWidget);
      expect(inRow('vpn', 'On'), findsOneWidget);
      expect(inRow('privateDns', 'Off'), findsOneWidget);

      // Three groups, top to bottom, the GrapheneOS lines last.
      final tops = [
        tester.getRect(find.text('Read from the phone')).top,
        tester.getRect(byKey('check-screenLock')).top,
        tester.getRect(byKey('check-vpn')).top,
        tester.getRect(find.text('To check yourself')).top,
        tester.getRect(byKey('check-alwaysOnVpn')).top,
        tester.getRect(find.text('GrapheneOS')).top,
        tester.getRect(byKey('check-autoReboot')).top,
        tester.getRect(byKey('check-networkSensors')).top,
      ];
      expect(tops, [...tops]..sort());
      // Google's advertising ID is not a thing on GrapheneOS.
      expect(byKey('check-advertisingId'), findsNothing);
      // The tick box leads its row.
      final row = tester.getRect(byKey('check-autoReboot'));
      final tick = tester.getRect(byKey('tick-autoReboot'));
      expect(tick.center.dx, lessThan(row.left + 60));
    });

    testWidgets('another phone has no GrapheneOS lines', (tester) async {
      world = World(probe: pixelLikePhone(graphene: false));
      await show(tester, const ChecklistPage(), world);
      expect(find.text('GrapheneOS'), findsNothing);
      expect(byKey('check-autoReboot'), findsNothing);
      expect(byKey('check-advertisingId'), findsOneWidget);
    });

    testWidgets('a tick is kept', (tester) async {
      await show(tester, const ChecklistPage(), world);
      await tester.tap(byKey('tick-duressPin'));
      await tester.pumpAndSettle();
      expect(world.choices.now.checked, {'duressPin'});
      expect(tester.widget<Checkbox>(byKey('tick-duressPin')).value, isTrue);
      expect(tester.widget<Checkbox>(byKey('tick-usbPort')).value, isFalse);
    });

    testWidgets('a line explains itself and opens its setting', (tester) async {
      await show(tester, const ChecklistPage(), world);
      await tester.tap(byKey('check-autoReboot'));
      await tester.pumpAndSettle();
      expect(find.textContaining('restart the phone'), findsOneWidget);
      final open = tester.getRect(byKey('check-open'));
      final mark = tester.getRect(byKey('check-mark'));
      expect(open.left, 16);
      expect(open.right, pixel.width - 16);
      expect(mark.top, greaterThanOrEqualTo(open.bottom));

      await tester.tap(byKey('check-open'));
      await tester.pumpAndSettle();
      expect(world.probe.openedWith, [(Screens.security, null)]);
      await tester.tap(byKey('check-mark'));
      await tester.pumpAndSettle();
      expect(world.choices.now.checked, {'autoReboot'});
    });

    testWidgets('a line read from the phone shows its value', (tester) async {
      await show(tester, const ChecklistPage(), world);
      await tester.tap(byKey('check-vpn'));
      await tester.pumpAndSettle();
      expect(tester.widget<Text>(byKey('check-value')).data, 'On');
      expect(find.textContaining('VPN provider'), findsOneWidget);
      // Nothing to tick: the phone answered for itself.
      expect(byKey('check-mark'), findsNothing);
    });

    testWidgets('a line that needs attention opens its finding', (
      tester,
    ) async {
      await show(tester, const ChecklistPage(), world);
      await tester.tap(byKey('check-wirelessDebugging'));
      await tester.pumpAndSettle();
      expect(byKey('finding-accept'), findsOneWidget);
      expect(find.text('Wireless debugging is on'), findsOneWidget);
    });

    testWidgets('in Hebrew the tick box is on the right', (tester) async {
      await show(tester, const ChecklistPage(), world, locale: hebrew);
      expect(find.text('נקרא מהטלפון'), findsOneWidget);
      final row = tester.getRect(byKey('check-autoReboot'));
      final tick = tester.getRect(byKey('tick-autoReboot'));
      expect(tick.center.dx, greaterThan(row.right - 60));
      expect(tester.takeException(), isNull);
    });

    for (final locale in const [Locale('en'), hebrew]) {
      testWidgets('fits a small phone with large text ($locale)', (
        tester,
      ) async {
        tester.platformDispatcher.textScaleFactorTestValue = 1.5;
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        await show(
          tester,
          const ChecklistPage(),
          world,
          size: smallPhone,
          locale: locale,
          height: 5000,
        );
        expect(tester.takeException(), isNull);
        await tester.tap(byKey('check-networkSensors'));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expectButtonsFit(tester, smallPhone.width);
      });
    }
  });
}
