# CareGap Windows 서버 복구와 전체 API — 2026-10-30 KST

## 최종 접속 주소

- 외부 웹 및 API: **https://transformation-subsidiary-softball-kitchen.trycloudflare.com**
- 로컬 API: http://127.0.0.1:4334
- 로컬 웹/간편 로그인 API: http://127.0.0.1:4339
- 보조 로컬 웹: http://127.0.0.1:4335
- 기존 wash/grams Quick Tunnel 주소는 DNS 조회에 실패했다. 새 주소를 사용한다.

최신 main 재조회: Backend `757f58bcc14bab12b97b94ac9aea0c53b9f3c261`, Frontend `e2431f3858f16fb4ccc2b36adccb2343fc1543de`. 최신 코드를 운영 메모리 서버에 덮어쓰지 않았다. 기존 검증 복제본의 스크립트·가상환경·모델·계정 파일을 재사용했다.

## 원인과 보존 범위

작업 시작 시 Windows 4324/4334/4335/4337/4339와 cloudflared 프로세스가 중단되어 TCP 연결이 거부됐다. 기존 임시 도메인도 조회되지 않았다. Ollama 및 Docker 4325는 살아 있어 재사용했다. 종료 원인(재부팅/사용자 종료 등)은 확정할 근거가 없다.

외부 전용 웹 빌드는 `USE_SAME_ORIGIN=true`여도 기본 HTTPS 정책 때문에 로컬 HTTP origin을 거부했다. 새 `build/web-recovery`는 `USE_MOCK=false`, `USE_SAME_ORIGIN=true`, `ALLOW_LOOPBACK_HTTP=true`로 빌드했다. HTTP 예외는 localhost/127.0.0.1/::1에만 적용된다. 휴대전화는 이 PC의 localhost가 아니라 위 HTTPS 주소를 사용한다.

계정·시드 상태·별칭은 복구 전 현재 사용자 전용 ACL 백업 폴더에 복사했다. 계정/별칭 비밀번호를 변경하거나 파일을 삭제하지 않았다. 기존 메모리 프로세스가 이미 없었으므로 예전의 임의 추가 자료를 모두 복구했다고 주장하지 않는다. 보존된 합성 대본으로 4334 시연 데이터를 다시 생성했고 user_id/person_id/담당 배정은 기존 파일을 재사용했다. 4324 파일과 Docker 컨테이너는 수정·종료·재시작하지 않았다.

## 포트·PID·상태

| 포트/서비스 | PID | 실제 상태 | 조치 |
|---|---:|---|---|
| 4324 이전 서버 | 없음 | TCP 연결 거부, health 실패 | 기존 자료 보존 위해 대체·재생성하지 않음. 이번 시연 주소가 아님 |
| 4334 4계정 API | 11828 (launcher 2904) | TCP 연결 가능, health 200 | 중단 확인·백업 후 start-four-demo.ps1로 신규 복구 |
| 4335 로컬 웹 | 48396 | TCP 연결 가능, health 200 | 기존 웹 빌드로 신규 실행 |
| 4337 구형 공개 프록시 | 없음 | TCP 연결 거부 | 과거 주소용이므로 미실행, 현재 시연에 불필요 |
| 4339 최신 웹/API | 31712 | TCP 연결 가능, health 200 | 새 Origin과 기존 별칭 파일로 신규 실행 |
| 11434 Ollama | 32328 (app 1924) | version/tags/ps 200 | 기존 프로세스 재사용 |
| cloudflared HTTP/2 | 45160 | icn01 연결, 외부 health 200 | 중단된 기존 터널 대신 신규 실행 |
| Docker 4325 | container 0dbb67a99369 | 기존 컨테이너 Up | 그대로 보존 |

`Get-NetTCPConnection`/netstat가 이 환경에서 실제 동작 포트를 LISTEN으로 안정적으로 열거하지 못하고 0/FIN_WAIT 계열을 보인 경우가 있다. 이 값만으로 장애라 판정하지 않았다. 새 프로세스 PID는 시작 기록과 Win32_Process 실행 경로/명령줄로 확인했고, TCP Connect 및 실제 HTTP 200을 함께 검증했다. 상세 원시 관측은 `.runtime/recovery-port-audit.json`에 있다.

실행 경로: API/프록시 `C:\Program Files\nodejs\node.exe`, Ollama `C:\Users\Owner\AppData\Local\Programs\Ollama\ollama.exe`, Cloudflare `C:\Program Files (x86)\cloudflared\cloudflared.exe`. API 명령은 `node --import tsx scripts/integrated-server.ts`, 프록시는 `node scripts/local-web-demo.mjs`, 터널은 `cloudflared tunnel --protocol http2 --url http://127.0.0.1:4339 --no-autoupdate`다.

## 실제 모델과 전체 시연 검증

- Ollama 0.40.13, RTX 4060 8 GB, `qwen2.5vl:7b` Q4_K_M. `ollama ps`: **100% GPU**, context 4096, size_vram 5,352,781,249 bytes. `/api/ps`에는 Qwen만 로딩됐다. 모델 다운로드·Gemma 동시 로딩 없음.
- 실제 텍스트 추론: done=true, eval_count=20. 응답: `식사 횟수를 하루 두 번에서 세 번으로 늘렸습니다.`
- ONNX OCR: 두 합성 PNG 실제 인식 성공. 예: `오늘식사는세번했고약을빠뜨리지않았습니다.` 띄어쓰기는 교정했다.
- Whisper: 한국어 합성 WAV 실제 인식 성공. 복약 등 오인식을 보존하고 합성 대본으로 교정·확정한 후 import했다. 무교정 정확도 PASS로 간주하지 않는다.
- 상담 비교: 두 사례 status=succeeded, review_state=approved. 실제 Qwen eval_count 181/146, elapsed_ms 4357/4145. 모든 evidence quote를 원문 consultation/record_version과 일치 검사했다.
- 복지: 승인 후 합성 후보 각 1개 반환. 자격 unverified이며 실제 신청 추천 아님.
- Vision PNG/JPEG: HTTP 201 및 data.status=succeeded. 실제 Ollama images 필드가 원본 base64와 일치, OCR 미사용. PNG 도형 수·색상 오인식이 있어 내용 정확도는 부분완료이며 자동 채택하지 않는다.
- 외부 실제 Dart Repository 흐름: 4로그인 → persons/appointments → OCR/STT → 교정/확정/import → Qwen/근거 → 검토/승인 → 복지 → 업무/알림 조회 → logout 성공. 실패 결과를 Mock으로 대체하지 않았다.
- 로컬 4339 브라우저 staff1 담당자 홈과 새 외부 HTTPS 브라우저 user1 본인 예약·기록 화면 렌더링/실제 로그인 확인.
- 계정 staff1/staff2/user1/user2 역할·본인/배정 자료 일치, 교차 대상자 records 403, patient 임상 쓰기 403. logout 204 및 이후 me 401 검증.
- 연속 자동 검증 중 분당 인증 제한 30회를 초과해 429가 관측됐다. 제한을 낮추지 않고 창이 끝난 뒤 재시도했다. 정상 로그인 실패와 보안 제한을 구분한다.

## 4계정과 인증 정보

| 간편 ID | 실제 역할 | 가명 | 배정 |
|---|---|---|---|
| staff1 | staff | 김민준 | 박영희 |
| staff2 | staff | 이서연 | 최정호 |
| user1 | patient | 박영희 | 김민준 |
| user2 | patient | 최정호 | 이서연 |

4334 직접 로그인은 Backend `.runtime/demo-credentials.json`의 원본 계정, 4339/외부는 Frontend `.runtime/demo-login-aliases.json`의 매핑을 사용한다. 비밀번호는 이 문서에 기재하지 않는다. 직접 4334에 간편 ID를 입력하면 로그인 계약이 다르므로 실패한다.

API 키 대신 로그인으로 발급되는 3600초 Bearer 토큰을 사용한다. 과거 토큰은 메모리 서버 중단 후 무효다. 4계정 새 토큰은 `.runtime/recovery-api-access.json`, staff1 별도 토큰은 `.runtime/api-token-staff1.json`에 저장한다(현재 사용자 전용 ACL, Git 비추적).

재발급: `pwsh -NoProfile -File scripts/issue-demo-token.ps1 -Identifier staff1`. 다른 간편 ID도 가능하다. 스크립트는 비밀번호·토큰 값을 로그에 출력하지 않고 새 주소에서 login/me를 확인한 뒤 개인 파일에 저장한다.

공통 헤더: `Content-Type: application/json`, 인증 요청은 `Authorization: Bearer <access_token>`. 요청/응답의 실제 비밀값은 문서·Git·검증 로그에 넣지 않는다.

## 전체 실행 중인 API 계약

아래 경로는 위 외부 base URL 뒤에 붙인다. 정상 응답은 `{data:...}`, 오류는 `{error:{code,...}}`다. 정상 HTTP 계약과 실제 실행 결과는 구분한다. 등록은 4계정 수 유지를 위해 실제 새 계정 생성 검증을 하지 않았다. 그 외 실제 시연 검증 범위는 위 결과/비밀을 제외한 로컬 증거를 따른다.

| Method | 경로 | 요청/용도 | 정상 HTTP |
|---|---|---|---:|
| GET | /health | 합성 모드·실제 provider·모델 가용성(추론 성공과 별개) | 200 |
| POST | /api/auth/register | identifier,password. 공개 등록은 staff만, role 선택 불가 | 201 |
| POST | /api/auth/login | identifier,password → access_token,expires_in,actor | 200 |
| GET | /api/auth/me | 현재 actor | 200 |
| POST | /api/auth/logout | `{}` → 세션 폐기 | 204 |
| GET | /api/persons | 배정 대상자 또는 본인만 | 200 |
| POST | /api/persons | staff, `{}` | 201 |
| GET | /api/appointments | 접근 가능한 예약만 | 200 |
| POST | /api/appointments | person_id,starts_at,ends_at(UTC ISO). 본인 patient도 가능 | 201 |
| POST | /api/appointments/:id/actions | staff, action:complete/cancel,expected_status | 200 |
| GET | /api/records?person_id=:person_id | 본인/배정 기록과 버전 | 200 |
| POST | /api/records | staff, person_id,text | 201 |
| POST | /api/records/:consultation_id/versions | expected_record_version_id,text | 201 |
| POST | /api/records/import | source:ocr/stt,job_id. 확정 필수·동일 job 중복 방지 | 201 |
| POST | /api/ocr/jobs | person_id,request_key,filename,mimeType,base64 | 202 |
| GET | /api/ocr/jobs/:id | 작업 상태·원문·교정 이력 | 200 |
| GET | /api/ocr/jobs/:id/result | succeeded일 때 결과, 미완료 409 | 200 |
| POST | /api/ocr/jobs/:id/corrections | expected_version,text | 200 |
| POST | /api/ocr/jobs/:id/confirmation | expected_version | 200 |
| POST | /api/stt/jobs | person_id,request_key,filename,mimeType:audio/wav,base64 | 202 |
| GET | /api/stt/jobs/:id | 상태·segments·교정 이력 | 200 |
| GET | /api/stt/jobs/:id/result | succeeded일 때 결과, 미완료 409 | 200 |
| POST | /api/stt/jobs/:id/corrections | expected_version,segments:[{start_ms,end_ms,speaker_id,text}] | 200 |
| POST | /api/stt/jobs/:id/confirmation | expected_version | 200 |
| POST | /api/analyses | person_id,past:[{consultation_id,record_version_id}],current:{동일 ref}. Idempotency-Key 필수 | 200 |
| GET | /api/analyses/:id | 분석·sources·inference·원문 근거·검토 이력 | 200 |
| GET | /api/analyses/:id/published | 승인된 분석, 미승인 409 | 200 |
| POST | /api/analysis-reviews/:id | action:edit/submit/approve/reject,expected_version. edit는 draft 추가 | 200 |
| POST | /api/welfare-recommendations | analysis_id,expected_analysis_version,confirmations:[{need,finding_index,evidence_index,confirmed}] | 200 |
| POST | /api/vision/analyses | person_id,filename,mimeType:image/png 또는 image/jpeg,base64. Idempotency-Key 필수 | 201 |
| GET | /api/follow-ups?person_id=:person_id | 대상자의 후속 업무 | 200 |
| POST | /api/follow-ups | person_id,title,consultation_id?,record_version_id? | 201 |
| POST | /api/follow-ups/:id/actions | action:complete/cancel,expected_status | 200 |
| GET | /api/notifications | 로그인 사용자 자신의 인앱 알림 | 200 |
| POST | /api/notifications | staff, title,body. 수신자는 로그인 사용자 | 201 |
| POST | /api/notifications/:id/read | `{}`. 타인 알림은 404 | 200 |

OCR/STT/모델/기록 쓰기/승인은 staff만 가능하다. patient는 본인 persons/appointments/records/follow-ups/notifications를 조회하고 자기 예약을 생성한다. 업로드는 data URI 접두어 없는 원본 base64를 사용한다. OCR JPEG/PNG 5 MB, STT 유효 WAV 10 MB 제한을 따른다. 분석은 HTTP 200이어도 data.status=failed이면 실패다. 작업 역시 status=succeeded를 확인한 뒤 진행한다. 버전 충돌/미확정/미승인은 409, 인증 실패 401, 인가 실패 403, 제한 초과 429다.

## Flutter 웹·APK

웹은 같은 출처 API를 사용하므로 원격 휴대전화의 localhost를 호출하지 않는다. 로컬은 루프백 URL을 사용하고, 같은 Wi-Fi의 휴대전화·다른 노트북은 HTTPS 주소로 접속한다. LAN HTTP 개방이나 방화벽 해제는 수행하지 않았다.

`USE_MOCK=false`, `USE_SAME_ORIGIN=false`, `BACKEND_URL=<위 실제 HTTPS>`로 Android debug APK 빌드 성공(182,230,524 bytes). 파일은 `build/app/outputs/flutter-apk/app-debug.apk`다. adb 연결 기기가 없어 설치·실기기 로그인은 미검증이다. 기존 Mock APK나 옛 터널 주소를 고정한 APK는 다시 빌드해야 한다. 새 Quick Tunnel 주소가 바뀌면 APK도 새 BACKEND_URL로 재빌드해야 한다. 자동 승인 검토가 공개 APK 게시를 거절하여 로컬 전달만 제공한다.

## 재부팅 후 한 번에 복구

Frontend 검증 복제본에서 PowerShell 7:

```powershell
pwsh -NoProfile -File scripts/recover-demo.ps1 -VerifyAI -BuildApk
```

API/웹만 빠르게 복구하려면 -BuildApk를 생략한다. 정상 서버·정상 터널은 재사용한다. 점유된 비정상 포트는 강제 해제하지 않는다. 기존 자격증명/시드 파일을 먼저 백업하고, 기존 모델·가상환경·웹 빌드를 재사용한다. Ollama에 다른 모델이 로딩돼 있으면 강제 언로드하지 않고 중단한다. 4324 및 Docker는 건드리지 않는다. 재사용 경로는 이 작업에서 실제 실행해 4로그인 성공을 확인했다. 이번 최초 cold restore의 개별 start/seed/build도 실제 성공했다. 스크립트 자체의 cold 경로를 확인하기 위해 정상 서버를 일부러 종료하지 않았다.

4339는 정상인데 터널만 죽어 Origin 변경이 필요한 경우, 정상 게이트웨이를 재시작하지 않고 명시적 오류로 멈춘다. 이 경우 기존 프로세스 Origin 설정을 검토해야 하며 무조건 새 프로세스로 교체하지 않는다. 복구된 최신 주소는 `.runtime/recovery-state.json`에 저장된다.

## 남은 사항

- 4324는 작업 시작 전부터 중단돼 있었다. 그 메모리 전체의 영속 snapshot이 없어 기존 임의 자료 복원을 보증하지 않는다. 파일·Docker는 보존했다. 프론트는 새 4339/HTTPS를 사용한다.
- 구형 4337은 미실행이며 현재 서비스 경로가 아니다.
- 실기기 카메라/마이크/FCM·양방향 통화·운영 DB/인증은 이 복구로 완료된 기능이 아니다. LiveKit staging/FCM 키는 구성·검증되지 않았고 API 목록에 운영 기능처럼 포함하지 않았다.
- 모델 인식 오류와 Vision 환각은 사람 검토가 필요하다. 합성 데이터만 공개했다.
- 이 복구용 PR의 CI는 별도 확인 대상이며 실제 실행 검증을 CI 성공으로 대체하지 않는다.
