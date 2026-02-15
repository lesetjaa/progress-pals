#!/bin/sh

# Fail this script if any command fails.
set -e

cd $CI_WORKSPACE

# 1. Safely install CocoaPods (Adding || true prevents crashing if it's already installed)
export HOMEBREW_NO_AUTO_UPDATE=1
brew install cocoapods || true

# 2. Safely clone Flutter (Only clone if the directory doesn't already exist)
if [ ! -d "$HOME/flutter" ]; then
  git clone https://github.com/flutter/flutter.git --depth 1 -b stable $HOME/flutter
fi
export PATH="$PATH:$HOME/flutter/bin"

# 3. Install Flutter artifacts
flutter precache --ios

# 4. Get Flutter packages
flutter pub get

# 5. Install iOS Pods (Added --repo-update to ensure Firebase links correctly)
cd ios
pod install --repo-update