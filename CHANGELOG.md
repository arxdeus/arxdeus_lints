# Changelog

## 1.0.0

First release.

This package ships exactly one thing, a shared analysis options file, adopted
in one line from your own `analysis_options.yaml`:

```yaml
include: package:arxdeus_lints/analysis_options/recommended.yaml
```

What that file configures:

- The three strict language modes together: `strict-casts`,
  `strict-inference` and `strict-raw-types`.
- 212 lints enabled, of which 20 are promoted to errors and 37 to warnings.
- Three lints that no `// ignore:` comment can silence: `avoid_dynamic_calls`,
  `close_sinks` and `cancel_subscriptions`.

Notes:

- The package contains no Dart code at all, so nothing it ships can reach your
  program at runtime. It belongs in `dev_dependencies`.
- It deliberately sets no `analyzer.exclude`, because exclude paths are
  per-project. Set yours alongside the include.
- `example/` is a small project that adopts the options, with one file whose
  every reported diagnostic demonstrates a specific thing the configuration
  does.

The annotation-driven lint rules that were developed alongside these options
are not part of this package. Each is published separately, one package per
annotation, so a project takes only the ones it wants.
