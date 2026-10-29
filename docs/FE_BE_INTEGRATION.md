# Flutter · 최종 백엔드 연동 (2026-10-30)

## 적용 대상과 실행
현재 Flutter 프로젝트를 실제 통합 HTTP 서버에 연결했다. React/Vite의 프록시 코드는 Flutter에 넣지 않았다. Android/iOS 네이티브 앱은 HTTPS를 직접 호출하며 브라우저 Origin을 임의 조작하지 않는다. Flutter Web은 서버 Origin 허용 또는 별도 같은 출처 프록시가 필요하며 이번 검증 대상이 아니다.

```bash
cd <프로젝트-경로>
flutter pub get
flutter run
```

기본 서버 주소는 비어 있으며 최신 BACKEND_URL 지정이 필요하다. 터널이 바뀌면:

```bash
flutter run --dart-define=BACKEND_URL=https://NEW-TUNNEL.trycloudflare.com
```

iCloud 코드서명 문제를 피하는 기존 iPhone 실행:

```bash
bash ./run_ios_local.sh "$PWD" -d "iPhone 16"
```

이 스크립트는 소스 복사본을 실행한다. 원본 수정 후 다시 실행해야 한다.
새 서버 주소도 마지막 인수로 `--dart-define=BACKEND_URL=...`를 전달할 수 있다.

실제 연동이 기본이다. 기존 전체 디자인/역할 화면은 명시적인 화면 체험 모드에서 보존했다:

```bash
flutter run --dart-define=USE_MOCK=true
```

실제 API 실패 시 Mock으로 자동 전환하지 않는다. 화면 상단 배너로 실행 모드를 구분한다.

## 계정과 시연 순서
1. 시작하기 → 합성 담당자 계정 생성. 아이디 3~80자, 비밀번호 12~128자. 고정 계정이나 기존 Supabase/Next.js 계정을 사용하지 않는다.
2. 홈 → 합성 대상자 생성. 이름·전화번호 대신 서버 ID를 표시한다.
3. 기록 → 새 상담 작성 → 이전 합성 예시 넣기 → 합성 확인 → 저장.
4. 새 상담 작성 → 녹음·음성 변환 → 합성 시연 파일 사용 → 합성 파일 전송 동의 → 실제 인식 요청.
5. 모델 원문을 읽고 구간별 교정 → 교정 저장 → 교정 확정 → 상담 기록 저장. 이미지도 같은 순서다.
6. 현재 상담에서 AI 비교 → 이전 상담 선택 → 분석 요청. 결과의 성공 상태·제공자·모델·이전/현재 원문·근거를 확인한다.
7. 필요 시 분석 문구 교정 → 원문 근거 대조 체크 → 검토 제출 → 별도 최종 승인 또는 반려.
8. 승인 후 지원 필요·판단 항목·근거 문장을 직접 선택 → 확인한 필요 추가 → 합성 복지 후보 조회.
9. 더보기 → 후속 업무/인앱 알림 생성·읽음·완료 확인.

내장 파일은 합성 TTS/인쇄체이며 실제 모델로 전송된다. 인식 결과를 고정 문자열로 대체하지 않는다. 현재 기록 순서와 버전을 확인해 이전/현재를 직접 선택해야 한다. 서버가 상담 일시를 저장하지 않으므로 서로 다른 상담 날짜를 앱에서 검증할 수 없다.

## 실제 연결한 API
| 화면/동작 | HTTP 계약 | 주의 |
|---|---|---|
| 가입/로그인 | POST /api/auth/register, /login | identifier/password, data.access_token |
| 사용자/로그아웃 | GET /api/auth/me, POST /logout | 토큰 1시간, logout 204 |
| 대상자 | GET/POST /api/persons | 생성은 {}만 전송 |
| 예약 | GET/POST /api/appointments | 시작/종료 UTC ISO, 기기 현지 시간으로 표시 |
| 예약 완료/취소 | POST /api/appointments/:id/actions | 실제 expected_status |
| 기록/불변 버전 | GET/POST /api/records, POST /api/records/:id/versions | 실제 consultation_id/record_version_id |
| OCR/STT | POST /api/{ocr,stt}/jobs, GET /jobs/:id | base64 JSON, 202를 완료로 취급하지 않음 |
| 교정/확정 | POST /jobs/:id/corrections, /confirmation | 응답의 최신 version 사용 |
| 결과 가져오기 | POST /api/records/import | 확정 후만 가능, 서버의 기록 ID 사용 |
| 분석 | POST /api/analyses, GET /api/analyses/:id | 실제 두 기록 참조, Idempotency-Key |
| 분석 수정/제출/승인/반려 | POST /api/analysis-reviews/:id | edit/submit/approve/reject를 별도 사용자 동작으로 실행 |
| 복지 후보 | POST /api/welfare-recommendations | 승인 버전과 선택한 finding/evidence 인덱스 |
| 후속 업무 | GET/POST /api/follow-ups, POST /:id/actions | open → completed/cancelled |
| 수동 인앱 알림 | GET/POST /api/notifications, POST /:id/read | 본인 알림, FCM 자동 발송 아님 |
| 서버 확인 | GET /health | 실제 분석 성공 여부는 분석 응답으로 별도 확인 |

## 프론트에는 있지만 최종 서버에 없는 기능
여기서 '없음'은 최종 공개 통합 라우터에 없다는 의미다. 백엔드 저장소의 독립 모듈 파일이 있어도 해당 서버가 노출하지 않으면 호출하지 않는다.

| 기존 프론트 기능 | 서버 차이 | 적용/남은 조치 |
|---|---|---|
| 대상자·가족·담당자 역할 가입/로그인 | staff만 가입 가능 | 실제 모드는 담당자 계정만 노출; 기존 역할 화면은 체험 모드 보존 |
| 이름·생년월일·주소·전화번호 대상자 프로필 | person_id와 synthetic_only만 반환 | 개인정보 폼 제거, ID 기반 합성 대상자 표시 |
| 담당자 소속/자격 자료/승인·반려/재제출 | 운영 직원 승인 API 미노출 | 실제 모드에서 숨김. 합성 staff를 운영 승인 완료로 표현하지 않음 |
| 아이디 찾기/비밀번호 재설정·변경/계정 탈퇴 | 최종 인증 API는 register/login/me/logout만 | 실제 화면에 해당 기능 제공 안 함; 백엔드 계약 추가 필요 |
| 사용자 프로필 변경 | API 없음 | 서버 저장 성공으로 표시하지 않음 |
| 가족 초대·동의·연결 해제·공유 | API 없음 | 실제 모드에서 접근 경로 제거; 권한 계약 추가 필요 |
| 예약 방식·사유·장소·담당자 선택 | 생성은 person/start/end만 | 실제 예약은 기기 날짜·시간 + 1시간; 미저장 항목 안내 |
| 예약 요청 수락/거절/변경/불참 | scheduled 완료/취소만 | 실제 모드는 두 전환만 노출 |
| 상담 가능 요일·시간·휴무 | 최종 라우터 없음 | 설정 경로 숨김; 예약 충돌은 서버의 409로 처리 |
| 상담 일시·유형·내부 메모·후속 메모 | 기록은 원문과 ID만 저장 | 실제 작성 화면에서 미지원 필드 제거; 후속 업무 별도 API 연결 |
| 기록에 사진·음성 원본 첨부 보관 | 인식 입력 업로드만 지원 | 파일을 기록 첨부로 저장했다고 표시하지 않음 |
| 상담 인수인계 | API 없음 | 실제 모드 미제공 |
| 실시간 전화/영상/채팅 | API 없음 | 기존 미리보기는 체험 모드만 |
| 누적 통계/차트 | 집계 API·상담 날짜 없음 | 실제 모드 미제공; 임의 차트 생성 안 함 |
| 전체 복지 목록·검색·상세·즐겨찾기 서버 동기화 | 승인 분석 기반 추천만 노출 | 합성 후보를 분석·복지 탭에 표시; 실제 신청 버튼 없음 |
| 상담 결과 대상자 공개/가족 열람 | 최종 서버에 연계 사용자 없음 | 승인과 가족 공개를 같은 기능으로 취급하지 않음 |
| FCM 사용자별 기기 토큰·알림 카테고리 저장·자동 발송 | 토큰 등록/해제 API와 발송 트리거 없음 | 기존 FCM 콘솔 테스트 유지, 서버 인앱 알림과 구분. 백엔드 추가 필요 |
| 영구 저장/재시작 뒤 세션 유지 | 메모리 저장소 | 토큰은 앱 메모리만 사용. 앱 재실행 시 로그인; 서버 재시작 시 재가입 안내 |

## 백엔드에는 있고 기존 화면에 없던 부분
| 기능 | 이번 추가 |
|---|---|
| 합성 대상자 직접 생성/목록 | 홈에서 생성·대상자 전환 |
| 불변 기록 버전·409 충돌 | 버전 이력, 최신 원문 다시 불러오기 |
| OCR/STT 비동기 작업·실패·작업 ID | 주기적 상태 조회, 작업 ID 복사/다시 열기, 실패 후 새 요청 |
| 원문/교정문/교정 확정/기록 import 분리 | 독립 단계와 사용자 확정 대화상자 |
| STT 구간·실제 시간·unknown 화자 | 서버 시간 구간을 보존한 문장별 교정, 자동 화자 분리 없음 안내 |
| 이전·현재 기록 ID 기반 분석 | 같은 대상자의 서로 다른 상담을 직접 선택 |
| 분석 실패 상태/실제 제공자 | 200+failed에도 제출/승인 비활성, provider/model 표시 |
| 근거 인용·원문 버전·edited/original | 원문 및 근거 ID와 최초 분석 표시 |
| 분석 edit/submit/approve/reject | 상태별 개별 버튼. 자동 제출·승인 없음 |
| 필요 확인과 실제 근거 위치 | 지원 필요, 판단 항목, 근거 문장, 담당자 확인 체크 |
| 수동 인앱 알림·후속 업무 취소 | 작성·조회·읽음·완료/취소 연결 |

## 서버/계약 측 후속 개선 필요
- 기록의 상담 일시·생성 시각·유형이 없어 날짜 기반 분석·월별 통계와 정확한 과거 순서를 검증할 수 없다. 현재 서버 목록 반환 순서를 표시하고 사용자가 선택한다.
- 분석 목록 API가 없다. 이번 로그인에서 생성/조회한 분석을 메모리에 표시하고 분석 ID로 다시 연다. 재로그인 후 자동 이력 복원은 불가.
- OCR/STT 작업 목록 API가 없다. 작업 ID를 복사해 재조회할 수 있지만 ID를 잃으면 자동 복구할 수 없다.
- 추천 목록/이력 조회 API가 없다. 응답은 이번 로그인 메모리에서만 표시하며 승인 분석에 대해 재조회 가능하다.
- 데이터 영속성, 페이지 단위 목록/배치 조회가 없다. 현재 대상자별 기록/업무 목록을 조회한다. 운영 규모 최적화 필요.
- 실제 가족 권한·프로필·직원 승인·FCM 토큰 API가 필요하다.
- 실제 정부 사업 카탈로그/자격 확인은 미구현이다. 후보는 항상 합성·미검증·신청 불가로 표시한다.

## 네트워크/보안 동작
- 요청은 단일 ApiClient에서 수행하며 비밀번호·Bearer 토큰·상담 원문을 로그에 출력하지 않는다. 토큰은 URL/디스크에 넣지 않는다.
- 401 또는 1시간 만료 시 세션·캐시를 정리한다. 이전 세션의 지연 응답이 새 계정 자료를 되살리지 못하도록 세대 검사를 둔다.
- 409는 서버 오류 성공으로 숨기지 않는다. 최신 버전을 다시 가져와 사용자 재확인이 필요하다.
- 분석의 같은 입력 재시도는 같은 Idempotency-Key를 쓴다. 업로드도 동일 파일의 네트워크 재시도에서 request_key를 유지한다. 일반 생성 POST는 자동 재시도하지 않는다.
- HTTP timeout 뒤 저장 요청은 완료됐을 수 있다고 안내한다. 목록 확인 후 재시도해야 한다.
- 작업 폴링은 2초 간격, 제한 횟수 이후 중지하며 화면 종료 시 타이머를 해제한다. 상태 재조회는 작업 ID를 유지한다.
- 원문은 Flutter Text/SelectableText로 렌더링하고 HTML로 실행하지 않는다.
- Supabase Secret/OpenAI 비밀 키는 사용하지 않는다. 로컬 모델은 백엔드만 호출한다.

## 검증 재실행

```bash
flutter analyze
flutter test
flutter build apk --debug
```

외부 서버 합성 계약 테스트(서버에 테스트 계정·자료 생성):

```bash
dart run scripts/verify_live_api.dart https://favourite-bizrate-passed-calibration.trycloudflare.com assets/demo/synthetic_consultation.wav
dart run scripts/verify_ocr.dart https://favourite-bizrate-passed-calibration.trycloudflare.com assets/demo/synthetic_note.png
```

스크립트의 자동 승인 호출은 HTTP 계약 검사 전용이다. 사용자 화면에서는 원문 확인·제출·최종 승인을 각각 직접 수행해야 한다. 저장된 보고서에는 비밀번호·토큰을 포함하지 않는다.

검증 결과와 미실행 범위는 `API_INTEGRATION_VALIDATION.md`에 별도 기록한다.

## 기준 자료
- 사용자 제공 `백엔드인계.md`
- KMU5881193/CareGap-Backend main의 docs/FE-BACKEND-FINAL-HANDOFF.md, docs/final-http-example.json
- src/integrated-app.ts, src/final-be2.ts, analysis-workflow.ts, analysis-welfare-bridge.ts, OCR/STT 모델·라우터
- 실제 HTTPS health 및 합성 계정 HTTP 실행 응답
