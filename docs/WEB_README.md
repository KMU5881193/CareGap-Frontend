# CareGap Frontend
React/Vite SPA 추천 스택의 초기 설정. TypeScript 7.0.2는 Backend와 동일.

pnpm install --frozen-lockfile → pnpm dev. 표시되는 실제 로컬 URL을 사용하세요.
pnpm typecheck / pnpm test / pnpm build.
E2E: pnpm --filter @caregap/web exec playwright install chromium 후 pnpm test:e2e.

apps/web 및 packages/* pnpm workspace. Router/Query 연결, 폼/Zod·FullCalendar·MSW 의존성, Tailwind 4·shadcn 설정 포함. 업무 화면 구현은 FE 담당자에게 남깁니다.
API 개발 프록시는 기본 비활성입니다. 필요한 경우 apps/web/.env.example을 같은 폴더의 .env로 복사하고 BACKEND_URL에 실제 백엔드 주소를 지정하세요. 배포 시 동일 출처 /api 라우팅은 별도 필요합니다. 인증은 BE1 계약 확정 후 연결하며 개발 헤더 자동 전송 없음.
PWA 산출물은 생성하지만 서비스워커 자동 등록은 보류. 민감한 API 응답 캐시 금지. 아이콘/설치 UX/푸시/카메라·녹음/네이티브 기능은 미확정.
Backend docs/contracts.md 및 docs/openapi.yaml을 공동 검토하세요.

완전히 새로 시작하는 프로젝트입니다. 기존 Next.js CareGap·caregap-camera-poc은 아이디어/요구사항 참고 자료일 뿐 코드·설정 복사 기반이 아닙니다.
팀 표준 프론트/백엔드 포트는 아직 미정입니다. Vite 자체 기본 개발 포트는 5173이며 충돌 시 다음 사용 가능한 포트를 시도합니다. 이는 프레임워크 동작 설명이며 팀 고정값이 아닙니다.
필요하면 pnpm --filter @caregap/web dev --port <선택한-로컬-포트>로 일회성 지정하세요. Playwright는 Vite port: 0으로 운영체제가 할당한 임시 포트를 사용하고 종료 시 서버를 닫습니다.

초대 없이 참여하는 Fork/PR 절차와 직접 Push 권한의 차이는 [CONTRIBUTING.md](CONTRIBUTING.md)를 참고하세요. 출처·포트 감사표는 [docs/initialization-audit.md](docs/initialization-audit.md)에 있습니다.
