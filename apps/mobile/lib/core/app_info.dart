/// The user-facing app version, shown in the Profile About footer.
///
/// Kept in sync with `pubspec.yaml` `version:` by hand — deliberately a plain constant rather than
/// a `package_info_plus` dependency, to avoid pulling a native plugin in just for a footer string.
const kAppVersion = '0.1.0';
