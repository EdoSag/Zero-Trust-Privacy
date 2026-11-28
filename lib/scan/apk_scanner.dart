import 'dart:io';

import 'dex_types.dart';
import 'tracker_list.dart';
import 'zip_reader.dart';

/// What a scan of one app's files found.
class ApkScanResult {
  ApkScanResult();

  /// Names of the kits whose code is in the app.
  final Set<String> found = {};

  /// Code files read, their unpacked size, and the class names in them.
  int dexFiles = 0;
  int dexBytes = 0;
  int types = 0;

  /// Files that could not be read, each with the reason.
  final List<String> errors = [];
}

/// A [Tracker] with its names ready to compare.
class _Wanted {
  _Wanted(this.tracker)
    : signatures = [for (final name in tracker.code) CodeSignature(name)];
  final Tracker tracker;
  final List<CodeSignature> signatures;

  bool isIn(DexTypes dex) => signatures.any(
    (s) => s.anywhere ? dex.hasPart(s.bytes) : dex.hasPrefix(s.bytes),
  );
}

final _dexName = RegExp(r'^classes\d*\.dex$');

/// No real code file is near this size; anything larger is skipped rather
/// than unpacked into memory.
const _largestDex = 96 * 1024 * 1024;

/// Looks for the code of [trackers] in an app, given the paths of its APK files
/// (the base file and any splits).
///
/// This reads class names only. It says a kit's code is in the app, not
/// that the code ever runs, and it cannot see code whose names were
/// scrambled.
///
/// Synchronous and heavy: call it from a background isolate.
ApkScanResult scanApkFiles(List<String> paths, List<Tracker> trackers) {
  final result = ApkScanResult();
  final wanted = [for (final tracker in trackers) _Wanted(tracker)];
  for (final path in paths) {
    RandomAccessFile? file;
    try {
      file = File(path).openSync();
      final zip = ZipReader(file);
      for (final entry in zip.entries()) {
        if (!_dexName.hasMatch(entry.name)) continue;
        if (entry.uncompressedSize > _largestDex) {
          result.errors.add('${entry.name}: too large to read');
          continue;
        }
        try {
          final bytes = zip.read(entry);
          final dex = DexTypes.parse(bytes);
          result.dexFiles++;
          result.dexBytes += bytes.length;
          result.types += dex.typeCount;
          for (final item in wanted) {
            if (result.found.contains(item.tracker.name)) continue;
            if (item.isIn(dex)) result.found.add(item.tracker.name);
          }
        } on FormatException catch (e) {
          result.errors.add('${entry.name}: ${e.message}');
        }
      }
    } on FormatException catch (e) {
      result.errors.add('${_fileName(path)}: ${e.message}');
    } on FileSystemException catch (e) {
      result.errors.add(
        '${_fileName(path)}: ${e.osError?.message ?? e.message}',
      );
    } finally {
      file?.closeSync();
    }
  }
  return result;
}

String _fileName(String path) => path.substring(path.lastIndexOf('/') + 1);
