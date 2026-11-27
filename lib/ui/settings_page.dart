import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:zero_trust_core/zero_trust_core.dart';

import '../app_info.dart';
import '../l10n/l10n.dart';
import '../phone/system_screens.dart';
import '../scan/tracker_scan.dart';
import 'phone_test_controller.dart';
import 'phone_test_page.dart';

/// The shared Zero-Trust settings screen, with Privacy's own row.
class PrivacySettingsPage extends ConsumerWidget {
  const PrivacySettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ZtSettingsPage(
      showSyncStatus: true,
      onSignedOut: () => Navigator.of(context).popUntil((r) => r.isFirst),
      onOpenUrl: (url) => launchUrl(url, mode: LaunchMode.externalApplication),
      privacyPolicyUrl: Uri.parse('https://zerotrust.bz/privacy'),
      termsUrl: Uri.parse('https://zerotrust.bz/terms'),
      supportUrl: Uri.parse('https://zerotrust.bz/support'),
      // "Export my data": what this app keeps in the account (the choices
      // made on each phone) as readable files.
      onDataExported: (file, _) => ref
          .read(vaultControllerProvider.notifier)
          .whileShowingSystemUi(
            () => SharePlus.instance.share(
              ShareParams(files: [XFile(file.path)]),
            ),
          ),
      appSection: const [PhoneTestRow()],
    );
  }
}

/// The way into the phone test, which stays in the app: it is how a new
/// Android version or another phone gets checked.
class PhoneTestRow extends StatelessWidget {
  const PhoneTestRow({super.key});

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return ListTile(
      key: const Key('setting-phone-test'),
      leading: const Icon(Icons.fact_check_outlined),
      title: Text(l.settingsPhoneTest),
      subtitle: Text(l.settingsPhoneTestHint),
      onTap: () => Navigator.of(
        context,
      ).push(MaterialPageRoute<void>(builder: (_) => const PhoneTestScreen())),
    );
  }
}

/// The phone test with a run of its own, thrown away when the page closes.
class PhoneTestScreen extends ConsumerStatefulWidget {
  const PhoneTestScreen({super.key});

  @override
  ConsumerState<PhoneTestScreen> createState() => _PhoneTestScreenState();
}

class _PhoneTestScreenState extends ConsumerState<PhoneTestScreen> {
  late final PhoneTestController _controller = PhoneTestController(
    probe: AwayAwareProbe(ref.read(systemScreensProvider)),
    scanner: const IsolateTrackerScanner(),
    build: appBuild,
  )..addListener(_active);

  /// The scan runs for minutes with nobody touching the screen; its
  /// progress counts as activity, so the app does not lock half way.
  void _active() {
    if (_controller.scanning) {
      ref.read(vaultControllerProvider.notifier).touch();
    }
  }

  @override
  void dispose() {
    _controller
      ..removeListener(_active)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => PhoneTestPage(controller: _controller);
}
