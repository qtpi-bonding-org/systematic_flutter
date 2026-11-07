/// App version and git commit from `--dart-define=APP_VERSION=` and
/// `GIT_COMMIT=` (see tool/build_defines.sh); null when not defined.
class BuildInfo {
  const BuildInfo({this.appVersion, this.commit});
  final String? appVersion;
  final String? commit;

  const BuildInfo.fromEnvironment()
      : appVersion = const String.fromEnvironment('APP_VERSION') == ''
            ? null
            : const String.fromEnvironment('APP_VERSION'),
        commit = const String.fromEnvironment('GIT_COMMIT') == ''
            ? null
            : const String.fromEnvironment('GIT_COMMIT');
}
