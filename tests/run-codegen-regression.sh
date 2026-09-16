#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
output="$(mktemp -d /tmp/designui-codegen.XXXXXX)"
xcrun swiftc -parse-as-library \
  tests/CodegenRegression.swift \
  DesignUI/Core/Views/Editor/Codegen/CodeGenerator.swift \
  DesignUI/Core/Views/Editor/Codegen/CodeGenerator_Chart.swift \
  DesignUI/Core/Views/Editor/Models/ChartConfiguration.swift \
  -o "$output/regression"
"$output/regression" "$output"
xcrun swiftc -typecheck "$output"/Export*.swift
xcrun swiftc -typecheck -sdk "$(xcrun --sdk iphonesimulator --show-sdk-path)" \
  -target arm64-apple-ios26.0-simulator "$output"/Export*.swift
echo "All exports type-check for macOS and iOS. Generated files: $output"
