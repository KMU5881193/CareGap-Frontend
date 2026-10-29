# CareGap Frontend — Flutter + React/Vite

Flutter 모바일 앱은 프로젝트 루트에, 기존 React/Vite 워크스페이스는 `apps/web` 및 `packages`에 있습니다. 기존 웹 코드·이력은 보존했습니다. 모바일 앱은 최종 통합 백엔드에 실제 HTTP로 연결하며, 합성 데이터 전용입니다.

## Flutter 모바일 앱

Flutter 3.47.4 / Dart 3.13.3에서 검증했습니다.

```bash
flutter pub get
flutter run
```

임시 주소를 앱에 고정하지 않습니다. 최신 HTTPS 주소를 반드시 지정하세요. 누락 시 설정 안내 화면이 표시됩니다. 터널 변경 시:

```bash
flutter run --dart-define=BACKEND_URL=https://NEW-TUNNEL.trycloudflare.com
```

새 합성 담당자 계정을 생성해야 합니다. 기존 고정 체험 계정/Supabase 계정은 실제 서버 로그인에 사용할 수 없습니다. 비밀번호 12~128자. 서버 재시작 시 계정·세션·상담 데이터가 모두 초기화됩니다.

홈에서 합성 대상자 생성 → 이전 상담 작성 → 현재 상담의 합성 시연 음성/이미지 선택 → 실제 인식·교정·확정·저장 → 이전/현재 분석 → 원문 근거 확인 → 검토 제출 → 별도 최종 승인 → 지원 필요와 근거 선택 → 합성 복지 후보 확인 순서입니다.

- [전체 API 연결·프론트/백엔드 차이표](docs/FE_BE_INTEGRATION.md)
- [실행한 검증과 남은 검증](docs/API_INTEGRATION_VALIDATION.md)
- [Firebase 기기 알림 설정](docs/FIREBASE_NOTIFICATIONS.md)
- [기존 디자인 체험 가이드](docs/FLUTTER_DESIGN_PREVIEW.md)

실제 연동이 기본입니다. 기존 역할/가족/관리자 등의 디자인 화면은 `flutter run --dart-define=USE_MOCK=true`로 명시적으로 실행합니다. 네트워크 실패 시 이 모드로 자동 전환하지 않습니다.

현재 서버가 지원하지 않는 가족 연결·운영 직원 승인·프로필 변경·전화/영상 통화 등의 기능은 실제 연동 화면에서 저장 성공으로 표시하지 않습니다. 상세 차이표를 확인하세요. 인앱 수동 알림은 FCM 자동 발송과 다릅니다.

검증:

```bash
flutter analyze
flutter test
flutter build apk --debug
```

macOS Documents/iCloud 코드서명 문제가 있으면:

```bash
bash ./run_ios_local.sh "$PWD" -d "iPhone 16"
```

## 기존 React/Vite 웹

이 작업에서 웹 소스·패키지 설정은 변경하지 않았습니다. 설치·실행 절차는 [기존 웹 README](docs/WEB_README.md)와 [협업 안내](CONTRIBUTING.md)를 참고하세요.

```bash
pnpm install --frozen-lockfile
pnpm --filter @caregap/web dev
```

웹의 API 프록시·CORS·실제 업무 화면 연결은 모바일 연동과 별도입니다. 이번 Flutter 검증을 웹 검증으로 간주하지 마세요.

## 보안 및 합성 시연

실제 개인정보·상담 녹음을 사용하지 마세요. AI 결과는 검토가 필요한 참고 정보이며 복지 후보는 합성/자격 미확인/실제 신청 불가입니다. 서버 저장은 비영구 메모리입니다. `.env`·APNs p8·서비스 계정 비밀키·서명키를 커밋하지 마세요. Firebase 클라이언트 설정 파일은 서버 비밀 키와 다릅니다.
