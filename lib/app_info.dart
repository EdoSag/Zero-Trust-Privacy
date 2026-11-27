/// Shown in the app and written into every phone test report. Kept equal to
/// the version in `pubspec.yaml` by `test/app_info_test.dart`.
const String appVersion = '0.2.0';

/// The build number GitHub gave this APK, `dev` for a local build.
const String appBuild = String.fromEnvironment('ZT_BUILD', defaultValue: 'dev');
