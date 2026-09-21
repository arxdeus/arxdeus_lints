// Checks that the example demonstrates what it claims to.
//
// This package ships no code, only an analysis options file, so the one thing
// that can regress is which diagnostics that file switches on. A lint removed
// from the shared options, or renamed by the analyzer, would leave the package
// resolving and publishing perfectly while quietly no longer doing its job.
//
// Rather than hard-code a tally that drifts, this reads the example's own
// comments as the specification. Each `// reported: <code>` comment claims one
// diagnostic of that code, and the totals per code must match exactly. Adding a
// case to the example therefore extends this check for free.
//
// Matching is by code rather than by line, because a marker may sit several
// lines above the code it describes, and one line can carry two diagnostics:
// a bare `List` is both `no_raw_types` and `strict_raw_type`. Counting per code
// keeps the comments free to explain themselves while still failing when a
// diagnostic stops firing, starts firing twice, or fires where nothing was
// claimed.
//
// Run from the package root:
//
//     dart run tool/verify_example.dart
//
// Exits non-zero, naming the code that disagreed, when the example and the
// shared options have drifted apart.

import 'dart:convert';
import 'dart:io';

/// The diagnostics the shared options are expected to switch on.
///
/// This package contributes no analyzer plugin: every code here comes from the
/// analyzer or the linter, and is reported only because the example includes
/// `arxdeus_lints`. Dart's default options report none of them, which is the
/// whole demonstration.
const _rules = {
  'avoid_dynamic_calls',
  'inference_failure_on_collection_literal',
  'no_dynamic_casts',
  'no_raw_types',
  'return_of_invalid_type',
  'strict_raw_type',
  'unrelated_type_equality_checks',
};

void main() async {
  final example = File('example/lib/example.dart');
  if (!example.existsSync()) {
    _fail('run this from the package root: ${example.path} not found');
  }

  final expected = _claimedCounts(example.readAsLinesSync());
  if (expected.isEmpty) {
    _fail('found no `// reported: <code>` markers in ${example.path}');
  }

  final actual = await _reportedCounts();

  final rules = {...expected.keys, ...actual.keys}.toList()..sort();
  final problems = <String>[];
  for (final rule in rules) {
    final claimed = expected[rule] ?? 0;
    final reported = actual[rule] ?? 0;
    if (claimed != reported) {
      problems.add(
        '  $rule: example claims $claimed, analyzer reported $reported',
      );
    }
  }

  if (problems.isEmpty) {
    final total = expected.values.fold(0, (sum, count) => sum + count);
    stdout.writeln(
      'OK: $total diagnostics across ${expected.length} codes, matching every '
      '`// reported:` claim in the example.',
    );
    return;
  }

  stderr.writeln('The example and the shared options disagree:');
  problems.forEach(stderr.writeln);
  stderr.writeln(
    '\nA code reporting nothing usually means the shared options stopped '
    'switching it on, or the analyzer renamed it. A code reporting more than '
    'claimed means either the example gained a case without a comment '
    'describing it, or a rule became more eager than it was.',
  );
  exit(1);
}

/// How many diagnostics of each rule the example says it should produce.
Map<String, int> _claimedCounts(List<String> lines) {
  final counts = <String, int>{};
  // Deliberately anchored to the line's start so that prose mentioning a rule
  // name mid-sentence cannot be mistaken for a claim.
  final marker = RegExp(r'^//\s*reported:\s*([a-z_]+)');

  for (final line in lines) {
    final match = marker.firstMatch(line.trim());
    if (match == null) {
      continue;
    }
    final rule = match.group(1)!;
    if (!_rules.contains(rule)) {
      _fail(
        'unknown code "$rule" claimed in the example. This tool knows '
        '${_rules.toList()..sort()}; add the new code there if one was added.',
      );
    }
    counts.update(rule, (n) => n + 1, ifAbsent: () => 1);
  }
  return counts;
}

/// How many diagnostics of each rule the analyzer actually reports.
///
/// Uses the machine-readable output rather than parsing the human format,
/// which is not a stable interface.
Future<Map<String, int>> _reportedCounts() async {
  final result = await Process.run(
    Platform.resolvedExecutable,
    ['analyze', '--format=json', '.'],
    workingDirectory: 'example',
  );

  // `dart analyze` exits non-zero simply for having found diagnostics, which is
  // the expected case here, so the exit code says nothing on its own. A broken
  // options file reports on stderr while still exiting non-zero, so that is
  // surfaced rather than swallowed.
  final stderrText = (result.stderr as String).trim();
  if (stderrText.isNotEmpty) {
    stderr.writeln('dart analyze wrote to stderr:\n$stderrText\n');
  }

  final Object? decoded;
  try {
    decoded = jsonDecode(result.stdout as String);
  } on FormatException catch (error) {
    _fail('could not parse `dart analyze --format=json` output: $error');
  }

  if (decoded is! Map<String, Object?>) {
    _fail('unexpected analyze output shape: ${decoded.runtimeType}');
  }
  final diagnostics = decoded['diagnostics'];
  if (diagnostics is! List) {
    _fail('analyze output carried no diagnostics list');
  }

  final counts = <String, int>{};
  for (final diagnostic in diagnostics) {
    if (diagnostic is! Map<String, Object?>) {
      continue;
    }
    final code = diagnostic['code'];
    if (code is! String || !_rules.contains(code)) {
      continue;
    }
    counts.update(code, (n) => n + 1, ifAbsent: () => 1);
  }
  return counts;
}

Never _fail(String message) {
  stderr.writeln(message);
  exit(1);
}
