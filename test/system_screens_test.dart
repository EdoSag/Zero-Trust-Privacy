import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:zerotrust_privacy/phone/system_screens.dart';
import 'package:zerotrust_privacy/probe/device_probe.dart';
import 'package:zerotrust_privacy/rules/checklist.dart';

import 'support/fake_phone.dart';

/// Stands in for the vault's "a system screen is showing".
class FakeHold {
  int started = 0;
  int ended = 0;

  bool get holding => started > ended;

  Future<void> call(Future<void> Function() wait) async {
    started++;
    await wait();
    ended++;
  }
}

Future<void> leaveApp(WidgetTester tester) async {
  for (final state in [
    AppLifecycleState.inactive,
    AppLifecycleState.hidden,
    AppLifecycleState.paused,
  ]) {
    tester.binding.handleAppLifecycleStateChanged(state);
  }
  await tester.pump();
}

Future<void> comeBack(WidgetTester tester) async {
  for (final state in [
    AppLifecycleState.hidden,
    AppLifecycleState.inactive,
    AppLifecycleState.resumed,
  ]) {
    tester.binding.handleAppLifecycleStateChanged(state);
  }
  await tester.pump();
}

void main() {
  late FakeProbe probe;
  late FakeHold hold;
  late SystemScreens screens;

  setUp(() {
    probe = FakeProbe();
    hold = FakeHold();
  });

  SystemScreens make(WidgetTester tester, {FakeProbe? on}) {
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    return screens = SystemScreens(on ?? probe, hold: hold.call);
  }

  /// Ends a test that left the user in a system screen.
  Future<void> finish(WidgetTester tester) async {
    screens.dispose();
    await tester.pump();
    expect(hold.holding, isFalse);
  }

  testWidgets('the app stays open from the tap until the user is back', (
    tester,
  ) async {
    final result = await make(tester).open(Screens.developer);
    expect(result.ok, isTrue);
    expect(hold.holding, isTrue);

    await leaveApp(tester);
    // A long look at Settings: still held (the vault has its own limit).
    await tester.pump(const Duration(minutes: 3));
    expect(hold.holding, isTrue);

    await comeBack(tester);
    expect(hold.holding, isFalse);
    expect(hold.started, 1);
  });

  testWidgets('two taps in a row are one stay away', (tester) async {
    make(tester);
    await screens.open(Screens.developer);
    await screens.open(Screens.security);
    expect(hold.started, 1);
    await leaveApp(tester);
    await comeBack(tester);
    expect(hold.holding, isFalse);

    // And the next trip is held again.
    await screens.open(Screens.vpn);
    expect(hold.started, 2);
    await leaveApp(tester);
    await comeBack(tester);
    expect(hold.ended, 2);
  });

  testWidgets('a screen that never came to the front is let go', (
    tester,
  ) async {
    await make(tester).open(Screens.developer);
    expect(hold.holding, isTrue);
    await tester.pump(SystemScreens.leaveWithin + const Duration(seconds: 1));
    await tester.pump();
    expect(hold.holding, isFalse);
  });

  testWidgets('a refusal holds nothing', (tester) async {
    probe.screens = {
      Screens.developer: const ActionResult(ok: false, error: 'refused'),
      Screens.settings: const ActionResult(ok: false, error: 'also refused'),
    };
    final result = await make(tester).open(Screens.developer);
    expect(result.ok, isFalse);
    // The first refusal is the one reported.
    expect(result.error, 'refused');
    await tester.pump();
    expect(hold.holding, isFalse);
    expect(probe.openedWith, [
      (Screens.developer, null),
      (Screens.settings, null),
    ]);
  });

  testWidgets('a refused phone screen opens Settings in its place', (
    tester,
  ) async {
    probe.screens = {
      Screens.systemUpdate: const ActionResult(ok: false, error: 'none'),
    };
    final result = await make(tester).open(Screens.systemUpdate);
    expect(result.ok, isTrue);
    expect(probe.opened, [Screens.systemUpdate, Screens.settings]);
    expect(hold.holding, isTrue);
    await finish(tester);
  });

  testWidgets('an app screen that throws falls back to the app page', (
    tester,
  ) async {
    final throwing = _ThrowingProbe(Screens.overlay);
    final result = await make(
      tester,
      on: throwing,
    ).open(Screens.overlay, package: 'com.maps');
    expect(result.ok, isTrue);
    expect(throwing.openedWith, [
      (Screens.overlay, 'com.maps'),
      (Screens.overlay, null),
      (Screens.appDetails, 'com.maps'),
    ]);
    await finish(tester);
  });

  testWidgets('sharing is a stay away too', (tester) async {
    final result = await make(tester).share('Subject', 'Text');
    expect(result.ok, isTrue);
    expect(probe.shared, ['Text']);
    expect(hold.holding, isTrue);
    await leaveApp(tester);
    await comeBack(tester);
    expect(hold.holding, isFalse);
  });

  testWidgets('the phone test records exactly the screen it asked for', (
    tester,
  ) async {
    probe.screens = {
      'privacyDashboard': const ActionResult(ok: false, error: 'refused'),
    };
    final forTest = AwayAwareProbe(make(tester));
    final refused = await forTest.openSettings('privacyDashboard');
    expect(refused.ok, isFalse);
    // No stand-in screen: the refusal is the result.
    expect(probe.opened, ['privacyDashboard']);
    await tester.pump();
    expect(hold.holding, isFalse);

    final opened = await forTest.openSettings('privacy');
    expect(opened.ok, isTrue);
    expect(hold.holding, isTrue);
    // Reading goes straight through.
    expect(await forTest.apps(), hasLength(4));
    await finish(tester);
  });

  testWidgets('without a vault nothing is held', (tester) async {
    screens = SystemScreens(probe);
    final result = await screens.open(Screens.developer);
    expect(result.ok, isTrue);
    await tester.pump(const Duration(seconds: 10));
  });
}

class _ThrowingProbe extends FakeProbe {
  _ThrowingProbe(this.screen);
  final String screen;

  @override
  Future<ActionResult> openSettings(String screen, {String? package}) async {
    final result = await super.openSettings(screen, package: package);
    if (screen == this.screen) throw StateError('Android threw');
    return result;
  }
}
