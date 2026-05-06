#!/bin/sh
# Runs after xcodebuild (success or failure). Surfaces logs on failure.
set -eu

echo "---- ci_post_xcodebuild.sh"
echo "    CI_XCODEBUILD_EXIT_CODE: ${CI_XCODEBUILD_EXIT_CODE:-?}"
echo "    CI_RESULT_BUNDLE_PATH:   ${CI_RESULT_BUNDLE_PATH:-?}"
echo "    CI_DERIVED_DATA_PATH:    ${CI_DERIVED_DATA_PATH:-?}"

# On failure, surface the most recent error lines from the result bundle.
if [ "${CI_XCODEBUILD_EXIT_CODE:-0}" != "0" ] && [ -n "${CI_RESULT_BUNDLE_PATH:-}" ]; then
  echo "---- build failed, recent xcresult activity log:"
  /usr/bin/find "$CI_RESULT_BUNDLE_PATH" -name '*.log' -print0 \
    | xargs -0 -I{} sh -c 'echo "= {} ="; tail -50 "{}"' 2>&1 | tail -200
fi
