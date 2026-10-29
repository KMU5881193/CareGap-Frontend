# 실제 API 연동 검증 (2026-10-30)

- Flutter analyze: No issues found.
- Flutter test: 36개 통과. 기존 체험 회귀, 실제 연동 UI 360px/글씨 2배, 실패 분석 승인 차단, HTTP 인증·버전·근거·세션 지연 응답 검사 포함.
- Android debug APK: iCloud 외부의 동일 소스 복사본에서 빌드 성공 (56.0초). 동기화 폴더 내부 빌드는 기존 Gradle 캐시 접근 대기로 종료하고 외부에서 검증했다.
- iOS simulator debug: Firebase를 포함한 실제 API 연결 소스 빌드 성공 (Xcode 63.5초).
- 실제 HTTPS 서버 health 성공: 합성 전용, 메모리 저장, OCR python / STT local / 분석 ollama.
- 실제 Flutter Dart HTTP 계층에서 새 합성 계정으로 21개 연결 검사 통과: 가입/로그인/me/대상자/예약/기록 버전/실제 STT/교정/확정/import/Qwen 분석/원문 근거/검토 제출/승인/합성 복지/후속 업무/인앱 알림/로그아웃.
- 별도 실제 OCR 합성 인쇄체 이미지 → 교정 → 확정 → 기록 가져오기 통과.
- 409 실패 검사: 오래된 기록 버전 수정, 미확정 STT 가져오기, 미승인 추천이 차단됨.
- 실제 분석 응답 provider=ollama, model=qwen2.5vl:7b 확인. HTTP 200만으로 성공 판단하지 않음.
- 비밀번호·Bearer 토큰을 보고서에 저장하지 않음.

## 검증의 범위
실제 서버 계약 검사는 앱과 같은 ApiClient/LiveCareRepository를 사용한 자동 HTTP 실행이다. 실제 기기 화면의 손동작 전체 흐름이나 3분 리허설 성공을 의미하지 않는다. 화면은 Flutter 위젯 테스트로 레이아웃과 접근/실패 상태를 확인했다.

미실행: 실제 iPhone/Android 기기의 전체 사용자 조작·마이크 권한/실제 녹음·FCM 실수신, Flutter Web CORS, TestFlight/앱스토어 배포. 실제 OCR/STT 정확도나 복지 자격을 보증하지 않는다.

Git 원격: KMU5881193/CareGap-Frontend. Flutter 작업 브랜치에서 기존 웹 main을 보존한 병합 이력을 사용한다. 인증 실패 시 커밋과 푸시 상태를 구분해 보고한다.
