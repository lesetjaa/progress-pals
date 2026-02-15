#!/bin/sh

# Fail this script if any command fails.
set -e

# THE FIX: This variable guarantees we are at the very root of your Flutter project
cd "$CI_PRIMARY_REPOSITORY_PATH"

# 1. Safely install CocoaPods
export HOMEBREW_NO_AUTO_UPDATE=1
brew install cocoapods || true

# 2. Safely clone Flutter
if [ ! -d "$HOME/flutter" ]; then
  git clone https://github.com/flutter/flutter.git --depth 1 -b stable $HOME/flutter
fi
export PATH="$PATH:$HOME/flutter/bin"

# 3. Install Flutter artifacts
flutter precache --ios

# 4. Get Flutter packages (This will now correctly find pubspec.yaml!)
flutter pub get

# 5. Install iOS Pods
cd ios
pod install --repo-update