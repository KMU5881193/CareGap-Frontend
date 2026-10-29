# CareGap 협업 안내

팀은 백엔드 3명·프론트엔드 2명입니다. React/Vite 추천 스택으로 새로 시작하며 기존 Next.js CareGap·개인 PoC의 코드/설정을 그대로 이식하지 않습니다. 네이티브 앱 구조와 외부 연동은 확정하지 않았습니다.

## 초대 없이 Fork와 PR로 참여

1. 열람용 Clone: `git clone https://github.com/KMU5881193/CareGap-Frontend.git`.
2. GitHub 원본 페이지의 **Fork**로 본인 계정에 Fork합니다.
3. 본인 Fork를 Clone하고 원본 upstream을 등록합니다. YOUR_LOGIN은 본인 GitHub 아이디로 바꾸세요.

```sh
git clone https://github.com/YOUR_LOGIN/CareGap-Frontend.git
cd CareGap-Frontend
git remote add upstream https://github.com/KMU5881193/CareGap-Frontend.git
git fetch upstream
git switch -c feature/your-task upstream/main
pnpm install --frozen-lockfile
```

4. 기능 브랜치에서 작업하고 `pnpm typecheck`, `pnpm test`, `pnpm build`를 실행합니다. 브라우저 설치 후 `pnpm test:e2e`도 실행하세요.
5. 변경한 파일만 선택해 커밋하고 본인 Fork로 Push합니다.

```sh
git add <변경한-파일>
git commit -m "변경 목적"
git push -u origin feature/your-task
```

6. **Compare & pull request**에서 원본 `KMU5881193/CareGap-Frontend`의 `main`으로 PR을 제출합니다. 변경 이유·화면/API 영향·테스트 결과를 적으세요.
7. 저장소 관리자가 CI와 리뷰를 확인한 뒤 Merge합니다. API 계약 변경은 백엔드 담당자와 함께 검토하세요.

Public 전환으로 누구나 원본에 직접 Push할 수 있게 되는 것은 아닙니다. Fork/PR은 초대 없이 가능하지만, 원본 직접 Push가 필요하면 관리자가 Settings → Collaborators에서 GitHub 계정을 초대하고 팀원이 수락해야 합니다. 이번 설정에서는 초대나 권한 부여를 하지 않았습니다.

## 설정과 정보 보호

- 팀 표준 포트는 미정입니다. Vite가 표시하는 URL을 사용하세요. BACKEND_URL은 실제 백엔드를 실행한 경우에만 지정합니다. 브라우저 테스트는 동적 포트를 사용합니다.
- `.env`, 토큰, 운영 DB 정보, 실제 상담/개인 자료를 커밋하지 마세요. `VITE_` 변수는 브라우저 번들에 노출되므로 비밀 값을 넣으면 안 됩니다.
- Git 작성자 이름·이메일은 공개 메타데이터입니다. 첫 커밋 전에 로컬 Git 설정을 확인하고 필요하면 GitHub noreply 이메일을 사용하세요. 설정 변경으로 과거 기록이 지워지지는 않습니다.
- 강제 Push·기록 재작성·기존 원본 프로젝트·공용 DB/서버 변경은 별도 합의 없이 하지 않습니다.
- 비밀정보를 발견하면 공개 전환을 중단하고 관리자에게 알리세요. 이미 노출된 자격증명은 폐기/교체가 필요하며 최신 파일 삭제만으로 기록이 없어지지 않습니다.
