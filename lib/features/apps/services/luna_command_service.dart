import 'dart:async';
import 'dart:convert';

import 'package:dartssh2/dartssh2.dart';

/// Thrown when a luna-bus call fails outright (non-zero exit, unparseable
/// response) - not the same as a call that succeeds but reports an
/// application-level error, which callers read from the decoded response.
class LunaCallException implements Exception {
  const LunaCallException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Runs `luna-send-pub` commands over an already-authenticated [SSHClient],
/// matching webosbrew/ares-cli-rs's (Apache-2.0) `common/connection/src/
/// luna/luna.rs` exactly: both the one-shot list call and the subscribed
/// install/remove calls go over the *public* bus (`luna-send-pub`, not
/// `luna-send`), confirmed by reading that file directly rather than
/// assuming from the command name alone.
class LunaCommandService {
  /// A single-response call (`luna-send-pub -n 1 <uri> <payload>`), for
  /// `dev/listApps`. Returns the decoded JSON response.
  Future<Map<String, dynamic>> call(
    SSHClient client,
    String uri,
    Map<String, dynamic> payload,
  ) async {
    final String command =
        'luna-send-pub -n 1 ${_shellEscape(uri)} '
        '${_shellEscape(jsonEncode(payload))}';
    final Uint8ListResult result = await _run(client, command).timeout(
      const Duration(seconds: 10),
      onTimeout: () => throw const LunaCallException(
        'The TV took too long to respond.',
      ),
    );
    if (result.exitCode != 0) {
      throw LunaCallException(
        result.stderrText.isEmpty
            ? 'The TV rejected that request.'
            : result.stderrText.trim(),
      );
    }
    try {
      return jsonDecode(result.stdoutText) as Map<String, dynamic>;
    } on FormatException {
      throw const LunaCallException('The TV sent an unexpected response.');
    }
  }

  /// A subscribed call (`luna-send-pub -i <uri> <payload>`), for
  /// `dev/install` and `dev/remove`. Each line of stdout is one JSON
  /// message; yields them as they arrive, for as long as the TV keeps the
  /// subscription open.
  Stream<Map<String, dynamic>> subscribe(
    SSHClient client,
    String uri,
    Map<String, dynamic> payload,
  ) async* {
    final String command =
        'luna-send-pub -i ${_shellEscape(uri)} '
        '${_shellEscape(jsonEncode(payload))}';
    final SSHSession session = await client.execute(command);
    final Stream<String> lines = session.stdout
        .cast<List<int>>()
        .transform(utf8.decoder)
        .transform(const LineSplitter());
    await for (final String line in lines) {
      if (line.trim().isEmpty) {
        continue;
      }
      try {
        yield jsonDecode(line) as Map<String, dynamic>;
      } on FormatException {
        // A partial or non-JSON line from the TV's stdout - ignored rather
        // than aborting the whole subscription over one malformed message.
      }
    }
  }

  Future<Uint8ListResult> _run(SSHClient client, String command) async {
    final SSHSession session = await client.execute(command);
    final List<int> stdoutBytes = [];
    final List<int> stderrBytes = [];
    await Future.wait([
      session.stdout.forEach(stdoutBytes.addAll),
      session.stderr.forEach(stderrBytes.addAll),
    ]);
    final int exitCode = await session.waitForExit() ?? 0;
    return Uint8ListResult(
      exitCode: exitCode,
      stdoutText: utf8.decode(stdoutBytes, allowMalformed: true),
      stderrText: utf8.decode(stderrBytes, allowMalformed: true),
    );
  }

  /// Standard POSIX single-quote shell escaping: wraps in `'...'`,
  /// replacing any embedded `'` with `'\''`. This is a stricter superset of
  /// what the reference's `snailquote::escape` produces for the values this
  /// app ever sends (ids, TV-side file paths, JSON booleans - never a `'`
  /// or non-ASCII control character), and is trivially correct for
  /// arbitrary content besides, unlike porting its full double-quote/
  /// unicode-escape branches for cases that can't occur here.
  static String shellEscape(String value) {
    return "'${value.replaceAll("'", "'\\''")}'";
  }

  String _shellEscape(String value) => shellEscape(value);
}

class Uint8ListResult {
  const Uint8ListResult({
    required this.exitCode,
    required this.stdoutText,
    required this.stderrText,
  });

  final int exitCode;
  final String stdoutText;
  final String stderrText;
}
