// Builds assets/trackers/exodus_trackers.json, the tracker list the app
// carries, from the Exodus Privacy tracker database.
//
//   dart run tool/build_tracker_list.dart <exodus-api-trackers.json> [fetched-on]
//
// The input is the JSON that https://reports.exodus-privacy.eu.org/api/trackers
// returns. The app itself never calls that address: the list is built in,
// so a scan needs no network and no app name ever leaves the phone.
//
// Only what the scan and the screens use is kept: id, name, kinds, website
// and the code signatures. The database is under the Open Database License
// (ODbL 1.0); see assets/trackers/NOTICE.md.

import 'dart:convert';
import 'dart:io';

/// Exodus's category names, and the names the app uses for them.
const kinds = {
  'Advertisement': 'ads',
  'Analytics': 'analytics',
  'Crash reporting': 'crashReporting',
  'Identification': 'identification',
  'Location': 'location',
  'Profiling': 'profiling',
};

void main(List<String> arguments) {
  if (arguments.isEmpty) {
    stderr.writeln(
      'usage: dart run tool/build_tracker_list.dart <exodus.json> [fetched-on]',
    );
    exit(64);
  }
  final input =
      jsonDecode(File(arguments[0]).readAsStringSync()) as Map<String, Object?>;
  final all = (input['trackers']! as Map<String, Object?>).values
      .cast<Map<String, Object?>>()
      .toList();
  all.sort((a, b) => (a['id']! as int).compareTo(b['id']! as int));

  final trackers = <Map<String, Object?>>[];
  var newest = '';
  final skipped = <String>[];
  for (final tracker in all) {
    final created = tracker['creation_date'] as String? ?? '';
    if (created.compareTo(newest) > 0) newest = created;
    final code = codeSignatures(tracker['code_signature'] as String? ?? '');
    if (code.isEmpty) {
      // Known by the servers it talks to only; a scan of code cannot see it.
      skipped.add(tracker['name']! as String);
      continue;
    }
    final unknown = [
      for (final category in (tracker['categories'] as List?) ?? const [])
        if (!kinds.containsKey(category)) category,
    ];
    if (unknown.isNotEmpty) {
      stderr.writeln('${tracker['name']}: unknown categories $unknown');
      exit(65);
    }
    trackers.add({
      'id': tracker['id'],
      'name': (tracker['name']! as String).trim(),
      'kinds': [
        for (final category in (tracker['categories'] as List?) ?? const [])
          kinds[category],
      ],
      'website': (tracker['website'] as String? ?? '').trim(),
      'code': code,
    });
  }

  final output = {
    'format': 1,
    'source': 'Exodus Privacy tracker database',
    'sourceUrl': 'https://reports.exodus-privacy.eu.org/api/trackers',
    'license': 'ODbL-1.0',
    'licenseUrl': 'https://opendatacommons.org/licenses/odbl/1-0/',
    'attribution':
        'Tracker definitions derived from the Exodus Privacy database, '
        'licensed under ODbL 1.0. https://exodus-privacy.eu.org/',
    'newestEntry': newest,
    if (arguments.length > 1) 'fetchedOn': arguments[1],
    'trackers': trackers,
  };
  final file = File('assets/trackers/exodus_trackers.json');
  file.writeAsStringSync(
    '${const JsonEncoder.withIndent(' ').convert(output)}\n',
  );
  stdout.writeln(
    '${trackers.length} trackers written to ${file.path} '
    '(newest entry $newest). Left out, no code signature: $skipped',
  );
}

/// An Exodus code signature is a regular expression in which only two things
/// are ever used: `|` between alternatives and `.` between the parts of a
/// Java package name. This splits it into those alternatives, as plain
/// names. Anything else in a signature stops the build, so a new shape in
/// the database is looked at instead of silently never matching.
List<String> codeSignatures(String signature) {
  final out = <String>[];
  for (final part in signature.split('|')) {
    final name = part.trim().replaceAll(r'\.', '.');
    // Exodus itself ignores signatures this short.
    if (name.length <= 3) continue;
    if (!RegExp(r'^[A-Za-z0-9_.$-]+$').hasMatch(name)) {
      stderr.writeln('Signature not understood: "$part" in "$signature"');
      exit(65);
    }
    out.add(name);
  }
  return out;
}
