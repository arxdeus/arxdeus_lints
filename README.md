# arxdeus_lints

A strict, opinionated set of analysis options for Dart and Flutter projects,
published as a single file you include from your own `analysis_options.yaml`.

**This package contains no Dart code.** It ships one YAML file. Adopting it is
one line, and adopting it costs you nothing at runtime: analysis options affect
what the analyzer reports, never what your program does.

## Install

```yaml
# pubspec.yaml
dev_dependencies:
  arxdeus_lints: ^2.0.0
```

```yaml
# analysis_options.yaml
include: package:arxdeus_lints/analysis_options/recommended.yaml
```

Then run `dart analyze` (or `flutter analyze`). That is the whole setup.

## What you get

The configuration is built on the premise that a problem is worth catching at
the moment it is typed rather than in review, and that the analyzer is the
cheapest place to catch it. Concretely:

**The three strict language modes, switched on together.**

```yaml
analyzer:
  language:
    strict-casts: true      # no silent downcast from `dynamic`
    strict-inference: true  # no type inferred only as `dynamic`
    strict-raw-types: true  # no bare `List`, `Map`, `Future`
```

These are the modern replacements for the removed `implicit-casts` and
`implicit-dynamic`, and they travel as a set: each one closes a different route
by which `dynamic` re-enters a codebase that meant to be typed.

**19 lints promoted to errors**, including `avoid_dynamic_calls`,
`close_sinks`, `cancel_subscriptions`, `prefer_final_locals`,
`always_declare_return_types` and `type_annotate_public_apis`. An error fails
`dart analyze` with a non-zero exit code, so these cannot reach a merged branch
through a CI job that only checks the exit status.

**37 more promoted to warnings**, and roughly 215 lints enabled in total.

**Three lints that no `// ignore:` comment can silence:**

```yaml
analyzer:
  cannot-ignore:
    - avoid_dynamic_calls
    - close_sinks
    - cancel_subscriptions
```

Each of these marks a defect that an ignore comment does not fix: a dynamic
call still fails at runtime, and an unclosed sink or uncancelled subscription
still leaks. Making them unignorable is the point of listing them.

The set deliberately leaves out lints that contradict each other, so you will
not find yourself unable to satisfy two rules at once.

## What it deliberately does not set

`analyzer.exclude`, because exclude paths are per-project. Set yours in your
own file, alongside the include:

```yaml
include: package:arxdeus_lints/analysis_options/recommended.yaml

analyzer:
  exclude:
    - "**/*.g.dart"
    - "**/*.freezed.dart"
```

## Adjusting it

Anything in the shared file can be overridden after the `include`, and a later
setting wins. If a rule does not suit your project, turn it off rather than
abandoning the set:

```yaml
include: package:arxdeus_lints/analysis_options/recommended.yaml

linter:
  rules:
    # This codebase uses `print` intentionally in its CLI entry points.
    avoid_print: false

analyzer:
  errors:
    # Demote rather than disable: still visible, no longer blocking.
    prefer_final_locals: warning
```

Adopting a shared file and overriding two lines stays in step with the set as
it evolves. Copying it and editing does not.

## Expectations when adopting

On an existing codebase this will report a lot on the first run. That is the
configuration working, not misconfigured. Two things make it manageable:

```sh
dart fix --apply     # mechanically fixes a large share of them
dart analyze         # see what is left
```

Much of the remainder is `prefer_final_locals` and
`always_declare_return_types`, both of which `dart fix` handles. If the rest is
still too much to take at once, demote the noisiest rules to `info` in your own
file and raise them back as you go.

## Example

The `example/` directory is a small project that adopts these options, with one
file whose every reported diagnostic exists to demonstrate a specific thing the
configuration does. Run `dart analyze` there to see them.

## Versioning

The version is a contract about analysis outcomes: a new lint, or a promotion
to a stricter level, can fail a build that previously passed. Such changes are
released as a major version. Patch and minor releases will not add diagnostics
to code that currently analyses clean.

## Development

This package is developed inside a pub workspace that checks it out as a
submodule alongside its sibling packages. Its pubspec declares
`resolution: workspace`, so a lone clone of *this* repository cannot resolve on
its own: `dart pub get` needs that workspace root above it.

```sh
cd packages/arxdeus_lints
```

## License

MIT. See [LICENSE](LICENSE).
