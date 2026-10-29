#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
export PATH="$HOME/flutter/bin:$HOME/.pub-cache/bin:$PATH"
if [[ $# -ne 1 || -z "$1" ]]; then
  echo '사용법: bash scripts/configure_firebase.sh FIREBASE_PROJECT_ID'
  exit 1
fi
flutterfire configure \
  --project="$1" \
  --platforms=android,ios \
  --android-package-name=com.example.caregap_app \
  --ios-bundle-id=com.example.caregapApp \
  --ios-target=Runner \
  --out=lib/firebase_options.dart
python3 - <<'PY'
from pathlib import Path
import plistlib,json
android=Path('android/app/google-services.json')
ios=Path('ios/Runner/GoogleService-Info.plist')
if not android.is_file() or not ios.is_file():
 raise SystemExit('네이티브 설정 파일이 없습니다. FlutterFire CLI의 등록 결과를 확인해 주세요.')
a=json.loads(android.read_text())
i=plistlib.loads(ios.read_bytes())
assert any(c['client_info']['android_client_info']['package_name']=='com.example.caregap_app' for c in a['client']), 'Android 앱 ID 불일치'
assert i['BUNDLE_ID']=='com.example.caregapApp', 'iOS 앱 ID 불일치'
assert a['project_info']['project_id']==i['PROJECT_ID'], 'Android/iOS Firebase 프로젝트 불일치'
print('두 플랫폼의 Firebase 설정 파일과 앱 ID를 확인했습니다.')
PY
flutter pub get
echo '앱을 완전히 종료하고 다시 빌드해 주세요. iOS는 Firebase 콘솔에 APNs 키 등록이 필요합니다.'
