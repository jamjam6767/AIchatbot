import 'package:google_generative_ai/google_generative_ai.dart';
import 'dart:developer' as developer;

class GeminiService {
  static const String _apiKey = 'AIzaSyD_bsFM68w0v-ecfcoCgSgjGzzXwKdbVDI';
  late final GenerativeModel _model;

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
      
      // PDF 문서 컨텍스트를 포함한 프롬프트 생성
      final prompt = '''
You are a friendly AI assistant that communicates in English.
Please provide accurate and helpful answers to user questions.
If questions are about PDF documents, find relevant information and answer them.

User question: $message

Please follow these rules for your answer:
1. Answer in friendly and natural English
2. Provide accurate information
3. Guide additional questions if necessary
4. Keep answers concise within 150 words
''';

      final content = [Content.text(prompt)];
      developer.log('API 요청 전송 중...', name: 'GeminiService');
      
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
      
      final prompt = '''
You are a professional AI assistant for Hanyang University ERICA Campus. Based on the orientation materials and academic guides provided below, please answer student questions accurately and concisely.

=== Reference Documents (Hanyang ERICA Orientation Materials) ===
$pdfContext

=== User Question ===
$message

=== Answer Guidelines ===
1. Refer to the Hanyang ERICA documents accurately and provide specific answers
2. Include concrete information like dates, times, locations, and procedures
3. Focus on course registration, academic schedules, orientation, and exchange programs
4. Provide helpful answers based on related content even if direct information isn't available
5. Emphasize important information or precautions students shouldn't miss
6. Use a friendly yet professional tone
7. Provide relevant department or contact information when necessary
8. Only say "Related information cannot be found in the provided materials" when truly irrelevant
9. Keep answers concise within 200 words

Answer for Hanyang ERICA students:
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
} 