import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zero_trust_core/zero_trust_core.dart';

import '../l10n/l10n.dart';
import '../phone/system_screens.dart';
import '../rules/finding.dart';
import 'finding_page.dart';
import 'texts.dart';

/// A short message at the bottom of the screen.
void showNote(BuildContext context, String text) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(content: Text(text), duration: const Duration(seconds: 4)),
    );
}

/// Opens one of Android's screens and says so when Android refuses.
Future<void> openSystemScreen(
  BuildContext context,
  WidgetRef ref,
  String screen, {
  String? package,
}) async {
  final l = context.l10n;
  final result = await ref
      .read(systemScreensProvider)
      .open(screen, package: package);
  if (!result.ok && context.mounted) {
    showNote(context, l.openFailed(result.error ?? ''));
  }
}

/// The heading over a group of rows.
class SectionTitle extends StatelessWidget {
  const SectionTitle(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(
        ZtSpacing.md,
        ZtSpacing.lg,
        ZtSpacing.md,
        ZtSpacing.sm,
      ),
      child: Text(
        text,
        style: theme.textTheme.titleSmall?.copyWith(
          color: theme.colorScheme.primary,
        ),
      ),
    );
  }
}

/// A plain paragraph with the page's side margins.
class Paragraph extends StatelessWidget {
  const Paragraph(this.text, {super.key, this.small = false});

  final String text;
  final bool small;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: ZtSpacing.md,
        vertical: ZtSpacing.xs,
      ),
      child: Text(
        text,
        style: small
            ? theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              )
            : theme.textTheme.bodyMedium,
      ),
    );
  }
}

/// An app's first letter in a circle. The apps' own icons are left to a
/// later round: reading 300 icons at once needs care not to slow the list.
class AppAvatar extends StatelessWidget {
  const AppAvatar(this.label, {super.key, this.radius = 20});

  final String label;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final letter = label.trim().isEmpty
        ? '?'
        : String.fromCharCode(label.trim().runes.first).toUpperCase();
    return CircleAvatar(
      radius: radius,
      child: Text(letter, style: TextStyle(fontSize: radius * 0.9)),
    );
  }
}

/// One finding in a list. Opens the page that explains it.
class FindingTile extends StatelessWidget {
  const FindingTile(this.finding, {super.key, this.accepted = false});

  final Finding finding;
  final bool accepted;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    return ListTile(
      key: Key('finding-${finding.id}'),
      leading: Icon(
        finding.rule.icon,
        color: accepted ? scheme.outline : scheme.error,
      ),
      title: Text(finding.title(l)),
      subtitle: Text(finding.rule.kind(l)),
      trailing: accepted
          ? Icon(Icons.check, color: scheme.outline)
          : Text(
              '−${finding.rule.points}',
              // The minus stays in front of the number in Hebrew too.
              textDirection: TextDirection.ltr,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(color: scheme.error),
            ),
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute<void>(builder: (_) => FindingPage(finding: finding)),
      ),
    );
  }
}
