# Gemini AI 챗봇 📱

Google Gemini AI와 연동된 Flutter 챗봇 애플리케이션입니다.

## 🎨 디자인 특징

- **통일된 색상 테마**: 파란색 기반의 일관된 UI (#3B82F6)
- **아이폰 메신저 스타일**: 말풍선 형태의 대화 인터페이스
- **자연스러운 타이핑 애니메이션**: 2초 딜레이와 함께 점 3개의 동적 애니메이션
- **플랫폼 최적화**: iOS는 SF Pro Display, Android는 Roboto 폰트 사용

## 🚀 기능

- ✅ 실시간 채팅 인터페이스
- ✅ **Google Gemini AI 연동** 🤖
- ✅ 메시지 버블 디자인 (아이폰 스타일)
- ✅ 타이핑 인디케이터 애니메이션
- ✅ 자동 스크롤
- ✅ 햅틱 피드백 (iOS/Android)
- ✅ 대화 내역 삭제 기능
- ✅ 앱 정보 다이얼로그
- ✅ 오류 처리 및 로깅
- 🔄 PDF RAG 기능 (준비 중)

## 📱 지원 플랫폼

- ✅ iOS
- ✅ Android 
- ✅ macOS
- ✅ Web
- ✅ Windows
- ✅ Linux

## 🔧 Gemini API 설정

이 앱은 Google Gemini AI API와 연동되어 있습니다:

- **모델**: `gemini-1.5-flash`
- **API 키**: 코드에 포함됨 (개발용)
- **기능**: 자연스러운 한국어 대화, 질문 답변
- **안전 설정**: 모든 유해 콘텐츠 차단

### API 키 보안
현재 API 키가 코드에 하드코딩되어 있습니다. 실제 배포 시에는:
```dart
// 환경변수 사용 권장
static const String _apiKey = String.fromEnvironment('GEMINI_API_KEY');
```

## 🛠 Android Studio에서 실행하기

### 1. 프로젝트 열기
```bash
# Android Studio 실행 후
File > Open > ai_chatbot 폴더 선택
```

### 2. Flutter SDK 설정 확인
```bash
# 터미널에서 확인
flutter doctor
```

### 3. 의존성 설치
```bash
flutter pub get
```

### 4. 디바이스/에뮬레이터에서 실행

#### Android 에뮬레이터
1. Android Studio > Tools > AVD Manager
2. 가상 디바이스 생성 및 실행
3. 실행 버튼(▶️) 클릭 또는 `flutter run`

#### iOS 시뮬레이터 (macOS만)
1. Xcode Simulator 실행
2. 원하는 iOS 디바이스 선택
3. 실행 버튼(▶️) 클릭 또는 `flutter run`

#### 실제 디바이스
1. USB로 디바이스 연결
2. 개발자 모드 활성화
3. 실행 버튼(▶️) 클릭

### 5. 빌드 명령어

```bash
# Android APK 빌드
flutter build apk

# Android App Bundle 빌드
flutter build appbundle

# iOS 빌드 (macOS만)
flutter build ios

# 웹 빌드
flutter build web
```

## 🧪 테스트 실행

```bash
# 모든 테스트 실행
flutter test

# 코드 분석
flutter analyze

# 프로젝트 정리
flutter clean
```

## 📂 프로젝트 구조

```
ai_chatbot/
├── lib/
│   ├── main.dart              # 메인 앱 엔트리포인트
├── test/
│   ├── widget_test.dart       # 위젯 테스트
├── android/                   # Android 플랫폼 설정
├── ios/                       # iOS 플랫폼 설정
├── web/                       # 웹 플랫폼 설정
├── pubspec.yaml              # 프로젝트 의존성
└── README.md                 # 프로젝트 가이드
```

## 🎯 핵심 위젯

### ChatScreen
- 메인 채팅 화면
- 메시지 목록 표시
- 입력 필드 및 전송 버튼
- Gemini AI 서비스 관리

### GeminiService
- Google Gemini AI API 클라이언트
- 자연어 응답 생성
- 오류 처리 및 로깅
- PDF 분석 기능 (준비 중)

### MessageBubble
- 개별 메시지 UI
- 사용자/봇 구분 표시
- 말풍선 스타일 적용

### TypingIndicator
- 타이핑 상태 애니메이션
- 3개 점의 순차적 깜빡임

## 🔧 개발 팁

### Hot Reload 사용
```bash
# 앱 실행 중 'r' 키를 누르면 Hot Reload
# 'R' 키를 누르면 Hot Restart
```

### 디버깅
- Android Studio의 Flutter Inspector 사용
- DevTools를 통한 성능 모니터링
- breakpoint를 설정하여 디버깅

### 플랫폼별 코드
```dart
import 'dart:io';

// 플랫폼 확인
if (Platform.isIOS) {
    // iOS 전용 코드
} else if (Platform.isAndroid) {
    // Android 전용 코드
}
```

## 🚀 향후 개발 계획

1. **PDF 업로드 기능** 
   - 파일 선택기 구현
   - PDF 파서 연동
   - Gemini의 PDF 분석 기능 활용

2. **RAG 시스템 연동**
   - 벡터 데이터베이스 연결
   - 임베딩 생성 및 검색
   - Gemini PDF 분석과 통합

3. **Gemini AI 기능 확장**
   - ✅ 기본 대화 (완료)
   - 🔄 PDF 문서 분석
   - 🔄 이미지 분석
   - 🔄 멀티모달 입력

4. **추가 기능**
   - 대화 내역 저장 (로컬/클라우드)
   - 음성 입력/출력
   - 다국어 지원
   - API 키 보안 강화

## 📝 라이선스

이 프로젝트는 MIT 라이선스 하에 배포됩니다.

## 📞 문의

프로젝트 관련 문의사항이 있으시면 이슈를 생성해주세요.

---

**Happy Coding! 🎉**
