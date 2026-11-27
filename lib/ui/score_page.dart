import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zero_trust_core/zero_trust_core.dart';

import '../l10n/l10n.dart';
import '../phone/phone_providers.dart';
import '../rules/finding.dart';
import '../rules/score.dart';
import 'texts.dart';
import 'widgets.dart';

/// The colour of a score: calm when high, a warning in the middle, the
/// error colour when low.
Color scoreColor(BuildContext context, int score) {
  final scheme = Theme.of(context).colorScheme;
  if (score >= 80) return scheme.primary;
  if (score >= 50) return scheme.tertiary;
  return scheme.error;
}

/// Every point of the score, listed: each kind of finding, how many were
/// found, and what they take off.
class ScorePage extends ConsumerWidget {
  const ScorePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final theme = Theme.of(context);
    final report = ref.watch(reportProvider).value;
    return Scaffold(
      appBar: AppBar(title: Text(l.scoreTitle)),
      body: report == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              children: [
                const SizedBox(height: ZtSpacing.md),
                Center(
                  child: Text(
                    '${report.score}',
                    key: const Key('score-page-value'),
                    style: theme.textTheme.displayLarge?.copyWith(
                      color: scoreColor(context, report.score),
                    ),
                  ),
                ),
                Center(child: Text(l.scoreOutOf)),
                const SizedBox(height: ZtSpacing.md),
                Paragraph(l.scoreIntro),
                if (report.lines.isEmpty) Paragraph(l.scoreNoLines),
                for (final line in report.lines) _Line(line),
                const SizedBox(height: ZtSpacing.lg),
              ],
            ),
    );
  }
}

class _Line extends StatelessWidget {
  const _Line(this.line);

  final ScoreLine line;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final theme = Theme.of(context);
    final counts = line.deducted > 0;
    return ListTile(
      key: Key('score-line-${line.rule.name}'),
      leading: Icon(
        line.rule.icon,
        color: counts ? theme.colorScheme.error : theme.colorScheme.outline,
      ),
      title: Text(line.rule.kind(l)),
      subtitle: Text(
        [
          l.scoreLine(line.open, line.deducted),
          if (line.accepted > 0) l.scoreLineAccepted(line.accepted),
        ].join('\n'),
      ),
      trailing: Text(
        counts ? '−${line.deducted}' : '0',
        // The minus stays in front of the number in Hebrew too.
        textDirection: TextDirection.ltr,
        style: theme.textTheme.titleMedium?.copyWith(
          color: counts ? theme.colorScheme.error : theme.colorScheme.outline,
        ),
      ),
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute<void>(builder: (_) => FindingsPage(rule: line.rule)),
      ),
    );
  }
}

/// The findings, the ones that count first, then the ones the user is fine
/// with. All of them, or those of one kind.
class FindingsPage extends ConsumerWidget {
  const FindingsPage({super.key, this.rule});

  final Rule? rule;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final report = ref.watch(reportProvider).value;
    bool wanted(Finding finding) => rule == null || finding.rule == rule;
    final open = [...?report?.open.where(wanted)];
    final accepted = [...?report?.accepted.where(wanted)];
    return Scaffold(
      appBar: AppBar(title: Text(rule?.kind(l) ?? l.allFindings)),
      body: ListView(
        children: [
          if (rule != null) ...[
            const SizedBox(height: ZtSpacing.sm),
            Paragraph(rule!.why(l)),
          ],
          if (open.isEmpty && accepted.isEmpty) Paragraph(l.nothingToLookAt),
          for (final finding in open) FindingTile(finding),
          if (accepted.isNotEmpty) SectionTitle(l.acceptedHeading),
          for (final finding in accepted) FindingTile(finding, accepted: true),
          const SizedBox(height: ZtSpacing.lg),
        ],
      ),
    );
  }
}
