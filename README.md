# arxdeus_lints

The shared analysis options used across the [arxdeus_lints monorepo], which is
also home to three annotation-driven analyzer plugins for Dart and Flutter.

**This package ships no lint rules.** What it publishes is one file,
`lib/analysis_options/recommended.yaml`, which you can adopt wholesale:

```yaml
# analysis_options.yaml
include: package:arxdeus_lints/analysis_options/recommended.yaml
```

```yaml
# pubspec.yaml
dev_dependencies:
  arxdeus_lints: ^2.0.0
```

It turns on the strict language modes, promotes a long list of lints to
warnings or errors, and deliberately leaves out the ones that contradict each
other. It sets no `analyzer.exclude`, because exclude paths are per-project;
set those in your own file.

Every package in the monorepo includes this same file, so the configuration is
the one its authors actually live with rather than one they only publish.

## The plugins

The rules live in separate packages, each with its own annotation, so a project
takes only the ones it wants. They compose: enable any combination in the same
`analysis_options.yaml`.

| Package | Annotation | Rules |
| --- | --- | --- |
| [`disposito`](https://pub.dev/packages/disposito) | `@Disposable` | `missing_dispose`, `stateful_in_build`, `this_in_dispose`, `late_initialized_in_dispose` |
| [`checked_exceptions`](https://pub.dev/packages/checked_exceptions) | `@Throws` | `unhandled_throws`, `empty_catch` |
| [`sensitive_exposure_lint`](https://pub.dev/packages/sensitive_exposure_lint) | `@Sensitive` | `sensitive_exposure` |

Each plugin is listed twice in a consuming project: once as a dependency,
because you write its annotation in your code, and once as a plugin, because
the analyzer runs its rules.

```yaml
# pubspec.yaml
dependencies:
  disposito: ^1.0.0
  checked_exceptions: ^1.0.0
  sensitive_exposure_lint: ^1.0.0
```

```yaml
# analysis_options.yaml
include: package:arxdeus_lints/analysis_options/recommended.yaml

plugins:
  disposito: ^1.0.0
  checked_exceptions: ^1.0.0
  sensitive_exposure_lint: ^1.0.0
```

Restart the Dart Analysis Server after changing the `plugins` section. Each
package's README documents its own rules, suppression syntax and limits.

Requires Dart 3.10 or later (analyzer plugins are not supported before that).

[arxdeus_lints monorepo]: https://github.com/arxdeus/arxdeus_lints
