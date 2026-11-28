import 'dart:async';
import 'dart:isolate';

import 'apk_scanner.dart';
import 'tracker_list.dart';

/// One app to scan: its package name and the paths of its APK files.
class ScanTarget {
  const ScanTarget(this.package, this.paths);
  final String package;
  final List<String> paths;
}

/// The result for one app, as it arrives.
class AppScan {
  const AppScan({
    required this.package,
    required this.found,
    required this.dexFiles,
    required this.dexBytes,
    required this.types,
    required this.errors,
    required this.elapsed,
  });

  final String package;
  final List<String> found;
  final int dexFiles;
  final int dexBytes;
  final int types;
  final List<String> errors;
  final Duration elapsed;
}

/// Scans apps for tracker code, one result per app as each finishes.
abstract class TrackerScanner {
  /// Cancelling the subscription stops the scan.
  Stream<AppScan> scan(List<ScanTarget> targets);
}

/// Scans in a background isolate, one app at a time, so the screen stays
/// smooth however many apps there are.
class IsolateTrackerScanner implements TrackerScanner {
  const IsolateTrackerScanner(this.trackers);

  /// The kits to look for. Asked for when a scan starts, since the list is
  /// read from the app's files.
  final Future<List<Tracker>> Function() trackers;

  @override
  Stream<AppScan> scan(List<ScanTarget> targets) {
    Isolate? isolate;
    var stopped = false;
    final port = ReceivePort();
    late final StreamController<AppScan> controller;

    void stop() {
      stopped = true;
      isolate?.kill(priority: Isolate.immediate);
      isolate = null;
      port.close();
    }

    controller = StreamController<AppScan>(
      onListen: () async {
        port.listen((message) {
          if (message is List && message.length == _resultLength) {
            controller.add(_fromMessage(message));
          } else if (message is List) {
            // An uncaught error in the isolate: [error, stack trace].
            controller.addError(StateError('${message.first}'));
          } else {
            // null: the isolate is done (or died); either way, the end.
            stop();
            controller.close();
          }
        });
        try {
          final wanted = await trackers();
          // Cancelled while the list was being read: start nothing.
          if (stopped) return;
          final started = await Isolate.spawn(
            _scanAll,
            [
              port.sendPort,
              [
                for (final target in targets) [target.package, target.paths],
              ],
              [
                for (final tracker in wanted) [tracker.name, tracker.code],
              ],
            ],
            onExit: port.sendPort,
            onError: port.sendPort,
          );
          if (stopped) {
            // Cancelled while it was starting: do not leave it running.
            started.kill(priority: Isolate.immediate);
          } else {
            isolate = started;
          }
        } catch (e, stack) {
          stop();
          controller.addError(e, stack);
          await controller.close();
        }
      },
      onCancel: stop,
    );
    return controller.stream;
  }
}

const _resultLength = 7;

// Runs in the background isolate. Messages are plain lists so they cross
// between isolates as they are.
void _scanAll(List<Object?> arguments) {
  final port = arguments[0] as SendPort;
  final targets = arguments[1] as List;
  // Only the names matter here; the id is not sent across.
  final trackers = [
    for (final (index, tracker) in (arguments[2] as List).indexed)
      Tracker(
        id: index,
        name: (tracker as List)[0] as String,
        code: (tracker[1] as List).cast<String>(),
      ),
  ];
  final clock = Stopwatch();
  for (final target in targets) {
    final package = (target as List)[0] as String;
    final paths = (target[1] as List).cast<String>();
    clock
      ..reset()
      ..start();
    ApkScanResult result;
    try {
      result = scanApkFiles(paths, trackers);
    } catch (e) {
      // One unreadable app must not end the scan of the rest.
      result = ApkScanResult()..errors.add(e.toString());
    }
    clock.stop();
    port.send([
      package,
      result.found.toList(),
      result.dexFiles,
      result.dexBytes,
      result.types,
      result.errors,
      clock.elapsedMicroseconds,
    ]);
  }
  Isolate.exit(port, null);
}

AppScan _fromMessage(List<Object?> message) => AppScan(
  package: message[0] as String,
  found: (message[1] as List).cast<String>(),
  dexFiles: message[2] as int,
  dexBytes: message[3] as int,
  types: message[4] as int,
  errors: (message[5] as List).cast<String>(),
  elapsed: Duration(microseconds: message[6] as int),
);
