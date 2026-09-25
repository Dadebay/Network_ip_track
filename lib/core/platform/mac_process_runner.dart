import 'dart:convert';
import 'dart:io';

/// Result of running a macOS command-line tool.
class MacProcessResult {
  const MacProcessResult({
    required this.exitCode,
    required this.stdout,
    required this.stderr,
  });

  final int exitCode;
  final String stdout;
  final String stderr;

  bool get succeeded => exitCode == 0;
}

/// Runs macOS command-line tools with an explicit argument list — never a
/// shell string — so user input can never be interpreted as shell syntax.
class MacProcessRunner {
  const MacProcessRunner();

  Future<MacProcessResult> run(
    String executable,
    List<String> arguments, {
    Duration? timeout,
  }) async {
    final process = await Process.start(executable, arguments);
    final stdoutFuture = process.stdout.transform(utf8.decoder).join();
    final stderrFuture = process.stderr.transform(utf8.decoder).join();

    late final int exitCode;
    if (timeout != null) {
      exitCode = await process.exitCode.timeout(
        timeout,
        onTimeout: () {
          process.kill();
          return -1;
        },
      );
    } else {
      exitCode = await process.exitCode;
    }

    return MacProcessResult(
      exitCode: exitCode,
      stdout: await stdoutFuture,
      stderr: await stderrFuture,
    );
  }

  /// For tools that never exit on their own (`dns-sd -B`, `dns-sd -G`):
  /// starts [executable], collects stdout for [collectFor], then kills it
  /// and returns whatever was captured. Never waits for `exitCode`.
  Future<String> runStreaming(
    String executable,
    List<String> arguments, {
    required Duration collectFor,
  }) async {
    final process = await Process.start(executable, arguments);
    final buffer = StringBuffer();
    final subscription = process.stdout
        .transform(utf8.decoder)
        .listen(buffer.write);

    await Future<void>.delayed(collectFor);
    await subscription.cancel();
    process.kill();

    return buffer.toString();
  }
}
