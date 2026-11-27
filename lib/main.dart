import 'package:flutter/material.dart';

import 'app.dart';
import 'probe/device_probe.dart';
import 'scan/tracker_scan.dart';
import 'ui/phone_test_controller.dart';

/// The build number, put in by the release workflow; "dev" when run locally.
const appBuild = String.fromEnvironment('ZT_BUILD', defaultValue: 'dev');

void main() {
  runApp(
    PrivacyApp(
      controller: PhoneTestController(
        probe: const ChannelDeviceProbe(),
        scanner: const IsolateTrackerScanner(),
        build: appBuild,
      ),
    ),
  );
}
