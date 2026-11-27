import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zero_trust_core/zero_trust_core.dart';

import '../choices/choices.dart';
import '../l10n/l10n.dart';
import '../phone/phone_providers.dart';
import '../rules/finding.dart';
import '../rules/score.dart';
import 'app_page.dart';
import 'texts.dart';
import 'widgets.dart';

/// One finding: what it is, why it matters, the way to the setting that
/// fixes it, and "I'm fine with this".
class FindingPage extends ConsumerWidget {
  const FindingPage({super.key, required this.finding});

  final Finding finding;

  Future<void> _setAccepted(
    BuildContext context,
    WidgetRef ref,
    bool accepted,
  ) async {
    final l = context.l10n;
    try {
      await ref.read(choicesControllerProvider).setAccepted(finding, accepted);
    } on Object catch (e) {
      if (context.mounted) showNote(context, l.saveFailed('$e'));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final theme = Theme.of(context);
    final rule = finding.rule;

    // Fixed in Settings while this page was open: nothing left to say.
    ref.listen<AsyncValue<PrivacyReport>>(reportProvider, (_, next) {
      final report = next.value;
      if (report != null &&
          !report.findings.contains(finding) &&
          (ModalRoute.of(context)?.isCurrent ?? false)) {
        Navigator.of(context).pop();
      }
    });

    final accepted =
        ref.watch(choicesProvider).value?.accepted.contains(finding.id) ??
        false;
    final package = finding.package;

    return Scaffold(
      appBar: AppBar(title: Text(rule.kind(l))),
      body: ListView(
        padding: const EdgeInsets.all(ZtSpacing.md),
        children: [
          Icon(
            rule.icon,
            size: 48,
            color: accepted
                ? theme.colorScheme.outline
                : theme.colorScheme.error,
          ),
          const SizedBox(height: ZtSpacing.md),
          Text(
            finding.title(l),
            key: const Key('finding-title'),
            style: theme.textTheme.headlineSmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: ZtSpacing.md),
          Text(rule.why(l), style: theme.textTheme.bodyLarge),
          const SizedBox(height: ZtSpacing.md),
          Text(
            accepted
                ? l.findingAccepted
                : rule.points == rule.cap
                ? l.findingCosts(rule.points)
                : l.findingCostsEach(rule.points, rule.cap),
            key: const Key('finding-cost'),
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: ZtSpacing.lg),
          FilledButton.icon(
            key: const Key('finding-open'),
            onPressed: () => openSystemScreen(
              context,
              ref,
              rule.screen,
              package: rule.screenTakesApp ? package : null,
            ),
            icon: const Icon(Icons.open_in_new),
            label: Text(
              rule.screen == 'appDetails' ? l.openAppSettings : l.openSetting,
            ),
          ),
          const SizedBox(height: ZtSpacing.sm),
          OutlinedButton(
            key: const Key('finding-accept'),
            onPressed: () => _setAccepted(context, ref, !accepted),
            child: Text(accepted ? l.unacceptButton : l.acceptButton),
          ),
          if (package != null) ...[
            const SizedBox(height: ZtSpacing.md),
            ListTile(
              key: const Key('finding-app'),
              contentPadding: EdgeInsets.zero,
              leading: AppAvatar(finding.label ?? package),
              title: Text(finding.label ?? package),
              subtitle: Text(l.aboutThisApp),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => AppPage(package: package),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
