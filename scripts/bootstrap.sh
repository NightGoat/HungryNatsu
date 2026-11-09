#!/usr/bin/env bash
set -euo pipefail

if ! command -v flutter >/dev/null 2>&1; then
  echo 'Flutter SDK не найден. Установите его по https://docs.flutter.dev/install и добавьте flutter/bin в PATH.' >&2
  exit 1
fi

cd "$(dirname "$0")/.."
flutter create --platforms=android,ios --project-name hungry_natsu --org dev.hungrynatsu .

python3 - <<'PY'
from pathlib import Path

manifest = Path('android/app/src/main/AndroidManifest.xml')
content = manifest.read_text()
permission = '    <uses-permission android:name="android.permission.CAMERA" />\n'
if permission.strip() not in content:
    content = content.replace('<manifest xmlns:android="http://schemas.android.com/apk/res/android">',
                              '<manifest xmlns:android="http://schemas.android.com/apk/res/android">\n' + permission)
internet = '    <uses-permission android:name="android.permission.INTERNET" />\n'
if internet.strip() not in content:
    content = content.replace('<manifest xmlns:android="http://schemas.android.com/apk/res/android">',
                              '<manifest xmlns:android="http://schemas.android.com/apk/res/android">\n' + internet)
manifest.write_text(content)

for build_file in (Path('android/app/build.gradle.kts'), Path('android/app/build.gradle')):
    if build_file.exists():
        content = build_file.read_text()
        content = content.replace('minSdk = flutter.minSdkVersion', 'minSdk = 23')
        content = content.replace('minSdkVersion flutter.minSdkVersion', 'minSdkVersion 23')
        build_file.write_text(content)

plist = Path('ios/Runner/Info.plist')
content = plist.read_text()
if '<key>NSCameraUsageDescription</key>' not in content:
    content = content.replace('<dict>', '<dict>\n\t<key>NSCameraUsageDescription</key>\n\t<string>Камера нужна для сканирования штрихкодов продуктов.</string>', 1)
    plist.write_text(content)
PY

flutter pub get
echo 'Готово. Запустите flutter run на подключённом Android-устройстве.'
