import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zerotrust_privacy/rules/checklist.dart';
import 'package:zerotrust_privacy/trackers/scan_cache.dart';
import 'package:zerotrust_privacy/trackers/tracker_results.dart';
import 'package:zerotrust_privacy/ui/privacy_home.dart';
import 'package:zerotrust_privacy/ui/score_page.dart';
import 'package:zerotrust_privacy/ui/trackers_page.dart';

import 'support/app.dart';
import 'support/fake_phone.dart';

/// Maps holds location and has three kits, one of them a crash reporter;
/// Notes holds the camera and has only the crash reporter; Old Game holds
/// nothing and has two; a system app has one.
Map<String, List<String>> someCode() => {
  'com.maps': ['Ad Network', 'App Stats', 'Crash Catcher'],
  'com.notes': ['Crash Catcher'],
  'com.game': ['Ad Network', 'Mystery Kit'],
  'android.system': ['App Stats'],
};

/// The vertical order of the rows with these keys.
void expectInOrder(WidgetTester tester, List<String> keys) {
  var bottom = 0.0;
  for (final key in keys) {
    final rect = tester.getRect(byKey(key));
    expect(rect.top, greaterThanOrEqualTo(bottom), reason: key);
    bottom = rect.bottom;
  }
}

String subtitleOf(WidgetTester tester, String key) {
  final tile = tester.widget<ListTile>(byKey(key));
  return (tile.subtitle! as Text).data!;
}

void main() {
  late World world;
  setUp(() => world = World()..found.addAll(someCode()));

  group('dashboard', () {
    testWidgets('says how many apps contain tracker code, and it counts', (
      tester,
    ) async {
      await show(tester, const PrivacyHome(), world);

      expect(find.text('Trackers'), findsOneWidget);
      expect(
        find.text('3 of your 5 apps contain tracker code'),
        findsOneWidget,
      );
      // Maps: tracker code and location together cost 2 of the 78.
      expect(tester.widget<Text>(byKey('home-score-value')).data, '76');
      expect(find.text('7 things to look at'), findsOneWidget);
      // Between the two other lists, full width, and no progress bar once
      // the scan is over.
      expectInOrder(tester, ['home-apps', 'home-trackers', 'home-checklist']);
      final door = tester.getRect(byKey('home-trackers'));
      expect(door.left, 0);
      expect(door.right, pixel.width);
      expect(
        find.descendant(
          of: byKey('home-trackers'),
          matching: find.byType(LinearProgressIndicator),
        ),
        findsNothing,
      );

      await tester.tap(byKey('home-trackers'));
      await tester.pumpAndSettle();
      expect(find.byType(TrackersPage), findsOneWidget);
    });

    testWidgets('no tracker code anywhere', (tester) async {
      world = World();
      await show(tester, const PrivacyHome(), world);
      expect(find.text('No tracker code found in your 5 apps'), findsOneWidget);
      expect(tester.widget<Text>(byKey('home-score-value')).data, '78');
    });

    testWidgets('one app with tracker code, in Hebrew too', (tester) async {
      world = World()..found['com.game'] = ['Ad Network'];
      await show(tester, const PrivacyHome(), world);
      expect(
        find.text('1 of your 5 apps contains tracker code'),
        findsOneWidget,
      );

      await show(tester, const PrivacyHome(), world, locale: hebrew);
      expect(find.text('רכיבי מעקב'), findsOneWidget);
      expect(find.text('אפליקציה אחת מתוך 5 מכילה קוד מעקב'), findsOneWidget);
    });

    testWidgets('shows a scan as it goes, and the score follows', (
      tester,
    ) async {
      final scanner = FakeScanner();
      world = World(scanner: scanner);
      await show(tester, const PrivacyHome(), world);

      // All six apps wait, the user's five first.
      expect(scanner.targets.map((t) => t.package), [
        'com.maps',
        'com.reader',
        'com.files',
        'com.game',
        'com.notes',
        'android.system',
      ]);
      expect(find.text('Checking apps: 0 of 6'), findsOneWidget);
      final bar = find.descendant(
        of: byKey('home-trackers'),
        matching: find.byType(LinearProgressIndicator),
      );
      expect(tester.widget<LinearProgressIndicator>(bar).value, 0);
      // The bar spans the card, under the words.
      final card = tester.getRect(
        find.descendant(
          of: byKey('home-trackers'),
          matching: find.byType(Card),
        ),
      );
      final line = tester.getRect(bar);
      expect(line.left, greaterThanOrEqualTo(card.left));
      expect(line.right, lessThanOrEqualTo(card.right));
      expect(line.width, greaterThan(pixel.width - 48));
      expect(
        tester.getRect(bar).top,
        greaterThan(tester.getRect(find.text('Checking apps: 0 of 6')).bottom),
      );
      expect(tester.widget<Text>(byKey('home-score-value')).data, '78');

      scanner
        ..give('com.maps', found: ['Ad Network'])
        ..give('com.reader')
        ..give('com.files');
      await tester.pumpAndSettle();
      expect(find.text('Checking apps: 3 of 6'), findsOneWidget);
      expect(tester.widget<LinearProgressIndicator>(bar).value, 0.5);

      scanner
        ..give('com.game')
        ..give('com.notes')
        ..give('android.system');
      await scanner.finish();
      await tester.pumpAndSettle();
      expect(
        find.text('1 of your 5 apps contains tracker code'),
        findsOneWidget,
      );
      expect(bar, findsNothing);
      expect(tester.widget<Text>(byKey('home-score-value')).data, '76');
    });

    testWidgets('what was found before is there at once, with no new scan', (
      tester,
    ) async {
      final maps = world.probe.installed.first;
      world.scans.kept =
          ScanMemory(listVersion: someTrackers().version, system: '')
            ..apps.addAll({
              for (final app in world.probe.installed)
                app.package: AppTrackers(
                  lastUpdate: app.lastUpdate,
                  trackerIds: app == maps ? [adNetwork.id] : const [],
                ),
            });
      await show(tester, const PrivacyHome(), world);
      expect((world.scanner as InstantScanner).scanned, isEmpty);
      expect(
        find.text('1 of your 5 apps contains tracker code'),
        findsOneWidget,
      );
      expect(tester.widget<Text>(byKey('home-score-value')).data, '76');
    });
  });

  group('the finding', () {
    testWidgets('says what was found, in careful words, and can be '
        'accepted', (tester) async {
      await show(tester, const FindingsPage(), world);
      await tester.tap(byKey('finding-trackerCode:com.maps'));
      await tester.pumpAndSettle();

      // The crash reporter is not counted against the app.
      expect(
        tester.widget<Text>(byKey('finding-title')).data,
        'Maps contains code from 2 trackers and holds sensitive permissions',
      );
      expect(find.textContaining('does not prove that it runs'), findsOne);
      expect(
        tester.widget<Text>(byKey('finding-cost')).data,
        'Each one takes 2 off the score, and all of this kind together 8 at '
        'most.',
      );
      expectButtonsFit(tester, pixel.width, atLeast: 2);

      await tester.tap(byKey('finding-open'));
      await tester.pumpAndSettle();
      expect(world.probe.openedWith, [(Screens.appDetails, 'com.maps')]);

      await tester.tap(byKey('finding-accept'));
      await tester.pumpAndSettle();
      expect(world.choices.now.accepted, {'trackerCode:com.maps'});
    });

    testWidgets('one tracker is said in the singular; Hebrew has its own '
        'words', (tester) async {
      world = World()..found['com.maps'] = ['Mystery Kit'];
      await show(tester, const FindingsPage(), world);
      expect(
        find.text(
          'Maps contains code from 1 tracker and holds sensitive permissions',
        ),
        findsOneWidget,
      );
      await show(tester, const FindingsPage(), world, locale: hebrew);
      expect(
        find.text('Maps מכילה קוד של רכיב מעקב אחד ומחזיקה בהרשאות רגישות'),
        findsOneWidget,
      );
    });
  });

  group('trackers page', () {
    testWidgets('by app: the most tracker code first, explained above, '
        'credited below', (tester) async {
      await show(tester, const TrackersPage(), world);

      expectInOrder(tester, [
        'show-system',
        'trackers-intro',
        'app-com.maps',
        'app-com.game',
        'app-com.notes',
        'app-com.files',
        'app-com.reader',
        'trackers-credit',
      ]);
      expect(subtitleOf(tester, 'app-com.maps'), 'Code from 3 trackers');
      expect(subtitleOf(tester, 'app-com.game'), 'Code from 2 trackers');
      expect(subtitleOf(tester, 'app-com.notes'), 'Code from 1 tracker');
      expect(subtitleOf(tester, 'app-com.files'), 'No tracker code found');
      expect(byKey('app-android.system'), findsNothing);
      expect(find.textContaining('Nothing is sent anywhere'), findsOneWidget);
      expect(
        find.textContaining('does not prove that the code runs'),
        findsOne,
      );
      expect(
        tester
            .widget<Text>(
              find.descendant(
                of: byKey('trackers-credit'),
                matching: find.byType(Text),
              ),
            )
            .data,
        'Tracker list: Exodus Privacy, under the Open Database License '
        '(ODbL 1.0). 4 trackers, newest entry 2023-12-05.',
      );
      // No scan is running: no progress line.
      expect(byKey('trackers-progress'), findsNothing);
      // Every row inside the screen.
      for (final key in ['trackers-intro', 'app-com.maps', 'trackers-credit']) {
        final rect = tester.getRect(byKey(key));
        expect(rect.left, greaterThanOrEqualTo(0), reason: key);
        expect(rect.right, lessThanOrEqualTo(pixel.width), reason: key);
      }

      await tester.tap(byKey('show-system'));
      await tester.pumpAndSettle();
      expect(subtitleOf(tester, 'app-android.system'), 'Code from 1 tracker');
    });

    testWidgets('by tracker: the ones in the most apps first, with their '
        'kind', (tester) async {
      await show(tester, const TrackersPage(), world);
      await tester.tap(find.text('By tracker'));
      await tester.pumpAndSettle();

      expectInOrder(tester, [
        'tracker-${adNetwork.id}',
        'tracker-${crashCatcher.id}',
        'tracker-${appStats.id}',
        'tracker-${mysteryKit.id}',
        'trackers-credit',
      ]);
      expect(
        subtitleOf(tester, 'tracker-${adNetwork.id}'),
        'In 2 apps · Advertising',
      );
      expect(
        subtitleOf(tester, 'tracker-${crashCatcher.id}'),
        'In 2 apps · Crash reporting',
      );
      expect(
        subtitleOf(tester, 'tracker-${appStats.id}'),
        'In 1 app · Analytics, Profiling',
      );
      expect(
        subtitleOf(tester, 'tracker-${mysteryKit.id}'),
        'In 1 app · Kind not stated',
      );

      // With the system's apps App Stats is in two, and moves up.
      await tester.tap(byKey('show-system'));
      await tester.pumpAndSettle();
      expectInOrder(tester, [
        'tracker-${adNetwork.id}',
        'tracker-${appStats.id}',
        'tracker-${crashCatcher.id}',
        'tracker-${mysteryKit.id}',
      ]);
    });

    testWidgets('one tracker: what it is, who has it, and where to read '
        'more', (tester) async {
      await show(tester, const TrackersPage(), world);
      await tester.tap(find.text('By tracker'));
      await tester.pumpAndSettle();
      await tester.tap(byKey('tracker-${adNetwork.id}'));
      await tester.pumpAndSettle();

      expect(find.byType(TrackerPage), findsOneWidget);
      expect(tester.widget<Text>(byKey('tracker-kinds')).data, 'Advertising');
      expect(find.text('https://adnetwork.example'), findsOneWidget);
      expect(find.text('Apps that contain this code'), findsOneWidget);
      expectInOrder(tester, [
        'tracker-kinds',
        'tracker-read-more',
        'app-com.maps',
        'app-com.game',
      ]);
      expect(byKey('app-com.notes'), findsNothing);

      final button = tester.getRect(byKey('tracker-read-more'));
      expect(button.left, 16);
      expect(button.right, pixel.width - 16);
      await tester.tap(byKey('tracker-read-more'));
      await tester.pumpAndSettle();
      // The page names the tracker, never an app.
      expect(world.links, [
        Uri.parse('https://reports.exodus-privacy.eu.org/en/trackers/11/'),
      ]);

      // On to one of the apps.
      await tester.tap(byKey('app-com.game'));
      await tester.pumpAndSettle();
      expect(find.text('Contains code from:'), findsOneWidget);
    });

    testWidgets('nothing found says so', (tester) async {
      world = World();
      await show(tester, const TrackersPage(), world);
      expect(subtitleOf(tester, 'app-com.maps'), 'No tracker code found');
      await tester.tap(find.text('By tracker'));
      await tester.pumpAndSettle();
      expect(
        find.text('No tracker code was found in these apps.'),
        findsOneWidget,
      );
    });

    testWidgets('during a scan: progress on top, and each app says where '
        'it stands', (tester) async {
      final scanner = FakeScanner();
      world = World(scanner: scanner);
      world.probe.installed = world.probe.installed.take(3).toList();
      await show(tester, const TrackersPage(), world);

      expect(find.text('Checking apps: 0 of 3'), findsOneWidget);
      expectInOrder(tester, ['trackers-progress', 'show-system']);
      final progress = tester.getRect(byKey('trackers-progress'));
      expect(progress.left, 0);
      expect(progress.right, pixel.width);
      expect(subtitleOf(tester, 'app-com.maps'), 'Not checked yet');

      await tester.tap(find.text('By tracker'));
      await tester.pumpAndSettle();
      expect(find.text('No tracker code found so far.'), findsOneWidget);
      await tester.tap(find.text('By app'));
      await tester.pumpAndSettle();

      scanner
        ..give('com.maps', found: ['Ad Network'])
        ..give(
          'com.reader',
          errors: ['base.apk: Permission denied'],
          dexFiles: 0,
        )
        ..give('com.files');
      await scanner.finish();
      await tester.pumpAndSettle();

      expect(byKey('trackers-progress'), findsNothing);
      expect(subtitleOf(tester, 'app-com.maps'), 'Code from 1 tracker');
      expect(
        subtitleOf(tester, 'app-com.reader'),
        'Its code could not be read',
      );
      expect(subtitleOf(tester, 'app-com.files'), 'No tracker code found');
    });

    testWidgets('in Hebrew the page is mirrored', (tester) async {
      await show(tester, const TrackersPage(), world, locale: hebrew);
      expect(find.text('רכיבי מעקב'), findsOneWidget);
      expect(find.text('לפי רכיב מעקב'), findsOneWidget);
      expect(subtitleOf(tester, 'app-com.maps'), 'קוד של 3 רכיבי מעקב');
      expect(subtitleOf(tester, 'app-com.notes'), 'קוד של רכיב מעקב אחד');
      expect(subtitleOf(tester, 'app-com.files'), 'לא נמצא קוד מעקב');
      // The app's picture is at the right, its name to the left of it.
      final row = byKey('app-com.maps');
      final avatar = tester.getRect(
        find.descendant(of: row, matching: find.byType(CircleAvatar)),
      );
      final name = tester.getRect(
        find.descendant(of: row, matching: find.text('Maps')),
      );
      expect(avatar.center.dx, greaterThan(pixel.width - 60));
      expect(name.right, lessThan(avatar.left));

      await tester.tap(find.text('לפי רכיב מעקב'));
      await tester.pumpAndSettle();
      expect(
        subtitleOf(tester, 'tracker-${appStats.id}'),
        'באפליקציה אחת · ניתוח שימוש, בניית פרופיל',
      );
      expect(
        subtitleOf(tester, 'tracker-${mysteryKit.id}'),
        'באפליקציה אחת · הסוג לא צוין',
      );
    });

    for (final locale in const [Locale('en'), hebrew]) {
      testWidgets('fits a small phone with large text ($locale)', (
        tester,
      ) async {
        tester.platformDispatcher.textScaleFactorTestValue = 1.5;
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        await show(
          tester,
          const TrackersPage(),
          world,
          size: smallPhone,
          locale: locale,
        );
        expect(tester.takeException(), isNull);
        for (final key in ['trackers-intro', 'app-com.maps']) {
          final rect = tester.getRect(byKey(key));
          expect(rect.left, greaterThanOrEqualTo(0), reason: key);
          expect(rect.right, lessThanOrEqualTo(smallPhone.width), reason: key);
        }
        await tester.tap(byKey('app-com.maps'));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        await tester.tap(byKey('tracker-${adNetwork.id}'));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expectButtonsFit(tester, smallPhone.width);
      });
    }
  });

  group('one app', () {
    Future<void> openApp(WidgetTester tester, String package) async {
      await show(tester, const TrackersPage(), world);
      await tester.tap(byKey('app-$package'));
      await tester.pumpAndSettle();
    }

    testWidgets('lists the trackers whose code it contains', (tester) async {
      await openApp(tester, 'com.maps');
      expect(find.text('Tracker code'), findsOneWidget);
      expect(find.text('Contains code from:'), findsOneWidget);
      expectInOrder(tester, [
        'finding-trackerCode:com.maps',
        'tracker-${adNetwork.id}',
        'tracker-${appStats.id}',
        'tracker-${crashCatcher.id}',
        'app-open-settings',
      ]);
      expect(
        subtitleOf(tester, 'tracker-${appStats.id}'),
        'Analytics, Profiling',
      );
      expect(
        find.textContaining('does not prove that the code runs'),
        findsOne,
      );

      await tester.tap(byKey('tracker-${crashCatcher.id}'));
      await tester.pumpAndSettle();
      expect(find.byType(TrackerPage), findsOneWidget);
      expect(byKey('app-com.notes'), findsOneWidget);
    });

    testWidgets('with none says none was found', (tester) async {
      await openApp(tester, 'com.files');
      expect(
        tester
            .widget<Text>(
              find.descendant(
                of: byKey('app-trackers-none'),
                matching: find.byType(Text),
              ),
            )
            .data,
        'No code from known trackers was found in this app.',
      );
      expect(find.text('Contains code from:'), findsNothing);
    });

    testWidgets('that could not be read says so, and is not called '
        'clean', (tester) async {
      (world.scanner as InstantScanner).unreadable = {'com.reader'};
      await openApp(tester, 'com.reader');
      expect(
        find.text("ZT Privacy could not read this app's code."),
        findsOneWidget,
      );
      expect(byKey('app-trackers-none'), findsNothing);
    });

    testWidgets('not read yet says so', (tester) async {
      world = World(scanner: FakeScanner());
      await openApp(tester, 'com.maps');
      expect(find.text('This app has not been checked yet.'), findsOneWidget);
      expect(byKey('app-trackers-none'), findsNothing);
    });
  });
}
