# Changelog

## 2.0.0

**Breaking: this package no longer ships lint rules.** It now ships exactly one
thing, the shared analysis options:

```yaml
include: package:arxdeus_lints/analysis_options/recommended.yaml
```

**If that line is all you used, upgrading requires no change.** The options
themselves are unchanged, and `dart analyze` reports the same diagnostics over
the same sources as 1.0.0 did.

The `@Disposable` and `@Throws` annotations, and the rules that acted on them,
are gone from this package. A project that used them needs the plugin package
that now owns each one; see the migration note in the 1.0.0 entry below for
what moved where.

Also in this release:

- The package is now `dev_dependencies`-only by nature: it contains no Dart
  code at all, so nothing it ships can reach your program at runtime. Move it
  out of `dependencies` if it is still there.
- Added an `example/` project demonstrating what adopting the options reports.
- The README documents the configuration directly: the strict language modes
  it enables, the lints it promotes to errors and warnings, the three it makes
  unignorable, and how to override any of it in your own file.

## 1.0.0

Initial release, as a package containing both analysis options and lint rules.

- Shared analysis options at
  `package:arxdeus_lints/analysis_options/recommended.yaml`.
- A `@Disposable` annotation and a `missing_dispose` rule, reporting instance
  fields that the declaring class never cleans up.
- A `@Throws` annotation and an `unhandled_throws` rule, reporting calls whose
  declared exceptions are neither caught nor re-declared.
- A `@Sensitive` annotation and a `sensitive_exposure` rule, reporting a secret
  that reaches a log or an exception message.

The rules listed here were removed in 2.0.0 and now live in separate plugin
packages, one per annotation, so a project takes only the ones it wants. The
rules are unchanged by the move. Migrating means depending on the plugin that
owns the annotation you use, importing the annotation from it, and changing any
`// ignore: arxdeus_lints/<rule>` comment to that plugin's prefix.
