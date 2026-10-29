# 초기 환경 검증 — 2026-10-29

- Node.js 22.15.0, pnpm 11.25.0, TypeScript 7.0.2 실제 설치.
- pnpm install --frozen-lockfile PASS, peer dependency 불일치 없음.
- 타입 검사, Testing Library 1개, Vite 프로덕션 빌드 및 PWA 산출물 생성 PASS.
- Playwright Chromium 실제 브라우저 초기 화면 E2E 1개 PASS.
- Vite 8.3.5, React 플러그인 6.1.2, Tailwind 4.3.3, PWA 플러그인 2.0.0 호환 조합 검증.
- TypeScript 7에서 제거된 baseUrl을 제거하고 상대 paths 별칭 사용.
- 서비스워커 자동 등록 보류. 실제 모바일 설치/권한·카메라·녹음·푸시·로그인/업무 API는 미검증/미구현.
- CI는 별도 GitHub Actions 결과를 확인하세요.
