import 'package:google_generative_ai/google_generative_ai.dart';
import 'dart:developer' as developer;

// 답변 스타일 열거형
enum ResponseStyle {
  concise,    // 간결한 답변
  detailed,   // 상세한 답변
  bullet,     // 불릿 포인트 형식
  stepByStep, // 단계별 설명
  casual,     // 캐주얼한 톤
  formal,     // 공식적인 톤
}

class GeminiService {
  static const String _apiKey = 'AIzaSyD_bsFM68w0v-ecfcoCgSgjGzzXwKdbVDI';
  late final GenerativeModel _model;
  
  // 현재 답변 스타일 (기본값: 간결)
  ResponseStyle _currentStyle = ResponseStyle.concise;

  GeminiService() {
    developer.log('GeminiService 초기화 중 (유료 Pro 모델)... API 키: ${_apiKey.substring(0, 10)}...', name: 'GeminiService');
    _model = GenerativeModel(
      model: 'gemini-1.5-pro',  // 유료 버전: Pro 모델 사용
      apiKey: _apiKey,
      generationConfig: GenerationConfig(
        temperature: 0.7,  // 더 안정적인 응답을 위해 조정
        topK: 40,         // 유료 버전에서 더 넓은 범위
        topP: 0.95,       // 더 정확한 응답
        maxOutputTokens: 8192,  // 유료 버전: 8K 토큰까지 가능
      ),
      safetySettings: [
        SafetySetting(HarmCategory.harassment, HarmBlockThreshold.high),
        SafetySetting(HarmCategory.hateSpeech, HarmBlockThreshold.high),
        SafetySetting(HarmCategory.sexuallyExplicit, HarmBlockThreshold.high),
        SafetySetting(HarmCategory.dangerousContent, HarmBlockThreshold.high),
      ],
    );
    developer.log('GeminiService 초기화 완료', name: 'GeminiService');
  }

  // 답변 스타일 설정
  void setResponseStyle(ResponseStyle style) {
    _currentStyle = style;
    developer.log('답변 스타일 변경: ${style.name}', name: 'GeminiService');
  }

  // 현재 답변 스타일 반환
  ResponseStyle getCurrentStyle() => _currentStyle;

  // 스타일별 프롬프트 생성
  String _getStylePrompt(ResponseStyle style) {
    switch (style) {
      case ResponseStyle.concise:
        return '''
RESPONSE STYLE: QUICK & HELPFUL
- Give short, clear answers (50-100 words) that get straight to the point
- Focus on what international students need to know most
- Use simple, easy-to-understand English
- Include essential info but skip unnecessary details
- End with supportive phrases like "Hope this helps!" or "Need anything else?"
''';

      case ResponseStyle.detailed:
        return '''
RESPONSE STYLE: THOROUGH EXPLANATION
- Provide comprehensive explanations (200-400 words)
- Include background context that helps international students understand Korean academic systems
- Cover different aspects they might be wondering about
- Add practical examples or real scenarios they might encounter
- End with encouraging phrases like "Does this make sense?" or "Feel free to ask if anything's unclear!"
''';

      case ResponseStyle.bullet:
        return '''
RESPONSE STYLE: EASY-TO-SCAN FORMAT
- Format answers using bullet points (•) for quick reading
- One clear, important point per bullet
- Keep each point informative but easy to digest
- Use sub-bullets for additional helpful details
- Maximum 5-7 main points
- End with "Any of these points you'd like me to explain more?"
''';

      case ResponseStyle.stepByStep:
        return '''
RESPONSE STYLE: GUIDED WALKTHROUGH
- Break down processes into clear, numbered steps
- Start with encouraging phrases like "Here's how to do it..." or "Let me guide you through this..."
- Each step should be clear and manageable for someone new to Korea
- Include what to prepare or bring beforehand
- Add helpful tips or cultural notes when relevant
- End with "Let me know if you need help with any of these steps!"
''';

      case ResponseStyle.casual:
        return '''
RESPONSE STYLE: FRIENDLY CONVERSATION
- Talk like a supportive friend helping them settle in
- Use warm expressions like "Hey there!", "Sure thing!", "No problem at all!"
- Use natural contractions (don't, won't, can't) but keep it clear
- Add occasional friendly emojis to make it welcoming
- Sound approachable and understanding of their situation
- End with "Hope this helps you feel more settled! What else can I help with?"
''';

      case ResponseStyle.formal:
        return '''
RESPONSE STYLE: CLEAR & PROFESSIONAL
- Use clear, professional English that's easy for non-native speakers
- Avoid overly casual language but remain welcoming
- Structure information in a logical, easy-to-follow way
- Be respectful and considerate of cultural differences
- Sound knowledgeable but approachable
- End with "Please don't hesitate to ask if you need any clarification!"
''';

      default:
        return '';
    }
  }

  // API 연결 테스트 함수
  Future<bool> testConnection() async {
    try {
      developer.log('Gemini Pro 모델 API 연결 테스트 시작', name: 'GeminiService');
      final content = [Content.text('안녕하세요. Gemini Pro 모델이 정상적으로 작동하는지 확인해주세요.')];
      final response = await _model.generateContent(content);
      developer.log('Gemini Pro API 연결 테스트 성공', name: 'GeminiService');
      return response.text != null && response.text!.isNotEmpty;
    } catch (e) {
      developer.log('Gemini Pro API 연결 테스트 실패: $e', name: 'GeminiService');
      return false;
    }
  }

  Future<String> generateResponse(String message) async {
    try {
      developer.log('Gemini API 호출 시작: $message', name: 'GeminiService');
      
      final stylePrompt = _getStylePrompt(_currentStyle);
      
      // 외국인 유학생 친화적 프롬프트 생성
      final prompt = '''
You are a welcoming campus buddy for international students at Hanyang University ERICA Campus. 
Help foreign students feel comfortable and supported while they navigate their new academic environment.

$stylePrompt

Student question: $message

Guidelines:
- Be warm and friendly (friendliness level 3/5) - supportive but not overly casual
- Remember you're talking to international students who might be adjusting to Korea
- Be encouraging and reassuring - help reduce any anxiety about being in a new country
- Keep answers clear and helpful
- If you don't have specific information, be honest and suggest where they might find help
- End with a supportive follow-up to keep them engaged
- Use approachable English that's easy to understand

Let's make this international student feel welcome and supported!
''';

      final content = [Content.text(prompt)];
      developer.log('API 요청 전송 중... (스타일: ${_currentStyle.name})', name: 'GeminiService');
      
      final response = await _model.generateContent(content);
      developer.log('API 응답 받음', name: 'GeminiService');

      if (response.text != null && response.text!.isNotEmpty) {
        developer.log('응답 성공: ${response.text!.substring(0, 50)}...', name: 'GeminiService');
        return response.text!.trim();
      } else {
        developer.log('빈 응답 수신', name: 'GeminiService');
        return 'Sorry, I cannot generate a response. Please try again.';
      }
    } catch (e) {
      developer.log('Gemini API Error 세부사항: $e', name: 'GeminiService');
      // Check for network errors
      if (e.toString().contains('SocketException')) {
        return '❌ Please check your internet connection. Network error occurred.';
      } else if (e.toString().contains('401') || e.toString().contains('403')) {
        return '❌ API key error. Please contact the administrator.';
      } else {
        return '❌ API connection error: ${e.toString().substring(0, 50)}...';
      }
    }
  }

  Future<String> generatePDFResponse(String message, String pdfContext) async {
    try {
      developer.log('PDF 컨텍스트와 함께 응답 생성 시작', name: 'GeminiService');
      developer.log('PDF 컨텍스트 길이: ${pdfContext.length}자', name: 'GeminiService');
      developer.log('사용자 질문: $message', name: 'GeminiService');
      
      final stylePrompt = _getStylePrompt(_currentStyle);
      
      final prompt = '''
You are a friendly campus buddy chatbot for international students at Hanyang University ERICA Campus. Your mission is to help foreign students feel welcome and comfortable while navigating campus life using official university documents.

=== Official University Documents ===
$pdfContext

=== Student Question ===
$message

=== Your Personality & Guidelines ===
1. **Answer ONLY based on official PDF documents** - Never guess or make up information
2. **Be warm and welcoming** - Use a friendly tone (friendliness level 3/5) - not too casual, not too formal
3. **Remember your audience** - These are international students who might be new to Korea and feeling overwhelmed
4. **Be reassuring and supportive** - Help them feel less anxious about being in a new country
5. **Explain things clearly** - Some students might not be familiar with Korean academic systems
6. **Include helpful contact information** - Provide department numbers or official contacts when relevant
7. **Vary your responses naturally** - Don't end every message the same way
8. **Check for understanding** - Ask "Does this help?" or "Is there anything unclear?" occasionally
9. **Keep the conversation flowing** - End with welcoming follow-ups like "What else can I help you with?" or "Any other questions about campus life?"

$stylePrompt

Remember: You're here to be a supportive friend helping international students feel at home at ERICA Campus!
''';

      final content = [Content.text(prompt)];
      final response = await _model.generateContent(content);

      if (response.text != null && response.text!.isNotEmpty) {
        developer.log('PDF 기반 응답 생성 성공', name: 'GeminiService');
        return response.text!.trim();
      } else {
        developer.log('빈 응답 수신', name: 'GeminiService');
        return 'Sorry, I cannot analyze the PDF documents.';
      }
    } catch (e) {
      developer.log('Gemini PDF Analysis Error: $e', name: 'GeminiService');
      return 'Sorry, an error occurred while analyzing the documents.';
    }
  }
  
  // 커스텀 프롬프트로 응답 생성
  Future<String> generateCustomResponse(String message, String customPrompt, String pdfContext) async {
    try {
      developer.log('커스텀 프롬프트로 응답 생성 시작', name: 'GeminiService');
      
      final prompt = '''
$customPrompt

=== Reference Documents ===
$pdfContext

=== User Question ===
$message

Please answer according to the custom instructions above.
''';

      final content = [Content.text(prompt)];
      final response = await _model.generateContent(content);

      if (response.text != null && response.text!.isNotEmpty) {
        developer.log('커스텀 응답 생성 성공', name: 'GeminiService');
        return response.text!.trim();
      } else {
        return 'Sorry, I cannot generate a response with the custom prompt.';
      }
    } catch (e) {
      developer.log('커스텀 응답 생성 오류: $e', name: 'GeminiService');
      return 'Sorry, an error occurred while generating a custom response.';
    }
  }
} 