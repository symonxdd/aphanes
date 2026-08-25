// Cuts a release: bump the version, commit it, tag it, push.
//
// Run with `dart run tool/release.dart`. Pushing the tag is what starts
// .github/workflows/release.yml, which builds the signed APK and creates
// the GitHub release; nothing is built locally.
//
// Written in Dart rather than as a shell script so it behaves the same on
// every machine, and so a Flutter repo does not grow a package.json just
// to hold one script.
import 'dart:io';

const String _pubspecPath = 'pubspec.yaml';

/// `version: 1.0.0+1`, where the part after the plus is Android's
/// versionCode. Play Store and every installer require that number to
/// increase on every build, so it is bumped on every release regardless
/// of which semver part moved.
// [ \t]* rather than \s* at either end: \s matches newlines too, and
// being greedy it would swallow the blank line after the version and
// quietly delete it on every release.
final RegExp _versionLine = RegExp(
  r'^version:[ \t]*(\d+)\.(\d+)\.(\d+)\+(\d+)[ \t]*$',
  multiLine: true,
);

Future<void> main(List<String> args) async {
  _requireRepoRoot();
  await _requireCleanTree();

  final _Version current = _readVersion();
  stdout.writeln('Current version: $current');
  stdout.writeln();

  final _Version next = _promptForNext(current);
  stdout.writeln();
  stdout.writeln('  $current  ->  $next');
  stdout.writeln('  tag: v${next.semver}');
  stdout.writeln();

  if (!_confirm('Release v${next.semver}?')) {
    stdout.writeln('Cancelled. Nothing was changed.');
    exit(1);
  }

  _writeVersion(next);
  stdout.writeln('Updated $_pubspecPath');

  await _run('git', ['add', _pubspecPath]);
  await _run('git', [
    'commit',
    '-m',
    'chore(release): bump version to ${next.semver}',
  ]);
  await _run('git', ['tag', 'v${next.semver}']);
  await _run('git', ['push']);
  await _run('git', ['push', 'origin', 'v${next.semver}']);

  stdout.writeln();
  stdout.writeln('Released v${next.semver}.');
  stdout.writeln(
    'The build runs at https://github.com/symonxdd/aphanes/actions',
  );
}

/// Refuses to run from anywhere but the repository root, since every path
/// here is relative to it.
void _requireRepoRoot() {
  if (!File(_pubspecPath).existsSync()) {
    stderr.writeln('Run this from the repository root.');
    exit(1);
  }
}

/// A dirty tree would get swept into the version commit, which is meant
/// to contain exactly one changed line.
Future<void> _requireCleanTree() async {
  final ProcessResult result = await Process.run('git', [
    'status',
    '--porcelain',
  ]);
  final String output = (result.stdout as String).trim();
  if (output.isNotEmpty) {
    stderr.writeln('Working tree is not clean:');
    stderr.writeln(output);
    stderr.writeln();
    stderr.writeln('Commit or stash first, then release.');
    exit(1);
  }
}

_Version _readVersion() {
  final String pubspec = File(_pubspecPath).readAsStringSync();
  final RegExpMatch? match = _versionLine.firstMatch(pubspec);
  if (match == null) {
    stderr.writeln('No `version: x.y.z+n` line found in $_pubspecPath.');
    exit(1);
  }
  return _Version(
    int.parse(match.group(1)!),
    int.parse(match.group(2)!),
    int.parse(match.group(3)!),
    int.parse(match.group(4)!),
  );
}

void _writeVersion(_Version version) {
  final File file = File(_pubspecPath);
  file.writeAsStringSync(
    file.readAsStringSync().replaceFirst(_versionLine, 'version: $version'),
  );
}

_Version _promptForNext(_Version current) {
  final Map<String, _Version> choices = {
    '1': current.bumpPatch(),
    '2': current.bumpMinor(),
    '3': current.bumpMajor(),
  };
  stdout.writeln('What kind of release is this?');
  stdout.writeln('  1) patch  ${choices['1']!.semver}   a fix, nothing new');
  stdout.writeln('  2) minor  ${choices['2']!.semver}   a new feature');
  stdout.writeln('  3) major  ${choices['3']!.semver}   a breaking change');
  stdout.write('> ');
  final String? answer = stdin.readLineSync()?.trim();
  final _Version? chosen = choices[answer];
  if (chosen == null) {
    stderr.writeln('Not one of the options. Cancelled.');
    exit(1);
  }
  return chosen;
}

bool _confirm(String question) {
  stdout.write('$question [y/N] ');
  final String answer = (stdin.readLineSync() ?? '').trim().toLowerCase();
  return answer == 'y' || answer == 'yes';
}

Future<void> _run(String executable, List<String> arguments) async {
  stdout.writeln('\$ $executable ${arguments.join(' ')}');
  final Process process = await Process.start(
    executable,
    arguments,
    mode: ProcessStartMode.inheritStdio,
  );
  final int code = await process.exitCode;
  if (code != 0) {
    stderr.writeln('Failed with exit code $code. Stopping here.');
    stderr.writeln(
      'Anything already committed or tagged is still in place; undo it '
      'before trying again.',
    );
    exit(code);
  }
}

class _Version {
  const _Version(this.major, this.minor, this.patch, this.build);

  final int major;
  final int minor;
  final int patch;
  final int build;

  String get semver => '$major.$minor.$patch';

  _Version bumpPatch() => _Version(major, minor, patch + 1, build + 1);
  _Version bumpMinor() => _Version(major, minor + 1, 0, build + 1);
  _Version bumpMajor() => _Version(major + 1, 0, 0, build + 1);

  @override
  String toString() => '$semver+$build';
}
