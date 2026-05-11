#!/bin/sh
# Xcode Cloud auto-runs this after cloning the repo, before any build action.
# Reference: https://developer.apple.com/documentation/xcode/writing-custom-build-scripts
#
# Apple's CI runners pick the Xcode version per-workflow in App Store Connect
# (Workflow -> Environment -> Xcode Version). Set that to "Latest Release".

set -eu

echo "---- ci_post_clone.sh starting"
echo "    PWD: $(pwd)"
echo "    CI_PRODUCT_PLATFORM: ${CI_PRODUCT_PLATFORM:-?}"
echo "    CI_XCODE_VERSION:    ${CI_XCODE_VERSION:-?}"
echo "    CI_WORKFLOW:         ${CI_WORKFLOW:-?}"
echo "    CI_BUILD_NUMBER:     ${CI_BUILD_NUMBER:-?}"
echo "    xcodebuild -version:"
xcodebuild -version 2>&1 | sed 's/^/      /'

# Xcode Cloud invokes ci_post_clone.sh with cwd = ci_scripts/.
# Move up to the project directory (the one that contains project.yml).
cd "$(dirname "$0")/.."

# Install xcodegen via brew if not already present.
if ! command -v xcodegen >/dev/null 2>&1; then
  echo "---- installing xcodegen via brew"
  brew install xcodegen
fi

# Stamp the Apple-assigned $CI_BUILD_NUMBER into project.yml so each Cloud build
# gets a unique CFBundleVersion without manual bumping.
if [ -n "${CI_BUILD_NUMBER:-}" ]; then
  echo "---- stamping CURRENT_PROJECT_VERSION=$CI_BUILD_NUMBER into project.yml"
  /usr/bin/sed -i '' -E "s/CURRENT_PROJECT_VERSION:.*/CURRENT_PROJECT_VERSION: \"$CI_BUILD_NUMBER\"/" project.yml
fi

# Auto-bump MARKETING_VERSION patch from $CI_BUILD_NUMBER to prevent ITMS-90382
# (Apple's per-app per-MARKETING_VERSION upload throttle, ~5–10 uploads of the
# same x.y.z per 24h). "1.0.0" → "1.0.<build_number>" — major.minor preserved.
# Set MARKETING_VERSION_LOCK=1 in workflow env to opt out for tagged releases.
if [ -n "${CI_BUILD_NUMBER:-}" ] && [ "${MARKETING_VERSION_LOCK:-0}" != "1" ]; then
  CURRENT_MV=$(/usr/bin/awk '/MARKETING_VERSION:/ { gsub(/"/,"",$2); print $2; exit }' project.yml)
  if [ -n "$CURRENT_MV" ]; then
    MAJOR_MINOR=$(echo "$CURRENT_MV" | /usr/bin/awk -F. '{ printf "%s.%s", $1, ($2 == "" ? 0 : $2) }')
    NEW_MV="${MAJOR_MINOR}.${CI_BUILD_NUMBER}"
    echo "---- auto-bumping MARKETING_VERSION: $CURRENT_MV -> $NEW_MV (prevents ITMS-90382)"
    /usr/bin/sed -i '' -E "s/MARKETING_VERSION:.*/MARKETING_VERSION: \"$NEW_MV\"/" project.yml
  fi
fi

# Optional: override the Release backend URL via Xcode Cloud workflow env var.
# Set LIKHITA_RELEASE_API_BASE in App Store Connect -> Workflow -> Environment.
if [ -n "${LIKHITA_RELEASE_API_BASE:-}" ]; then
  echo "---- overriding Release LIKHITA_API_BASE -> $LIKHITA_RELEASE_API_BASE"
  /usr/bin/awk -v url="$LIKHITA_RELEASE_API_BASE" '
    /^[[:space:]]+Release:[[:space:]]*$/ { in_release = 1; print; next }
    in_release && /^[[:space:]]+[A-Za-z]/ {
      if ($0 ~ /LIKHITA_API_BASE:/) {
        sub(/".*"/, "\"" url "\"")
      }
    }
    in_release && /^[[:space:]]*[A-Z][A-Za-z_]+:[[:space:]]*$/ { in_release = 0 }
    { print }
  ' project.yml > project.yml.tmp && mv project.yml.tmp project.yml
fi

echo "---- running xcodegen generate"
xcodegen generate

echo "---- done. Generated project at: $(pwd)/Likhita.xcodeproj"
ls -la *.xcodeproj | head -5
