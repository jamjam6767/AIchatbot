import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:io';
import 'services/gemini_service.dart';
import 'services/pdf_service.dart';

void main() {
  runApp(const ChatBotApp());
}

class ChatBotApp extends StatelessWidget {
  const ChatBotApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AI Chatbot',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF3B82F6),
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: const Color(0xFFF5F5F5),
        fontFamily: Platform.isIOS ? 'SF Pro Display' : 'Roboto',
        textTheme: const TextTheme(
          bodyLarge: TextStyle(
            fontSize: 16,
            color: Color(0xFF1F2937),
            fontWeight: FontWeight.w400,
          ),
          bodyMedium: TextStyle(
            fontSize: 14,
            color: Color(0xFF6B7280),
            fontWeight: FontWeight.w400,
          ),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF3B82F6),
          foregroundColor: Colors.white,
          elevation: 0,
          centerTitle: true,
          systemOverlayStyle: SystemUiOverlayStyle(
            statusBarColor: Color(0xFF3B82F6),
            statusBarIconBrightness: Brightness.light,
            statusBarBrightness: Brightness.dark,
          ),
          titleTextStyle: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFFF9FAFB),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: const BorderSide(
              color: Color(0xFFE5E7EB),
              width: 1,
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: const BorderSide(
              color: Color(0xFFE5E7EB),
              width: 1,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: const BorderSide(
              color: Color(0xFF3B82F6),
              width: 2,
            ),
          ),
        ),
      ),
      home: const ChatScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen>
    with TickerProviderStateMixin {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];
  bool _isTyping = false;
  late AnimationController _typingAnimationController;
  late GeminiService _geminiService;
  late PDFService _pdfService;
  
  // PDF 컨텍스트 저장
  String _pdfContext = '';
  bool _isPDFLoaded = false;
  
  // 언어 설정
  String? _selectedLanguage;
  bool _isLanguageSet = false;

  @override
  void initState() {
    super.initState();
    _typingAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();
    
    // 서비스 초기화
    _geminiService = GeminiService();
    _pdfService = PDFService();
    
    // 앱 시작 시 초기화
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _initializeApp();
    });
  }

  @override
  void dispose() {
    _typingAnimationController.dispose();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _initializeApp() async {
    try {
      // 백그라운드에서 PDF 로드
      _pdfContext = await _pdfService.loadAssetPDFs();
      _isPDFLoaded = true;
      
      print('DEBUG: PDF 컨텍스트 로드 완료, 길이: ${_pdfContext.length}자');
      
      // API 연결 테스트
      final isConnected = await _geminiService.testConnection();
      
      // 언어 선택 요청 메시지
      if (isConnected) {
        _addMessage(ChatMessage(
          text: "Hello! 👋 안녕하세요! こんにちは! 你好! Привет! Bonjour!\n\nI'm your AI assistant for Hanyang University ERICA Campus.\n\nWhich language would you prefer for our conversation?\n\n1. 🇺🇸 English\n2. 🇰🇷 한국어 (Korean)\n3. 🇯🇵 日本語 (Japanese)\n4. 🇨🇳 中文 (Chinese)\n5. 🇷🇺 Русский (Russian)\n6. 🇫🇷 Français (French)\n\nJust type the number (1-6) or language name! 😊",
          isUser: false,
          timestamp: DateTime.now(),
        ));
      } else {
        _addMessage(ChatMessage(
          text: "Hello! 👋 I'm your AI assistant for Hanyang University ERICA Campus.\n\nI'm having trouble connecting to the network right now. Please check your internet connection and try again.",
          isUser: false,
          timestamp: DateTime.now(),
        ));
      }
    } catch (e) {
      print('DEBUG: 초기화 실패: $e');
      _addMessage(ChatMessage(
        text: "Hello! 👋 I'm your AI assistant for Hanyang University ERICA Campus.\n\nI'm having some trouble initializing all features right now, but I can still help you with basic questions.\n\nWhat can I help you with today?",
        isUser: false,
        timestamp: DateTime.now(),
      ));
    }
  }

  void _addMessage(ChatMessage message) {
    setState(() {
      _messages.add(message);
    });
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  // 언어 변경 요청 감지 및 처리
  String? _detectLanguageChangeRequest(String userInput) {
    final input = userInput.toLowerCase().trim();
    
    // 특정 언어로 변경 요청
    if (input.contains('영어로') || input.contains('english로') || 
        input.contains('change to english') || input.contains('switch to english')) {
      return 'English';
    }
    if (input.contains('한국어로') || input.contains('korean로') || 
        input.contains('change to korean') || input.contains('switch to korean')) {
      return 'Korean';
    }
    if (input.contains('일본어로') || input.contains('japanese로') || 
        input.contains('change to japanese') || input.contains('switch to japanese') ||
        input.contains('日本語に')) {
      return 'Japanese';
    }
    if (input.contains('중국어로') || input.contains('chinese로') || 
        input.contains('change to chinese') || input.contains('switch to chinese') ||
        input.contains('中文')) {
      return 'Chinese';
    }
    if (input.contains('러시아어로') || input.contains('russian로') || 
        input.contains('change to russian') || input.contains('switch to russian') ||
        input.contains('на русский')) {
      return 'Russian';
    }
    if (input.contains('프랑스어로') || input.contains('french로') || 
        input.contains('change to french') || input.contains('switch to french') ||
        input.contains('en français')) {
      return 'French';
    }
    
    // 일반적인 언어 변경 요청 (언어 선택 메뉴로 이동)
    List<String> generalChangeKeywords = [
      // English
      'change language', 'switch language', 'language change', 'different language',
      'choose language', 'select language', 'language setting', 'language option',
      
      // Korean
      '언어 변경', '언어 바꾸기', '언어 선택', '언어 설정', '다른 언어',
      
      // Japanese  
      '言語変更', '言語を変える', '言語選択', '言語設定', '他の言語',
      
      // Chinese
      '语言更改', '更改语言', '语言选择', '语言设置', '其他语言', '换语言',
      
      // Russian
      'изменить язык', 'сменить язык', 'выбрать язык', 'другой язык',
      
      // French
      'changer langue', 'modifier langue', 'choisir langue', 'autre langue'
    ];
    
    if (generalChangeKeywords.any((keyword) => input.contains(keyword))) {
      return 'MENU'; // 언어 선택 메뉴 표시
    }
    
    return null; // 언어 변경 요청 없음
  }

  // 언어 변경 확인 메시지 생성
  String _getLanguageChangeMessage(String newLanguage) {
    switch (newLanguage) {
      case 'English':
        return "언어 설정이 English로 변경되었어. 무엇을 도와줄까?";
      case 'Korean':
        return "언어 설정이 한국어로 변경되었어. 무엇을 도와줄까?";
      case 'Japanese':
        return "言語設定が日本語に変更されました。何をお手伝いしましょうか？";
      case 'Chinese':
        return "语言设置已更改为中文。需要我帮什么忙吗？";
      case 'Russian':
        return "Настройка языка изменена на русский. Чем могу помочь?";
      case 'French':
        return "Configuration linguistique changée en français. Que puis-je faire pour vous?";
      default:
        return "Language changed. How can I help you?";
    }
  }

  // 언어 감지 및 설정
  bool _detectAndSetLanguage(String userInput) {
    final input = userInput.toLowerCase().trim();
    
    print('DEBUG: 사용자 입력: "$input"');
    
    if (input == '1' || input.contains('english') || input.contains('eng')) {
      _selectedLanguage = 'English';
      _geminiService.setLanguage('English');
      print('DEBUG: English 언어 설정 완료');
      return true;
    } else if (input == '2' || input.contains('한국어') || input.contains('korean') || input.contains('kor')) {
      _selectedLanguage = 'Korean';
      _geminiService.setLanguage('Korean');
      print('DEBUG: Korean 언어 설정 완료');
      return true;
    } else if (input == '3' || input.contains('日本語') || input.contains('japanese') || input.contains('jpn')) {
      _selectedLanguage = 'Japanese';
      _geminiService.setLanguage('Japanese');
      print('DEBUG: Japanese 언어 설정 완료');
      return true;
    } else if (input == '4' || input.contains('中文') || input.contains('chinese') || input.contains('chn')) {
      _selectedLanguage = 'Chinese';
      _geminiService.setLanguage('Chinese');
      print('DEBUG: Chinese 언어 설정 완료');
      return true;
    } else if (input == '5' || input.contains('русский') || input.contains('russian') || input.contains('rus')) {
      _selectedLanguage = 'Russian';
      _geminiService.setLanguage('Russian');
      print('DEBUG: Russian 언어 설정 완료');
      return true;
    } else if (input == '6' || input.contains('français') || input.contains('french') || input.contains('fra') || input.contains('francais')) {
      _selectedLanguage = 'French';
      _geminiService.setLanguage('French');
      print('DEBUG: French 언어 설정 완료');
      return true;
    }
    
    print('DEBUG: 언어를 인식하지 못함');
    return false;
  }

  // 언어별 환영 메시지
  String _getWelcomeMessage(String language) {
    switch (language) {
      case 'English':
        return "English 설정이 완료되었어. 무엇을 도와줄까?";
      case 'Korean':
        return "한국어 설정이 완료되었어. 무엇을 도와줄까?";
      case 'Japanese':
        return "言語設定が完了しました。何をお手伝いしましょうか？";
      case 'Chinese':
        return "中文设置完成了。需要我帮什么忙吗？";
      case 'Russian':
        return "Настройка русского языка завершена. Чем могу помочь?";
      case 'French':
        return "Configuration du français terminée. Que puis-je faire pour vous?";
      default:
        return "Language set! How can I help you today?";
    }
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;

    // 햅틱 피드백
    HapticFeedback.lightImpact();

    final userMessage = ChatMessage(
      text: _messageController.text.trim(),
      isUser: true,
      timestamp: DateTime.now(),
    );

    _addMessage(userMessage);
    final userText = _messageController.text.trim();
    _messageController.clear();

    // 언어가 설정되지 않은 경우 언어 설정 처리
    if (!_isLanguageSet) {
      if (_detectAndSetLanguage(userText)) {
        _isLanguageSet = true;
        
        _addMessage(ChatMessage(
          text: _getWelcomeMessage(_selectedLanguage!),
          isUser: false,
          timestamp: DateTime.now(),
        ));
        return;
      } else {
        // 언어를 인식하지 못한 경우
        _addMessage(ChatMessage(
          text: "I didn't understand that language choice. Please type:\n\n1 for English 🇺🇸\n2 for 한국어 🇰🇷\n3 for 日본語 🇯🇵\n4 for 중文 🇨🇳\n5 for Русский 🇷🇺\n6 for Français 🇫🇷\n\nOr type the language name directly! 😊",
          isUser: false,
          timestamp: DateTime.now(),
        ));
        return;
      }
    }

    // 언어 변경 요청 처리
    String? languageChangeRequest = _detectLanguageChangeRequest(userText);
    if (languageChangeRequest != null) {
      if (languageChangeRequest == 'MENU') {
        // 일반적인 언어 변경 요청 - 메뉴 표시
        _isLanguageSet = false;
        _selectedLanguage = null;
        
        _addMessage(ChatMessage(
          text: "Hello! 👋 안녕하세요! こんにちは! 你好! Привет! Bonjour!\n\nWhich language would you prefer for our conversation?\n\n1. 🇺🇸 English\n2. 🇰🇷 한국어 (Korean)\n3. 🇯🇵 日本語 (Japanese)\n4. 🇨🇳 中문 (Chinese)\n5. 🇷🇺 Русский (Russian)\n6. 🇫🇷 Français (French)\n\nJust type the number (1-6) or language name! 😊",
          isUser: false,
          timestamp: DateTime.now(),
        ));
        return;
      } else {
        // 특정 언어로 직접 변경 요청
        _selectedLanguage = languageChangeRequest;
        _geminiService.setLanguage(languageChangeRequest);
        
        _addMessage(ChatMessage(
          text: _getLanguageChangeMessage(languageChangeRequest),
          isUser: false,
          timestamp: DateTime.now(),
        ));
        return;
      }
    }

    // 타이핑 상태 시작
    setState(() {
      _isTyping = true;
    });

    // Generate Gemini AI response (always include PDF context)
    try {
      String botResponse;
      
      if (_isPDFLoaded && _pdfContext.isNotEmpty) {
        // Generate response with PDF context
        botResponse = await _geminiService.generatePDFResponse(userText, _pdfContext);
      } else {
        // General conversation
        botResponse = await _geminiService.generateResponse(userText);
      }
      
      // 타이핑 상태 종료
      if (mounted) {
        setState(() {
          _isTyping = false;
        });
      }
      
      _addMessage(ChatMessage(
        text: botResponse,
        isUser: false,
        timestamp: DateTime.now(),
      ));
    } catch (e) {
      // 타이핑 상태 종료 (에러 시에도)
      if (mounted) {
        setState(() {
          _isTyping = false;
        });
      }
      
      // 설정된 언어에 따른 에러 메시지
      String errorMessage;
      switch (_selectedLanguage) {
        case 'Korean':
          errorMessage = "죄송합니다! 문제가 발생했습니다. 😅 다시 질문해 주시겠어요? 계속 문제가 발생하면 알려주세요!";
          break;
        case 'Japanese':
          errorMessage = "申し訳ございません！問題が発生しました。😅 もう一度質問していただけますか？問題が続く場合はお知らせください！";
          break;
        case 'Chinese':
          errorMessage = "抱歉！出现了问题。😅 您能再问一次吗？如果问题持续出现，请告诉我！";
          break;
        case 'Russian':
          errorMessage = "Извините! Что-то пошло не так. 😅 Не могли бы вы спросить еще раз? Если проблема продолжается, дайте мне знать!";
          break;
        case 'French':
          errorMessage = "Désolé! Quelque chose s'est mal passé. 😅 Pourriez-vous reposer votre question? Si le problème persiste, faites-le moi savoir!";
          break;
        default:
          errorMessage = "Sorry! Something went wrong on my end. 😅 Could you try asking that again? If this keeps happening, just let me know!";
      }
      
      _addMessage(ChatMessage(
        text: errorMessage,
        isUser: false,
        timestamp: DateTime.now(),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ERICA Campus Buddy'),
        actions: [
          IconButton(
            icon: const Icon(Icons.tune),
            onPressed: () => _showStyleSelector(),
            tooltip: 'Response Style',
          ),
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () => _showAppInfo(),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // PDF loaded status indicator
            if (_isPDFLoaded) _buildPDFLoadedIndicator(),
            
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.all(16),
                itemCount: _messages.length + (_isTyping ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index == _messages.length && _isTyping) {
                    return _buildTypingIndicator();
                  }
                  return _buildMessageBubble(_messages[index]);
                },
              ),
            ),
            _buildMessageInput(),
          ],
        ),
      ),
    );
  }

  // PDF loaded completion indicator widget
  Widget _buildPDFLoadedIndicator() {
    return Container(
      margin: const EdgeInsets.all(8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF0FDF4),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF22C55E), width: 1),
      ),
      child: const Row(
        children: [
          Icon(Icons.check_circle, color: Color(0xFF22C55E), size: 16),
          SizedBox(width: 8),
          Text(
            '📄 Official documents loaded - I can reference them for accurate answers',
            style: TextStyle(
              color: Color(0xFF22C55E),
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment:
            message.isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!message.isUser) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: const Color(0xFF3B82F6),
              child: const Icon(
                Icons.smart_toy,
                size: 18,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.75,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: message.isUser
                    ? const Color(0xFF3B82F6)
                    : const Color(0xFFE5E7EB),
                borderRadius: BorderRadius.circular(18).copyWith(
                  bottomLeft: message.isUser
                      ? const Radius.circular(18)
                      : const Radius.circular(4),
                  bottomRight: message.isUser
                      ? const Radius.circular(4)
                      : const Radius.circular(18),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Text(
                message.text,
                style: TextStyle(
                  color: message.isUser ? Colors.white : const Color(0xFF1F2937),
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                  height: 1.4,
                ),
              ),
            ),
          ),
          if (message.isUser) ...[
            const SizedBox(width: 8),
            CircleAvatar(
              radius: 16,
              backgroundColor: const Color(0xFF6B7280),
              child: const Icon(
                Icons.person,
                size: 18,
                color: Colors.white,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: const Color(0xFF3B82F6),
            child: const Icon(
              Icons.smart_toy,
              size: 18,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFE5E7EB),
              borderRadius: BorderRadius.circular(18).copyWith(
                bottomLeft: const Radius.circular(4),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: AnimatedBuilder(
              animation: _typingAnimationController,
              builder: (context, child) {
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(3, (index) {
                    final delay = index * 0.2;
                    final animationValue = Curves.easeInOut.transform(
                      ((_typingAnimationController.value + delay) % 1.0),
                    );
                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: Color.lerp(
                          const Color(0xFF9CA3AF),
                          const Color(0xFF3B82F6),
                          animationValue,
                        ),
                        shape: BoxShape.circle,
                      ),
                    );
                  }),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: 16 + MediaQuery.of(context).padding.bottom,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(
            color: Color(0xFFE5E7EB),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              decoration: const InputDecoration(
                hintText: 'Ask me anything about campus life...',
                hintStyle: TextStyle(
                  color: Color(0xFF9CA3AF),
                  fontSize: 16,
                ),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
              ),
              maxLines: null,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _sendMessage(),
              style: const TextStyle(
                fontSize: 16,
                color: Color(0xFF1F2937),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Material(
            color: const Color(0xFF3B82F6),
            borderRadius: BorderRadius.circular(20),
            child: InkWell(
              onTap: _sendMessage,
              borderRadius: BorderRadius.circular(20),
              child: Container(
                width: 40,
                height: 40,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.send,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 답변 스타일 선택 다이얼로그
  void _showStyleSelector() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Choose Response Style'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: ResponseStyle.values.map((style) {
                return ListTile(
                  leading: Radio<ResponseStyle>(
                    value: style,
                    groupValue: _geminiService.getCurrentStyle(),
                    onChanged: (ResponseStyle? value) {
                      if (value != null) {
                        setState(() {
                          _geminiService.setResponseStyle(value);
                        });
                        Navigator.pop(context);
                        // 언어별 스타일 변경 확인 메시지
                        String confirmMessage;
                        switch (_selectedLanguage) {
                          case 'Korean':
                            confirmMessage = "스타일이 변경되었어. 무엇을 도와줄까?";
                            break;
                          case 'Japanese':
                            confirmMessage = "スタイルが変更されました。何をお手伝いしましょうか？";
                            break;
                          case 'Chinese':
                            confirmMessage = "风格已更改。需要我帮什么忙吗？";
                            break;
                          case 'Russian':
                            confirmMessage = "Стиль изменен. Чем могу помочь?";
                            break;
                          case 'French':
                            confirmMessage = "Style modifié. Que puis-je faire pour vous?";
                            break;
                          default:
                            confirmMessage = "Style changed. How can I help?";
                        }
                        
                        _addMessage(ChatMessage(
                          text: confirmMessage,
                          isUser: false,
                          timestamp: DateTime.now(),
                        ));
                      }
                    },
                  ),
                  title: Text(_getStyleName(style)),
                  subtitle: Text(_getStyleDescription(style)),
                );
              }).toList(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  // 스타일 이름 반환
  String _getStyleName(ResponseStyle style) {
    switch (style) {
      case ResponseStyle.concise:
        return 'Quick & Helpful';
      case ResponseStyle.detailed:
        return 'Detailed Explanation';
      case ResponseStyle.bullet:
        return 'Easy-to-Scan';
      case ResponseStyle.stepByStep:
        return 'Step-by-Step Guide';
      case ResponseStyle.casual:
        return 'Friendly Chat';
      case ResponseStyle.formal:
        return 'Clear & Professional';
    }
  }

  // 스타일 설명 반환
  String _getStyleDescription(ResponseStyle style) {
    switch (style) {
      case ResponseStyle.concise:
        return 'Short, straight-to-the-point answers (50-100 words)';
      case ResponseStyle.detailed:
        return 'Comprehensive explanations with context (200-400 words)';
      case ResponseStyle.bullet:
        return 'Organized bullet points for easy reading';
      case ResponseStyle.stepByStep:
        return 'Clear numbered steps with helpful guidance';
      case ResponseStyle.casual:
        return 'Warm, friendly conversation style';
      case ResponseStyle.formal:
        return 'Professional but approachable tone';
    }
  }

  void _showAppInfo() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('ERICA Campus Buddy'),
          content: const Text(
            'Your friendly AI campus guide for international students at Hanyang University ERICA Campus.\n\n• Natural conversation interface\n• Real-time AI-powered responses\n• Automatic reference to official documents\n• Customizable response styles\n• Support for students new to Korea\n\n🌍 Designed for international students\n📚 Accurate info based on official documents\n🤝 Friendly support level 3/5',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Got it'),
            ),
          ],
        );
      },
    );
  }
}

class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;

  ChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
  });
}


