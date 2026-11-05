#!/bin/sh

set -e

FLUTTER_VERSION="${FLUTTER_VERSION:-3.47.3}"

cd "$CI_PRIMARY_REPOSITORY_PATH"

if [ ! -f ios/Runner/GoogleService-Info.plist ]; then
  echo "error: ios/Runner/GoogleService-Info.plist is missing." >&2
  exit 1
fi

plutil -lint ios/Runner/GoogleService-Info.plist
FIREBASE_IOS_BUNDLE_ID=$(/usr/libexec/PlistBuddy -c 'Print :BUNDLE_ID' ios/Runner/GoogleService-Info.plist)
if [ "$FIREBASE_IOS_BUNDLE_ID" != "com.quickboom.qbsuite" ]; then
  echo "error: GoogleService-Info.plist must be downloaded from Firebase for iOS bundle ID com.quickboom.qbsuite." >&2
  exit 1
fi

if ! grep -Fq "iosBundleId: 'com.quickboom.qbsuite'" lib/firebase_options.dart; then
  echo "error: regenerate lib/firebase_options.dart with FlutterFire after registering the iOS app in Firebase." >&2
  exit 1
fi

# Avoid Xcode Cloud's experimental Swift Package Manager dependency resolution;
# the Flutter plugins are installed by CocoaPods during the config-only build.
echo "Installing Flutter $FLUTTER_VERSION"
git clone https://github.com/flutter/flutter.git --depth 1 -b "$FLUTTER_VERSION" "$HOME/flutter"
export PATH="$HOME/flutter/bin:$PATH"
flutter --version

flutter config --no-enable-swift-package-manager
flutter precache --ios

if ! command -v pod >/dev/null 2>&1; then
  if ! command -v brew >/dev/null 2>&1; then
    echo "error: CocoaPods is missing and Homebrew is unavailable." >&2
    exit 1
  fi
  echo "Installing CocoaPods"
  HOMEBREW_NO_AUTO_UPDATE=1 brew install cocoapods
fi

echo "Generating Flutter iOS configuration"
flutter build ios --release --config-only --build-number="${CI_BUILD_NUMBER:-1}"

echo "ci_post_clone.sh completed"
