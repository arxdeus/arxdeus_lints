// Demonstrates the shared analysis options that `arxdeus_lints` publishes.
//
// The point of this file is the `analysis_options.yaml` beside it, which is a
// single `include:` line. Everything flagged below is flagged *because* of
// that line: with Dart's default analysis options, none of it is reported.
//
// Run `dart analyze` in this directory to see them.

import 'dart:io';

/// `strict-raw-types` rejects a bare `List`, because its element type is then
/// silently `dynamic` and every use of it goes unchecked.
// reported: no_raw_types
// reported: strict_raw_type
List rawType() => <Object?>[];

/// `strict-casts` rejects the implicit downcast from `dynamic` to `String`.
/// Written out as `value as String`, the line that can throw is visible.
String implicitCast(dynamic value) {
  // reported: no_dynamic_casts
  // reported: return_of_invalid_type
  return value;
}

/// `strict-inference` rejects a type inference could only fill in as
/// `dynamic`. Writing `<String>[]` says what was meant.
List<String> inferenceFailure() {
  // reported: inference_failure_on_collection_literal
  final untyped = [];
  return untyped.cast<String>();
}

/// `avoid_dynamic_calls` is promoted to an **error**, and listed under
/// `cannot-ignore`, so not even an `// ignore:` comment silences it. A call
/// dispatched on `dynamic` fails at runtime rather than here.
void dynamicCall(dynamic target) {
  // reported: avoid_dynamic_calls
  target.whateverMethod();
}

/// One of the many lints the shared options switch on that are off by
/// default: `==` between unrelated types is always false, so it is a bug in
/// every case rather than a matter of style.
// reported: unrelated_type_equality_checks
bool unrelatedEquality(int a, String b) => a == b;

/// Referencing each of the above, so that none is reported as unused and the
/// diagnostics stay confined to the lines they illustrate.
///
/// Nothing is called: several of these would throw, which is the point. The
/// value of this file is what `dart analyze` says about it, not what running
/// it does.
const demonstrations = [
  rawType,
  implicitCast,
  inferenceFailure,
  dynamicCall,
  unrelatedEquality,
];

void main() {
  stdout.writeln('Run `dart analyze` here: ${demonstrations.length} cases.');
}
