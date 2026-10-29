# 실제 서버 시연 (2026-10-30)

- 로컬 Flutter 웹: http://127.0.0.1:4335 (실제 API 4334로 같은 출처 프록시)
- 기존 4324 서버에는 변경을 적용하지 않았다.
- 합성 담당자/예약자 각각 2명. 자격증명은 Backend 검증 복제본 `.runtime/demo-credentials.json`에만 있다.
- `flutter analyze`: 문제 없음. 전체 테스트 42 PASS/0 FAIL/0 SKIP, 실제 로컬 서버 4개 로그인 위젯 테스트 1 PASS.
- 실제 Repository: 로그인 → OCR/STT → 교정 → 확정 → 기록 → Qwen → 원문 근거 → 승인 → 합성 복지 후보 및 Vision 호출 성공.
- 승인 동작은 합성 계정으로 실행한 자동 검증이다. 실제 사람의 임상 검토를 의미하지 않는다.
- 카메라 버튼과 WAV 선택 경로는 유지. Android 연결 기기가 없어 촬영·마이크 권한 실기기 검증은 미완료.
- Vision은 OCR과 별도 선택 기능이며 자동 기록/승인이 없다. 실제 모델 출력에는 도형 수 오인식이 있었다.

## 실행

`flutter build web --dart-define=USE_MOCK=false --dart-define=ALLOW_LOOPBACK_HTTP=true --dart-define=BACKEND_URL=http://127.0.0.1:4335`

`node scripts/local-web-demo.mjs`

포트가 사용 중이면 위 서버를 다시 실행하지 않는다. 기존 실행을 종료하지 않는다.
루프백 HTTP 허용은 명시적 컴파일 옵션이며 기본값은 false다. 외부 HTTP는 항상 거부한다.

## 재검증

`dart run --define=ALLOW_LOOPBACK_HTTP=true scripts/verify_four_accounts.dart http://127.0.0.1:4334 ../final-verification-CareGap-Backend/.runtime/demo-credentials.json`

`flutter test scripts/live_server_ui_test.dart --dart-define=ALLOW_LOOPBACK_HTTP=true --timeout 90s`

테스트/실행 도구에 비밀번호를 인자로 넣지 않는다. 공개 터널을 통해 자격증명을 전송하지 않는다.

## 외부 접속 추가 검증

사용자 명시 허용 후 새 공개 링크를 추가했다: https://grams-viewing-given-categories.trycloudflare.com/

- 별도 Windows 웹 프록시 4337 → 합성 API 4334. 기존 4335와 4324는 유지했다.
- `USE_SAME_ORIGIN=true` 빌드로 외부 접속 기기의 localhost를 호출하는 오류를 방지한다.
- 공개용 빌드: `flutter build web --output=build/web-public --dart-define=USE_MOCK=false --dart-define=USE_SAME_ORIGIN=true`
- 프록시 환경변수: DEMO_WEB_PORT=4337, DEMO_WEB_ROOT=build/web-public, DEMO_PUBLIC_ORIGIN은 위 정확한 origin.
- Cloudflare는 HTTP/2 터널로 실행했다. Quick Tunnel 주소는 프로세스 수명에 의존한다.
- Docker 컨테이너가 아니라 Windows 프로세스이므로 Docker Ports 목록에 나타나지 않는다.
- 외부 링크에서 Flutter 실제 화면 렌더링과 /health 200을 확인했다. 로그인 정보는 로컬 비밀 파일에서 확인한다.
