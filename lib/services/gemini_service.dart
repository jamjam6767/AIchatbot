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
  
  // 현재 언어 설정 (기본값: English)
  String _currentLanguage = 'English';
  
  // 대화 히스토리 관리
  List<Content> _conversationHistory = [];
  bool _isFirstMessage = true;  // 첫 번째 메시지 여부

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
  
  // 언어 설정
  void setLanguage(String language) {
    _currentLanguage = language;
    developer.log('언어 변경: $language', name: 'GeminiService');
    // 언어가 변경되면 대화를 새로 시작
    _resetConversation();
  }

  // 현재 언어 반환
  String getCurrentLanguage() => _currentLanguage;
  
  // 대화 초기화
  void _resetConversation() {
    _conversationHistory.clear();
    _isFirstMessage = true;
    developer.log('대화 히스토리 초기화', name: 'GeminiService');
  }
  
  // 앱 재시작 시 대화 초기화 (공개 메서드)
  void resetOnAppRestart() {
    _resetConversation();
    developer.log('앱 재시작으로 인한 대화 초기화', name: 'GeminiService');
  }
  
  // 대화 히스토리에 메시지 추가
  void _addToHistory(String userMessage, String aiResponse) {
    _conversationHistory.add(Content.text('User: $userMessage'));
    _conversationHistory.add(Content.text('AI: $aiResponse'));
    
    // 히스토리가 너무 길어지면 오래된 것들 제거 (최근 10개 대화만 유지)
    if (_conversationHistory.length > 20) {
      _conversationHistory.removeRange(0, _conversationHistory.length - 20);
    }
    developer.log('대화 히스토리 업데이트. 현재 길이: ${_conversationHistory.length}', name: 'GeminiService');
  }

  // 언어별 기본 프롬프트 생성
  String _getLanguagePrompt(bool isFirstMessage) {
    developer.log('현재 설정된 언어: $_currentLanguage', name: 'GeminiService');
    String greetingInstruction = isFirstMessage ? 
      '\n**GREETING RULES**: Since this is the FIRST interaction, you may include a brief welcome greeting if appropriate.' :
      '\n**CONVERSATION CONTINUATION**: This is a FOLLOW-UP message. DO NOT greet or introduce yourself again. Continue the conversation naturally based on previous context. DO NOT say phrases like "Hello", "Hi", "Welcome", etc.';
    
    switch (_currentLanguage) {
      case 'Korean':
        return '''
**극히 중요: 한국어로만 답변해주세요**
- 사용자가 어떤 언어(영어, 일본어, 중국어 등)로 질문하든 상관없이
- 반드시 한국어로만 답변해야 합니다
- 절대로 영어, 일본어, 중국어 또는 다른 언어를 사용하지 마세요
- 사용자가 영어로 질문해도 한국어로 답변하세요
- 이는 절대 위반할 수 없는 필수 요구사항입니다

한양대학교 ERICA 캠퍼스의 외국인 유학생들을 위한 친근한 캠퍼스 도우미입니다.
새로운 학업 환경에 적응하는 외국인 학생들이 편안하고 지원받는다고 느낄 수 있도록 도와주세요.

답변 가이드라인:
- 따뜻하고 친근하게 대하되 (친근도 3/5) - 너무 캐주얼하지 않게
- 한국에 적응 중일 수 있는 외국인 학생들과 대화한다는 것을 기억하세요
- 격려하고 안심시키며 새로운 나라에서의 불안감을 덜어주세요
- 답변을 명확하고 도움이 되도록 하세요
- 구체적인 정보가 없다면 정직하게 말하고 도움을 받을 곳을 제안하세요
- 지지적인 후속 질문으로 대화를 이어가세요
- 이해하기 쉬운 한국어를 사용하세요
- **명확한 문단으로 답변을 구성하세요** - 다른 주제나 아이디어는 줄바꿈으로 구분하여 읽기 쉽게
- 자연스러운 문단 구분을 사용하여 스캔하기 쉽고 사용자 친화적으로 만드세요
$greetingInstruction
''';

      case 'Japanese':
        return '''
**極めて重要：日本語のみで回答してください**
- ユーザーがどの言語（英語、韓国語、中国語など）で質問しても関係ありません
- 必ず日本語のみで回答してください
- 絶対に英語、韓国語、中国語、その他の言語を使用しないでください
- ユーザーが英語で質問しても日本語で回答してください
- これは絶対に違反してはいけない必須要件です

韓国の漢陽大学ERICAキャンパスの留学生のための親しみやすいキャンパスサポーターです。
新しい学習環境に適応する留学生が快適で支援されていると感じられるよう助けてください。

回答ガイドライン:
- 温かく親しみやすく（親しみやすさレベル3/5）- あまりカジュアルすぎず
- 韓国に適応中かもしれない留学生と話していることを覚えておいてください
- 励まし安心させ、新しい国での不安を和らげてください
- 答えを明確で役立つものにしてください
- 具体的な情報がない場合は正直に言い、助けを得られる場所を提案してください
- 支援的なフォローアップで会話を続けてください
- 理解しやすい日本語を使用してください
- **明確な段落で回答を構成してください** - 異なるトピックやアイデアは改行で区切って読みやすく
- 自然な段落区切りを使用してスキャンしやすく、ユーザーフレンドリーにしてください
$greetingInstruction
''';

      case 'Chinese':
        return '''
**极其重要：只能用中文回答**
- 无论用户用什么语言（英语、韩语、日语等）提问都无关紧要
- 您必须始终只用中文回答
- 绝对不要使用英语、韩语、日语或任何其他语言
- 即使用户用英语提问，也要用中文回答
- 这是绝对不能违反的必要要求

您是韩国汉阳大学ERICA校区留学生的友好校园助手。
帮助适应新学习环境的留学生感到舒适和受到支持。

回答指导原则:
- 温暖友好（友好程度3/5）- 不要太随意
- 记住您在与可能正在适应韩国的留学生交谈
- 鼓励和安慰，帮助减少在新国家的焦虑
- 让答案清晰有用
- 如果没有具体信息，请诚实说明并建议哪里可以获得帮助
- 用支持性的后续问题继续对话
- 使用易于理解的中文
- **用清晰的段落构成回答** - 用换行分隔不同主题或想法，便于阅读
- 使用自然的段落分隔，使其易于浏览且用户友好
$greetingInstruction
''';

      case 'Russian':
        return '''
**КРИТИЧЕСКИ ВАЖНО: ОТВЕЧАЙТЕ ТОЛЬКО НА РУССКОМ ЯЗЫКЕ**
- Неважно, на каком языке пользователь задает вопрос (английский, корейский, японский и т.д.)
- ВЫ ДОЛЖНЫ ВСЕГДА отвечать ТОЛЬКО на русском языке
- Никогда не используйте английский, корейский или любой другой язык в своих ответах
- Даже если пользователь пишет на английском языке, отвечайте на русском
- Это обязательное требование, которое нельзя нарушать

Вы дружелюбный помощник кампуса для иностранных студентов Университета Ханян ЭРИКА Кампус.
Помогите иностранным студентам чувствовать себя комфортно и поддержанными в новой академической среде.

Руководящие принципы ответа:
- Будьте теплыми и дружелюбными (уровень дружелюбия 3/5) - поддерживающими, но не слишком неформальными
- Помните, что вы разговариваете с иностранными студентами, которые могут адаптироваться к Корее
- Будьте ободряющими и успокаивающими - помогите уменьшить беспокойство о пребывании в новой стране
- Делайте ответы ясными и полезными
- Если у вас нет конкретной информации, будьте честными и предложите, где они могут найти помощь
- Заканчивайте поддерживающими вопросами для продолжения разговора
- Используйте понятный русский язык
- **Форматируйте ответ четкими абзацами** - разделяйте разные темы или идеи разрывами строк для легкого чтения
- Используйте естественные разрывы абзацев, чтобы сделать ответ удобным для просмотра
$greetingInstruction
''';

      case 'French':
        return '''
**EXTRÊMEMENT IMPORTANT : Répondez uniquement en français**
- Peu importe dans quelle langue (anglais, coréen, japonais, etc.) l'utilisateur pose sa question
- Vous DEVEZ toujours répondre uniquement en français
- N'utilisez jamais l'anglais, le coréen, le japonais ou toute autre langue
- Même si l'utilisateur écrit en anglais, répondez en français
- C'est une exigence obligatoire qui ne peut pas être violée

Vous êtes un assistant de campus amical pour les étudiants internationaux de l'Université Hanyang ERICA Campus.
Aidez les étudiants étrangers à se sentir à l'aise et soutenus dans leur nouvel environnement académique.

Directives de réponse:
- Soyez chaleureux et amical (niveau d'amabilité 3/5) - soutenants mais pas trop décontractés
- Rappelez-vous que vous parlez à des étudiants internationaux qui pourraient s'adapter à la Corée
- Soyez encourageant et rassurant - aidez à réduire l'anxiété d'être dans un nouveau pays
- Gardez les réponses claires et utiles
- Si vous n'avez pas d'informations spécifiques, soyez honnête et suggérez où ils peuvent trouver de l'aide
- Terminez par des questions de suivi soutenantes pour maintenir la conversation
- Utilisez un français facile à comprendre
- **Formatez votre réponse avec des paragraphes clairs** - séparez les différents sujets ou idées avec des sauts de ligne pour une lecture facile
- Utilisez des ruptures de paragraphe naturelles pour rendre votre réponse lisible et conviviale
$greetingInstruction
''';

      default: // English
        return '''
**EXTREMELY IMPORTANT: ALWAYS respond in English only**
- No matter what language (Korean, Japanese, Chinese, etc.) the user asks questions in
- You MUST always respond ONLY in English
- Never use Korean, Japanese, Chinese, or any other language in your responses
- Even if the user writes in Korean, respond in English
- This is a mandatory requirement that cannot be violated

You are a welcoming campus buddy for international students at Hanyang University ERICA Campus. 
Help foreign students feel comfortable and supported while they navigate their new academic environment.

Guidelines:
- Be warm and friendly (friendliness level 3/5) - supportive but not overly casual
- Remember you're talking to international students who might be adjusting to Korea
- Be encouraging and reassuring - help reduce any anxiety about being in a new country
- Keep answers clear and helpful
- If you don't have specific information, be honest and suggest where they might find help
- End with a supportive follow-up to keep them engaged
- Use approachable English that's easy to understand
- **Format your response with clear paragraphs** - separate different topics or ideas with line breaks for easy reading
- Use natural paragraph breaks to make your response scannable and user-friendly
$greetingInstruction
''';
    }
  }

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
      final content = [Content.text('Hello. Please confirm that the Gemini Pro model is working properly.')];
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
      developer.log('첫 번째 메시지 여부: $_isFirstMessage', name: 'GeminiService');
      
      final stylePrompt = _getStylePrompt(_currentStyle);
      
      // 언어별 프롬프트 생성 (첫 번째 메시지 여부 전달)
      final languagePrompt = _getLanguagePrompt(_isFirstMessage);
      
      // 대화 히스토리를 포함한 프롬프트 생성
      String conversationContext = '';
      if (_conversationHistory.isNotEmpty && !_isFirstMessage) {
        conversationContext = '''
=== Previous Conversation Context ===
${_conversationHistory.map((content) => _extractTextFromContent(content)).join('\n')}

=== Current Question ===
''';
      }
      
      final prompt = '''
$languagePrompt

IMPORTANT REMINDER: You must respond in $_currentLanguage ONLY, regardless of the language the user uses to ask questions.

$stylePrompt

$conversationContext
Student question: $message

${_isFirstMessage ? "Let's make this international student feel welcome and supported!" : "Continue the conversation naturally, keeping the context of previous messages."}
''';

      final content = [Content.text(prompt)];
      developer.log('API 요청 전송 중... (언어: $_currentLanguage, 스타일: ${_currentStyle.name}, 첫번째: $_isFirstMessage)', name: 'GeminiService');
      developer.log('생성된 프롬프트 미리보기: ${prompt.substring(0, prompt.length > 300 ? 300 : prompt.length)}...', name: 'GeminiService');
      
      final response = await _model.generateContent(content);
      developer.log('API 응답 받음', name: 'GeminiService');

      if (response.text != null && response.text!.isNotEmpty) {
        final formattedResponse = _formatResponseWithParagraphs(response.text!.trim());
        developer.log('응답 성공: ${response.text!.substring(0, 50)}...', name: 'GeminiService');
        
        // 대화 히스토리에 추가
        _addToHistory(message, formattedResponse);
        
        // 첫 번째 메시지 플래그 업데이트
        _isFirstMessage = false;
        
        return formattedResponse;
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
      developer.log('첫 번째 메시지 여부: $_isFirstMessage', name: 'GeminiService');
      
      final stylePrompt = _getStylePrompt(_currentStyle);
      
      // 언어별 프롬프트 생성 (첫 번째 메시지 여부 전달)
      final languagePrompt = _getLanguagePrompt(_isFirstMessage);
      
      // 대화 히스토리를 포함한 프롬프트 생성
      String conversationContext = '';
      if (_conversationHistory.isNotEmpty && !_isFirstMessage) {
        conversationContext = '''
=== Previous Conversation Context ===
${_conversationHistory.map((content) => _extractTextFromContent(content)).join('\n')}

=== Current Question ===
''';
      }
      
      final prompt = '''
$languagePrompt

CRITICAL REMINDER: You must respond in $_currentLanguage ONLY, no matter what language the user asks in.

You are a friendly campus buddy chatbot for international students at Hanyang University ERICA Campus. Your mission is to help foreign students feel welcome and comfortable while navigating campus life using official university documents.

=== Official University Documents ===
$pdfContext

$conversationContext
=== Student Question ===
$message

=== Additional Guidelines ===
- **Answer ONLY based on official PDF documents** - Never guess or make up information
- **Include helpful contact information** - Provide department numbers or official contacts when relevant
- **Vary your responses naturally** - Don't end every message the same way
- **Check for understanding** - Ask "Does this help?" occasionally
- **Keep the conversation flowing** - End with welcoming follow-ups

$stylePrompt

${_isFirstMessage ? "Remember: You're here to be a supportive friend helping international students feel at home at ERICA Campus!" : "Continue the conversation naturally, keeping the context of previous messages while using the PDF information."}
''';

      final content = [Content.text(prompt)];
      final response = await _model.generateContent(content);

      if (response.text != null && response.text!.isNotEmpty) {
        final formattedResponse = _formatResponseWithParagraphs(response.text!.trim());
        developer.log('PDF 기반 응답 생성 성공', name: 'GeminiService');
        
        // 대화 히스토리에 추가
        _addToHistory(message, formattedResponse);
        
        // 첫 번째 메시지 플래그 업데이트
        _isFirstMessage = false;
        
        return formattedResponse;
      } else {
        developer.log('빈 응답 수신', name: 'GeminiService');
        return 'Sorry, I cannot analyze the PDF documents.';
      }
    } catch (e) {
      developer.log('Gemini PDF Analysis Error: $e', name: 'GeminiService');
      return 'Sorry, an error occurred while analyzing the documents.';
    }
  }
  
  // 응답을 문단별로 나누어 읽기 편하게 포맷팅
  String _formatResponseWithParagraphs(String response) {
    // 이미 잘 포맷된 응답은 그대로 반환
    if (response.contains('\n\n')) {
      return response;
    }
    
    // 문장을 나누어 문단 생성
    List<String> sentences = response.split('. ');
    List<String> paragraphs = [];
    String currentParagraph = '';
    
    for (int i = 0; i < sentences.length; i++) {
      String sentence = sentences[i].trim();
      if (sentence.isEmpty) continue;
      
      // 마지막 문장이 아니라면 마침표 추가
      if (i < sentences.length - 1 && !sentence.endsWith('.')) {
        sentence += '.';
      }
      
      // 현재 문단에 문장 추가
      if (currentParagraph.isEmpty) {
        currentParagraph = sentence;
      } else {
        currentParagraph += ' ' + sentence;
      }
      
      // 문단이 너무 길거나 특정 조건에서 문단 나누기
      if (currentParagraph.length > 150 || 
          sentence.contains('?') || 
          sentence.contains('!') ||
          (i > 0 && i % 2 == 0)) {
        paragraphs.add(currentParagraph);
        currentParagraph = '';
      }
    }
    
    // 남은 문장이 있다면 추가
    if (currentParagraph.isNotEmpty) {
      paragraphs.add(currentParagraph);
    }
    
    // 문단들을 두 줄 바꿈으로 연결
    return paragraphs.join('\n\n');
  }

  // Content에서 텍스트를 추출하는 헬퍼 함수
  String _extractTextFromContent(Content content) {
    final parts = content.parts;
    for (final part in parts) {
      if (part is TextPart) {
        return part.text;
      }
      // 다른 타입의 Part인 경우 toString() 사용
      try {
        final partStr = part.toString();
        if (partStr.isNotEmpty && !partStr.startsWith('Instance of')) {
          return partStr;
        }
      } catch (e) {
        // toString() 실패 시 무시
      }
    }
    return '';
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
        return _formatResponseWithParagraphs(response.text!.trim());
      } else {
        return 'Sorry, I cannot generate a response with the custom prompt.';
      }
    } catch (e) {
      developer.log('커스텀 응답 생성 오류: $e', name: 'GeminiService');
      return 'Sorry, an error occurred while generating a custom response.';
    }
  }
} 