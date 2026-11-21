#!/bin/bash
#
# Builds the documentation of both libraries into one website that can be served as
# static files, such as from GitHub Pages.
#
# Needs a Mac with Xcode: the libraries use XCTest's UI testing API, SwiftUI and the
# Network framework, so their symbols can only be read where those exist.
#
# usage: scripts/build-docs.sh [output directory]
#
# The output directory defaults to .build/documentation/site.
#
# Environment:
#   HOSTING_BASE_PATH  The path the site is served under, without slashes. The default
#                      is swift-uitesting, as on GitHub Pages. Set it to an empty string
#                      for a site served from the root, such as a local preview.
#   DOCS_DESTINATION   The xcodebuild destination to build for. The default is an iOS
#                      simulator, because some symbols are iOS only.

set -euo pipefail

cd "$(dirname "$0")/.."

output="${1:-.build/documentation/site}"
base_path="${HOSTING_BASE_PATH-swift-uitesting}"
destination="${DOCS_DESTINATION:-platform=iOS Simulator,name=iPhone 17}"
derived_data=".build/documentation/derived-data"
merged=".build/documentation/merged.doccarchive"

# The order here is the order of the libraries on the site's first page.
schemes=(UITesting UITestingCore)

archives=()
for scheme in "${schemes[@]}"; do
    echo "Building the documentation of $scheme"
    xcodebuild docbuild \
        -scheme "$scheme" \
        -destination "$destination" \
        -derivedDataPath "$derived_data" \
        -skipMacroValidation \
        -quiet

    archive="$(find "$derived_data/Build/Products" -type d -name "$scheme.doccarchive" | head -n 1)"
    if [ -z "$archive" ]; then
        echo "error: xcodebuild did not produce $scheme.doccarchive in $derived_data/Build/Products" >&2
        exit 1
    fi
    archives+=("$archive")
done

echo "Merging the libraries into one archive"
rm -rf "$merged" "$output"
xcrun docc merge "${archives[@]}" \
    --synthesized-landing-page-name "swift-uitesting" \
    --synthesized-landing-page-kind "Package" \
    --output-path "$merged"

echo "Preparing the archive for static hosting"
hosting_options=()
if [ -n "$base_path" ]; then
    hosting_options=(--hosting-base-path "$base_path")
fi
xcrun docc process-archive transform-for-static-hosting "$merged" \
    --output-path "$output" \
    ${hosting_options[@]+"${hosting_options[@]}"}

# The site's pages are under documentation/ and tutorials/. Send its root to the first page.
cat > "$output/index.html" <<'HTML'
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="utf-8">
<title>swift-uitesting</title>
<meta http-equiv="refresh" content="0; url=documentation/">
<link rel="canonical" href="documentation/">
</head>
<body>
<p><a href="documentation/">swift-uitesting documentation</a></p>
</body>
</html>
HTML

echo "The site is in $output"
