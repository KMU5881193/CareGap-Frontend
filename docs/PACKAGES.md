# 패키지 선택과 라이선스

최종 lockfile과 네이티브 빌드로 호환성을 확인했습니다. 패키지 전체가 앱 UI를 결정하게 두지 않고, 공통 컴포넌트가 앱의 색상·타입·크기·상태를 관리합니다. 의존성은 파일 선택·카메라·오디오·달력·개발 시 에셋 생성에 한정했습니다.

| 패키지 | 사용 버전 | 선택 이유 | 직접 패키지 라이선스 |
|---|---|---|---|
| [table_calendar](https://pub.dev/packages/table_calendar) | 3.3.0 | 한국어 월 달력·날짜 상태·실제 일정 마커를 공통 위젯으로 커스텀 | Apache-2.0 |
| [file_selector](https://pub.dev/packages/file_selector) | 1.1.0 | Flutter 공식 플랫폼 파일 선택기. 음성·자격 자료 선택 | BSD-3-Clause |
| [image_picker](https://pub.dev/packages/image_picker) | 1.2.4 | Flutter 공식 카메라·사진 선택, Android lost-data 복구 | BSD-3-Clause (LICENSE 내 고지 포함) |
| [record](https://pub.dev/packages/record) | 7.1.2 | 마이크 권한·PCM 스트림 녹음·명시적 종료와 리소스 해제 | BSD-3-Clause |
| [audioplayers](https://pub.dev/packages/audioplayers) | 6.8.1 | 선택·녹음한 WAV/오디오 미리보기, 탐색과 속도 | MIT |
| [flutter_launcher_icons](https://pub.dev/packages/flutter_launcher_icons) | 0.14.4 | 브랜드 원본으로 플랫폼별 아이콘 생성; 개발 의존성 | MIT |
| [flutter_native_splash](https://pub.dev/packages/flutter_native_splash) | 2.4.8 | Android 12 포함 네이티브 시작 화면; 개발 의존성 | MIT |
| Pretendard Variable | 로컬 TTF | 한국어 가독성과 일관된 타이포그래피, 네트워크 폰트 의존 제거 | SIL Open Font License 1.1 |

배포 전 전체 전이 의존성의 LICENSE도 유지해야 합니다. Flutter의 라이선스 화면을 제공하며 폰트 고지를 LicenseRegistry에 등록했습니다. 직접 패키지 LICENSE 사본은 docs/licenses에 있습니다. lockfile은 이번 검증 버전을 기록한 참고 파일이며 설치기는 기존 앱 lockfile을 덮어쓰지 않습니다.

유지보수·배포 현황은 위 pub.dev 공식 패키지 페이지와 설치된 소스로 검토했고, Android/iOS 실제 빌드로 이 조합을 확인했습니다. iOS 사진·마이크·카메라 사용 목적을 Info.plist에 추가하고 Android RECORD_AUDIO를 선언했습니다. 실제 권한 허용/거부와 기기별 녹음·코덱은 출시 전 실기기 검증 항목입니다.

UI 애니메이션과 상태 관리는 Flutter 내장 기능으로 구현해 별도의 대형 UI 키트·차트·애니메이션 패키지는 추가하지 않았습니다. 가상의 건강 점수 그래프를 생성하는 대신 실제 선택 기록과 승인된 내용을 표시합니다.

접근성의 기본 기준은 [Flutter 접근성 문서](https://docs.flutter.dev/ui/accessibility)를 참고했습니다. 큰 글씨에서 카드·탭을 재배치하고 48dp 이상의 주요 터치 영역, 의미 있는 아이콘 안내, OS 동작 줄이기와 고대비 테마를 지원합니다.


## Firebase 알림 (2026-10-30)
공식 Firebase Core 4.15.2 / Messaging 16.7.1을 사용한다. 기존 FCM 토큰 계약을 유지하는 계열이며 17의 FID 등록 전환은 별도 검토한다. shared_preferences 2.5.6은 기기 알림 켜기 선택만 저장한다. 모두 BSD-3-Clause이며 docs/licenses에 원문을 포함했다. 설정/검증/백엔드 역할은 FIREBASE_NOTIFICATIONS.md 참고.
