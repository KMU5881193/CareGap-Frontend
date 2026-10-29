#!/usr/bin/env bash
set -euo pipefail
package_dir="$(cd -- "$(dirname -- "$0")" && pwd)"
project="${1:?Flutter 프로젝트 경로를 지정하세요}"
shift
if [ -n "${FLUTTER_ROOT:-}" ]; then export PATH="$FLUTTER_ROOT/bin:$PATH"; fi
command -v flutter >/dev/null || { printf '%s\n' 'Flutter를 PATH 또는 FLUTTER_ROOT로 지정하세요.' >&2; exit 1; }
printf '%s\n' '동기화 메타데이터 없이 iOS 실행용 소스를 준비합니다. 기존 앱 코드와 서명 설정은 유지합니다.'
preview_dir="$(python3 "$package_dir/prepare_ios_preview.py" "$project")"
printf 'iOS 실행용 폴더: %s\n' "$preview_dir"
printf '%s\n' '코드 수정은 원래 프로젝트에서 하고 수정 후 이 명령을 다시 실행하세요.'
cd "$preview_dir"
flutter pub get
if [ "$#" -eq 0 ]; then set -- -d "iPhone 16"; fi
flutter run "$@"
