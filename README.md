# CareGap Frontend
React/Vite SPA 추천 스택의 초기 설정. TypeScript 7.0.2는 Backend와 동일.

pnpm install --frozen-lockfile → pnpm dev (127.0.0.1:5173).
pnpm typecheck / pnpm test / pnpm build.
E2E: pnpm --filter @caregap/web exec playwright install chromium 후 pnpm test:e2e.

apps/web 및 packages/* pnpm workspace. Router/Query 연결, 폼/Zod·FullCalendar·MSW 의존성, Tailwind 4·shadcn 설정 포함. 업무 화면 구현은 FE 담당자에게 남깁니다.
API 개발 프록시 3002, 배포 시 동일 출처 /api 라우팅 별도 필요. 인증은 BE1 계약 확정 후 연결하며 개발 헤더 자동 전송 없음.
PWA 산출물은 생성하지만 서비스워커 자동 등록은 보류. 민감한 API 응답 캐시 금지. 아이콘/설치 UX/푸시/카메라·녹음/네이티브 기능은 미확정.
Backend docs/contracts.md 및 docs/openapi.yaml을 공동 검토하세요.
