## 2.0.0

- The package moved from the repository root to `packages/arxdeus_lints`, and
  the repository became a [pub workspace]. Nothing about what this package
  publishes changed: it still ships only
  `lib/analysis_options/recommended.yaml`, and
  `include: package:arxdeus_lints/analysis_options/recommended.yaml` keeps
  working exactly as before. The move matters only to people working in the
  repository, where one `dart pub get` at the root now resolves every package
  against a single lockfile, and the packages depend on each other by the same
  version constraints they publish with rather than by path.

- **Breaking: this package no longer ships any lint rules.** They now live in
  three plugin packages, each with its own annotation, so a project takes only
  what it wants:

  | Package | Annotation | Rules |
  | --- | --- | --- |
  | `disposito` | `@Disposable` | `missing_dispose`, `stateful_in_build`, `this_in_dispose`, `late_initialized_in_dispose` |
  | `checked_exceptions` | `@Throws` | `unhandled_throws`, `empty_catch` |
  | `sensitive_exposure_lint` | `@Sensitive` | `sensitive_exposure` |

  What `arxdeus_lints` still publishes is the shared analysis options, which
  are unchanged: `include: package:arxdeus_lints/analysis_options/recommended.yaml`
  keeps working exactly as before. The repository is now the monorepo root for
  the packages above.

  Migration: replace the `arxdeus_lints` dependency and `plugins` entry with
  whichever of the three you use, import the annotation from its new package,
  and change `// ignore: arxdeus_lints/<rule>` comments to the new plugin
  prefix (`disposito/`, `checked_exceptions/` or `sensitive_exposure_lint/`).
  A project that only used the shared options needs no change at all.

  The rules themselves are unchanged. Over the same sources they report the
  same diagnostics with the same messages as in 1.0.0.

- **Breaking:** the `sensitive_exposure` rule and its `@Sensitive` annotation
  moved to their own package, `sensitive_exposure_lint`, in
  `packages/sensitive_exposure_lint`.

  Keeping a secret out of a log has nothing to do with disposing a controller.
  They shared a package only because they were written at the same time, and a
  project that wanted one had to take the other. They are now separate plugins
  that can be enabled independently or together.

  Migration, for code that used `@Sensitive`:

  ```yaml
  # pubspec.yaml
  dependencies:
    sensitive_exposure_lint: ^1.0.0

  # analysis_options.yaml
  plugins:
    sensitive_exposure_lint: ^1.0.0
  ```

  Then import `package:sensitive_exposure_lint/sensitive_exposure_lint.dart`
  for `@Sensitive`, and change any
  `// ignore: arxdeus_lints/sensitive_exposure` comment to the
  `sensitive_exposure_lint/` prefix. Code that used only `@Disposable` needs
  no change.

  The rule itself is unchanged: over the same sources it reports the same
  diagnostics with the same messages as before the split.

- `export` directives no longer carry `show` clauses. A `show` that lists
  exactly what the file declares is noise, and one that drifts out of date is
  worse than noise, so the exported surface is now decided by what the `src/`
  files declare publicly.

  That is only safe with something checking it, because without a `show` a
  helper added to an exported `src/` file becomes public API the moment it is
  written. `test/public_api_test.dart` pins the exported names of every
  published library and fails naming the symbol when one leaks. The removal
  itself was verified the same way: the exported surface is byte-identical to
  what the `show` clauses produced, so the clauses were redundant rather than
  load-bearing.

- The shared analyzer-plugin infrastructure moved to a new package,
  `analyzer_plugin_toolkit`, in `packages/analyzer_plugin_toolkit`. The
  per-element memo table, the annotation lookup, the element normalization and
  the quick-fix test harness live there now, in one copy rather than two.

  Splitting checked exceptions out had left both plugins holding near-identical
  copies of the same code, including the annotation lookup, which is
  correctness-critical: it is what stops a same-named annotation from another
  package driving rules that know nothing about it. Two copies of that is one
  too many.

  The lookup is now `AnnotationFinder`, parameterized by the declaring package
  instead of hardcoding one, and it carries its own tests, including a mutation
  check that breaking the package comparison fails the suite. Nothing about the
  rules changed: over the same sources they report byte-identical diagnostics.

- **Breaking:** checked exceptions moved to their own package,
  `checked_exceptions`, in `packages/checked_exceptions`. The `@Throws`
  annotation, the `unhandled_throws` and `empty_catch` rules, the `@Throws`
  quick fix and the curated SDK throws table all live there now.

  They were a self-contained idea sharing a package with an unrelated one:
  `@Throws` is about how failures travel through a call graph, while
  `@Disposable` and `@Sensitive` are about the lifetime and the secrecy of
  values. Splitting them means a project can take either without the other,
  and the two can still be enabled together.

  `empty_catch` went with them rather than staying: an empty `catch` is the
  cheapest way to silence `unhandled_throws` without handling anything, so the
  two rules only do their job in the same package.

  Migration, for code that used `@Throws`:

  ```yaml
  # pubspec.yaml
  dependencies:
    checked_exceptions: ^1.0.0

  # analysis_options.yaml
  plugins:
    checked_exceptions: ^1.0.0
  ```

  Then import `package:checked_exceptions/checked_exceptions.dart` for
  `@Throws`, and change any `// ignore: arxdeus_lints/unhandled_throws` or
  `// ignore: arxdeus_lints/empty_catch` comment to the `checked_exceptions/`
  prefix. Code that used only `@Disposable` and `@Sensitive` needs no change.

  The rules themselves are unchanged: over the same sources they report the
  same diagnostics with the same messages as before the split.

- Performance: the rules run about 2.8x faster, with byte-identical
  diagnostics. They had been re-deriving the same facts about the same
  elements once per *mention* rather than once per element: whether a class is
  a `Widget`, whether it owns a lifecycle, whether a declaration carries
  `@Disposable`, `@Throws` or `@Sensitive`, and which SDK table entry a callee
  matches. A widget tree mentions the same handful of classes hundreds of
  times, so the work scaled with node count instead of element count. Those
  answers are now memoized in an `Expando` keyed on the element, which ties an
  entry's lifetime to the element it describes rather than pinning every
  element the server has ever analysed.

  Several hot paths also did their most expensive work before the cheap check
  that would have made it unnecessary: annotation lookup evaluated a constant
  before comparing the annotation's name, `stateful_in_build` walked the
  enclosing constant context before asking whether the created type owns a
  lifecycle at all, `missing_dispose` resolved every method invocation in
  every member against every candidate field, and the SDK throws table
  consulted an element's library before its name. Each now leads with the
  cheap test.

  Measured with `tool/benchmark.dart` over 315k lines of generated
  Flutter-shaped code: 366 ms to 129 ms overall, `stateful_in_build` 155 ms to
  56 ms, `unhandled_throws` 124 ms to 76 ms, `sensitive_exposure` 116 ms to
  59 ms, `missing_dispose` 87 ms to 70 ms.

- `@Disposable` quick fix for `missing_dispose`: writes the cleanup call for
  the reported field into the class's disposal method, creating that method
  when there is none. The call is resolved from the element model rather than
  guessed: `@Disposable(#detach)` wins when the type really declares `detach`,
  otherwise `dispose`, `close` and `cancel` are tried in that order, through
  inherited members too, and a nullable field is cleaned up with `?.`. An
  existing `dispose`, `close` or `cancel` gains the statement, an expression
  body becomes a block holding both calls, and the call goes before a trailing
  `super.dispose()`, which has to run last. A class that inherits a `dispose`
  (a Flutter `State` being the case that matters) gets an `@override` ending in
  `super.dispose()`, and an asynchronous cleanup produces
  `Future<void> dispose() async` with the call awaited. No fix is offered when
  the type has no method callable with no arguments (including a
  `@Disposable(#detach)` naming a method the type does not declare, where the
  written call would not compile), or when the existing `dispose` is abstract
  or external and so has no body to write into.

- The SDK table now lists only `Exception`s, never `Error`s. Declaring an
  `Error` with `@Throws` is advice to catch it, which is exactly what the
  `avoid_catching_errors` lint forbids, so the two rules contradicted each
  other. `Iterable.first`/`.last`/`.single`/`.reduce`/`.firstWhere`, the
  `Stream` equivalents, `Queue.removeFirst`/`.removeLast`,
  `LinkedList.remove` (all `StateError`) and the `AssetBundle` loaders
  (`FlutterError`) are no longer reported. The `orElse` exemption went with
  them, since the exception it ruled out is no longer tabled.

- `@Throws` quick fix for `unhandled_throws`: annotates the enclosing function
  with exactly the exceptions the warning named, adding the imports for the
  annotation and for any exception class not already in scope. An existing
  `@Throws` is extended rather than duplicated, a partially caught set declares
  only what escapes, and no fix is offered inside a closure, whose exceptions
  do not propagate to the enclosing declaration.

- `unhandled_throws` now honours `@Throws` on a getter, so reading an annotated
  getter propagates the exception to the reader exactly as calling an annotated
  method propagates it to the caller. Previously the annotation was looked for
  on the getter's synthetic variable and never found, which silently dropped
  the obligation at the getter.

- `unhandled_throws` now knows what common SDK and Flutter members throw, so
  `int.parse`, `Uri.parse`, `jsonDecode`, `Iterable.first`/`.last`/`.single`/
  `.reduce`, the `dart:io` file, socket, process and HTTP members, and
  `MethodChannel.invokeMethod` are reported without annotating anything.
  Membership is matched through inheritance, `tryParse`, a tear-off and an
  `orElse` callback are exempt, and members that throw an `Error` about a bug
  (`list[0]`, `elementAt`, `jsonEncode`) are deliberately not covered.
  `dart run tool/verify_sdk_table.dart` resolves every entry of the table
  against the installed Dart and Flutter SDKs through the real analyzer element
  model, and fails when an entry names a member that does not exist or that the
  rule's own lookup can never reach.

- `empty_catch` warning rule: reports a `catch`/`on` clause whose body is
  empty, that does not `rethrow`, and that never uses the caught exception.
  Stricter than `empty_catches`: `catch (_) {}` is still reported. Calls out
  clauses that swallow a `@Throws` declaration, and treats a comment inside the
  block as a deliberate "ignored on purpose" marker.

- `@Sensitive` annotation and the `sensitive_exposure` warning rule: reports a
  `@Sensitive` field, getter, parameter, local or top-level variable that is
  interpolated into or concatenated into a string, converted with `toString()`, passed to a
  logging sink, or put into an exception or error constructor. Follows local
  aliases and conditionals, and treats the annotation on a field as covering
  its `this.x` constructor parameter.

- `stateful_in_build` warning rule: reports an object that owns a lifecycle
  being instantiated inside a Flutter build, where it is thrown away and
  replaced on every rebuild. A type owns a lifecycle when it declares or
  inherits a no-argument `dispose`, `close` or `cancel`, or is annotated with
  `@Disposable`, which is the same definition `missing_dispose` uses, so
  `ChangeNotifier`, `TextEditingController`, `ScrollController`,
  `AnimationController`, `FocusNode`, `StreamController`, `Timer` and your own
  types are covered without a hardcoded list. A build is any function that
  returns `Widget` or `List<Widget>`, including builder closures and
  widget-returning helpers. Recognises constructors, dot shorthands, a static
  factory on the class being created, and `Stream.listen`; accepts `const`
  creation, `??=`/`??` lazy initialization, `State.initState`, event callbacks
  and service-locator lookups such as `Provider.of<T>(context)`.

- `this_in_dispose` warning rule: reports a Flutter `State` handing out a
  reference to itself from its own `dispose`, where the object is already
  being torn down and the retained reference pins the element tree. Reports
  `this` passed as a positional or named argument, assigned to a field or a
  local, returned from a closure, or put into a collection literal, looking
  through `()`, `!` and `as`. Reading the object's own members is left alone,
  including explicit `this.field` access and the `removeListener` tear-off
  that cleanup requires, as is `this` in `initState`, `build` or in the
  `dispose` of a class that is not a `State`.

- `late_initialized_in_dispose` warning rule: reports a `late` field of a
  Flutter `State` whose initializer depends on the state object, through
  `this` (which covers `vsync: this`), `context` or `widget`, and which no
  member other than `dispose` reads. A `late` initializer is lazy, so such a
  field is constructed *during* teardown. Verified at runtime with
  `flutter test`: the field is created after `dispose` begins, two lazy
  controllers on a `SingleTickerProviderStateMixin` throw "multiple tickers
  were created" from inside `dispose`, and an initializer reading `context`
  throws "Null check operator used on a null value" while the tree is being
  finalized. A read anywhere else clears the report, including `initState`,
  `build` and closures; a write does not, since assigning a `late` field never
  runs its initializer, while a compound assignment does read first. A `late`
  field with no initializer, a non-`late` field, a static field and a class
  that is not a `State` are all left alone.

- `example_flutter/`: a second example package that runs the rules against the
  real Flutter SDK, so the Flutter rules are verified end to end and not only
  against the analyzer's mock packages. Its `flutter test` asserts the runtime
  behaviour that justifies `late_initialized_in_dispose`, and `dart analyze`
  reports the rule on exactly the three fixtures that misbehave there.

## 1.0.0

- Initial release.
- `@Disposable` and `@Throws` annotations.
- `missing_dispose` warning rule: reports instance fields annotated with
  `@Disposable` that the declaring class never cleans up. Recognises direct
  calls, null-aware and null-asserted access, cascades, awaited calls, custom
  cleanup names, local alias chains, getters that forward to a field,
  conditional and loop-over-literal targets, and helper functions that dispose
  a parameter.
- `unhandled_throws` warning rule: reports calls to `@Throws`-annotated targets
  whose declared exceptions are neither caught by an enclosing `try` nor
  re-declared by the enclosing function.
- Shared analysis options at
  `package:arxdeus_lints/analysis_options/recommended.yaml`, which this package
  also includes for its own sources.

[pub workspace]: https://dart.dev/tools/pub/workspaces
