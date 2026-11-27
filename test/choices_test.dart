import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zero_trust_core/zero_trust_core.dart';
import 'package:zerotrust_privacy/choices/choices.dart';
import 'package:zerotrust_privacy/rules/checklist.dart';
import 'package:zerotrust_privacy/rules/finding.dart';

import 'support/app.dart';

void main() {
  const maps = Finding(
    Rule.backgroundLocation,
    package: 'com.maps',
    label: 'Maps',
  );

  test('choices go into the store and come back the same', () async {
    final store = InMemoryItemStore();
    const choices = Choices(
      id: 'device-abc',
      accepted: {'usbDebugging', 'backgroundLocation:com.maps'},
      checked: {'duressPin'},
    );
    await store.put(
      LocalItem(
        itemId: choices.id,
        updatedAt: DateTime.utc(2026, 11, 27),
        json: choicesCollection.encode(choices),
      ),
    );

    final back = await choicesCollection.get(store, 'device-abc');
    expect(back!.id, 'device-abc');
    expect(back.accepted, choices.accepted);
    expect(back.checked, choices.checked);
    // Stored as the `device` kind of the Privacy app.
    expect((await store.get('device-abc'))!.json!['kind'], 'device');
  });

  test('the part the server can read never names an app', () {
    // The item's id is stored as plain text; what is inside is sealed.
    const choices = Choices(
      id: 'device-abc',
      accepted: {'backgroundLocation:com.maps'},
    );
    expect(choicesCollection.idOf(choices), 'device-abc');
    expect(choicesCollection.idOf(choices), isNot(contains('com.maps')));
    expect(choices.toJson()['accepted'], ['backgroundLocation:com.maps']);
  });

  test('choices written by something else are read as far as they go', () {
    final choices = Choices.fromJson('device-abc', {
      'accepted': ['usbDebugging', 7, null],
      'checked': 'not a list',
    }, DateTime.utc(2026));
    expect(choices.accepted, {'usbDebugging'});
    expect(choices.checked, isEmpty);
  });

  group('changing the choices', () {
    late MemoryChoices memory;
    late ProviderContainer container;

    setUp(() {
      memory = MemoryChoices();
      container = ProviderContainer(
        overrides: [choicesRepositoryProvider.overrideWithValue(memory)],
      );
      addTearDown(container.dispose);
      // Someone is watching, as the screens do.
      container.listen(choicesProvider, (_, _) {});
    });

    test('"I\'m fine with this" adds the finding, and takes it away', () async {
      final controller = container.read(choicesControllerProvider);
      await controller.setAccepted(maps, true);
      await controller.setAccepted(const Finding(Rule.usbDebugging), true);
      expect(memory.now.accepted, {
        'backgroundLocation:com.maps',
        'usbDebugging',
      });
      expect(
        (await container.read(choicesProvider.future)).accepted,
        memory.now.accepted,
      );

      await controller.setAccepted(maps, false);
      expect(memory.now.accepted, {'usbDebugging'});
    });

    test('a tick leaves the accepted findings alone', () async {
      final controller = container.read(choicesControllerProvider);
      await controller.setAccepted(maps, true);
      await controller.setChecked(CheckId.duressPin, true);
      await controller.setChecked(CheckId.usbPort, true);
      await controller.setChecked(CheckId.duressPin, false);
      expect(memory.now.checked, {'usbPort'});
      expect(memory.now.accepted, {'backgroundLocation:com.maps'});
      expect(memory.now.id, 'device-test');
    });

    test('taps faster than the store answers are all kept', () async {
      final controller = container.read(choicesControllerProvider);
      await Future.wait([
        controller.setChecked(CheckId.duressPin, true),
        controller.setChecked(CheckId.usbPort, true),
        controller.setAccepted(maps, true),
        controller.setChecked(CheckId.autoReboot, true),
      ]);
      expect(memory.now.checked, {'duressPin', 'usbPort', 'autoReboot'});
      expect(memory.now.accepted, {'backgroundLocation:com.maps'});
    });

    test('a failed change does not block the next one', () async {
      final controller = container.read(choicesControllerProvider);
      memory.failure = StateError('no room');
      await expectLater(
        controller.setChecked(CheckId.duressPin, true),
        throwsStateError,
      );
      memory.failure = null;
      await controller.setChecked(CheckId.usbPort, true);
      expect(memory.now.checked, {'usbPort'});
    });

    test('a change that cannot be saved is passed on', () async {
      memory.failure = StateError('no room');
      await expectLater(
        container.read(choicesControllerProvider).setAccepted(maps, true),
        throwsStateError,
      );
      expect(memory.now.accepted, isEmpty);
    });
  });
}
