import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../l10n/l10n.dart';
import '../probe/device_probe.dart';
import '../report/report.dart';
import 'phone_test_controller.dart';

/// The phone test: six steps, top to bottom, ending with "send the results".
class PhoneTestPage extends StatefulWidget {
  const PhoneTestPage({super.key, required this.controller});

  final PhoneTestController controller;

  @override
  State<PhoneTestPage> createState() => _PhoneTestPageState();
}

class _PhoneTestPageState extends State<PhoneTestPage>
    with WidgetsBindingObserver {
  PhoneTestController get _controller => widget.controller;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Back from a system screen (or from the computer): look again.
    if (state == AppLifecycleState.resumed) _controller.refreshOptional();
  }

  void _say(String text) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(text), duration: const Duration(seconds: 4)),
      );
  }

  Future<void> _copy(String text) async {
    final l10n = context.l10n;
    await Clipboard.setData(ClipboardData(text: text));
    if (mounted) _say(l10n.copied);
  }

  Future<void> _open(String screen) async {
    final l10n = context.l10n;
    final result = await _controller.open(screen);
    if (mounted && !result.ok) _say(l10n.actionFailed(result.error ?? ''));
  }

  Future<void> _shareSummary() async {
    final l10n = context.l10n;
    if (!_controller.hasApps) return _say(l10n.nothingYet);
    ActionResult result;
    try {
      result = await _controller.probe.shareText(
        'ZT Privacy phone test',
        _controller.report(withNames: false),
      );
    } catch (e) {
      result = ActionResult(ok: false, error: e.toString());
    }
    if (mounted && !result.ok) _say(l10n.actionFailed(result.error ?? ''));
  }

  Future<void> _saveFull() async {
    final l10n = context.l10n;
    if (!_controller.hasApps) return _say(l10n.nothingYet);
    final name = 'zt-privacy-phone-test-${_controller.results.build}.txt';
    try {
      await _controller.probe.saveToDownloads(
        name,
        _controller.report(withNames: true),
      );
      if (mounted) _say(l10n.savedFull(name));
    } catch (e) {
      if (mounted) _say(l10n.actionFailed(e.toString()));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(title: Text('${l10n.appTitle} · ${l10n.phoneTestTitle}')),
      body: SafeArea(
        child: ListenableBuilder(
          listenable: _controller,
          builder: (context, _) => ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                l10n.buildLabel(_controller.results.build),
                style: Theme.of(context).textTheme.labelMedium,
              ),
              const SizedBox(height: 8),
              Text(l10n.intro),
              const SizedBox(height: 8),
              _readStep(l10n),
              _usageStep(l10n),
              _deepStep(l10n),
              _scanStep(l10n),
              _screensStep(l10n),
              _sendStep(l10n),
            ],
          ),
        ),
      ),
    );
  }

  Widget _readStep(AppL10n l10n) {
    final results = _controller.results;
    final apps = results.apps;
    final device = results.device;
    final lists = results.specialAccess;
    return _StepCard(
      title: l10n.stepReadTitle,
      body: l10n.stepReadBody,
      children: [
        if (apps != null)
          Text(l10n.appsLine(apps.length, results.userApps.length)),
        if (apps != null)
          Text(
            l10n.networkOffLine(
              apps
                  .where(
                    (a) =>
                        a.requests('android.permission.INTERNET') &&
                        !a.internetGranted,
                  )
                  .length,
            ),
          ),
        if (device != null)
          Text(
            l10n.settingsLine(device.where((v) => v.ok).length, device.length),
          ),
        if (lists != null)
          Text(
            l10n.accessListsLine(
              lists.values.where((v) => v.ok).length,
              lists.length,
            ),
          ),
        for (final step in const [
          'apps',
          'device',
          'specialAccess',
          'accessAnswers',
        ])
          if (results.errors[step] != null)
            _ErrorText(l10n.stepFailed(results.errors[step]!)),
        _Buttons([
          FilledButton(
            key: const Key('read'),
            onPressed: _controller.reading ? null : _controller.readPhone,
            child: Text(
              _controller.reading
                  ? l10n.reading
                  : apps == null
                  ? l10n.readButton
                  : l10n.readAgainButton,
            ),
          ),
        ]),
      ],
    );
  }

  Widget _usageStep(AppL10n l10n) {
    final usage = _controller.results.usage;
    return _StepCard(
      title: l10n.stepUsageTitle,
      body: l10n.stepUsageBody,
      children: [
        if (usage != null)
          Text(usage.granted ? l10n.usageOn(usage.apps.length) : l10n.usageOff),
        if (_controller.results.errors['usage'] != null)
          _ErrorText(l10n.stepFailed(_controller.results.errors['usage']!)),
        _Buttons([
          OutlinedButton(
            key: const Key('open-usage'),
            onPressed: () => _open('usageAccess'),
            child: Text(l10n.openUsageAccess),
          ),
          TextButton(
            onPressed: _controller.hasApps ? _controller.refreshOptional : null,
            child: Text(l10n.checkAgain),
          ),
        ]),
      ],
    );
  }

  Widget _deepStep(AppL10n l10n) {
    final deep = _controller.results.deepMode;
    return _StepCard(
      title: l10n.stepDeepTitle,
      body: l10n.stepDeepBody,
      children: [
        // A command reads left to right whatever the app's language.
        Directionality(
          textDirection: TextDirection.ltr,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const SelectableText(
              PhoneTestController.deepModeCommand,
              style: TextStyle(fontFamily: 'monospace', fontSize: 13),
            ),
          ),
        ),
        if (deep != null)
          Text(
            !deep.permissionGranted
                ? l10n.deepNotGranted
                : deep.works
                ? l10n.deepGrantedWorks(deep.entries.length)
                : l10n.deepGrantedBlocked,
          ),
        if (_controller.results.errors['deepMode'] != null)
          _ErrorText(l10n.stepFailed(_controller.results.errors['deepMode']!)),
        _Buttons([
          OutlinedButton(
            key: const Key('copy-command'),
            onPressed: () => _copy(PhoneTestController.deepModeCommand),
            child: Text(l10n.copyCommand),
          ),
          TextButton(
            onPressed: _controller.hasApps ? _controller.refreshOptional : null,
            child: Text(l10n.checkAgain),
          ),
        ]),
      ],
    );
  }

  Widget _scanStep(AppL10n l10n) {
    final results = _controller.results;
    final done = results.scans.length;
    final total = results.scanTargets;
    final seconds = (_controller.scanElapsed.inMilliseconds / 1000)
        .toStringAsFixed(1);
    final totals = scanTotals(results.scans);
    return _StepCard(
      title: l10n.stepScanTitle,
      body: l10n.stepScanBody,
      children: [
        if (!_controller.hasApps) Text(l10n.scanNeedsApps),
        if (_controller.scanning) ...[
          LinearProgressIndicator(value: total == 0 ? null : done / total),
          Text(l10n.scanProgress(done, total, seconds)),
        ] else if (total > 0) ...[
          Text(l10n.scanDone(done, seconds, totals.withKits)),
          if (totals.errors > 0) Text(l10n.scanErrors(totals.errors)),
        ],
        if (results.errors['scan'] != null)
          _ErrorText(l10n.stepFailed(results.errors['scan']!)),
        _Buttons([
          if (_controller.scanning)
            OutlinedButton(
              key: const Key('stop-scan'),
              onPressed: _controller.stopScan,
              child: Text(l10n.stopScan),
            )
          else
            FilledButton(
              key: const Key('start-scan'),
              onPressed: _controller.hasApps ? _controller.startScan : null,
              child: Text(l10n.startScan),
            ),
        ]),
      ],
    );
  }

  Widget _screensStep(AppL10n l10n) {
    final screens = {
      'privacyDashboard': l10n.screenPrivacyDashboard,
      'permissionManager': l10n.screenPermissionManager,
      'privacy': l10n.screenPrivacy,
      'appDetails': l10n.screenAppDetails,
    };
    return _StepCard(
      title: l10n.stepScreensTitle,
      body: l10n.stepScreensBody,
      children: [
        for (final entry in screens.entries)
          Row(
            children: [
              Expanded(
                child: Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: TextButton(
                    key: Key('screen-${entry.key}'),
                    onPressed: () => _open(entry.key),
                    child: Text(entry.value),
                  ),
                ),
              ),
              if (_controller.results.screens[entry.key] case final result?)
                Text(result.ok ? l10n.screenOpened : l10n.screenRefused),
            ],
          ),
      ],
    );
  }

  Widget _sendStep(AppL10n l10n) {
    // Steps 2 and 3 are optional; 4 and 5 are easy to pass over, and a
    // summary without them leaves two of the questions open.
    final missing = stepsNotRun(
      _controller.results,
    ).where((step) => step == 4 || step == 5).toList();
    return _StepCard(
      title: l10n.stepSendTitle,
      body: l10n.stepSendBody,
      children: [
        if (_controller.hasApps && missing.isNotEmpty)
          _ErrorText(l10n.stepsMissing(missing.join(', '))),
        _Buttons([
          FilledButton(
            key: const Key('share-summary'),
            onPressed: _shareSummary,
            child: Text(l10n.shareSummary),
          ),
          OutlinedButton(
            key: const Key('copy-summary'),
            onPressed: () => _controller.hasApps
                ? _copy(_controller.report(withNames: false))
                : _say(l10n.nothingYet),
            child: Text(l10n.copySummary),
          ),
          OutlinedButton(
            key: const Key('save-full'),
            onPressed: _saveFull,
            child: Text(l10n.saveFull),
          ),
        ]),
      ],
    );
  }
}

class _StepCard extends StatelessWidget {
  const _StepCard({
    required this.title,
    required this.body,
    required this.children,
  });

  final String title;
  final String body;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 4),
            Text(body),
            for (final child in children) ...[const SizedBox(height: 8), child],
          ],
        ),
      ),
    );
  }
}

/// Buttons side by side, wrapping onto more lines on a narrow screen or
/// with long (Hebrew) labels.
class _Buttons extends StatelessWidget {
  const _Buttons(this.buttons);

  final List<Widget> buttons;

  @override
  Widget build(BuildContext context) =>
      Wrap(spacing: 8, runSpacing: 4, children: buttons);
}

class _ErrorText extends StatelessWidget {
  const _ErrorText(this.text);

  final String text;

  @override
  Widget build(BuildContext context) =>
      Text(text, style: TextStyle(color: Theme.of(context).colorScheme.error));
}
