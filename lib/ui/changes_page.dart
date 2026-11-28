import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zero_trust_core/zero_trust_core.dart';

import '../l10n/l10n.dart';
import '../phone/phone_providers.dart';
import '../scan/tracker_list.dart';
import '../trackers/changes.dart';
import '../trackers/tracker_providers.dart';
import 'app_page.dart';
import 'texts.dart';
import 'trackers_page.dart';
import 'widgets.dart';

extension ChangeTexts on Change {
  IconData get icon => switch (kind) {
    ChangeKind.newAppTrackers => Icons.download_outlined,
    ChangeKind.trackersAdded => Icons.add_circle_outline,
    ChangeKind.trackersRemoved => Icons.remove_circle_outline,
    ChangeKind.permissionsAdded => Icons.key_outlined,
  };

  /// One sentence that says what happened. [list] gives the trackers
  /// their names; one it no longer knows is shown by its number.
  String text(AppL10n l, TrackerList? list) {
    final app = label.isEmpty ? package : label;
    String trackers() => [
      for (final id in trackerIds) list?.byId[id]?.name ?? '#$id',
    ].join(', ');
    return switch (kind) {
      ChangeKind.newAppTrackers => l.changeNewApp(app, trackers()),
      ChangeKind.trackersAdded => l.changeTrackersAdded(app, trackers()),
      ChangeKind.trackersRemoved => l.changeTrackersRemoved(app, trackers()),
      ChangeKind.permissionsAdded => l.changePermissionsAdded(
        app,
        // Some of these names have a comma of their own.
        permissionNames(l, permissions).join('; '),
      ),
    };
  }
}

/// What changed in the user's apps from one look at the phone to the
/// next, newest first.
class ChangesPage extends ConsumerStatefulWidget {
  const ChangesPage({super.key});

  @override
  ConsumerState<ChangesPage> createState() => _ChangesPageState();
}

class _ChangesPageState extends ConsumerState<ChangesPage> {
  /// When the list was last opened before this time: what came after it
  /// is marked as new for as long as this page stays open. Null until
  /// what the app kept has been read.
  int? _seenBefore;

  void _markSeen() {
    if (mounted) ref.read(trackerScansProvider.notifier).markChangesSeen();
  }

  void _open(Change change) {
    final phone = ref.read(reportProvider).value?.phone;
    if (phone == null) return;
    if (!phone.byPackage.containsKey(change.package)) {
      final name = change.label.isEmpty ? change.package : change.label;
      showNote(context, context.l10n.changeAppGone(name));
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => AppPage(package: change.package)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    // Kept up to date while the page is open: a row asks it whether its
    // app is still there.
    final read = ref.watch(reportProvider.select((report) => report.hasValue));
    final scan = ref.watch(trackerScansProvider);
    final ready = read && scan.results != null;
    if (ready) {
      if (_seenBefore == null) {
        _seenBefore = scan.seenAt;
        Future.microtask(_markSeen);
      } else if (scan.unseenChanges > 0) {
        // A change that arrives while the list is in front of the user
        // has been seen as well.
        Future.microtask(_markSeen);
      }
    }
    final seenBefore = _seenBefore;
    final list = scan.results?.list;
    return Scaffold(
      appBar: AppBar(title: Text(l.changesTile)),
      body: !ready || seenBefore == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              children: [
                const SizedBox(height: ZtSpacing.sm),
                Paragraph(l.changesIntro, key: const Key('changes-intro')),
                const ScanProgress(),
                if (scan.changes.isEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: ZtSpacing.md),
                    child: Paragraph(
                      l.changesEmpty,
                      key: const Key('changes-none'),
                    ),
                  )
                else
                  const SizedBox(height: ZtSpacing.sm),
                for (final (index, change) in scan.changes.indexed)
                  _ChangeTile(
                    key: Key('change-$index'),
                    change: change,
                    text: change.text(l, list),
                    isNew: change.at > seenBefore,
                    onTap: () => _open(change),
                  ),
                const SizedBox(height: ZtSpacing.lg),
              ],
            ),
    );
  }
}

class _ChangeTile extends StatelessWidget {
  const _ChangeTile({
    super.key,
    required this.change,
    required this.text,
    required this.isNew,
    required this.onTap,
  });

  final Change change;
  final String text;
  final bool isNew;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return ListTile(
      leading: Icon(change.icon),
      title: Text(text),
      // A Wrap, so that with very large text the mark moves under the day
      // in place of being squeezed beside it.
      subtitle: Padding(
        padding: const EdgeInsets.only(top: ZtSpacing.xs),
        child: Wrap(
          spacing: ZtSpacing.sm,
          runSpacing: ZtSpacing.xs,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(dayText(change.at)),
            if (isNew)
              Container(
                key: const Key('change-new'),
                padding: const EdgeInsets.symmetric(
                  horizontal: ZtSpacing.sm,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: scheme.primaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  context.l10n.changesNew,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: scheme.onPrimaryContainer,
                  ),
                ),
              ),
          ],
        ),
      ),
      onTap: onTap,
    );
  }
}
