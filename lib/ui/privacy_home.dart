import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zero_trust_core/zero_trust_core.dart';

import '../choices/choices.dart';
import '../l10n/l10n.dart';
import '../phone/phone_providers.dart';
import '../rules/checklist.dart';
import '../rules/score.dart';
import '../trackers/tracker_providers.dart';
import 'apps_page.dart';
import 'changes_page.dart';
import 'checklist_page.dart';
import 'score_page.dart';
import 'settings_page.dart';
import 'trackers_page.dart';
import 'widgets.dart';

/// The dashboard: the score, what to fix next, and the ways into the app
/// list and the device checklist.
class PrivacyHome extends ConsumerStatefulWidget {
  const PrivacyHome({super.key});

  @override
  ConsumerState<PrivacyHome> createState() => _PrivacyHomeState();
}

class _PrivacyHomeState extends ConsumerState<PrivacyHome>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // After an unlock the phone may have changed while the app was away.
    Future.microtask(_refresh);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// Back from Settings: what was just changed there shows right away.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _refresh();
  }

  Future<void> _refresh() async {
    if (mounted) await ref.read(phoneProvider.notifier).refresh();
  }

  void _push(Widget page) =>
      Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => page));

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final report = ref.watch(reportProvider);
    return Scaffold(
      appBar: AppBar(
        title: Text(l.appTitle),
        actions: [
          IconButton(
            key: const Key('home-refresh'),
            tooltip: l.refreshTooltip,
            icon: const Icon(Icons.refresh),
            onPressed: _refresh,
          ),
          IconButton(
            key: const Key('home-settings'),
            tooltip: l.settingsTooltip,
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => _push(const PrivacySettingsPage()),
          ),
        ],
      ),
      body: switch (report) {
        AsyncData(:final value) => RefreshIndicator(
          onRefresh: _refresh,
          child: _Dashboard(report: value, push: _push),
        ),
        AsyncError(:final error) => _ReadFailed(
          error: error,
          onRetry: () => ref.invalidate(phoneProvider),
        ),
        _ => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: ZtSpacing.md),
              Text(l.readingPhone),
            ],
          ),
        ),
      },
    );
  }
}

class _ReadFailed extends StatelessWidget {
  const _ReadFailed({required this.error, required this.onRetry});

  final Object error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(ZtSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l.readFailed('$error'), textAlign: TextAlign.center),
            const SizedBox(height: ZtSpacing.md),
            FilledButton(
              key: const Key('home-retry'),
              onPressed: onRetry,
              child: Text(l.tryAgain),
            ),
          ],
        ),
      ),
    );
  }
}

class _Dashboard extends ConsumerWidget {
  const _Dashboard({required this.report, required this.push});

  final PrivacyReport report;
  final void Function(Widget page) push;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final theme = Theme.of(context);
    final phone = report.phone;
    final next = report.fixNext();
    final checks = deviceChecks(phone);
    final checked =
        ref.watch(choicesProvider).value?.checked ?? const <String>{};
    final toFix = checks
        .where(
          (c) =>
              c.state == CheckState.attention &&
              !report.accepted.any((f) => f.rule == c.rule),
        )
        .length;
    final scan = ref.watch(trackerScansProvider);
    final trackers = report.trackers;
    final withTrackers = trackers == null
        ? 0
        : phone.userApps
              .where((app) => trackers.of(app)?.isNotEmpty ?? false)
              .length;
    final toCheck = checks
        .where(
          (c) => c.state == CheckState.manual && !checked.contains(c.id.name),
        )
        .length;

    return ListView(
      // Always scrollable, so pulling down to read again works on a phone
      // with nothing to show.
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(vertical: ZtSpacing.sm),
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: ZtSpacing.md),
          child: _ScoreCard(
            report: report,
            onTap: () => push(const ScorePage()),
          ),
        ),
        if (phone.errors.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: ZtSpacing.sm),
            child: Paragraph(
              l.partsFailed(phone.errors.keys.join(', ')),
              key: const Key('home-parts-failed'),
              small: true,
            ),
          ),
        if (next.isNotEmpty) ...[
          SectionTitle(l.fixNext),
          for (final finding in next) FindingTile(finding),
          if (report.open.length > next.length)
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: ZtSpacing.sm),
                child: TextButton(
                  key: const Key('home-see-all'),
                  onPressed: () => push(const FindingsPage()),
                  child: Text(l.seeAll(report.open.length)),
                ),
              ),
            ),
        ],
        if (!phone.usageGranted)
          Padding(
            padding: const EdgeInsets.fromLTRB(
              ZtSpacing.md,
              ZtSpacing.md,
              ZtSpacing.md,
              0,
            ),
            child: _UsageCard(),
          ),
        const SizedBox(height: ZtSpacing.md),
        _Door(
          key: const Key('home-apps'),
          icon: Icons.apps,
          title: l.appsTile,
          subtitle: l.appsTileSub(
            phone.userApps.length,
            report.openAbout(apps: true).length,
          ),
          onTap: () => push(const AppsPage()),
        ),
        _Door(
          key: const Key('home-trackers'),
          icon: Icons.radar,
          title: l.trackersTile,
          subtitle: trackers == null
              ? l.trackersTileWaiting
              : scan.scanning
              ? l.trackersScanning(scan.done, scan.total)
              : l.trackersTileSub(withTrackers, phone.userApps.length),
          progress: scan.scanning && scan.total > 0
              ? scan.done / scan.total
              : null,
          onTap: () => push(const TrackersPage()),
        ),
        _Door(
          key: const Key('home-changes'),
          icon: Icons.update,
          title: l.changesTile,
          subtitle: scan.changes.isEmpty
              ? l.changesTileNone
              : scan.unseenChanges > 0
              ? l.changesTileNew(scan.unseenChanges)
              : l.changesTileNothingNew,
          badge: scan.unseenChanges,
          onTap: () => push(const ChangesPage()),
        ),
        _Door(
          key: const Key('home-checklist'),
          icon: Icons.checklist,
          title: l.checklistTile,
          subtitle: l.checklistTileSub(toFix, toCheck),
          onTap: () => push(const ChecklistPage()),
        ),
        const SizedBox(height: ZtSpacing.md),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: ZtSpacing.md),
          child: Row(
            children: [
              Icon(
                Icons.phonelink_lock_outlined,
                size: 18,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: ZtSpacing.sm),
              Expanded(
                child: Text(
                  l.phoneOnlyNote,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: ZtSpacing.lg),
      ],
    );
  }
}

class _ScoreCard extends StatelessWidget {
  const _ScoreCard({required this.report, required this.onTap});

  final PrivacyReport report;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final theme = Theme.of(context);
    final color = scoreColor(context, report.score);
    return Card(
      key: const Key('home-score'),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(ZtSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l.scoreTitle, style: theme.textTheme.titleMedium),
              const SizedBox(height: ZtSpacing.sm),
              // A Wrap, so that with very large text "of 100" moves under
              // the number in place of running off the card.
              Wrap(
                crossAxisAlignment: WrapCrossAlignment.end,
                spacing: ZtSpacing.sm,
                children: [
                  Text(
                    '${report.score}',
                    key: const Key('home-score-value'),
                    style: theme.textTheme.displayLarge?.copyWith(
                      color: color,
                      fontWeight: FontWeight.w600,
                      height: 1,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(bottom: ZtSpacing.sm),
                    child: Text(
                      l.scoreOutOf,
                      style: theme.textTheme.titleMedium,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: ZtSpacing.sm),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: report.score / 100,
                  minHeight: 8,
                  color: color,
                ),
              ),
              const SizedBox(height: ZtSpacing.md),
              Text(
                report.open.isEmpty
                    ? l.scoreAllGood
                    : l.scoreToFix(report.open.length),
                key: const Key('home-score-summary'),
              ),
              const SizedBox(height: ZtSpacing.xs),
              Text(
                l.scoreExplain,
                style: theme.textTheme.labelLarge?.copyWith(
                  color: theme.colorScheme.primary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Asks for Usage access, which Android only gives from its own screen.
class _UsageCard extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final theme = Theme.of(context);
    return Card(
      key: const Key('home-usage'),
      child: Padding(
        padding: const EdgeInsets.all(ZtSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l.usageCardTitle, style: theme.textTheme.titleMedium),
            const SizedBox(height: ZtSpacing.sm),
            Text(l.usageCardBody),
            const SizedBox(height: ZtSpacing.md),
            OutlinedButton(
              key: const Key('home-usage-open'),
              onPressed: () =>
                  openSystemScreen(context, ref, Screens.usageAccess),
              child: Text(l.usageCardButton),
            ),
          ],
        ),
      ),
    );
  }
}

/// A way into one of the app's big lists.
class _Door extends StatelessWidget {
  const _Door({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.progress,
    this.badge = 0,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  /// From 0 to 1 while the list behind the door is still being made.
  final double? progress;

  /// A number on the icon: how many new things wait behind the door.
  final int badge;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: ZtSpacing.md,
        vertical: ZtSpacing.xs,
      ),
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: badge > 0
                  ? Badge(label: Text('$badge'), child: Icon(icon))
                  : Icon(icon),
              title: Text(title),
              subtitle: Text(subtitle),
              onTap: onTap,
            ),
            if (progress != null)
              LinearProgressIndicator(value: progress, minHeight: 4),
          ],
        ),
      ),
    );
  }
}
