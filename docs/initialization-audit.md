# 초기 설정 감사 및 정정 — 2026-10-29

## 읽기 전용 감사 기준
원격 fetch 후 확인한 main: 5e47f56. 백엔드 BE3 브랜치는 951c836으로 별도 존재. 감사 시작 시 추가 커밋·PR·로컬 미커밋 변경 없음.

A: 이번 새 프로젝트를 위해 작성한 스캐폴딩·설정·테스트·문서와 설치 도구 생성물(pnpm-lock.yaml). 근거는 이전 작업의 파일 작성/설치 도구 실행 기록과 해당 루트 커밋. Git 루트 커밋만으로 출처를 증명한 것은 아님.
B: 기존 Next.js CareGap에서 그대로 복사됐다고 확인된 파일 없음.
C: caregap-camera-poc에서 그대로 복사됐다고 확인된 파일 없음.
D: 현재 추적 파일 중 출처 불명으로 분류한 파일 없음. 외부 원본 프로젝트 전체와 바이트 비교를 수행한 감사는 아니며, 이전 생성 작업 기록에 근거함.
R: 업로드된 역할 참고 문서. A/B/C/D와 구별되는 알려진 외부 참고 자료. 기존 프로젝트 구현 코드가 아님.
E: 포트 가정은 출처 분류와 별개로 아래 기록.

## 감사 시작 당시 전체 main 파일 분류

| 파일 | 분류 |
|---|---|
| .github/workflows/ci.yml | A |
| .gitignore | A |
| .npmrc | A |
| .nvmrc | A |
| README.md | A |
| apps/web/components.json | A |
| apps/web/e2e/home.spec.ts | A |
| apps/web/index.html | A |
| apps/web/package.json | A |
| apps/web/playwright.config.ts | A |
| apps/web/src/App.test.tsx | A |
| apps/web/src/App.tsx | A |
| apps/web/src/lib/utils.ts | A |
| apps/web/src/main.tsx | A |
| apps/web/src/mocks/handlers.ts | A |
| apps/web/src/styles.css | A |
| apps/web/src/test/setup.ts | A |
| apps/web/tsconfig.json | A |
| apps/web/vite.config.ts | A |
| docs/validation.md | A |
| package.json | A |
| packages/README.md | A |
| pnpm-lock.yaml | A |
| pnpm-workspace.yaml | A |

## E: 발견한 포트 가정과 정정
- apps/web/vite.config.ts:6 — 개발 포트 5173 고정과 백엔드 3002 프록시 제거. BACKEND_URL 명시 시에만 프록시 생성.
- apps/web/playwright.config.ts:2 — 5173 baseURL/webServer 제거. e2e/fixtures.ts에서 Vite port:0으로 직접 기동, 실제 할당 URL 사용 및 서버 정리.
- README.md:4,9 — 고정 URL/3002 가정 제거. Vite 프레임워크 기본값과 미정인 팀 표준을 구별.
- CI와 package.json에는 고정 실행 포트 없음. apps/web/.env.example 추가.

## 제거/보존 및 검증
제거한 파일 없음. React/Vite 스캐폴딩, 추천 스택, Query/Router, 테스트·CI, PWA 등록 보류 보존. 네이티브 앱 구조 미확정.
타입 검사, Testing Library, 빌드 및 동적 포트 Playwright 실행 결과는 PR에 기록.

## 보안 확인 범위 및 팀 합의
추적 파일과 초기 커밋의 검사에서 실제 운영 토큰/개인정보 유출은 확인되지 않음. Compose의 local-only는 로컬 DB용 공개 예시 비밀번호이며 운영 자격증명이 아님. 외부 전체 저장소/계정에 대한 비밀정보 전수 검사를 의미하지 않음.
팀 표준 포트, API·ID·권한 계약, DB 테이블, 운영 인증, 가족 공개/동의, 외부 AI·파일 저장소, 네이티브 기능은 담당자 합의 필요. 기존 원본 프로젝트/공유 서버/공용 DB/Supabase 변경 없음.
