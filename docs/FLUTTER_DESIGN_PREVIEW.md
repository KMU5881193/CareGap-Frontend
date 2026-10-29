# 돌봄틈새 AI · Flutter 프론트엔드

제공된 디자인 이미지와 caregap-design-code의 화면 구성을 Flutter 네이티브 화면으로 구현했습니다. 현재 실행 환경은 **체험용 메모리 Repository**입니다. 실제 인증·API·푸시·OCR·STT·AI·상담 연결은 서버 및 운영 설정을 연결해야 합니다. 앱을 완전히 재시작하면 체험 정보와 선택한 파일이 초기화됩니다.

## 기존 프로젝트 적용

압축을 풀고 터미널에 프로젝트 경로를 지정합니다. lib 전체를 최종본으로 교체하고 테스트·에셋·아이콘·스플래시·권한 안내를 적용합니다. 기존 lib 전체와 변경 대상 파일은 읽기 복사 없이 같은 디스크의 caregap_backups로 이동해 보존합니다. 사용자 코드를 따로 추가했다면 먼저 이 차이를 확인한 뒤 적용하세요. package name은 caregap_app을 확인합니다. Gradle, 앱 ID, 서명 설정은 덮어쓰지 않습니다.

```bash
python3 apply_frontend.py "/Users/seonghun/Documents/Codex/2026-10-29/24-1-api/caregap_app" --check
python3 apply_frontend.py "/Users/seonghun/Documents/Codex/2026-10-29/24-1-api/caregap_app"
cd "/Users/seonghun/Documents/Codex/2026-10-29/24-1-api/caregap_app"
export PATH="/Users/seonghun/flutter/bin:$PATH"
flutter pub get
flutter analyze
flutter test
flutter devices
flutter run
```

이 작업에서 실제 caregap_app에 이미 최종본을 적용한 경우 재적용할 필요 없이 flutter run을 실행합니다. Android Studio에서 여는 명령:

```bash
open -a "Android Studio" "/Users/seonghun/Documents/Codex/2026-10-29/24-1-api/caregap_app"
```

검증은 Flutter 3.47.4 / Dart 3.13.3 / JDK 17 / Android SDK 36 / Xcode 26.6에서 했습니다. 설치된 Android Studio 2024.1은 현재 프로젝트의 AGP 9.1 IDE 동기화를 지원하지 않을 수 있습니다. CLI 빌드는 검증했습니다. 기존 Gradle을 임의로 낮추지 말고 IDE 호환 버전을 함께 맞춰 주세요.

## 화면·동작

- 시작, 역할 선택, 체험 로그인·가입, 아이디 찾기·비밀번호 재설정, 담당자 승인 대기·재제출
- 대상자·가족 홈, 담당자 업무 홈, 대상자 목록·상세, 연결 대상자 전환
- 일·주·월 일정, 상담 신청, 수락·거절·변경·취소·완료·노쇼, 담당자 가용 시간
- 상담 기록 검색·필터·정렬, 상세 대화/요약/후속 조치, 작성·수정, 사진·음성 가져오기, 인계 요청
- 사진 선택·촬영, 마이크 녹음, 오디오 파일 선택·재생·탐색·속도 변경, 변환 예시 수정 후 기록에 삽입
- AI 결과·근거 확인·수정·검토, 기간·기록 선택 누적 화면
- 복지 추천·전체·즐겨찾기·검색·상세, 가족 연결 요청·동의·해제
- 알림 목록·읽음·관련 화면 이동, 설정·프로필·접근성·비밀번호·탈퇴·도움말·라이선스
- 영상·전화·채팅은 명세에 따른 후속 기능 UI 미리보기이며 실제 연결하지 않습니다.
- 별도 admin_web: 대시보드·상담·AI 검토·담당자 승인·복지 정보·사용자·연결·통계·관리 이력·설정

기록 첨부는 시험 파일 20MB 이하 4개까지, 마이크 녹음은 2분 이내입니다. 사진과 녹음 원본은 담당자 체험 기록에서 확인하며 대상자·가족 공개 응답에는 포함하지 않습니다. 변환 버튼은 실제 OCR/STT가 아닌 명시된 체험 결과입니다.

## 디자인 구조

lib/app/theme: 색상·간격·타입·ThemeData. lib/app/widgets: 상위 공통 버튼·카드·달력·분할 탭·브랜드·배너·아바타·로딩·오류·입력·상태 컴포넌트. 기능 화면은 이를 가져옵니다. core/widgets는 이전 경로 호환 export입니다.

TableCalendar를 앱 스타일로 커스터마이즈했고, 기본 기능의 재구현보다 플랫폼 파일·카메라·오디오 패키지를 사용했습니다. Pretendard 가변 폰트를 로컬 번들로 제공하고 생성한 이미지 8종을 모든 관련 화면과 네이티브 아이콘·시작 화면에 적용했습니다.

녹색 그라데이션 버튼, 잔잔한 그림자, 둥근 카드, 햅틱·눌림 애니메이션, 스켈레톤, 플랫폼 화면 전환을 제공합니다. 큰 글씨에서는 카드·탭이 줄바꿈되고 달력은 가로 스크롤됩니다. OS 동작 줄이기를 지원하는 효과는 해당 설정을 따릅니다. 고대비 테마와 앱 내 글자 확대도 제공합니다.

## 체험 계정

공통 비밀번호: care1234

| 아이디 | 확인할 흐름 |
|---|---|
| beneficiary | 대상자 홈·공개 요약·가족 동의 |
| family | 연결된 가족·대상자 선택 |
| family_pending | 허용 전 접근 제한 |
| staff | 담당자 업무·기록·AI 검토 |
| staff_pending | 승인 대기 |
| staff_rejected | 반려 사유·재제출 |

가입·수정은 예시 정보를 사용합니다. 계정 복구 시험 연락처는 01000000000, 재설정 시험 코드는 123456이며 실제 SMS 인증이 아닙니다.

## 관리자 실행

```bash
cd admin_web
python3 -m http.server 54232 --bind 127.0.0.1
```

http://127.0.0.1:54232/ 에서 admin / care1234로 체험합니다. 관리자와 모바일의 데이터는 각각 독립된 합성 데이터입니다. 운영 관리자 권한 검증은 서버 연결 후 구현해야 합니다.

## iOS 빌드 폴더 메타데이터 문제

Documents 동기화 폴더에서 Xcode가 FinderInfo 등의 메타데이터 때문에 서명을 거부하면 함께 제공한 run_ios_local.sh를 사용합니다. 원본을 수정한 뒤 임시 프로젝트를 다시 준비하는 방식이며 서명을 끄지 않습니다.

```bash
bash run_ios_local.sh "/Users/seonghun/Documents/Codex/2026-10-29/24-1-api/caregap_app" -d "시뮬레이터 ID"
```

자세한 범위·역할 분담은 docs/BACKEND_HANDOFF.md, 패키지 근거는 docs/PACKAGES.md, 확인 결과는 VALIDATION.md에 있습니다. 향후 작업 기준은 AGENTS.md에 저장했습니다.
