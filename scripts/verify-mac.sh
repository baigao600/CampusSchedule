#!/usr/bin/env bash
set -euo pipefail

project_root="$(cd "$(dirname "$0")/.." && pwd)"
cd "$project_root"

plutil -lint CampusSchedule/App/Info.plist
plutil -lint CampusScheduleWidget/Info.plist
xcodebuild -list -project CampusSchedule.xcodeproj
xcodebuild \
  -project CampusSchedule.xcodeproj \
  -scheme CampusSchedule \
  -sdk iphonesimulator \
  -destination 'generic/platform=iOS Simulator' \
  CODE_SIGNING_ALLOWED=NO \
  build

if [[ $# -gt 0 ]]; then
  xcodebuild \
    -project CampusSchedule.xcodeproj \
    -scheme CampusSchedule \
    -destination "$1" \
    CODE_SIGNING_ALLOWED=NO \
    test
else
  echo "Build finished. Pass a simulator destination as the first argument to run tests."
  echo "Example: bash scripts/verify-mac.sh 'platform=iOS Simulator,name=iPhone 16 Pro'"
fi
