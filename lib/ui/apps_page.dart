import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zero_trust_core/zero_trust_core.dart';

import '../l10n/l10n.dart';
import '../phone/phone_providers.dart';
import '../phone/phone_snapshot.dart';
import '../probe/device_probe.dart';
import '../rules/score.dart';
import 'app_page.dart';
import 'texts.dart';
import 'widgets.dart';

/// Whether [app] holds what [access] stands for.
bool holdsAccess(PhoneSnapshot phone, WatchedAccess access, InstalledApp app) =>
    access.list != null
    ? phone.listed(access.list!).contains(app.package)
    : phone.holdsSpecial(access.permission!, app.package);

int _byLabel(InstalledApp a, InstalledApp b) =>
    a.label.toLowerCase().compareTo(b.label.toLowerCase());

/// Apps and permissions, two ways round: which apps hold a permission, and
/// what one app holds.
class AppsPage extends ConsumerStatefulWidget {
  const AppsPage({super.key});

  @override
  ConsumerState<AppsPage> createState() => _AppsPageState();
}

class _AppsPageState extends ConsumerState<AppsPage> {
  bool _showSystem = false;
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final report = ref.watch(reportProvider).value;
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text(l.appsTile),
          bottom: TabBar(
            tabs: [
              Tab(text: l.tabByPermission),
              Tab(text: l.tabByApp),
            ],
          ),
        ),
        body: report == null
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
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
                        _ByPermission(
                          phone: report.phone,
                          apps: _apps(report.phone),
                          withSystemApps: _showSystem,
                        ),
                        _ByApp(
                          report: report,
                          apps: _apps(report.phone),
                          query: _query,
                          onQuery: (text) => setState(() => _query = text),
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

class _ByPermission extends StatelessWidget {
  const _ByPermission({
    required this.phone,
    required this.apps,
    required this.withSystemApps,
  });

  final PhoneSnapshot phone;
  final List<InstalledApp> apps;
  final bool withSystemApps;

  void _open(BuildContext context, String title, String? why, HoldsIt holds) =>
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => HoldersPage(
            title: title,
            why: why,
            holds: holds,
            withSystemApps: withSystemApps,
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return ListView(
      children: [
        SectionTitle(l.sectionSpecial),
        for (final access in watchedAccess)
          () {
            final holders = [
              for (final app in apps)
                if (holdsAccess(phone, access, app)) app,
            ]..sort(_byLabel);
            return ListTile(
              key: Key('access-${access.rule.name}'),
              leading: Icon(access.rule.icon),
              title: Text(access.rule.kind(l)),
              subtitle: Text(l.heldByOnly(holders.length)),
              onTap: () => _open(
                context,
                access.rule.kind(l),
                access.rule.why(l),
                (phone, app) => holdsAccess(phone, access, app),
              ),
            );
          }(),
        SectionTitle(l.sectionPermissions),
        for (final permission in watchedPermissions)
          () {
            final holders = [
              for (final app in apps)
                if (permission.permissions.any(app.holds)) app,
            ]..sort(_byLabel);
            final asking = apps
                .where((app) => permission.permissions.any(app.requests))
                .length;
            return ListTile(
              key: Key('permission-${permission.permissions.first}'),
              leading: Icon(permission.icon),
              title: Text(permission.name(l)),
              subtitle: Text(l.heldBy(holders.length, asking)),
              onTap: () => _open(
                context,
                permission.name(l),
                null,
                (_, app) => permission.permissions.any(app.holds),
              ),
            );
          }(),
        const SizedBox(height: ZtSpacing.lg),
      ],
    );
  }
}

class _ByApp extends StatelessWidget {
  const _ByApp({
    required this.report,
    required this.apps,
    required this.query,
    required this.onQuery,
  });

  final PrivacyReport report;
  final List<InstalledApp> apps;
  final String query;
  final ValueChanged<String> onQuery;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final open = <String, int>{};
    for (final finding in report.open) {
      final package = finding.package;
      if (package != null) open[package] = (open[package] ?? 0) + 1;
    }
    final wanted = query.trim().toLowerCase();
    final shown =
        [
            for (final app in apps)
              if (wanted.isEmpty ||
                  app.label.toLowerCase().contains(wanted) ||
                  app.package.toLowerCase().contains(wanted))
                app,
          ]
          // The apps with something to look at first, then by name.
          ..sort((a, b) {
            final count = (open[b.package] ?? 0).compareTo(
              open[a.package] ?? 0,
            );
            return count != 0 ? count : _byLabel(a, b);
          });
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(ZtSpacing.md),
          child: TextField(
            key: const Key('app-search'),
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.search),
              hintText: l.searchApps,
            ),
            onChanged: onQuery,
          ),
        ),
        Expanded(
          child: shown.isEmpty
              ? Center(child: Text(l.noAppsMatch))
              : ListView.builder(
                  itemCount: shown.length,
                  itemBuilder: (context, index) {
                    final app = shown[index];
                    final count = open[app.package] ?? 0;
                    return AppRow(
                      app,
                      note: count > 0 ? l.appToLookAt(count) : null,
                      warn: count > 0,
                    );
                  },
                ),
        ),
      ],
    );
  }
}

/// One app in a list. Opens the app's page.
class AppRow extends StatelessWidget {
  const AppRow(this.app, {super.key, this.note, this.warn = false});

  final InstalledApp app;

  /// Shown under the name in place of the app's technical name.
  final String? note;
  final bool warn;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final theme = Theme.of(context);
    final name = app.label.isEmpty ? app.package : app.label;
    return ListTile(
      key: Key('app-${app.package}'),
      leading: AppAvatar(name),
      title: Text(name, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Text(
        note ?? (app.system ? l.appSystem : app.package),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: warn ? TextStyle(color: theme.colorScheme.error) : null,
      ),
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute<void>(builder: (_) => AppPage(package: app.package)),
      ),
    );
  }
}

/// The apps that hold one permission or one special access.
/// Whether an app holds the thing a [HoldersPage] is about.
typedef HoldsIt = bool Function(PhoneSnapshot phone, InstalledApp app);

/// The apps that hold one permission or access. It asks the phone as it is
/// now, not as it was when the page opened: an app whose permission was
/// just taken away in Android's settings leaves the list.
class HoldersPage extends ConsumerWidget {
  const HoldersPage({
    super.key,
    required this.title,
    required this.holds,
    this.withSystemApps = false,
    this.why,
  });

  final String title;
  final String? why;
  final HoldsIt holds;
  final bool withSystemApps;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final phone = ref.watch(reportProvider).value?.phone;
    if (phone == null) {
      return Scaffold(
        appBar: AppBar(title: Text(title)),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    final holders = [
      for (final app in withSystemApps ? phone.apps : phone.userApps)
        if (holds(phone, app)) app,
    ]..sort(_byLabel);
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: ListView(
        children: [
          if (why != null) ...[
            const SizedBox(height: ZtSpacing.sm),
            Paragraph(why!),
          ],
          SectionTitle(l.holdersTitle),
          if (holders.isEmpty) Paragraph(l.noAppHolds),
          for (final app in holders) AppRow(app),
          const SizedBox(height: ZtSpacing.lg),
        ],
      ),
    );
  }
}
