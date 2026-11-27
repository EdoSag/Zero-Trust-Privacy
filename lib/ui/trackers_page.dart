import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zero_trust_core/zero_trust_core.dart';

import '../l10n/l10n.dart';
import '../phone/phone_providers.dart';
import '../phone/phone_snapshot.dart';
import '../probe/device_probe.dart';
import '../scan/tracker_list.dart';
import '../trackers/tracker_providers.dart';
import '../trackers/tracker_results.dart';
import 'apps_page.dart';
import 'texts.dart';
import 'widgets.dart';

/// Exodus Privacy's own page about one tracker. Opened only when the user
/// asks; it names the tracker, never an app on this phone.
Uri exodusPageOf(Tracker tracker) => Uri.parse(
  'https://reports.exodus-privacy.eu.org/en/trackers/${tracker.id}/',
);

int _byLabel(InstalledApp a, InstalledApp b) =>
    a.label.toLowerCase().compareTo(b.label.toLowerCase());

/// The line under an app's name in a list about tracker code.
String trackerNote(AppL10n l, TrackerResults results, InstalledApp app) {
  final scan = results.scanOf(app);
  if (scan == null) return l.appNotChecked;
  if (scan.unreadable) return l.appUnreadable;
  final count = results.of(app)?.length ?? 0;
  return count == 0 ? l.appNoTrackers : l.appTrackerCount(count);
}

/// Where the scan stands, shown while it runs.
class ScanProgress extends ConsumerWidget {
  const ScanProgress({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scan = ref.watch(trackerScansProvider);
    if (!scan.scanning || scan.total == 0) return const SizedBox.shrink();
    return Padding(
      key: const Key('trackers-progress'),
      padding: const EdgeInsets.fromLTRB(
        ZtSpacing.md,
        ZtSpacing.sm,
        ZtSpacing.md,
        ZtSpacing.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(context.l10n.trackersScanning(scan.done, scan.total)),
          const SizedBox(height: ZtSpacing.xs),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: scan.done / scan.total,
              minHeight: 6,
            ),
          ),
        ],
      ),
    );
  }
}

/// Tracker code in the phone's apps, two ways round: what each app
/// contains, and which apps contain one tracker.
class TrackersPage extends ConsumerStatefulWidget {
  const TrackersPage({super.key});

  @override
  ConsumerState<TrackersPage> createState() => _TrackersPageState();
}

class _TrackersPageState extends ConsumerState<TrackersPage> {
  bool _showSystem = false;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final report = ref.watch(reportProvider).value;
    final results = report?.trackers;
    final scanning = ref.watch(
      trackerScansProvider.select((scan) => scan.scanning),
    );
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text(l.trackersTile),
          bottom: TabBar(
            tabs: [
              Tab(text: l.tabByApp),
              Tab(text: l.tabByTracker),
            ],
          ),
        ),
        body: report == null || results == null
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  const ScanProgress(),
                  SwitchListTile(
                    key: const Key('show-system'),
                    title: Text(l.showSystem),
                    value: _showSystem,
                    onChanged: (value) => setState(() => _showSystem = value),
                  ),
                  const Divider(height: 1),
                  Expanded(
                    child: TabBarView(
                      children: [
                        _ByApp(apps: _apps(report.phone), results: results),
                        _ByTracker(
                          apps: _apps(report.phone),
                          results: results,
                          scanning: scanning,
                          withSystemApps: _showSystem,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  List<InstalledApp> _apps(PhoneSnapshot phone) =>
      _showSystem ? phone.apps : phone.userApps;
}

class _Credit extends StatelessWidget {
  const _Credit(this.list);

  final TrackerList list;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: ZtSpacing.md, bottom: ZtSpacing.lg),
    child: Paragraph(
      context.l10n.trackersCredit(list.trackers.length, list.newestEntry),
      key: const Key('trackers-credit'),
      small: true,
    ),
  );
}

class _ByApp extends StatelessWidget {
  const _ByApp({required this.apps, required this.results});

  final List<InstalledApp> apps;
  final TrackerResults results;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    int count(InstalledApp app) => results.of(app)?.length ?? 0;
    // The apps with the most tracker code first, then by name.
    final shown = [...apps]
      ..sort((a, b) {
        final byCount = count(b).compareTo(count(a));
        return byCount != 0 ? byCount : _byLabel(a, b);
      });
    return ListView.builder(
      itemCount: shown.length + 2,
      itemBuilder: (context, index) {
        if (index == 0) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: ZtSpacing.sm),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Paragraph(l.trackersIntro, key: const Key('trackers-intro')),
                Paragraph(l.trackersCaveat, small: true),
              ],
            ),
          );
        }
        if (index == shown.length + 1) return _Credit(results.list);
        final app = shown[index - 1];
        return AppRow(
          app,
          note: trackerNote(l, results, app),
          warn: count(app) > 0,
        );
      },
    );
  }
}

class _ByTracker extends StatelessWidget {
  const _ByTracker({
    required this.apps,
    required this.results,
    required this.scanning,
    required this.withSystemApps,
  });

  final List<InstalledApp> apps;
  final TrackerResults results;
  final bool scanning;
  final bool withSystemApps;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final inApps = <Tracker, int>{};
    for (final app in apps) {
      for (final tracker in results.of(app) ?? const <Tracker>[]) {
        inApps[tracker] = (inApps[tracker] ?? 0) + 1;
      }
    }
    // The trackers in the most apps first, then by name.
    final found = inApps.keys.toList()
      ..sort((a, b) {
        final byCount = inApps[b]!.compareTo(inApps[a]!);
        return byCount != 0
            ? byCount
            : a.name.toLowerCase().compareTo(b.name.toLowerCase());
      });
    return ListView(
      children: [
        const SizedBox(height: ZtSpacing.sm),
        if (found.isEmpty)
          Paragraph(
            scanning ? l.noTrackersYet : l.noTrackersAnywhere,
            key: const Key('trackers-none'),
          ),
        for (final tracker in found)
          ListTile(
            key: Key('tracker-${tracker.id}'),
            leading: const Icon(Icons.radar),
            title: Text(tracker.name),
            subtitle: Text(
              '${l.trackerInApps(inApps[tracker]!)} · '
              '${tracker.kindsText(l)}',
            ),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => TrackerPage(
                  trackerId: tracker.id,
                  withSystemApps: withSystemApps,
                ),
              ),
            ),
          ),
        _Credit(results.list),
      ],
    );
  }
}

/// One tracker: what it is for, and the apps whose code contains it. Like
/// the other lists it asks the phone as it is now.
class TrackerPage extends ConsumerWidget {
  const TrackerPage({
    super.key,
    required this.trackerId,
    this.withSystemApps = false,
  });

  final int trackerId;
  final bool withSystemApps;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final theme = Theme.of(context);
    final report = ref.watch(reportProvider).value;
    final results = report?.trackers;
    final tracker = results?.list.byId[trackerId];
    if (report == null || results == null || tracker == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    final phone = report.phone;
    final holders = [
      for (final app in withSystemApps ? phone.apps : phone.userApps)
        if (results.of(app)?.contains(tracker) ?? false) app,
    ]..sort(_byLabel);
    return Scaffold(
      appBar: AppBar(title: Text(tracker.name)),
      body: ListView(
        children: [
          const SizedBox(height: ZtSpacing.md),
          const Center(child: Icon(Icons.radar, size: 48)),
          const SizedBox(height: ZtSpacing.sm),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: ZtSpacing.md),
            child: Text(
              tracker.name,
              style: theme.textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: ZtSpacing.md),
            child: Text(
              tracker.kindsText(l),
              key: const Key('tracker-kinds'),
              style: theme.textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ),
          if (tracker.website.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: ZtSpacing.md),
              child: Text(
                tracker.website,
                // An address reads left to right in Hebrew too.
                textDirection: TextDirection.ltr,
                style: theme.textTheme.bodySmall,
                textAlign: TextAlign.center,
              ),
            ),
          const SizedBox(height: ZtSpacing.md),
          Paragraph(l.trackersCaveat),
          Padding(
            padding: const EdgeInsets.all(ZtSpacing.md),
            child: OutlinedButton.icon(
              key: const Key('tracker-read-more'),
              onPressed: () => openLink(context, ref, exodusPageOf(tracker)),
              icon: const Icon(Icons.open_in_new),
              label: Text(l.trackerReadMore),
            ),
          ),
          SectionTitle(l.trackerAppsTitle),
          if (holders.isEmpty) Paragraph(l.trackerNoApps),
          for (final app in holders) AppRow(app),
          const SizedBox(height: ZtSpacing.lg),
        ],
      ),
    );
  }
}
