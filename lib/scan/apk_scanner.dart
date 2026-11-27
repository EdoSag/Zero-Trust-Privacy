import 'dart:io';
import 'dart:typed_data';

import 'dex_types.dart';
import 'tracker_signatures.dart';
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

/// A [TrackerSdk] with its package prefixes ready to compare.
class _Wanted {
  _Wanted(this.sdk) : prefixes = sdk.prefixes;
  final TrackerSdk sdk;
  final List<Uint8List> prefixes;
}

final _dexName = RegExp(r'^classes\d*\.dex$');

/// No real code file is near this size; anything larger is skipped rather
/// than unpacked into memory.
const _largestDex = 96 * 1024 * 1024;

/// Looks for the code of [sdks] in an app, given the paths of its APK files
/// (the base file and any splits).
///
/// This reads class names only. It says a kit's code is in the app, not
/// that the code ever runs, and it cannot see code whose names were
/// scrambled.
///
/// Synchronous and heavy: call it from a background isolate.
ApkScanResult scanApkFiles(List<String> paths, List<TrackerSdk> sdks) {
  final result = ApkScanResult();
  final wanted = [for (final sdk in sdks) _Wanted(sdk)];
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
            if (result.found.contains(item.sdk.name)) continue;
            if (item.prefixes.any(dex.hasPrefix)) {
              result.found.add(item.sdk.name);
            }
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
