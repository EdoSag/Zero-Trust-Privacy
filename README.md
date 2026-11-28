# Zero-Trust Privacy

A privacy dashboard for the [Zero-Trust apps](https://zerotrust.bz). On the
phone it is called **ZT Privacy**; in stores and on release pages,
**Zero-Trust Privacy**.

It will show, on one screen, how private the phone and the accounts are and
what to fix first: which apps hold which permissions, which apps carry tracker
code, whether an account was part of a breach, the state of the Zero-Trust
account, and a checklist of device settings. Every check runs on the phone.
The list of installed apps never leaves it.

## Where it stands

The first part of the dashboard is here:

- **Privacy score**, 0 to 100, with every point listed. Each thing found takes
  points off, up to a limit for its kind, so that twenty unused apps cannot
  drown a missing screen lock. A finding you mark "I'm fine with this" stops
  counting.
- **Fix next**: the findings that cost the most, each with a plain explanation
  and a button that opens the Android screen where it is changed. Back in the
  app, the phone is read again and the score follows.
- **Apps and permissions**, both ways round: which apps hold a permission or a
  special access (accessibility, device admin, notification access, all files,
  display over other apps, installing apps, usage access), and what one app
  holds, who installed it and when it was last used.
- **Device checklist**: what the phone says about itself (screen lock, security
  update, debugging, lock screen, scanning, Private DNS, VPN), then the
  settings Android keeps from apps, to look at and tick off by hand. On
  GrapheneOS that part has a section of its own.

- **Trackers**: which apps contain code from known advertising, analytics
  and similar kits. The app reads the class names inside each installed app,
  on the phone, and compares them with
  [Exodus Privacy](https://exodus-privacy.eu.org/)'s list, which ships inside
  the app. Nothing is looked up online. Apps are read in the background, one
  at a time, and only again after they are updated. The lists go both ways
  round: what one app contains, and which apps contain one tracker. The
  wording is "contains code from": finding the code does not prove that it
  runs, and code with scrambled names cannot be seen. It costs points only
  where the app also holds a permission that tells it something about you,
  and never for code that only reports crashes.

- **What changed**: each time the app opens it compares the apps with the
  last time. A newly installed app that contains tracker code is listed, and
  so is an update that brought tracker code, dropped some, or started asking
  for a sensitive permission. The first look at a phone is the starting
  point, not a change, and a newer tracker list is never told as a change in
  an app. The dashboard counts what is new since the list was last opened.

Still to come: a daily re-scan in the background with a notification, breach
checks, and the state of the Zero-Trust account.

### What leaves the phone

The app signs in to the shared Zero-Trust account, like the other apps. The
only thing it stores there is one small item per phone: the findings you said
you are fine with and the checks you ticked. It is encrypted on the phone
before it is stored or sent, so the server cannot read it.

What the app reads about the phone (the list of apps, their permissions, the
settings, when apps were used) is read fresh each time the app opens, kept in
memory only, and never sent anywhere.

What the tracker scan found is kept between two openings of the app, so that
hundreds of apps are not read again each time. With it are kept the list of
what changed (the newest 200), and which sensitive permissions each app asked
for at the last look, which is what the next look is compared with. All of it
is in one file in the app's own folder on the phone, sealed with a key made
from the account's key, and it is not part of the account: it is never
synced, not even encrypted. Another account on the same phone starts with an
empty file.

### The tracker list

`assets/trackers/exodus_trackers.json` is made from the Exodus Privacy
tracker database, which is under the Open Database License (ODbL 1.0). See
`assets/trackers/NOTICE.md` for the credit, what was changed, and where the
copy came from. To take a newer list, save
`https://reports.exodus-privacy.eu.org/api/trackers` to a file and run
`dart run tool/build_tracker_list.dart <file> <date>`. The app itself never
calls Exodus Privacy's servers; the only link to them is a button on a
tracker's page that opens their description of it in the browser.

The build fails if the app's own list of Android permissions grows beyond the
ones written down in `.github/workflows/android-apk.yml`.

### The phone test

Under Settings there is a **Phone test**. It answers what Android, and
GrapheneOS in particular, lets an ordinary app read without root, and is how a
new Android version or another phone gets checked. Six steps on one screen:

1. **Read the phone.** Installed apps with their permissions, who holds
   special access, and the settings a privacy check looks at.
2. **Usage access** (optional). When each app was last used.
3. **Deep mode** (optional, needs a computer). Whether a one-time command from
   a computer unlocks the history of which app used the camera, microphone or
   location.
4. **Tracker scan.** Reads the class names inside each installed app, on the
   phone, and looks for the trackers of the Exodus Privacy list. The point of
   this step is the time a full scan takes.
5. **Android's own screens.** Which system screens the app is allowed to open.
6. **Send the results.** A summary with counts only, no app names, to share
   or copy. A full report with one line per app can be saved to Downloads.

## Layout

| Path | What is there |
|---|---|
| `android/app/src/main/kotlin/` | The Android side: `DeviceProbe.kt` reads the phone, `AppOpsReader.kt` is deep mode, `MainActivity.kt` opens system screens. |
| `lib/probe/` | The Dart side of the same calls. |
| `lib/phone/` | One reading of the phone, and the trips to Android's settings and back. |
| `lib/rules/` | What counts as a finding, the score, and the device checklist. No screens, no Android: plain rules with tests. |
| `lib/choices/` | "I'm fine with this" and the ticked checks, kept encrypted in the account. |
| `lib/ui/` | The screens. |
| `lib/app/` | Sign-in, lock and links, on the shared Zero-Trust core. |
| `lib/scan/` | Reading an app's code for tracker names: the zip and DEX readers, the tracker list, the background reader. |
| `lib/trackers/` | Which apps to read and when, what changed since the last look, and the file both are kept in on the phone. |
| `lib/report/` | The phone test's reports. |
| `assets/trackers/`, `tool/` | The tracker list, its licence notice, and the tool that makes it. |
| `lib/l10n/` | English and Hebrew. |

## Building

Flutter 3.47.9.

The app reads the address of the Zero-Trust account service from a `.env`
file, which is not committed. The build on GitHub writes it; for a local build
copy the two public values from `.github/workflows/android-apk.yml`.

```
flutter pub get
flutter analyze
flutter test test/
flutter build apk --release --target-platform android-arm64
```

Every pull request builds an APK you can download from its checks page. A
push to `main` publishes a signed APK as a GitHub release.

Before the build, the suite's release checks run (`dart run zt_release_checks
--app privacy`, from Zero-Trust-Core): keys, sync, sign-in, app setup and the
database rules. After it, the build reads its own APK for tracker code with
the same list and rules the app uses on other apps
(`dart run zt_release_checks:zt_tracker_check <apk>`), and fails if it finds
any. The APK's permissions are checked against a fixed list in the same
step that builds it.

Work happens on the `Dev` branch. Licensed under the AGPL-3.0.
