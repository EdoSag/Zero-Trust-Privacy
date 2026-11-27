import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zero_trust_core/zero_trust_core.dart';
import 'package:zerotrust_privacy/app/privacy_config.dart';
import 'package:zerotrust_privacy/l10n/generated/app_l10n.dart';
import 'package:zerotrust_privacy/probe/device_probe.dart';
import 'package:zerotrust_privacy/ui/phone_test_controller.dart';
import 'package:zerotrust_privacy/ui/phone_test_page.dart';

import 'support/fake_phone.dart';

/// Logical sizes: a Pixel 10 Pro, and the smallest phone still in use.
const pixel = Size(412, 915);
const smallPhone = Size(320, 568);

const stepKeys = [
  'read',
  'open-usage',
  'copy-command',
  'start-scan',
  'screen-privacyDashboard',
  'share-summary',
];

void main() {
  late FakeProbe probe;
  late FakeScanner scanner;
  late PhoneTestController controller;

  setUp(() {
    probe = FakeProbe();
    scanner = FakeScanner();
    controller = PhoneTestController(
      probe: probe,
      scanner: scanner,
      build: '1001',
    );
  });

  tearDown(() => controller.dispose());

  Future<void> show(
    WidgetTester tester, {
    Size size = pixel,
    Locale locale = const Locale('en'),
  }) async {
    // Tall enough to lay out all six steps at once, so that every button's
    // place on the page can be checked, at the width of a real phone.
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = Size(size.width, 4000);
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        // The suite's real theme, as in the app.
        theme: ZtTheme.light(accent: privacyAccent),
        locale: locale,
        localizationsDelegates: AppL10n.localizationsDelegates,
        supportedLocales: AppL10n.supportedLocales,
        home: PhoneTestPage(controller: controller),
      ),
    );
    await tester.pumpAndSettle();
  }

  Finder key(String name) => find.byKey(Key(name));

  /// Every button is fully inside the screen's width, with room at the sides.
  void expectInsideWidth(WidgetTester tester, double width) {
    final buttons = find.byWidgetPredicate((w) => w is ButtonStyleButton);
    expect(buttons, findsAtLeastNWidgets(12));
    for (final element in buttons.evaluate()) {
      final rect = tester.getRect(find.byWidget(element.widget));
      expect(
        rect.left,
        greaterThanOrEqualTo(16),
        reason: '${element.widget.key}',
      );
      expect(
        rect.right,
        lessThanOrEqualTo(width - 16),
        reason: '${element.widget.key}',
      );
      expect(rect.width, greaterThan(40), reason: '${element.widget.key}');
      expect(
        rect.height,
        greaterThanOrEqualTo(40),
        reason: '${element.widget.key}',
      );
    }
  }

  testWidgets('the six steps come in order, top to bottom', (tester) async {
    await show(tester);
    expect(tester.takeException(), isNull);
    expect(find.text('ZT Privacy · Phone test'), findsOneWidget);
    expect(find.text('Build 1001'), findsOneWidget);

    var last = 0.0;
    for (final name in stepKeys) {
      final top = tester.getRect(key(name)).top;
      expect(top, greaterThan(last), reason: name);
      last = top;
    }
    expectInsideWidth(tester, pixel.width);
  });

  testWidgets('buttons sit at the start of their card in English', (
    tester,
  ) async {
    await show(tester);
    for (final name in ['read', 'open-usage', 'copy-command', 'start-scan']) {
      // Page padding 16 + card padding 16.
      expect(tester.getRect(key(name)).left, 32, reason: name);
    }
  });

  testWidgets('in Hebrew the page is mirrored and nothing overflows', (
    tester,
  ) async {
    await show(tester, locale: const Locale('he'));
    expect(tester.takeException(), isNull);
    final l10n = lookupAppL10n(const Locale('he'));
    expect(find.text(l10n.stepReadTitle), findsOneWidget);
    expect(find.text('1. Read the phone'), findsNothing);
    for (final name in ['read', 'open-usage', 'copy-command', 'start-scan']) {
      expect(tester.getRect(key(name)).right, pixel.width - 32, reason: name);
    }
    expectInsideWidth(tester, pixel.width);

    // The command still reads left to right.
    final command = find.text(PhoneTestController.deepModeCommand);
    expect(Directionality.of(tester.element(command)), TextDirection.ltr);
  });

  for (final locale in const [Locale('en'), Locale('he')]) {
    testWidgets('fits a small phone with large text (${locale.languageCode})', (
      tester,
    ) async {
      tester.platformDispatcher.textScaleFactorTestValue = 1.3;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await show(tester, size: smallPhone, locale: locale);
      expect(tester.takeException(), isNull);
      expectInsideWidth(tester, smallPhone.width);

      await tester.tap(key('read'));
      await tester.pumpAndSettle();
      controller.startScan();
      scanner.give('com.maps', found: ['Ad Kit']);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expectInsideWidth(tester, smallPhone.width);
      controller.stopScan();
    });
  }

  testWidgets('step 1 shows what was read', (tester) async {
    await show(tester);
    expect(find.text('Read the phone first.'), findsOneWidget);
    expect(tester.widget<FilledButton>(key('start-scan')).onPressed, isNull);

    await tester.tap(key('read'));
    await tester.pumpAndSettle();
    expect(find.text('4 apps, 3 of them yours'), findsOneWidget);
    expect(find.text('Apps with the network switched off: 1'), findsOneWidget);
    expect(find.text('Settings read: 2 of 3'), findsOneWidget);
    expect(find.text('Special access lists read: 2 of 3'), findsOneWidget);
    expect(find.text('Usage access is off.'), findsOneWidget);
    expect(find.text('Not unlocked yet.'), findsOneWidget);
    expect(find.text('Read again'), findsOneWidget);
    expect(find.text('Read the phone first.'), findsNothing);
    expect(tester.widget<FilledButton>(key('start-scan')).onPressed, isNotNull);

    // The results sit between the step's text and its button.
    final line = tester.getRect(find.text('4 apps, 3 of them yours'));
    expect(
      line.top,
      greaterThan(tester.getRect(find.text('1. Read the phone')).bottom),
    );
    expect(line.bottom, lessThan(tester.getRect(key('read')).top));
  });

  testWidgets('a failed step says so in its own card', (tester) async {
    probe.appsFailure = StateError('no app list');
    await show(tester);
    await tester.tap(key('read'));
    await tester.pumpAndSettle();
    final error = find.text('This step failed: Bad state: no app list');
    expect(error, findsOneWidget);
    expect(
      tester.getRect(error).bottom,
      lessThan(tester.getRect(key('read')).top),
    );
    expect(
      tester.getRect(error).top,
      lessThan(tester.getRect(key('open-usage')).top),
    );
  });

  testWidgets('coming back to the app picks up usage access', (tester) async {
    await show(tester);
    await tester.tap(key('read'));
    await tester.pumpAndSettle();
    await tester.tap(key('open-usage'));
    await tester.pumpAndSettle();
    expect(probe.opened, ['usageAccess']);

    probe.usageReport = const UsageReport(
      granted: true,
      apps: [AppUsage(package: 'com.maps', lastUsed: 1, foregroundMs: 1)],
    );
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpAndSettle();
    expect(
      find.text('Usage access is on. Apps with a last-used time: 1'),
      findsOneWidget,
    );
  });

  testWidgets('the command is copied as written', (tester) async {
    String? copied;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'Clipboard.setData') {
          copied = (call.arguments as Map)['text'] as String;
        }
        return null;
      },
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      ),
    );
    await show(tester);
    await tester.tap(key('copy-command'));
    await tester.pump();
    expect(
      copied,
      'adb shell pm grant dev.sagron.zerotrustprivacy '
      'android.permission.GET_APP_OPS_STATS',
    );
    expect(find.text('Copied'), findsOneWidget);
    // The note goes away by itself after four seconds.
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 3));
    expect(find.text('Copied'), findsOneWidget);
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();
    expect(find.text('Copied'), findsNothing);
  });

  testWidgets('the scan shows progress, then the result', (tester) async {
    await show(tester);
    await tester.tap(key('read'));
    await tester.pumpAndSettle();
    await tester.tap(key('start-scan'));
    await tester.pump();
    expect(key('start-scan'), findsNothing);
    expect(key('stop-scan'), findsOneWidget);
    expect(find.byType(LinearProgressIndicator), findsOneWidget);
    // The bar spans the card.
    expect(
      tester.getRect(find.byType(LinearProgressIndicator)).width,
      pixel.width - 64,
    );

    scanner.give('com.maps', found: ['Ad Kit']);
    await tester.pump();
    await tester.pump();
    expect(find.textContaining('1 of 3 apps'), findsOneWidget);

    scanner
      ..give('com.camera', errors: ['base.apk: not a zip file'])
      ..give('com.notes');
    await scanner.finish();
    await tester.pumpAndSettle();
    expect(find.textContaining('Done: 3 apps in'), findsOneWidget);
    expect(find.textContaining('1 contain at least one kit.'), findsOneWidget);
    expect(find.text('Apps that could not be read: 1'), findsOneWidget);
    expect(key('start-scan'), findsOneWidget);
    expect(key('stop-scan'), findsNothing);
  });

  testWidgets('each system screen shows opened or refused beside its name', (
    tester,
  ) async {
    probe.screens['permissionManager'] = const ActionResult(
      ok: false,
      error: 'SecurityException: denied',
    );
    await show(tester);
    await tester.tap(key('screen-privacyDashboard'));
    await tester.pumpAndSettle();
    await tester.tap(key('screen-permissionManager'));
    await tester.pump();

    final opened = tester.getRect(find.text('opened'));
    final refused = tester.getRect(find.text('refused'));
    final first = tester.getRect(key('screen-privacyDashboard'));
    final second = tester.getRect(key('screen-permissionManager'));
    // Same row as its button, at the far end of the card.
    expect(opened.center.dy, closeTo(first.center.dy, 1));
    expect(refused.center.dy, closeTo(second.center.dy, 1));
    expect(opened.left, greaterThanOrEqualTo(first.right));
    expect(opened.right, pixel.width - 32);
    expect(
      find.text('That did not work: SecurityException: denied'),
      findsOneWidget,
    );
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
  });

  testWidgets('step 6 says when the scan or the screens were passed over', (
    tester,
  ) async {
    await show(tester);
    expect(find.textContaining('Not run yet'), findsNothing);
    await tester.tap(key('read'));
    await tester.pumpAndSettle();
    final note = find.text(
      'Not run yet: step 4, 5. The summary is more useful with them.',
    );
    expect(note, findsOneWidget);
    // Above the send buttons, inside the last card.
    expect(
      tester.getRect(note).bottom,
      lessThan(tester.getRect(key('share-summary')).top),
    );
    expect(
      tester.getRect(note).top,
      greaterThan(tester.getRect(find.text('6. Send the results')).bottom),
    );

    await tester.tap(key('screen-privacy'));
    await tester.pumpAndSettle();
    expect(
      find.text('Not run yet: step 4. The summary is more useful with them.'),
      findsOneWidget,
    );
    await tester.tap(key('start-scan'));
    await tester.pump();
    expect(find.textContaining('Not run yet'), findsNothing);
    controller.stopScan();
  });

  testWidgets('nothing is sent before step 1', (tester) async {
    await show(tester);
    await tester.tap(key('share-summary'));
    await tester.pump();
    expect(find.text('Nothing to send yet. Run step 1 first.'), findsOneWidget);
    expect(probe.shared, isEmpty);
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();

    await tester.tap(key('save-full'));
    await tester.pump();
    expect(probe.saved, isEmpty);
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
  });

  testWidgets(
    'the summary is shared without names, the full report saved with',
    (tester) async {
      await show(tester);
      await tester.tap(key('read'));
      await tester.pumpAndSettle();

      await tester.tap(key('share-summary'));
      await tester.pumpAndSettle();
      expect(probe.shared, hasLength(1));
      expect(probe.shared.single, contains('App names: left out'));
      expect(probe.shared.single, isNot(contains('com.maps')));

      await tester.tap(key('save-full'));
      await tester.pump();
      expect(probe.saved.keys.single, 'zt-privacy-phone-test-1001.txt');
      expect(probe.saved.values.single, contains('App names: included'));
      expect(probe.saved.values.single, contains('com.maps |'));
      expect(
        find.text('Saved to Downloads as zt-privacy-phone-test-1001.txt'),
        findsOneWidget,
      );
      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();
    },
  );

  test('Hebrew has every English text', () {
    final en = lookupAppL10n(const Locale('en'));
    final he = lookupAppL10n(const Locale('he'));
    expect(he.stepReadTitle, isNot(en.stepReadTitle));
    expect(he.shareSummary, isNot(en.shareSummary));
    expect(he.appsLine(4, 3), allOf(contains('4'), contains('3')));
    expect(he.scanDone(3, '1.5', 2), allOf(contains('1.5'), contains('2')));
  });
}
