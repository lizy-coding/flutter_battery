#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT_DIR"

mkdir -p app/lib app/android app/ios
mkdir -p android-iot-native/src/main/{kotlin,res}
mkdir -p integration/channel/contracts

create_if_missing() {
  local target="$1"
  [[ -f "$target" ]] || touch "$target"
}

create_if_missing android-iot-native/build.gradle.kts
create_if_missing android-iot-native/src/main/AndroidManifest.xml
create_if_missing integration/channel/contracts/channel_contract.yaml
