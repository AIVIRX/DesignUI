# Visual quality suite

The corpus covers fitness, shopping, finance, travel, social, productivity,
onboarding, empty/loading/error states, pricing, checkout and comparison charts.
Each screen is rendered with the production component renderer at 375×812 and
430×932, in light and dark appearances. This is a macOS renderer at phone sizes;
it does not replace iOS Simulator verification.

Generate deterministic editable fixtures without credentials:

```sh
node tests/visual/generate-fixtures.mjs
```

To benchmark actual model output instead, set `OPENAI_API_KEY` in the environment
and use `--live`. This makes paid API requests, runs the real generation pipeline,
and records request durations. Use `DESIGNUI_FIXTURE_DIR` to keep those fixtures
separate. Never commit credentials. The generation manifest labels each source.

Build an isolated renderer (preserve inherited dependency flags):

```sh
xcodebuild -quiet -project DesignUI.xcodeproj -scheme DesignUI -sdk macosx \
  -destination 'platform=macOS,arch=arm64' -configuration Debug \
  -derivedDataPath /tmp/designui-visual-build \
  'OTHER_SWIFT_FLAGS=$(inherited) -D DESIGNUI_VISUAL_TEST' \
  build CODE_SIGNING_ALLOWED=NO
'/tmp/designui-visual-build/Build/Products/Debug/Dock UI.app/Contents/MacOS/Dock UI' \
  "$PWD/tests/visual/fixtures" "$PWD/tests/visual/output"
node tests/visual/report.mjs
```

The runner measures actual text and component frames. The report flags missing
requested text, horizontal overflow, absent layout measurements and primary
actions outside the initial viewport. Review the PNG gallery for hierarchy,
contrast, spacing, clipping and visual balance; a passing geometry test is not
a claim of aesthetic perfection. The backend separately tests schema validity,
cross-section repetition, exact counts, shared styling, and bounded repairs.

`backend/supabase/functions/StudioAI/patterns.ts` is the source for the editable
recipe catalog. `DesignUI/Resources/design-patterns.json` is its bundled snapshot;
the backend test runner checks that they match.
