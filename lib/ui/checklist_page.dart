import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zero_trust_core/zero_trust_core.dart';

import '../choices/choices.dart';
import '../l10n/l10n.dart';
import '../phone/phone_providers.dart';
import '../rules/checklist.dart';
import '../rules/finding.dart';
import 'finding_page.dart';
import 'texts.dart';
import 'widgets.dart';

/// What to show next to a line that was read from the phone.
String checkValueText(AppL10n l, DeviceCheck check) {
  final value = switch (check.value) {
    'on' => l.valueOn,
    'off' => l.valueOff,
    final value => value,
  };
  return switch (check.state) {
    CheckState.good => [l.stateGood, ?value].join(' · '),
    CheckState.attention => [l.stateAttention, ?value].join(' · '),
    CheckState.info => value ?? '',
    CheckState.unknown => l.stateUnknown,
    CheckState.manual => '',
  };
}

Future<void> _setChecked(
  BuildContext context,
  WidgetRef ref,
  CheckId id,
  bool checked,
) async {
  final l = context.l10n;
  try {
    await ref.read(choicesControllerProvider).setChecked(id, checked);
  } on Object catch (e) {
    if (context.mounted) showNote(context, l.saveFailed('$e'));
  }
}

/// The device checklist: what the phone says about itself, then the lines
/// Android keeps from apps, which the user looks at and ticks off.
class ChecklistPage extends ConsumerWidget {
  const ChecklistPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final report = ref.watch(reportProvider).value;
    final checked =
        ref.watch(choicesProvider).value?.checked ?? const <String>{};
    final checks = report == null
        ? const <DeviceCheck>[]
        : deviceChecks(report.phone);
    final read = checks.where((c) => c.state != CheckState.manual);
    final manual = checks.where(
      (c) => c.state == CheckState.manual && !c.id.grapheneOnly,
    );
    final graphene = checks.where(
      (c) => c.state == CheckState.manual && c.id.grapheneOnly,
    );

    Widget manualRow(DeviceCheck check) => ListTile(
      key: Key('check-${check.id.name}'),
      leading: Checkbox(
        key: Key('tick-${check.id.name}'),
        value: checked.contains(check.id.name),
        onChanged: (value) =>
            _setChecked(context, ref, check.id, value ?? false),
      ),
      title: Text(check.id.title(l)),
      onTap: () => Navigator.of(
        context,
      ).push(MaterialPageRoute<void>(builder: (_) => CheckPage(id: check.id))),
    );

    return Scaffold(
      appBar: AppBar(title: Text(l.checklistTile)),
      body: report == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              children: [
                SectionTitle(l.checksRead),
                for (final check in read)
                  _ReadRow(
                    check,
                    // A line that needs attention opens its finding, where
                    // "I'm fine with this" lives.
                    finding: check.rule == null
                        ? null
                        : report.findings
                              .where((f) => f.rule == check.rule)
                              .firstOrNull,
                    accepted:
                        check.rule != null &&
                        report.accepted.any((f) => f.rule == check.rule),
                  ),
                SectionTitle(l.checksManual),
                Paragraph(l.checksManualHint, small: true),
                for (final check in manual) manualRow(check),
                if (graphene.isNotEmpty) ...[
                  SectionTitle(l.checksGraphene),
                  for (final check in graphene) manualRow(check),
                ],
                const SizedBox(height: ZtSpacing.lg),
              ],
            ),
    );
  }
}

class _ReadRow extends StatelessWidget {
  const _ReadRow(this.check, {this.finding, this.accepted = false});

  final DeviceCheck check;
  final Finding? finding;
  final bool accepted;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final (icon, color) = switch (check.state) {
      CheckState.good => (Icons.check_circle_outline, scheme.primary),
      CheckState.attention when accepted => (
        Icons.error_outline,
        scheme.outline,
      ),
      CheckState.attention => (Icons.error_outline, scheme.error),
      CheckState.info => (Icons.info_outline, scheme.onSurfaceVariant),
      _ => (Icons.help_outline, scheme.outline),
    };
    final found = finding;
    return ListTile(
      key: Key('check-${check.id.name}'),
      leading: Icon(icon, color: color),
      title: Text(check.id.title(l)),
      subtitle: Text(checkValueText(l, check)),
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => found != null
              ? FindingPage(finding: found)
              : CheckPage(id: check.id),
        ),
      ),
    );
  }
}

/// One line of the checklist: why it is there and the way to its setting.
class CheckPage extends ConsumerWidget {
  const CheckPage({super.key, required this.id});

  final CheckId id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final theme = Theme.of(context);
    final phone = ref.watch(reportProvider).value?.phone;
    final check = phone == null
        ? null
        : deviceChecks(phone).where((c) => c.id == id).firstOrNull;
    final checked =
        ref.watch(choicesProvider).value?.checked.contains(id.name) ?? false;
    final value = check == null ? '' : checkValueText(l, check);
    return Scaffold(
      appBar: AppBar(title: Text(id.title(l))),
      body: ListView(
        padding: const EdgeInsets.all(ZtSpacing.md),
        children: [
          Text(id.title(l), style: theme.textTheme.headlineSmall),
          if (value.isNotEmpty) ...[
            const SizedBox(height: ZtSpacing.sm),
            Text(
              value,
              key: const Key('check-value'),
              style: theme.textTheme.titleMedium,
            ),
          ],
          const SizedBox(height: ZtSpacing.md),
          Text(id.why(l), style: theme.textTheme.bodyLarge),
          const SizedBox(height: ZtSpacing.lg),
          FilledButton.icon(
            key: const Key('check-open'),
            onPressed: () => openSystemScreen(context, ref, id.screen),
            icon: const Icon(Icons.open_in_new),
            label: Text(l.openSetting),
          ),
          if (id.manual)
            CheckboxListTile(
              key: const Key('check-mark'),
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
              title: Text(l.markChecked),
              value: checked,
              onChanged: (value) =>
                  _setChecked(context, ref, id, value ?? false),
            ),
        ],
      ),
    );
  }
}
