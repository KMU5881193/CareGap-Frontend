# 합성 시연 입력

실제 개인정보가 없는 앱 내 시연 입력입니다. 네트워크 응답을 흉내내는 Mock이 아닙니다.
- synthetic_consultation.wav: macOS Yuna TTS로 생성한 한국어 합성 음성, 16kHz mono PCM16 WAV.
- synthetic_note.png: AppKit 시스템 글꼴로 생성한 합성 인쇄체 한 줄 이미지.
실제 서버 OCR/STT로 전송하며 인식 원문을 사용자에게 표시하고 교정/확정 후에만 기록으로 가져옵니다.
음성 문장: 오늘 식사는 세 번 했습니다. 약을 빠뜨리지 않았습니다. 산책은 두 번 했습니다.
이미지 문장: 오늘 식사는 세 번 했습니다.
