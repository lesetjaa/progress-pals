#!/bin/sh

# Fail this script if any command fails.
set -e

# The default execution directory of this script is the ci_scripts directory.
# We need to navigate to the root of your Flutter project.
cd $CI_WORKSPACE

# 1. Install CocoaPods using Homebrew
export HOMEBREW_NO_AUTO_UPDATE=1
brew install cocoapods

# 2. Install Flutter (stable channel)
git clone https://github.com/flutter/flutter.git --depth 1 -b stable $HOME/flutter
export PATH="$PATH:$HOME/flutter/bin"

# 3. Install Flutter artifacts for iOS
flutter precache --ios

# 4. Get Flutter packages (This generates Generated.xcconfig!)
flutter pub get

# 5. Install iOS Pods (This generates the Pods-Runner files!)
cd ios
pod install