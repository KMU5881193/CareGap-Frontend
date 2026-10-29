# 최종 FE·BE 통합 검토 보고서 — 2026-10-30

## 기준과 구조
Backend main e8cd5ac45: PR23 이미 병합. 실행4324 소스9e4be3b와 주요 통합 라우터 diff 없음. Frontend main a6291fb8d, Flutter 원본 b99036e15. 새 release/caregap-frontend-final-20261030은 Flutter 기준이며 main ancestry 확인. 기존 apps/web·packages·웹 CI 소스 보존.
Flutter ApiClient → 공개 HTTPS → Windows4324 → CPU OCR ONNX/Whisper 및 GPU Ollama Qwen → 기존 검토/승인 → 합성 복지 후보. 실행 서버와 터널은 중단하지 않았다.

## 계약 비교
|영역|확인 결과|
|---|---|
|가입/로그인/me/logout/만료|Bearer 헤더, 1시간 세션, 204, 401 초기화. 비JSON401도 초기화하도록 수정|
|대상자/예약|서버 ID, UTC 시간, 완료/취소 expected_status 사용|
|기록/버전|consultation_id·record_version_id, 불변 버전, 오래된 수정409|
|OCR/STT|202 후 폴링, 원본/교정 구분, 교정버전·확정 후 import. OCR5MB 제한 일치 수정, WAV 헤더 길이·byte rate·block align 추가 검사|
|분석|이전/현재 버전 참조, 재시도 Idempotency-Key, HTTP200 failed 차단, provider/model 표시|
|검토/추천|문구 수정·제출·승인·반려 별도, 근거 확인, 승인 버전과 선택 근거로 합성 후보 요청|
|후속 업무/인앱 알림|실제 인증 HTTP 생성·조회·완료·읽음 연결|
|미지원|전화·영상·채팅·가족계정·운영직원승인·통계·서버 분석/작업/추천 이력 목록·FCM 서버 토큰 등록/자동발송·영구저장 없음. 실제 모드 안내 유지|

## 수정
- 임시 URL 하드코딩 제거: BACKEND_URL 필수, 누락 시 설정 안내. 로그인 화면에 안전한 서버 origin 표시.
- Flutter analyze/test/debug APK용 별도 CI 추가; 기존 pnpm CI 유지. CI에서 실제 AI 호출·비밀키 사용 없음.
- 검증 스크립트가 분석 의미·정확한 근거·실추론 메타데이터를 승인 전에 확인. 빈 후보/빈 OCR 결과를 성공으로 오판하지 않음.
- macOS 전용 보고서 경로를 OS 임시경로로 변경. 특정 개발자 Flutter 경로 제거.
- Gradle 최대heap8GB→3GB, workers2; Mac 메모리 압박 완화 목적이며 실제 Mac 안정성 재현 검증은 미실행.
- 추적된 android/build HTML 보고서 제거 및 재발 방지 ignore. 디자인·이미지·기존 React 코드 보존.

## 실제 검증
Flutter3.47.4/Dart3.13.3 공식 태그 SDK를 격리 준비했다. 시스템 PATH·기존 SDK를 변경하지 않았다.
- flutter pub get PASS
- flutter analyze PASS: No issues found
- flutter test PASS: 40개
- React pnpm frozen install/typecheck/test/build/Playwright PASS: 단위1·E2E1
- Backend typecheck/test/build PASS: 532개
- scripts/verify_live_api.dart 실제 HTTPS PASS: 가입→예약→버전충돌검사→실제STT→교정/확정→기록→Qwen→정답 방향3개·정확한인용→미승인차단→제출/승인→추천→후속업무/알림→로그아웃. 24500ms, 실제 Qwen 메타데이터 확인.
- scripts/verify_ocr.dart 실제 HTTPS PASS: 합성 이미지 실제OCR→교정→확정→기록.
- flutter build apk --debug: 별도 최종 결과 참조(진행 중).
- iOS 빌드: 이번 Windows 환경에서 미실행. 원본 문서의 과거 Mac 성공은 이번 변경 검증으로 간주하지 않음.
- adb devices: 연결된 실제기기 없음. 마이크권한/실제녹음/카메라/푸시수신/실제 화면 전체 조작 미검증.

## 실행과 남은 조건
flutter run --dart-define=BACKEND_URL=https://favourite-bizrate-passed-calibration.trycloudflare.com
터널 만료 시 새 HTTPS 주소로 다시 빌드/실행. 합성데이터 전용이며 서버 재시작 시 재가입 필요. 체험화면은 USE_MOCK=true를 명시.
Mac은 iCloud 밖 작업 복사본에서 실기기 우선, 에뮬레이터 중복 실행 피하기. run_ios_local.sh는 FLUTTER_ROOT 또는 PATH를 사용한다.
Android applicationId com.example.caregap_app 및 debug 서명은 시연용이다. 정식 스토어 배포 불가; 팀 앱ID·release 서명 확정 필요. 비밀키/토큰을 기록하지 않았다.
PR과 빌드 최종 결과는 아래 후속 기록에 기재한다. CI 및 실제기기 검증이 끝나기 전 main 병합 안전 완료로 선언하지 않는다.
