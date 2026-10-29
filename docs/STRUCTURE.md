# 돌봄틈새 AI 개발 구조

현재 단계는 폴더와 파일 자리 생성이다. 주석만 있는 Dart 파일은 미구현이다.
신규 프로젝트의 lib/main.dart와 기본 위젯 테스트는 Flutter 생성본이다.
기존 프로젝트에서는 기존 파일 내용이 보존된다.

## 구조
- app: 최상위 앱, 화면 이동, 디자인 토큰과 테마
- core: API 공통 처리, 토큰 저장, 공통 UI와 오류
- features: auth, connections, home, appointments, beneficiaries, records,
  analysis, welfare, notifications, settings, followups, counseling
- feature/data: 서버 응답 DTO, API와 모의 데이터 구현
- feature/domain: 화면에서 사용하는 모델과 저장소 인터페이스
- feature/presentation: pages(화면), providers(상태), widgets(기능별 UI)
- assets: 이미지, 아이콘, 글꼴. 실제 파일 추가 시 pubspec.yaml에 등록
- test/unit, test/widget, integration_test: 향후 검증 코드

가족은 대상자 공통 화면을 사용하고, 로그인한 가족과 선택 대상자 ID를 구분한다.
역할과 담당자 승인 상태는 로그인/내 정보 API 응답이 기준이다.
서버에서도 매 요청마다 역할, 담당 관계와 가족 연결 권한을 검증한다.
관리자 웹은 별도 프로젝트 범위다. counseling은 후속 개발용이다.

## 구현 순서
1. 색상 → 간격 → 테마 → 공통 위젯
2. 앱 설정 → 오류 → API 클라이언트 → 토큰 저장
3. 사용자 모델 → 모의 인증 → 로그인 상태 → 라우터 → 시작/로그인 화면
4. 역할·승인·가족 연결 → 공통 메뉴 → 역할별 홈
5. 일정 → 상담 기록/업로드 → AI/복지
6. 알림/접근성/통합 점검 → 후속 실시간 상담

외부 패키지는 해당 코드를 구현할 때 추가하고 pubspec.lock을 함께 관리한다.
API URL/필드명/정책은 백엔드와 합의한 문서를 기준으로 구현한다.
처음에는 모의 데이터를 사용하며 실제 사용자 데이터를 넣지 않는다.
