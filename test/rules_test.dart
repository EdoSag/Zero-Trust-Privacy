import 'package:flutter_test/flutter_test.dart';
import 'package:zerotrust_privacy/phone/phone_snapshot.dart';
import 'package:zerotrust_privacy/probe/device_probe.dart';
import 'package:zerotrust_privacy/rules/checklist.dart';
import 'package:zerotrust_privacy/rules/finding.dart';
import 'package:zerotrust_privacy/rules/rules.dart';
import 'package:zerotrust_privacy/rules/score.dart';

import 'support/fake_phone.dart';

final now = DateTime.utc(2026, 11, 27, 12);
int daysAgo(int days) =>
    now.subtract(Duration(days: days)).millisecondsSinceEpoch;

/// A user's app installed a year ago and updated a month ago.
InstalledApp userApp(
  String package, {
  Map<String, bool> permissions = const {},
  int targetSdk = 35,
  int? lastUpdate,
  int? firstInstall,
  bool enabled = true,
  bool system = false,
}) => InstalledApp(
  package: package,
  label: 'Label of $package',
  system: system,
  enabled: enabled,
  uid: 10100,
  targetSdk: targetSdk,
  firstInstall: firstInstall ?? daysAgo(365),
  lastUpdate: lastUpdate ?? daysAgo(30),
  installer: 'org.example.store',
  sourceDir: '/data/app/$package/base.apk',
  splitDirs: const [],
  requested: permissions.keys.toList(),
  granted: permissions.values.toList(),
  internetGranted: true,
  otherSensorsGranted: true,
);

/// A phone with nothing to point out, unless told otherwise.
PhoneSnapshot phone({
  List<InstalledApp> apps = const [],
  Map<String, String?> facts = const {},
  Set<String> refused = const {},
  Map<String, List<String>> lists = const {},
  Map<String, Set<String>> special = const {},
  UsageReport? usage,
}) {
  final all = <String, String?>{
    'lock.deviceSecure': 'true',
    'encryption.status': 'active, per user',
    'build.securityPatch': '2026-11-01',
    'global.adb_enabled': '0',
    'global.adb_wifi_enabled': '0',
    'global.development_settings_enabled': '0',
    'secure.lock_screen_show_notifications': '1',
    'secure.lock_screen_allow_private_notifications': '0',
    'global.wifi_scan_always_enabled': '0',
    'global.ble_scan_always_enabled': null,
    'network.privateDnsActive': 'false',
    'network.vpnActive': 'false',
    ...facts,
  };
  return PhoneSnapshot(
    takenAt: now,
    apps: apps,
    facts: {
      for (final entry in all.entries)
        entry.key: refused.contains(entry.key)
            ? ProbeValue(id: entry.key, ok: false, error: 'SecurityException')
            : ProbeValue(id: entry.key, ok: true, value: entry.value),
    },
    accessLists: {
      for (final entry in lists.entries)
        entry.key: AccessList(ok: true, items: entry.value),
    },
    specialAccess: special,
    usage: usage,
  );
}

List<String> ids(PhoneSnapshot phone) => [
  for (final finding in findFindings(phone)) finding.id,
];

void main() {
  group('the phone', () {
    test('a well kept phone has nothing to point out and scores 100', () {
      final clean = phone(apps: [userApp('com.notes')]);
      expect(findFindings(clean), isEmpty);
      expect(PrivacyReport(phone: clean, accepted: const {}).score, 100);
    });

    test('no screen lock', () {
      expect(ids(phone(facts: {'lock.deviceSecure': 'false'})), [
        'noScreenLock',
      ]);
    });

    test('a security update older than 90 days, with its date', () {
      expect(ids(phone(facts: {'build.securityPatch': '2026-08-29'})), isEmpty);
      final old = findFindings(
        phone(facts: {'build.securityPatch': '2026-08-28'}),
      );
      expect(old.single.rule, Rule.oldSecurityPatch);
      expect(old.single.detail, '2026-08-28');
      // A date Android did not give is not held against the phone.
      expect(ids(phone(facts: {'build.securityPatch': null})), isEmpty);
      expect(ids(phone(facts: {'build.securityPatch': 'unknown'})), isEmpty);
    });

    test('debugging: each kind is said once, developer options only alone', () {
      // What Edo's Pixel showed on 2026-11-27.
      expect(
        ids(
          phone(
            facts: {
              'global.adb_enabled': '0',
              'global.adb_wifi_enabled': '1',
              'global.development_settings_enabled': '1',
            },
          ),
        ),
        ['wirelessDebugging'],
      );
      expect(
        ids(
          phone(
            facts: {
              'global.adb_enabled': '1',
              'global.adb_wifi_enabled': '1',
              'global.development_settings_enabled': '1',
            },
          ),
        ),
        ['usbDebugging', 'wirelessDebugging'],
      );
      expect(ids(phone(facts: {'global.development_settings_enabled': '1'})), [
        'developerOptions',
      ]);
    });

    test('message text on the lock screen', () {
      expect(
        ids(
          phone(facts: {'secure.lock_screen_allow_private_notifications': '1'}),
        ),
        ['lockScreenContent'],
      );
      // Nothing is shown on the lock screen at all: nothing to hide.
      expect(
        ids(
          phone(
            facts: {
              'secure.lock_screen_allow_private_notifications': '1',
              'secure.lock_screen_show_notifications': '0',
            },
          ),
        ),
        isEmpty,
      );
    });

    test('scanning while Wi-Fi or Bluetooth is off', () {
      expect(
        ids(
          phone(
            facts: {
              'global.wifi_scan_always_enabled': '1',
              'global.ble_scan_always_enabled': '1',
            },
          ),
        ),
        ['wifiScanning', 'bluetoothScanning'],
      );
    });

    test('a setting Android refuses is never a finding', () {
      expect(
        ids(
          phone(
            facts: {
              'lock.deviceSecure': 'false',
              'global.adb_enabled': '1',
              'global.adb_wifi_enabled': '1',
            },
            refused: {
              'lock.deviceSecure',
              'global.adb_enabled',
              'global.adb_wifi_enabled',
            },
          ),
        ),
        isEmpty,
      );
    });
  });

  group('apps', () {
    test('holders of accessibility, device admin and notification access', () {
      final found = ids(
        phone(
          apps: [
            userApp('com.reader'),
            userApp('com.guard'),
            userApp('com.watch'),
            userApp('com.system.talkback', system: true),
          ],
          lists: {
            'accessibilityServices': [
              'com.reader/.Service',
              'com.system.talkback/.Service',
            ],
            'deviceAdmins': ['com.guard/.Admin'],
            'notificationListeners': ['com.watch/com.watch.Listener'],
          },
        ),
      );
      // The system's own services are not the user's to judge.
      expect(found, [
        'accessibility:com.reader',
        'deviceAdmin:com.guard',
        'notificationAccess:com.watch',
      ]);
    });

    test('location all the time, text messages and the call log', () {
      final found = ids(
        phone(
          apps: [
            userApp('com.maps', permissions: {fineLocation: true}),
            userApp(
              'com.weather',
              permissions: {fineLocation: true, backgroundLocation: true},
            ),
            userApp(
              'com.asks.only',
              permissions: {
                backgroundLocation: false,
                'android.permission.READ_SMS': false,
              },
            ),
            userApp(
              'com.bank',
              permissions: {'android.permission.RECEIVE_SMS': true},
            ),
            userApp(
              'com.messages',
              permissions: {'android.permission.READ_SMS': true},
            ),
            userApp(
              'com.caller.id',
              permissions: {'android.permission.READ_CALL_LOG': true},
            ),
            userApp(
              'com.dialer',
              permissions: {'android.permission.READ_CALL_LOG': true},
            ),
          ],
          lists: {
            'defaultSms': ['com.messages'],
            'defaultDialer': ['com.dialer'],
          },
        ),
      );
      // The apps chosen for messages and calls need what they hold.
      expect(found, [
        'backgroundLocation:com.weather',
        'sms:com.bank',
        'callLog:com.caller.id',
      ]);
    });

    test('special access counts only when it is really held', () {
      final found = ids(
        phone(
          apps: [
            userApp('com.files', permissions: {allFilesPermission: false}),
            userApp('com.bubble', permissions: {overlayPermission: false}),
            userApp('com.store', permissions: {installAppsPermission: false}),
            userApp('com.stats', permissions: {usageAccessPermission: false}),
            userApp('com.asks', permissions: {allFilesPermission: false}),
          ],
          special: {
            allFilesPermission: {'com.files'},
            overlayPermission: {'com.bubble'},
            installAppsPermission: {'com.store'},
            usageAccessPermission: {'com.stats'},
          },
        ),
      );
      expect(found, [
        'allFiles:com.files',
        'overlay:com.bubble',
        'installsApps:com.store',
        'usageAccess:com.stats',
      ]);
    });

    test('built for an old Android, and not updated for two years', () {
      final found = findFindings(
        phone(
          apps: [
            userApp('com.old', targetSdk: 28),
            userApp('com.edge', targetSdk: 30),
            userApp('com.stale', lastUpdate: daysAgo(731)),
            userApp('com.fresh', lastUpdate: daysAgo(729)),
          ],
        ),
      );
      expect(found.map((f) => f.id), [
        'oldTarget:com.old',
        'notUpdated:com.stale',
      ]);
      expect(found.first.detail, '9');
      expect(found.last.detail, '731');
    });

    test(
      'unused for 90 days counts only with usage access and a permission',
      () {
        final apps = [
          userApp('com.forgotten', permissions: {camera: true}),
          userApp('com.recent', permissions: {camera: true}),
          userApp('com.harmless'),
          userApp(
            'com.new',
            permissions: {camera: true},
            firstInstall: daysAgo(10),
          ),
          userApp('com.keys', permissions: {camera: true}),
          userApp('com.never.listed', permissions: {fineLocation: true}),
        ];
        final usage = UsageReport(
          granted: true,
          apps: [
            AppUsage(
              package: 'com.forgotten',
              lastUsed: daysAgo(91),
              foregroundMs: 1,
            ),
            AppUsage(
              package: 'com.recent',
              lastUsed: daysAgo(89),
              foregroundMs: 1,
            ),
            AppUsage(
              package: 'com.harmless',
              lastUsed: daysAgo(300),
              foregroundMs: 1,
            ),
          ],
        );
        final lists = {
          'keyboards': ['com.keys/.Ime'],
        };
        expect(ids(phone(apps: apps, lists: lists, usage: usage)), [
          'unused:com.forgotten',
          // No record in 90 days is "not used in 90 days".
          'unused:com.never.listed',
        ]);
        // Without usage access nothing is known, so nothing is said.
        expect(ids(phone(apps: apps, lists: lists)), isEmpty);
        expect(
          ids(
            phone(
              apps: apps,
              lists: lists,
              usage: const UsageReport(granted: false),
            ),
          ),
          isEmpty,
        );
      },
    );

    test(
      'switched-off apps, system apps and ZT Privacy itself are left out',
      () {
        final found = ids(
          phone(
            apps: [
              userApp(
                'com.off',
                permissions: {backgroundLocation: true},
                enabled: false,
              ),
              userApp(
                'com.system.maps',
                permissions: {backgroundLocation: true},
                system: true,
              ),
              userApp(
                DeepModeReport.ownPackage,
                permissions: {usageAccessPermission: false},
              ),
            ],
            special: {
              usageAccessPermission: {DeepModeReport.ownPackage},
            },
          ),
        );
        expect(found, isEmpty);
      },
    );
  });

  group('the score', () {
    test('each finding costs its points, up to the cap of its kind', () {
      final report = PrivacyReport(
        phone: phone(
          facts: {'global.adb_wifi_enabled': '1'},
          apps: [
            for (var i = 0; i < 5; i++)
              userApp('com.loc$i', permissions: {backgroundLocation: true}),
            userApp('com.reader'),
          ],
          lists: {
            'accessibilityServices': ['com.reader/.Service'],
          },
        ),
        accepted: const {},
      );
      // Wireless debugging 6, accessibility 6, location 5 x 4 capped at 12.
      expect(report.score, 100 - 6 - 6 - 12);
      expect(
        [
          for (final line in report.lines)
            (line.rule, line.open, line.deducted),
        ],
        [
          (Rule.wirelessDebugging, 1, 6),
          (Rule.accessibility, 1, 6),
          (Rule.backgroundLocation, 5, 12),
        ],
      );
    });

    test('a finding the user is fine with costs nothing and stays listed', () {
      final phoneNow = phone(
        facts: {'global.adb_wifi_enabled': '1'},
        apps: [
          userApp('com.weather', permissions: {backgroundLocation: true}),
        ],
      );
      final report = PrivacyReport(
        phone: phoneNow,
        accepted: {'backgroundLocation:com.weather', 'gone:com.removed'},
      );
      expect(report.score, 94);
      expect(report.open.map((f) => f.id), ['wirelessDebugging']);
      expect(report.accepted.map((f) => f.id), [
        'backgroundLocation:com.weather',
      ]);
      final line = report.lines.last;
      expect(
        (line.rule, line.open, line.accepted, line.deducted),
        (Rule.backgroundLocation, 0, 1, 0),
      );
    });

    test('the score never goes below zero', () {
      final report = PrivacyReport(
        phone: phone(
          facts: {
            'lock.deviceSecure': 'false',
            'build.securityPatch': '2024-01-01',
            'global.adb_enabled': '1',
            'global.adb_wifi_enabled': '1',
            'secure.lock_screen_allow_private_notifications': '1',
            'global.wifi_scan_always_enabled': '1',
          },
          apps: [
            for (var i = 0; i < 4; i++)
              userApp(
                'com.bad$i',
                targetSdk: 26,
                lastUpdate: daysAgo(900),
                permissions: {
                  backgroundLocation: true,
                  'android.permission.READ_SMS': true,
                  'android.permission.READ_CALL_LOG': true,
                },
              ),
          ],
          lists: {
            'accessibilityServices': [
              for (var i = 0; i < 4; i++) 'com.bad$i/.A',
            ],
            'deviceAdmins': [for (var i = 0; i < 4; i++) 'com.bad$i/.D'],
            'notificationListeners': [
              for (var i = 0; i < 4; i++) 'com.bad$i/.N',
            ],
          },
          special: {
            allFilesPermission: {for (var i = 0; i < 4; i++) 'com.bad$i'},
            overlayPermission: {for (var i = 0; i < 4; i++) 'com.bad$i'},
            installAppsPermission: {for (var i = 0; i < 4; i++) 'com.bad$i'},
            usageAccessPermission: {for (var i = 0; i < 4; i++) 'com.bad$i'},
          },
        ),
        accepted: const {},
      );
      expect(report.score, 0);
    });

    test('fix next: the heaviest first, and one app is named once', () {
      final report = PrivacyReport(
        phone: phone(
          facts: {'global.adb_wifi_enabled': '1'},
          apps: [
            userApp(
              'com.reader',
              permissions: {backgroundLocation: true},
              targetSdk: 28,
            ),
            userApp('com.weather', permissions: {backgroundLocation: true}),
            userApp('com.old', targetSdk: 28),
            userApp('com.older', targetSdk: 27),
          ],
          lists: {
            'accessibilityServices': ['com.reader/.Service'],
          },
        ),
        accepted: const {},
      );
      expect(report.fixNext().map((f) => f.id), [
        'wirelessDebugging',
        'accessibility:com.reader',
        'backgroundLocation:com.weather',
        'oldTarget:com.old',
      ]);
      expect(report.fixNext(2), hasLength(2));
      expect(report.forApp('com.reader').map((f) => f.rule), [
        Rule.accessibility,
        Rule.backgroundLocation,
        Rule.oldTarget,
      ]);
    });
  });

  group('reading the phone', () {
    test('special access: allowed, or left to the granted flag', () {
      expect(effectiveSpecialAccess(mode: 'allowed', grantedFlag: false), true);
      expect(
        effectiveSpecialAccess(mode: 'foreground', grantedFlag: false),
        true,
      );
      expect(effectiveSpecialAccess(mode: 'default', grantedFlag: true), true);
      expect(
        effectiveSpecialAccess(mode: 'default', grantedFlag: false),
        false,
      );
      expect(effectiveSpecialAccess(mode: 'errored', grantedFlag: true), false);
      expect(effectiveSpecialAccess(mode: 'ignored', grantedFlag: true), false);
      expect(
        effectiveSpecialAccess(
          mode: 'SecurityException: no',
          grantedFlag: true,
        ),
        false,
      );
    });

    test('a snapshot is put together from every part', () async {
      final probe = FakeProbe()
        ..mode = (query) => query.package == 'com.maps' ? 'allowed' : 'default';
      final snapshot = await readPhone(probe, now: () => now);
      expect(snapshot.takenAt, now);
      expect(snapshot.apps, hasLength(4));
      expect(snapshot.userApps.map((a) => a.package), [
        'com.maps',
        'com.camera',
        'com.notes',
      ]);
      expect(snapshot.fact('build.model'), 'Test Phone');
      expect(snapshot.flag('global.adb_enabled'), false);
      // Refused by Android: no value, and no guess.
      expect(snapshot.fact('secure.always_on_vpn_app'), isNull);
      expect(snapshot.listed('accessibilityServices'), {'com.reader'});
      expect(snapshot.listed('keyboards'), {'com.keys', 'com.other'});
      // com.maps asked and Android says allowed; android.system asked, the
      // answer is "default" and its granted flag is set.
      expect(snapshot.specialAccess[overlayPermission], {
        'com.maps',
        'android.system',
      });
      expect(snapshot.holdsSpecial(overlayPermission, 'com.maps'), isTrue);
      expect(snapshot.holdsSpecial(overlayPermission, 'com.notes'), isFalse);
      expect(snapshot.usageGranted, isFalse);
      expect(snapshot.lastUsed('com.maps'), isNull);
      expect(snapshot.errors, isEmpty);
    });

    test('one part failing leaves the rest; no app list is an error', () async {
      final broken = _BrokenParts();
      final snapshot = await readPhone(broken, now: () => now);
      expect(snapshot.apps, hasLength(4));
      expect(snapshot.facts, isEmpty);
      expect(snapshot.accessLists, isEmpty);
      expect(snapshot.usage, isNull);
      expect(snapshot.errors.keys, ['device', 'specialAccess', 'usage']);
      expect(findFindings(snapshot), isA<List<Finding>>());

      await expectLater(
        readPhone(FakeProbe()..appsFailure = StateError('no list')),
        throwsStateError,
      );
    });
  });

  group('the device checklist', () {
    Map<CheckId, DeviceCheck> checks(PhoneSnapshot phone) => {
      for (final check in deviceChecks(phone)) check.id: check,
    };

    test('a well kept phone: every line read is good or for information', () {
      final all = checks(phone());
      expect(all[CheckId.screenLock]!.state, CheckState.good);
      expect(all[CheckId.encryption]!.state, CheckState.good);
      expect(all[CheckId.encryption]!.value, 'active, per user');
      expect(all[CheckId.securityPatch]!.state, CheckState.good);
      expect(all[CheckId.securityPatch]!.value, '2026-11-01');
      expect(all[CheckId.usbDebugging]!.state, CheckState.good);
      expect(all[CheckId.wirelessDebugging]!.state, CheckState.good);
      expect(all[CheckId.developerOptions]!.state, CheckState.good);
      expect(all[CheckId.lockScreenContent]!.state, CheckState.good);
      expect(all[CheckId.wifiScanning]!.state, CheckState.good);
      // Empty until first switched on: read, and off.
      expect(all[CheckId.bluetoothScanning]!.state, CheckState.good);
      expect(all[CheckId.privateDns]!.state, CheckState.info);
      expect(all[CheckId.privateDns]!.value, 'off');
      expect(all[CheckId.vpn]!.value, 'off');
      // Not on this Android version.
      expect(all.containsKey(CheckId.advancedProtection), isFalse);
      expect(all.values.where((c) => c.state == CheckState.attention), isEmpty);
    });

    test('lines that need attention carry the finding they raise', () {
      final all = checks(
        phone(
          facts: {
            'lock.deviceSecure': 'false',
            'build.securityPatch': '2026-01-01',
            'global.adb_wifi_enabled': '1',
            'global.development_settings_enabled': '1',
            'secure.lock_screen_allow_private_notifications': '1',
            'network.vpnActive': 'true',
            'global.private_dns_mode': 'hostname',
            'global.private_dns_specifier': 'dns.example.net',
            'advancedProtection.enabled': 'false',
          },
        ),
      );
      expect(all[CheckId.screenLock]!.rule, Rule.noScreenLock);
      expect(all[CheckId.securityPatch]!.state, CheckState.attention);
      expect(all[CheckId.securityPatch]!.rule, Rule.oldSecurityPatch);
      expect(all[CheckId.wirelessDebugging]!.rule, Rule.wirelessDebugging);
      // Developer options are on because of debugging: shown, not counted.
      expect(all[CheckId.developerOptions]!.state, CheckState.info);
      expect(all[CheckId.developerOptions]!.rule, isNull);
      expect(all[CheckId.lockScreenContent]!.rule, Rule.lockScreenContent);
      expect(all[CheckId.vpn]!.value, 'on');
      expect(all[CheckId.privateDns]!.value, 'dns.example.net');
      expect(all[CheckId.advancedProtection]!.value, 'off');

      // Every line that needs attention matches a finding, and the reverse.
      final snapshot = phone(
        facts: {
          'lock.deviceSecure': 'false',
          'global.adb_enabled': '1',
          'global.wifi_scan_always_enabled': '1',
        },
      );
      expect(
        {
          for (final check in deviceChecks(snapshot))
            if (check.state == CheckState.attention) check.rule,
        },
        {for (final finding in findFindings(snapshot)) finding.rule},
      );
    });

    test('what Android refuses is shown as unknown, never as good', () {
      final all = checks(
        phone(
          refused: {
            'lock.deviceSecure',
            'global.adb_enabled',
            'secure.lock_screen_allow_private_notifications',
            'build.securityPatch',
            'encryption.status',
            'network.vpnActive',
          },
        ),
      );
      for (final id in [
        CheckId.screenLock,
        CheckId.usbDebugging,
        CheckId.lockScreenContent,
        CheckId.securityPatch,
        CheckId.encryption,
        CheckId.vpn,
      ]) {
        expect(all[id]!.state, CheckState.unknown, reason: id.name);
      }
    });

    test('the manual lines follow the kind of phone', () {
      final stock = checks(phone());
      expect(stock[CheckId.alwaysOnVpn]!.state, CheckState.manual);
      expect(stock[CheckId.advertisingId]!.state, CheckState.manual);
      expect(stock.containsKey(CheckId.autoReboot), isFalse);
      expect(stock.containsKey(CheckId.duressPin), isFalse);

      final graphene = checks(
        phone(
          facts: {
            'grapheneos.otherSensorsPermission':
                'android.permission.OTHER_SENSORS',
          },
        ),
      );
      expect(graphene.containsKey(CheckId.advertisingId), isFalse);
      for (final id in [
        CheckId.alwaysOnVpn,
        CheckId.autoReboot,
        CheckId.usbPort,
        CheckId.wifiAutoOff,
        CheckId.bluetoothAutoOff,
        CheckId.pinScrambling,
        CheckId.duressPin,
        CheckId.networkSensors,
      ]) {
        expect(graphene[id]!.state, CheckState.manual, reason: id.name);
      }
      // Read lines first, then the ones to look at, in the order written.
      final order = deviceChecks(phone()).map((c) => c.id.manual).toList();
      expect(order, [...order]..sort((a, b) => a == b ? 0 : (a ? 1 : -1)));
    });
  });

  test('Android versions by target level', () {
    expect(androidVersionOf(28), '9');
    expect(androidVersionOf(29), '10');
    expect(androidVersionOf(32), '12L');
    expect(androidVersionOf(33), '13');
    expect(androidVersionOf(37), '17');
    expect(androidVersionOf(0), '?');
  });
}

/// A phone where everything but the app list fails.
class _BrokenParts extends FakeProbe {
  @override
  Future<List<ProbeValue>> device() async => throw StateError('device');

  @override
  Future<Map<String, AccessList>> specialAccess() async =>
      throw StateError('lists');

  @override
  Future<UsageReport> usage() async => throw StateError('usage');
}
