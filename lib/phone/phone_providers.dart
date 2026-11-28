import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../choices/choices.dart';
import '../probe/device_probe.dart';
import '../rules/score.dart';
import '../trackers/tracker_providers.dart';
import 'phone_snapshot.dart';

/// How the app reads the phone. Tests put a made-up phone here.
final deviceProbeProvider = Provider<DeviceProbe>(
  (ref) => const ChannelDeviceProbe(),
);

/// The phone as it is now. Read when the dashboard opens and again each
/// time the app comes back to the front, since the user has usually just
/// changed something in Settings.
class Phone extends AsyncNotifier<PhoneSnapshot> {
  @override
  Future<PhoneSnapshot> build() => readPhone(ref.watch(deviceProbeProvider));

  /// Reads again. What is on screen stays until the new reading is in, so
  /// coming back from Settings does not flash an empty page.
  Future<void> refresh() async {
    // The first reading is still on its way: it is fresh enough.
    if (_reading || (state.isLoading && !state.hasValue)) return;
    _reading = true;
    try {
      final next = await AsyncValue.guard(
        () => readPhone(ref.read(deviceProbeProvider)),
      );
      // A reading that fails does not wipe a good one already on screen.
      if (next.hasValue || !state.hasValue) state = next;
    } finally {
      _reading = false;
    }
  }

  bool _reading = false;
}

final phoneProvider = AsyncNotifierProvider<Phone, PhoneSnapshot>(Phone.new);

/// The findings and the score: the phone and what the scan for tracker
/// code found in its apps, less what the user is fine with.
final reportProvider = Provider<AsyncValue<PrivacyReport>>((ref) {
  final choices = ref.watch(choicesProvider);
  // Waits for the choices, so the score does not start low and jump up.
  // Choices that cannot be read count as none.
  if (choices.isLoading && !choices.hasValue) return const AsyncLoading();
  final accepted = choices.value?.accepted ?? const <String>{};
  // The same for what earlier scans found, which is read in a moment.
  if (ref.watch(trackerScansProvider.select((scan) => scan.starting))) {
    return const AsyncLoading();
  }
  final trackers = ref.watch(trackerResultsProvider);
  return ref
      .watch(phoneProvider)
      .whenData(
        (phone) =>
            PrivacyReport(phone: phone, accepted: accepted, trackers: trackers),
      );
});
