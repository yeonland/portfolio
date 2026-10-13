#!/usr/bin/env bash
# Vercel 빌드 서버에는 Flutter가 없어서 직접 받아서 설치함 (로컬과 같은 버전)
set -euo pipefail

FLUTTER_VERSION=3.47.5

# Flutter가 Dart SDK를 받을 때 unzip이 필요함
if ! command -v unzip >/dev/null 2>&1; then
  dnf install -y unzip
fi

if [ ! -x .flutter-sdk/bin/flutter ]; then
  git clone https://github.com/flutter/flutter.git -b "$FLUTTER_VERSION" --depth 1 .flutter-sdk
fi

.flutter-sdk/bin/flutter config --no-analytics --no-cli-animations
.flutter-sdk/bin/flutter --version
.flutter-sdk/bin/flutter pub get
