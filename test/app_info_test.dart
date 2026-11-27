import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:zerotrust_privacy/app_info.dart';

void main() {
  test('the version shown in the app is the one in pubspec.yaml', () {
    expect(
      File('pubspec.yaml').readAsStringSync(),
      contains(RegExp('^version: $appVersion\\+', multiLine: true)),
    );
  });

  test('the app never carries cryptography_flutter', () {
    // It breaks the shared core's key derivation: sign-in fails.
    expect(
      File('pubspec.lock').readAsStringSync(),
      isNot(contains('cryptography_flutter')),
    );
  });
}
