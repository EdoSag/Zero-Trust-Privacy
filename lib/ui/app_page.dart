import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zero_trust_core/zero_trust_core.dart';

import '../l10n/l10n.dart';
import '../phone/phone_providers.dart';
import '../rules/checklist.dart';
import '../rules/rules.dart';
import 'apps_page.dart';
import 'texts.dart';
import 'widgets.dart';

/// One app: where it came from, when it was last used, what it holds, and
/// what there is to look at.
class AppPage extends ConsumerWidget {
  const AppPage({super.key, required this.package});

  final String package;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final theme = Theme.of(context);
    final report = ref.watch(reportProvider).value;
    final phone = report?.phone;
    final app = phone?.byPackage[package];
    if (report == null || phone == null || app == null) {
      // Not read yet, or removed while this page was open.
      return Scaffold(
        appBar: AppBar(),
        body: Center(
          child: report == null
              ? const CircularProgressIndicator()
              : Text(l.nothingToLookAt),
        ),
      );
    }

    final name = app.label.isEmpty ? app.package : app.label;
    final installer = app.installer;
    final lastUsed = phone.lastUsed(package);
    final findings = report.forApp(package);
    final holds = <(IconData, String)>[
      for (final access in watchedAccess)
        if (holdsAccess(phone, access, app))
          (access.rule.icon, access.rule.kind(l)),
      for (final permission in watchedPermissions)
        if (permission.permissions.any(app.holds))
          (permission.icon, permission.name(l)),
    ];

    return Scaffold(
      appBar: AppBar(title: Text(name)),
      body: ListView(
        children: [
          const SizedBox(height: ZtSpacing.md),
          Center(child: AppAvatar(name, radius: 32)),
          const SizedBox(height: ZtSpacing.sm),
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: ZtSpacing.md),
              child: Text(
                name,
                style: theme.textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),
            ),
          ),
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: ZtSpacing.md),
              child: Text(
                app.package,
                // A technical name reads left to right in Hebrew too.
                textDirection: TextDirection.ltr,
                style: theme.textTheme.bodySmall,
                textAlign: TextAlign.center,
              ),
            ),
          ),
          const SizedBox(height: ZtSpacing.md),
          if (app.system) Paragraph(l.appSystem),
          Paragraph(
            installer == null
                ? l.appInstalledFromUnknown
                : l.appInstalledFrom(
                    phone.byPackage[installer]?.label ?? installer,
                  ),
          ),
          if (app.targetSdk > 0)
            Paragraph(l.appBuiltFor(androidVersionOf(app.targetSdk))),
          if (app.firstInstall > 0)
            Paragraph(l.appInstalledOn(dayText(app.firstInstall))),
          if (app.lastUpdate > 0)
            Paragraph(l.appUpdatedOn(dayText(app.lastUpdate))),
          Paragraph(
            lastUsed == null
                ? (phone.usageGranted
                      ? l.lastUsedUnknown
                      : l.lastUsedNeedsAccess)
                : lastUsed > 0
                ? l.appLastUsed(dayText(lastUsed))
                : l.appNotUsed,
            key: const Key('app-last-used'),
          ),
          SectionTitle(l.appFindingsTitle),
          if (findings.isEmpty) Paragraph(l.appNoFindings),
          for (final finding in findings)
            FindingTile(finding, accepted: report.isAccepted(finding)),
          SectionTitle(l.appHoldsTitle),
          if (holds.isEmpty) Paragraph(l.appHoldsNothing),
          for (final (icon, text) in holds)
            ListTile(dense: true, leading: Icon(icon), title: Text(text)),
          Padding(
            padding: const EdgeInsets.all(ZtSpacing.md),
            child: FilledButton.icon(
              key: const Key('app-open-settings'),
              onPressed: () => openSystemScreen(
                context,
                ref,
                Screens.appDetails,
                package: package,
              ),
              icon: const Icon(Icons.open_in_new),
              label: Text(l.openAppSettings),
            ),
          ),
        ],
      ),
    );
  }
}
