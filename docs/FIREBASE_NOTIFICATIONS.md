# Firebase 알림 연결 — Android / iOS

## 현재 구현 상태
- Firebase Core 4.15.2, Messaging 16.7.1: 기존 FCM registration token 기반 백엔드와 연결 가능한 공식 FlutterFire 계열. FID 전환을 도입한 17 계열과 섞지 않는다.
- shared_preferences 2.5.6: 기기 전체 푸시 허용 선택만 저장. 토큰·상담 원문은 저장하지 않는다.
- 위 세 패키지는 BSD-3-Clause이며 Flutter/Dart 버전 의존성 해결 및 Android 빌드로 호환성 확인.
- Firebase 설정이 없어도 기존 앱 실행을 유지하고 설정 화면에 연결 대기를 표시한다.
- 최초 실행에서 권한을 자동 요청하지 않는다. 로그인 후 더보기 → 알림 설정에서 사용자가 켠다.
- Android 13+ 알림 권한, caregap_updates 채널, 흰색 단색 알림 아이콘.
- iOS Push entitlement, Background fetch / Remote notifications 모드. Firebase swizzling을 비활성화하지 않는다.
- 포그라운드: 민감한 원문 대신 공통 인앱 배너. 백그라운드/종료 상태의 notification 메시지: 운영체제 표시.
- data-only 메시지는 화면을 만들거나 상담 데이터를 변경하지 않는다. 배경 수신 핸들러는 원문을 로깅하지 않는다.
- 초기 알림 터치와 백그라운드 터치를 처리하며 로그인·접근 권한 확인 후 알림 설정을 연다. 서버 알림함/상세 리소스 딥링크는 미연결이다.
- 토큰 갱신 이벤트 처리. iOS APNs 토큰을 받은 뒤 FCM 토큰을 조회한다. APNs 대기 시 상태 다시 확인으로 재시도한다.
- 푸시 끄기: 자동 초기화 중지 + FCM 토큰 삭제. 로그아웃에서도 토큰 삭제를 시도한다. 실패하면 재시도가 필요하며 백엔드 토큰 연결 해제는 별도 구현해야 한다.
- 예약/상담 결과별 스위치는 기존 체험 설정이며 서버 필터링에 적용되지 않는다.

## 1. Firebase 프로젝트 생성
https://console.firebase.google.com/ 에서 프로젝트를 만든다. 이름은 CareGap, 프로젝트 ID는 실제 사용할 고유 ID로 지정한다. Analytics는 현재 알림 테스트에 필수가 아니다. 현재 단계는 Firebase Auth나 Firestore를 추가하지 않는다. 기존 인증 서버를 유지한다.

## 2. 터미널 로그인 및 앱 등록
Android Studio 터미널에서 실행:

```bash
cd "/Users/seonghun/Documents/Codex/2026-10-29/24-1-api/caregap_app"
export PATH="$HOME/flutter/bin:$HOME/.pub-cache/bin:$PATH"
firebase login --reauth
firebase projects:list
```

프로젝트 ID를 확인한 뒤 다음 명령의 `YOUR_FIREBASE_PROJECT_ID`를 바꾼다:

```bash
bash scripts/configure_firebase.sh YOUR_FIREBASE_PROJECT_ID
```

스크립트는 Android/iOS 앱을 선택하거나 등록하고 네이티브 설정을 내려받는다. CLI 확인 질문에는 사용할 프로젝트와 현재 앱을 선택한다. 대상 ID:

| 플랫폼 | 현재 앱 ID |
|---|---|
| Android package | com.example.caregap_app |
| iOS bundle | com.example.caregapApp |

앱 ID는 대소문자와 밑줄까지 일치해야 한다. 출시용 ID로 바꾸려면 Firebase 등록 전에 두 플랫폼 ID와 스크립트를 함께 수정한다.

생성되는 파일:
- android/app/google-services.json
- ios/Runner/GoogleService-Info.plist
- lib/firebase_options.dart
- firebase.json 및 네이티브 빌드 등록 변경

현재 앱은 백그라운드 isolate에서도 같은 프로젝트를 쓰기 위해 네이티브 설정 파일의 기본 Firebase 앱으로 초기화한다. firebase_options.dart만 복사하는 것으로는 충분하지 않다. 스크립트가 두 네이티브 파일의 앱 ID와 프로젝트 일치를 검사한다.

## 3. iOS APNs 연결
1. https://developer.apple.com/account 에 로그인한다.
2. Certificates, Identifiers & Profiles → Identifiers에서 `com.example.caregapApp` App ID를 확인한다. Push Notifications를 활성화한다. 명시적인 App ID여야 한다.
3. Keys → + → APNs 키 생성. Apple 화면에서 필요한 환경/권한 범위를 선택하고 해당 앱에 쓸 수 있는 키를 만든다.
4. .p8 파일을 안전하게 보관한다. Key ID와 Team ID를 확인한다.
5. Firebase 프로젝트 설정 → Cloud Messaging → iOS 앱 구성 → APNs 인증 키에서 .p8, Key ID, Team ID를 등록한다. 개발/운영 환경에 맞는 키가 필요하다.
6. Xcode에서 ios/Runner.xcworkspace → Runner → Signing & Capabilities. 올바른 Team, Automatically manage signing, Push Notifications, Background Modes의 Background fetch/Remote notifications를 확인한다.

코드에는 이미 capabilities와 development APS entitlement를 추가했다. 실제 프로비저닝은 Apple 계정과 App ID 설정 후 Xcode가 갱신한다. 배포 아카이브에서는 배포 프로파일의 production entitlement가 적용되는지 확인한다.

.p8, 서비스 계정 JSON, 인증 토큰을 앱 에셋·Git·채팅에 넣지 않는다. APNs 키는 Firebase 콘솔에 직접 등록한다.

## 4. 실제 기기 테스트
앱 완전 종료 후 다시 빌드한다. Android는 Google Play 서비스가 있는 기기/에뮬레이터를 사용한다. iOS는 실제 iPhone에서 검증한다.

```bash
flutter devices
flutter run
```

Documents/iCloud 코드서명 문제가 발생했던 iPhone 실행은 기존 스크립트 사용:

```bash
bash ./run_ios_local.sh "$PWD" -d "iPhone 16"
```

로그인 → 더보기 → 알림 설정 → 이 기기의 푸시 알림 켜기. iOS 기기 등록 대기라면 몇 초 뒤 연결 상태 다시 확인. 개발용 알림 테스트를 펼쳐 FCM 토큰을 복사한다.

Firebase 콘솔 Messaging → 알림 메시지 작성 → 테스트 메시지 전송에서 해당 토큰을 붙여넣는다. 제목은 `돌봄틈새 AI`, 본문은 `새로운 돌봄 소식이 있어요. 앱에서 확인해 주세요.`처럼 합성 테스트만 사용한다.

검증할 상태:
- 앱 실행 중: 공통 인앱 배너 1회.
- 홈으로 나가 백그라운드: OS 알림 수신, 터치 시 설정 화면.
- 앱 종료 후 터치: 로그인·접근 확인을 거쳐 설정 화면.
- 알림 거부 후 복귀: 거부 상태 표시.
- 알림 끄기: 토큰 삭제 성공 확인. 이전 토큰에 새 테스트 메시지를 보내 미수신 확인.
- 로그아웃 후 다시 로그인: 푸시를 다시 켜 토큰을 등록한다.

OS에서 앱을 강제 종료한 경우 배경 처리가 제한될 수 있어 앱을 다시 실행한 뒤 검사한다.

## 5. 백엔드 담당자와 나눌 역할
앱: 권한·기기 토큰 발급/갱신·로그인한 사용자와 토큰 등록·알림 탭 후 인증된 데이터 재조회.
백엔드: Firebase Admin SDK 또는 FCM HTTP v1 인증·발송·예약 트리거·사용자별 대상자 권한·토큰 폐기·동의/카테고리 필터·중복 방지.

현재 제공된 API 계약에는 기기 토큰 등록/삭제나 알림 목록 API가 없다. 경로를 추측해 호출하지 않았으며 실제 자동 발송은 구현하지 않았다. 서버 담당자와 로그인 후 등록, 토큰 갱신 교체, 로그아웃/탈퇴 시 연결 해제, 서버의 무효 토큰 정리 계약을 추가해야 한다.

토큰은 사용자 계정마다 여러 기기를 허용하고, 로그인 계정이 바뀌면 이전 소유권을 해제한다. 브로드캐스트 topic을 개인정보/대상자 권한의 대체 수단으로 사용하지 않는다.

예시 발송 메시지 계약(HTTP v1의 message 내부):

```json
{
  "token": "SERVER_STORED_FCM_TOKEN",
  "notification": {
    "title": "돌봄틈새 AI",
    "body": "새로운 돌봄 소식이 있어요. 앱에서 확인해 주세요."
  },
  "android": {"notification": {"channel_id": "caregap_updates"}},
  "apns": {"payload": {"aps": {"sound": "default"}}}
}
```

수신한 푸시만으로 예약 확정/분석 승인 상태를 바꾸지 않는다. 메시지 원문은 잠금 화면에 노출되므로 발송 측에서 상담 원문·이름·건강 정보를 넣지 않는다.

## 참고
- https://firebase.google.com/docs/flutter/setup
- https://firebase.google.com/docs/cloud-messaging/flutter/get-started
- https://firebase.google.com/docs/cloud-messaging/flutter/receive-messages
- https://developer.apple.com/help/account/keys/create-a-private-key/
