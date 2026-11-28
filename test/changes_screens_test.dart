import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zerotrust_privacy/l10n/generated/app_l10n_en.dart';
import 'package:zerotrust_privacy/rules/rules.dart';
import 'package:zerotrust_privacy/trackers/changes.dart';
import 'package:zerotrust_privacy/trackers/scan_cache.dart';
import 'package:zerotrust_privacy/ui/app_page.dart';
import 'package:zerotrust_privacy/ui/changes_page.dart';
import 'package:zerotrust_privacy/ui/privacy_home.dart';
import 'package:zerotrust_privacy/ui/texts.dart';

import 'support/app.dart';
import 'support/fake_phone.dart';

const contacts = 'android.permission.READ_CONTACTS';

int day(int dayOfMonth) =>
    DateTime(2026, 11, dayOfMonth, 12).millisecondsSinceEpoch;

/// What the app kept from earlier looks at [world]'s phone: it knows every
/// app that is there now, and noticed [changes] (oldest first).
ScanMemory keptWith(World world, List<Change> changes, {int seenAt = 0}) =>
    ScanMemory(
      listVersion: someTrackers().version,
      baselined: true,
      seenAt: seenAt,
      asked: {
        for (final app in world.probe.installed)
          if (!app.system)
            app.package: [
              for (final permission in permissionsToWatchFor)
                if (app.requested.contains(permission)) permission,
            ],
      },
      changes: changes,
    );

/// Four changes, one of each kind, on four days.
List<Change> fourChanges() => [
  Change(
    at: day(20),
    kind: ChangeKind.newAppTrackers,
    package: 'com.game',
    label: 'Old Game',
    trackerIds: [adNetwork.id, mysteryKit.id],
  ),
  Change(
    at: day(21),
    kind: ChangeKind.trackersAdded,
    package: 'com.maps',
    label: 'Maps',
    trackerIds: [appStats.id],
  ),
  Change(
    at: day(22),
    kind: ChangeKind.trackersRemoved,
    package: 'com.maps',
    label: 'Maps',
    trackerIds: [adNetwork.id],
  ),
  Change(
    at: day(23),
    kind: ChangeKind.permissionsAdded,
    package: 'com.notes',
    label: 'Notes',
    permissions: const [fineLocation, contacts],
  ),
];

String titleOf(WidgetTester tester, String key) =>
    (tester
                .widget<ListTile>(
                  find.descendant(
                    of: byKey(key),
                    matching: find.byType(ListTile),
                  ),
                )
                .title!
            as Text)
        .data!;

String doorText(WidgetTester tester) =>
    (tester
                .widget<ListTile>(
                  find.descendant(
                    of: byKey('home-changes'),
                    matching: find.byType(ListTile),
                  ),
                )
                .subtitle!
            as Text)
        .data!;

Finder newMarkIn(String key) =>
    find.descendant(of: byKey(key), matching: byKey('change-new'));

void main() {
  late World world;
  setUp(() => world = World());

  group('dashboard', () {
    testWidgets('before anything changed the door says so', (tester) async {
      await show(tester, const PrivacyHome(), world);
      expect(find.text('What changed'), findsOneWidget);
      expect(doorText(tester), 'Nothing has changed yet');
      // Under the trackers, over the checklist, full width, no number.
      final trackers = tester.getRect(byKey('home-trackers'));
      final door = tester.getRect(byKey('home-changes'));
      final checklist = tester.getRect(byKey('home-checklist'));
      expect(door.top, greaterThanOrEqualTo(trackers.bottom));
      expect(checklist.top, greaterThanOrEqualTo(door.bottom));
      expect(door.left, 0);
      expect(door.right, pixel.width);
      expect(find.byType(Badge), findsNothing);
    });

    testWidgets('new changes are counted on the door until the list is '
        'opened', (tester) async {
      world.scans.kept = keptWith(world, fourChanges(), seenAt: day(21));
      await show(tester, const PrivacyHome(), world);
      expect(doorText(tester), '2 new changes since you last looked');
      final badge = find.descendant(
        of: byKey('home-changes'),
        matching: find.byType(Badge),
      );
      expect(badge, findsOneWidget);
      expect(
        find.descendant(of: badge, matching: find.text('2')),
        findsOneWidget,
      );

      await tester.tap(byKey('home-changes'));
      await tester.pumpAndSettle();
      expect(find.byType(ChangesPage), findsOneWidget);
      // The two that came since stay marked while the list is open.
      expect(find.byKey(const Key('change-new')), findsNWidgets(2));
      expect(world.scans.kept!.seenAt, day(23));

      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(doorText(tester), 'Nothing new since you last looked');
      expect(find.byType(Badge), findsNothing);

      // Opened again, nothing is new.
      await tester.tap(byKey('home-changes'));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('change-new')), findsNothing);
      expect(find.byKey(const Key('change-3')), findsOneWidget);
    });

    testWidgets('one new change', (tester) async {
      world.scans.kept = keptWith(world, fourChanges(), seenAt: day(22));
      await show(tester, const PrivacyHome(), world);
      expect(doorText(tester), '1 new change since you last looked');
    });

    testWidgets('a newly installed app with tracker code shows up after '
        'reading the phone again', (tester) async {
      await show(tester, const PrivacyHome(), world);
      expect(doorText(tester), 'Nothing has changed yet');

      world.found['com.weather'] = ['Ad Network', 'App Stats'];
      world.probe.installed = [
        ...world.probe.installed,
        userApp('com.weather', 'Weather', uid: 10120),
      ];
      await tester.tap(byKey('home-refresh'));
      await tester.pumpAndSettle();
      expect(doorText(tester), '1 new change since you last looked');

      await tester.tap(byKey('home-changes'));
      await tester.pumpAndSettle();
      expect(
        titleOf(tester, 'change-0'),
        'Weather was installed. It contains code from: Ad Network, App Stats',
      );
      expect(newMarkIn('change-0'), findsOneWidget);
    });
  });

  group('the list', () {
    testWidgets('says what happened to which app, newest first', (
      tester,
    ) async {
      world.scans.kept = keptWith(world, fourChanges(), seenAt: day(22));
      await show(tester, const ChangesPage(), world);

      expect(
        titleOf(tester, 'change-0'),
        [
          'An update of Notes started asking for: ',
          'Location, precise; Contacts',
        ].join(),
      );
      expect(
        titleOf(tester, 'change-1'),
        'An update of Maps removed code from: Ad Network',
      );
      expect(
        titleOf(tester, 'change-2'),
        'An update of Maps added code from: App Stats',
      );
      expect(
        titleOf(tester, 'change-3'),
        'Old Game was installed. It contains code from: Ad Network, '
        'Mystery Kit',
      );

      // The explanation on top, then the rows in order, each as wide as
      // the screen.
      var bottom = tester.getRect(byKey('changes-intro')).bottom;
      for (var i = 0; i < 4; i++) {
        final row = tester.getRect(byKey('change-$i'));
        expect(row.top, greaterThanOrEqualTo(bottom), reason: 'change-$i');
        expect(row.left, 0);
        expect(row.right, pixel.width);
        bottom = row.bottom;
      }
      expect(find.byKey(const Key('changes-none')), findsNothing);

      // Each row has its day under the sentence; only the newest is new,
      // and its mark sits beside the day, inside the row.
      for (final (index, date) in ['23', '22', '21', '20'].indexed) {
        final row = tester.getRect(byKey('change-$index'));
        final title = tester.getRect(
          find.descendant(
            of: byKey('change-$index'),
            matching: find.textContaining(index == 3 ? 'installed' : 'update'),
          ),
        );
        final when = tester.getRect(
          find.descendant(
            of: byKey('change-$index'),
            matching: find.text('2026-11-$date'),
          ),
        );
        expect(when.top, greaterThanOrEqualTo(title.bottom));
        expect(when.bottom, lessThanOrEqualTo(row.bottom));
      }
      expect(newMarkIn('change-0'), findsOneWidget);
      expect(find.byKey(const Key('change-new')), findsOneWidget);
      final mark = tester.getRect(newMarkIn('change-0'));
      final when = tester.getRect(find.text('2026-11-23'));
      final row = tester.getRect(byKey('change-0'));
      expect(mark.left, greaterThan(when.right));
      expect(mark.right, lessThan(row.right));
      expect(mark.center.dy, closeTo(when.center.dy, 2));
      expect(find.text('New'), findsOneWidget);
    });

    testWidgets('a row opens the app; an app that is gone says so', (
      tester,
    ) async {
      world.scans.kept = keptWith(world, [
        Change(
          at: day(19),
          kind: ChangeKind.newAppTrackers,
          package: 'com.gone',
          label: 'Gone App',
          trackerIds: const [999],
        ),
        ...fourChanges(),
      ]);
      await show(tester, const ChangesPage(), world);

      // A tracker the list no longer has is shown by its number.
      expect(
        titleOf(tester, 'change-4'),
        'Gone App was installed. It contains code from: #999',
      );
      await tester.tap(byKey('change-4'));
      await tester.pump();
      expect(find.text('Gone App is no longer on this phone.'), findsOneWidget);
      expect(find.byType(AppPage), findsNothing);

      await tester.tap(byKey('change-1'));
      await tester.pumpAndSettle();
      expect(find.byType(AppPage), findsOneWidget);
      expect(find.widgetWithText(AppBar, 'Maps'), findsOneWidget);
    });

    testWidgets('an app without a name goes by its technical name', (
      tester,
    ) async {
      world.scans.kept = keptWith(world, [
        Change(
          at: day(20),
          kind: ChangeKind.trackersAdded,
          package: 'com.maps',
          label: '',
          trackerIds: [appStats.id],
        ),
      ]);
      await show(tester, const ChangesPage(), world);
      expect(
        titleOf(tester, 'change-0'),
        'An update of com.maps added code from: App Stats',
      );
    });

    testWidgets('with nothing in it says that nothing changed', (tester) async {
      await show(tester, const ChangesPage(), world);
      expect(
        find.text(
          'Nothing has changed since ZT Privacy first looked at this phone.',
        ),
        findsOneWidget,
      );
      final intro = tester.getRect(byKey('changes-intro'));
      final none = tester.getRect(byKey('changes-none'));
      expect(intro.top, greaterThan(0));
      expect(none.top, greaterThanOrEqualTo(intro.bottom));
      expect(find.textContaining('kept on this phone only'), findsOneWidget);
    });

    testWidgets('in Hebrew, mirrored', (tester) async {
      world.scans.kept = keptWith(world, fourChanges(), seenAt: day(22));
      await show(tester, const ChangesPage(), world, locale: hebrew);
      expect(find.widgetWithText(AppBar, 'מה השתנה'), findsOneWidget);
      expect(
        titleOf(tester, 'change-0'),
        'עדכון של Notes התחיל לבקש: מיקום מדויק; אנשי קשר',
      );
      expect(
        titleOf(tester, 'change-1'),
        'עדכון של Maps הסיר קוד של: Ad Network',
      );
      expect(
        titleOf(tester, 'change-2'),
        'עדכון של Maps הוסיף קוד של: App Stats',
      );
      expect(
        titleOf(tester, 'change-3'),
        'Old Game הותקנה. היא מכילה קוד של: Ad Network, Mystery Kit',
      );
      expect(find.text('חדש'), findsOneWidget);
      // The icon leads from the right, and the mark follows the day to
      // its left.
      final icon = tester.getRect(
        find.descendant(of: byKey('change-0'), matching: find.byType(Icon)),
      );
      final title = tester.getRect(
        find.descendant(
          of: byKey('change-0'),
          matching: find.textContaining('התחיל לבקש'),
        ),
      );
      expect(icon.left, greaterThan(title.right));
      final mark = tester.getRect(newMarkIn('change-0'));
      final when = tester.getRect(find.text('2026-11-23'));
      expect(mark.right, lessThan(when.left));
      expect(mark.left, greaterThan(0));
    });

    for (final locale in const [Locale('en'), hebrew]) {
      testWidgets('fits a small phone with large text ($locale)', (
        tester,
      ) async {
        tester.platformDispatcher.textScaleFactorTestValue = 1.5;
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        world.scans.kept = keptWith(world, fourChanges());
        await show(
          tester,
          const ChangesPage(),
          world,
          size: smallPhone,
          locale: locale,
        );
        expect(tester.takeException(), isNull);
        expect(find.byKey(const Key('change-new')), findsNWidgets(4));
        for (var i = 0; i < 4; i++) {
          final row = tester.getRect(byKey('change-$i'));
          final mark = tester.getRect(newMarkIn('change-$i'));
          expect(mark.left, greaterThanOrEqualTo(0), reason: 'change-$i');
          expect(
            mark.right,
            lessThanOrEqualTo(smallPhone.width),
            reason: 'change-$i',
          );
          expect(mark.bottom, lessThanOrEqualTo(row.bottom));
        }
      });
    }
  });

  test('every permission worth telling about has a plain name', () {
    final l = AppL10nEn();
    for (final permission in permissionsToWatchFor) {
      expect(
        permissionNames(l, [permission]),
        hasLength(1),
        reason: permission,
      );
    }
    // Two of Android's permissions behind one name are told once.
    expect(
      permissionNames(l, const [
        'android.permission.READ_SMS',
        'android.permission.RECEIVE_SMS',
        allFilesPermission,
      ]),
      ['All files access', 'Text messages'],
    );
    expect(permissionNames(l, const ['android.permission.VIBRATE']), isEmpty);
  });
}
