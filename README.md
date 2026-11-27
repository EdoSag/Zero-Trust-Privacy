# Zero-Trust Privacy

A privacy dashboard for the [Zero-Trust apps](https://zerotrust.bz). On the
phone it is called **ZT Privacy**; in stores and on release pages,
**Zero-Trust Privacy**.

It will show, on one screen, how private the phone and the accounts are and
what to fix first: which apps hold which permissions, which apps carry tracker
code, whether an account was part of a breach, the state of the Zero-Trust
account, and a checklist of device settings. Every check runs on the phone.
The list of installed apps never leaves it.

## Where it stands: the phone test

The app in this repository today is the **phone test**, not the dashboard. It
answers one question before the real app is built: what does Android, and
GrapheneOS in particular, let an ordinary app read without root?

It has no sign-in and does not ask for the network permission, so nothing it
reads can leave the phone unless you share it yourself. Six steps on one
screen:

1. **Read the phone.** Installed apps with their permissions, who holds
   special access (accessibility, device admin, notification access and so
   on), and the settings a privacy check looks at. Also whether GrapheneOS's
   Network and Sensors switches of other apps can be seen.
2. **Usage access** (optional). When each app was last used and how much data
   it moved.
3. **Deep mode** (optional, needs a computer). Whether a one-time command from
   a computer unlocks the history of which app used the camera, microphone or
   location.
4. **Tracker scan.** Reads the class names inside each installed app, on the
   phone, and looks for a short starter list of well-known advertising and
   tracking kits. The point of this step is the time a full scan takes.
5. **Android's own screens.** Which system screens the app is allowed to open.
6. **Send the results.** A summary with counts only, no app names, to share
   or copy. A full report with one line per app can be saved to Downloads.

Every answer Android refuses is recorded with Android's own words, because a
refusal is a result too.

## Layout

| Path | What is there |
|---|---|
| `android/app/src/main/kotlin/` | The Android side: `DeviceProbe.kt` reads the phone, `AppOpsReader.kt` is deep mode. |
| `lib/probe/` | The Dart side of the same calls. |
| `lib/scan/` | The tracker scan: a small zip reader, a reader for the class names in an app's code, and the starter list of kits. Runs off the main thread. |
| `lib/report/` | Builds the summary and the full report. |
| `lib/ui/` | The one screen and its controller. |
| `lib/l10n/` | English and Hebrew. |

## Building

Flutter 3.47.9.

```
flutter pub get
flutter analyze
flutter test test/
flutter build apk --release --target-platform android-arm64
```

Every pull request builds an APK you can download from its checks page. A
push to `main` publishes a signed APK as a GitHub release.

Work happens on the `Dev` branch. Licensed under the AGPL-3.0.
