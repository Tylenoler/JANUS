/// Keep this aligned with pubspec.yaml using Semantic Versioning.
const applicationVersion = '2.0.0';
const coreVersion = '0.4.0';
const protocolVersion = 'v2';

/// Supplied by the release script. Development runs deliberately show a
/// visible marker instead of pretending to be a packaged release.
const buildGitRevision =
    String.fromEnvironment('JANUS_GIT_SHA', defaultValue: '开发构建');
const buildTimestamp =
    String.fromEnvironment('JANUS_BUILD_TIME', defaultValue: '未打包');
