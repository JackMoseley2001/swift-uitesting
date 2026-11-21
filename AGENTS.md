# AGENTS.md

This file provides guidance to coding agents when working with code in this repository.

## What this is

A Swift package that layers Swift Testing-style macros and traits (`@UITestSuite`, `@UITest`, `#expect`, `#require`) on top of XCTest's UI testing. Pre-release: no tagged version, API may change. `README.md` is the user-facing reference for every feature and is kept in step with the API.

## Commands

```bash
# Package tests (unit tests; run on macOS, no simulator needed)
swift test --disable-experimental-prebuilts

# One suite / one test
swift test --disable-experimental-prebuilts --filter ScrollSearchTests
swift test --disable-experimental-prebuilts --filter ScrollSearchTests/doesNotScrollWhenTheElementIsInView

# One test target
swift test --disable-experimental-prebuilts --filter UITestingMacrosTests

# Demo app's UI tests (the only tests that drive a real app on a simulator)
xcodebuild test -project Examples/Demo/Demo.xcodeproj -scheme Demo \
  -destination "platform=iOS Simulator,name=iPhone 17" -skipMacroValidation

# The same tests against the demo as a Mac app. They take over the pointer and the
# keyboard of the Mac while they run.
xcodebuild test -project Examples/Demo/Demo.xcodeproj -scheme Demo \
  -destination "platform=macOS" -skipMacroValidation

# And as a watch app and a visionOS app.
xcodebuild test -project Examples/Demo/Demo.xcodeproj -scheme Demo \
  -destination "platform=watchOS Simulator,name=Apple Watch Series 12 (46mm)" -skipMacroValidation
xcodebuild test -project Examples/Demo/Demo.xcodeproj -scheme Demo \
  -destination "platform=visionOS Simulator,name=Apple Vision Pro" -skipMacroValidation

# One demo suite / test (generated methods are named test_<function name>)
xcodebuild test ... -only-testing:DemoUITests/FruitListTests/test_<functionName>
```

- `--disable-experimental-prebuilts` is required: with the prebuilt swift-syntax, the macro test bundle fails to link.
- `-skipMacroValidation` is required for `xcodebuild` on the command line.
- The `UITestingTests` target needs Swift 6.3+ (its files import both `Testing` and `UITesting`), so it is only in `Package@swift-6.3.swift`, the manifest that SwiftPM uses from Swift 6.3. `Package.swift` is the manifest for older compilers and is otherwise the same, so a change to one has to be made in both. The libraries and other test targets build with Swift 6.0. `tests.yml` runs the package's tests with the latest Xcode of each supported major version, and builds `UITesting` for every platform in the manifest (`generic/platform=…`, which needs no simulator), and `demo.yml` runs the demo's UI tests on one iOS version from each major version that a runner image has a simulator for (18, 26 and 27; none has 16 or 17, and CI does not download runtimes). Each row of that matrix names a simulator the image already has, in its `destination`, one more row runs them against the demo as a Mac app, and three each run them on an Apple Watch and an Apple Vision Pro simulator of each major version. A new Xcode or iOS version is added to the `matrix` of those two workflows and to the table in the README's Requirements section. The demo's deployment targets are iOS 16.4, macOS 14, watchOS 10 and visionOS 1, so demo code has to build for all four.
- Actions that touch the screen (taps, drags, swipes) do not exist in XCTest on tvOS, so they are inside `#if !os(tvOS)`. A new action that uses one goes inside it too; the build for tvOS in CI fails otherwise.
- **XCTest reports a Mac app differently from an iOS one**, and the library takes up the differences so that a test reads the same on both: a tap is a click, text is a value and not a label, and several controls are other element types. The helpers are in `Sources/UITesting/Elements/PlatformActions.swift` (`tapOrClick()`, `drag(afterPressingFor:to:)`, `labelOrText`, `NSPredicate.hasLabel(_:)`); library code uses them and never `XCUIElement.tap()` or `label` directly. A kind that XCTest reports as different types (`MenuPicker`, `SegmentedPicker`, `List`) chooses its type with `#if os(macOS)`. The README's "Testing a Mac app" section lists every difference.
- **watchOS and visionOS have differences of their own**, each inside `#if os(watchOS)` or `#if os(visionOS)` where it applies: on watchOS a field is typed into on a separate screen (`focus(inOrderTo:…)` in `UITestElement+Text.swift`), an alert is a table, a stepper is matched as any type, a slider is stepped by taps (`ControlState.stepSlider`) and scrolling drags slowly; on visionOS scrolling swipes the app's first list or scroll view, the cursor is moved to the end of a field with the keyboard, and a slider is dragged by its thumb element. The README's "Testing a watch app" and "Testing a visionOS app" sections list them. The identifiers the system gives its own screens there (`TextInputHost`, `PUICActionContentChild`, `AXSliderKnob`) are constants beside the pure logic.
- There is no linter or formatter configuration in the repo; match the surrounding style.
- CI (`.github/workflows`) runs both of the above on every pull request, on Xcode 27. The demo workflow retries only when the simulator was not ready, never on a failing test. `docs.yml` runs on pushes to `main`: it builds the documentation website with `scripts/build-docs.sh` on a Mac runner, then deploys it to GitHub Pages from an Ubuntu job.

## Releasing

A version is a tag with no prefix (`1.2.0`). `.github/workflows/release.yml` is run by hand from the Actions tab: it finds the last version tag, works out the next one with `scripts/next-version.sh` (from a choice of patch, feature or breaking, from the `breaking`/`feature`/`patch` labels of the pull requests merged since, or from an exact version), and creates the tag and a GitHub release with generated notes. `.github/release.yml` groups those notes by the same labels. Nothing in the package records its own version, so a release changes no files.

## Architecture

Three targets, with a strict dependency direction:

- **`UITestingCore`** — linked into the *app*. Must not depend on XCTest. Holds what both sides of the process boundary share: `LaunchConfiguration` (arguments + environment), `LaunchPayload` (Codable values encoded into the launch environment), `LaunchTraits.current` (how the app reads them back, plus SwiftUI environment helpers), and typed element identifiers (`ElementID<Kind>`, `ElementIDs` groups, `ElementKind`), and the app's end of the message channel (`UITestMessage`, `UITestMessages`, `onUITestMessage`).
- **`UITesting`** — linked into the *UI test target*. Re-exports `UITestingCore`. Holds the macro declarations (`Macros.swift`), the runner, traits, typed elements and expectations.
- **`UITestingMacros`** — the compiler plugin. Only swift-syntax; it cannot see the runtime, so it refers to runtime declarations by name.

### How a test runs

`@UITestSuite` conforms the class to the `UITestSuite` protocol, generates `suiteTraits`, and adds `@MainActor` to the class's methods and computed properties (not to overrides, or members already `nonisolated`/actor-annotated). `@UITest` is a peer macro that adds `test_<name>()`, which calls `UITestRunner.run(self, traits:) { context in self.<name>(...) }`. With `arguments:`, the same single method calls `UITestRunner.run(self, traits:arguments:named:)`, which makes a full run (launch, set-up, tear-down) for each argument inside a step named after it, records a thrown error for one argument and carries on with the rest.

`UITestRunner.run` is the centre of the runtime. In order: every trait's `prepare(_:)` builds the `LaunchConfiguration` (suite traits first) → every `willLaunch` → `app.launch()` unless a `ManualLaunchTrait` is present → every `setUp` → body → `tearDown` in reverse, for traits whose `willLaunch` started. The first error is thrown; later ones are recorded as extra XCTest issues. Per-test settings that code deep in the library needs (action timeout, failure capture, system alert rules) are passed down as task-locals set in `run`, and the runner finds them by inspecting the trait list (e.g. `$0 is ManualLaunchTrait`, `as? any SystemAlertAnswering`) rather than through `UITestTrait` requirements.

`UITestContext` also has the app lifecycle calls (`background`, `foreground`, `terminate`, `open`, `relaunch(opening:with:)`) in `Lifecycle/`. `UITestContext.relaunch(with:)` re-applies only `prepare(_:)` of the extra traits on top of the test's configuration; no other trait steps run again.

### Messages to the running app

The `.messageChannel` trait lets a test call `context.send(_:)` with a `UITestMessage` while the app runs. The code is in `Messages/` in both libraries. `MessageChannelTrait.prepare` starts `MessageHost.shared`, an `NWListener` on a loopback port chosen by the system, and puts the port in the launch environment; its `tearDown` stops the host, so a channel lasts for one test. In the app, the first call that asks to receive a message starts a `MessageClient`, which connects to that port (read from `LaunchTraits.current`, so never in a release build). Messages and replies are one JSON value to a line (`MessageEnvelope`, `MessageReply`, `MessageLines`, all `package` in `UITestingCore`). The app answers each message once its receivers have run (`MessageReceivers`), which is what lets `send` block until the app is done. `MessageSend` is the pure part of sending: it retries while the app is not connected or has no receiver, and never resends a message that reached a receiver. The public ways to receive (`UITestMessages.receive`, `messages(of:)`, `onUITestMessage`) are all built on one internal `AsyncStream` of `MessageDelivery`, which answers the test when it is finished or let go.

### Expectations

`#expect`/`#require` (and their `UITestingExpect`/`UITestingRequire` aliases, which exist because Swift Testing has macros with the same names) share one expansion, `ExpectationExpansion`. It wraps the argument in a closure so it can be re-evaluated while polling, splits a top-level `==` into two closures so a failure can show a CustomDump diff, and expands to `UITesting.__expect` / `__expectEqual` / `__require` / `__requireEqual` / `__requireValue`. `#require` records the failure at the call site and then throws `RequirementFailedError`, which the runner swallows so the failure is not reported twice.

### Conventions that span files

- **Names shared between plugin and runtime live in `Sources/UITestingMacros/Names.swift`** (`MacroName`, `MacroParameter`, `RuntimeName`). Renaming a runtime symbol that an expansion refers to (`UITestRunner`, `__expect…`, `suiteTraits`, `UITestContext.app`, the `test_` prefix) means updating that file and the expected expansions in `Tests/UITestingMacrosTests`.
- **Logic is split from XCUITest so it can be unit tested.** Anything that does not need a running app is a pure type taking closures or plain values (`ScrollSearch`, `ElementWait`, `TextEntry`, `SwipeActions`, `DatePickerValues`, `SystemAlertRules`, `ControlState`, `AppStateWait`, `MessageSend`, `ExpectationPolling`, `UITestRunner.withSteps`), and the `UITestElement+*.swift` extensions are thin wrappers that feed it `XCUIElement` calls. New element behaviour should follow the same split; the pure part gets tests in `Tests/UITestingTests`, the wrapper gets a demo screen and UI test.
- **Tests use Swift Testing**, not XCTest. In `UITestingTests`, both `Testing` and `UITesting` are imported, so expectations must be written module-qualified: `#Testing::expect(...)`. `Tests/UITestingTests/Support.swift` has `reportedFailures(in:)`, which captures the library's own expectation failures (via the `ExpectationReporter.$handler` task-local) so they can be asserted on rather than failing the test.
- **Macro tests** use `assertMacro` from swift-macro-testing with inline expansion/diagnostic snapshots.
- **Every public symbol has a documentation comment**, and each library has a DocC catalog (`Documentation.docc`). The root page of a catalog is a short overview; each topic has an article in `Articles/` (traits, entering text, alerts, system alerts and so on), and `Sources/UITesting/Documentation.docc/Tutorials/` has step-by-step tutorials whose code is in `Resources/`. Public API is curated in the `## Topics` of the article it belongs to, not on the root page. A new feature gets a README section and the same text in an article, new or existing; a new article is added to the root page's topics. Examples check the app with `#expect` and `#require`, not `XCTAssert…`.
- **Check the docs build** with `xcodebuild docbuild -scheme UITesting -destination "platform=iOS Simulator,name=iPhone 17" -skipMacroValidation` (and `-scheme UITestingCore`). Build for iOS, because some symbols are iOS only and their links do not resolve on macOS. Warnings about undocumented `filePath` and `line` parameters are expected. Tutorial code is not compiled by the build. `scripts/build-docs.sh` builds both catalogs the same way, merges the two archives into one with `docc merge`, and transforms the result for static hosting; it is what the Documentation workflow runs, so a change to how the docs are built belongs in the script. The build cannot run on Linux, because the libraries do not compile there.

### Demo app (`Examples/Demo`)

An Xcode project that depends on the package by relative path, whose app and UI tests build for iOS, macOS, watchOS and visionOS. Screens and tests for what only iOS has are inside `#if os(iOS)`, and those for what one platform lacks are inside `#if !os(…)` with a comment that says what is missing. `DemoUITests.entitlements` lets the tests listen for the message channel on macOS. Three folders: `Demo` (the SwiftUI app), `DemoUITests`, and `Shared`, which is a member of both targets and holds the payload types and `ElementIDs` groups that app and tests share. The app opens on a list of examples; each UI test suite jumps straight to its screen with the `.example(...)` trait defined in `DemoUITests/Traits.swift`. A new library feature normally adds an `…ID.swift` in `Shared`, a view in `Demo`, an entry in `Example`, and a `…Tests.swift` in `DemoUITests`.
