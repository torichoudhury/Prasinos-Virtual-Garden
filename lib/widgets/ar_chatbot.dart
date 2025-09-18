import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:plant_arvr/services/gemini_service.dart';
import 'package:plant_arvr/providers/ar_providers.dart';

// Provider for chatbot state
final chatbotProvider = StateNotifierProvider<ChatbotNotifier, ChatbotState>((ref) {
  return ChatbotNotifier();
});

class ChatbotState {
  final bool isOpen;
  final bool isLoading;
  final List<ChatMessage> messages;
  final String inputText;

  ChatbotState({
    this.isOpen = false,
    this.isLoading = false,
    this.messages = const [],
    this.inputText = '',
  });

  ChatbotState copyWith({
    bool? isOpen,
    bool? isLoading,
    List<ChatMessage>? messages,
    String? inputText,
  }) {
    return ChatbotState(
      isOpen: isOpen ?? this.isOpen,
      isLoading: isLoading ?? this.isLoading,
      messages: messages ?? this.messages,
      inputText: inputText ?? this.inputText,
    );
  }
}

class ChatbotNotifier extends StateNotifier<ChatbotState> {
  ChatbotNotifier() : super(ChatbotState()) {
    _addWelcomeMessage();
  }

  final GeminiService _geminiService = GeminiService();

  void _addWelcomeMessage() {
    final welcomeMessage = ChatMessage(
      text: "🌱 Hello! I'm your AR Garden Assistant. I can help you with plant care, garden design, and AR features. What would you like to know?",
      isUser: false,
      timestamp: DateTime.now(),
    );
    state = state.copyWith(messages: [welcomeMessage]);
  }

  void toggleChat() {
    state = state.copyWith(isOpen: !state.isOpen);
  }

  void closeChat() {
    state = state.copyWith(isOpen: false);
  }

  void updateInputText(String text) {
    state = state.copyWith(inputText: text);
  }

  Future<void> sendMessage(String message, {List<String>? placedPlants}) async {
    if (message.trim().isEmpty) return;

    // Add user message
    final userMessage = ChatMessage(
      text: message,
      isUser: true,
      timestamp: DateTime.now(),
    );

    state = state.copyWith(
      messages: [...state.messages, userMessage],
      inputText: '',
      isLoading: true,
    );

    try {
      String response;
      
      if (_geminiService.isConfigured) {
        // Check internet connectivity first
        bool hasInternet = await _checkInternetConnection();
        
        if (hasInternet) {
          // Use Gemini AI for response
          response = await _geminiService.getChatResponse(
            message,
            state.messages,
            placedPlants: placedPlants,
          );
        } else {
          // No internet, use offline responses
          response = "🌐 No internet connection detected. Using offline mode:\n\n${_getOfflineResponse(message, placedPlants)}";
        }
      } else {
        // Use offline responses
        response = _getOfflineResponse(message, placedPlants);
      }

      // Add assistant response
      final assistantMessage = ChatMessage(
        text: response,
        isUser: false,
        timestamp: DateTime.now(),
      );

      state = state.copyWith(
        messages: [...state.messages, assistantMessage],
        isLoading: false,
      );
    } catch (e) {
      final errorMessage = ChatMessage(
        text: "Sorry, I couldn't process your message. ${_geminiService.isConfigured ? 'Please check your internet connection and try again!' : 'I\'m running in offline mode with basic responses.'}",
        isUser: false,
        timestamp: DateTime.now(),
      );

      state = state.copyWith(
        messages: [...state.messages, errorMessage],
        isLoading: false,
      );
    }
  }

  Future<bool> _checkInternetConnection() async {
    try {
      // Use a quick HTTP request to check connectivity
      final response = await http.get(
        Uri.parse('https://www.google.com'),
      ).timeout(const Duration(seconds: 5));
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  String _getOfflineResponse(String message, List<String>? placedPlants) {
    final lowerMessage = message.toLowerCase();
    
    // Plant care questions
    if (lowerMessage.contains('care') || lowerMessage.contains('water') || lowerMessage.contains('grow')) {
      return "🌿 For basic plant care:\n• Water when soil feels dry\n• Provide adequate sunlight\n• Use well-draining soil\n• Remove dead leaves regularly\n\nFor specific plant care, I'd recommend consulting detailed guides online!";
    }
    
    // AR help
    if (lowerMessage.contains('ar') || lowerMessage.contains('place') || lowerMessage.contains('camera')) {
      return "📱 AR Tips:\n• Point your camera at flat, well-lit surfaces\n• Move slowly for better tracking\n• Tap on detected planes to place plants\n• Use good lighting for best results\n• Clear the area of clutter for better AR detection";
    }
    
    // Plant information
    if (lowerMessage.contains('basil')) {
      return "🌿 Basil is a popular culinary herb. It prefers warm, sunny conditions and regular watering. Great for cooking and has natural pest-repelling properties!";
    }
    
    if (lowerMessage.contains('neem')) {
      return "🌿 Neem is known for its medicinal properties. It's drought-resistant and has natural pesticide qualities. Often used in traditional medicine and organic farming.";
    }
    
    if (lowerMessage.contains('rosemary')) {
      return "🌿 Rosemary is a hardy, aromatic herb. It loves sunny, dry conditions and doesn't need much water. Great for cooking and has antioxidant properties!";
    }
    
    if (lowerMessage.contains('eucalyptus')) {
      return "🌿 Eucalyptus is known for its distinctive scent and medicinal uses. It grows quickly and prefers well-drained soil. Often used for respiratory health.";
    }
    
    if (lowerMessage.contains('aloe')) {
      return "🌿 Aloe Vera is a succulent with healing properties. It needs minimal water and bright, indirect light. The gel inside leaves is great for skin care!";
    }
    
    // Garden design
    if (lowerMessage.contains('design') || lowerMessage.contains('layout') || lowerMessage.contains('arrange')) {
      return "🏡 Garden Design Tips:\n• Group plants with similar water needs\n• Consider plant heights and spacing\n• Mix textures and colors for visual appeal\n• Plan for seasonal changes\n• Leave space for growth";
    }
    
    // Current garden status
    if (placedPlants != null && placedPlants.isNotEmpty) {
      if (lowerMessage.contains('garden') || lowerMessage.contains('plant')) {
        return "🌱 Your current AR garden has: ${placedPlants.join(', ')}. These are great choices! Each plant has unique care requirements and benefits.";
      }
    } else {
      if (lowerMessage.contains('garden') || lowerMessage.contains('start')) {
        return "🌱 You haven't placed any plants yet! Start by pointing your camera at a flat surface and tap to place your first plant. I'd recommend starting with basil or aloe vera - they're great for beginners!";
      }
    }
    
    // Default responses
    final defaultResponses = [
      "🌱 I'm here to help with your AR garden! You can ask me about plant care, AR features, or garden design tips.",
      "🌿 Try asking me about specific plants like basil, neem, rosemary, eucalyptus, or aloe vera!",
      "📱 Need help with the AR features? I can guide you through placing and managing your virtual plants.",
      "🏡 Interested in garden design? I can share tips on arranging your plants for the best results!",
    ];
    
    return defaultResponses[DateTime.now().millisecond % defaultResponses.length];
  }

  void clearChat() {
    state = ChatbotState();
    _addWelcomeMessage();
  }
}

class ARChatbot extends ConsumerStatefulWidget {
  const ARChatbot({Key? key}) : super(key: key);

  @override
  ConsumerState<ARChatbot> createState() => _ARChatbotState();
}

class _ARChatbotState extends ConsumerState<ARChatbot> 
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _expandController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _expandAnimation;
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);
    
    _expandController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _pulseAnimation = Tween<double>(begin: 0.9, end: 1.1).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    
    _expandAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _expandController, curve: Curves.elasticOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _expandController.dispose();
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
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

  @override
  Widget build(BuildContext context) {
    final chatbotState = ref.watch(chatbotProvider);
    final chatbotNotifier = ref.read(chatbotProvider.notifier);
    final placedPlants = ref.watch(placedPlantsProvider);
    final geminiService = GeminiService();

    // Update expand animation based on chat state
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (chatbotState.isOpen) {
        _expandController.forward();
      } else {
        _expandController.reverse();
      }
    });

    // Auto-scroll when new messages arrive
    if (chatbotState.messages.isNotEmpty) {
      _scrollToBottom();
    }

    return Positioned(
      bottom: 100,
      right: 20,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Chat window
          AnimatedBuilder(
            animation: _expandAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: _expandAnimation.value,
                alignment: Alignment.bottomRight,
                child: _expandAnimation.value > 0
                    ? Container(
                        width: 320,
                        height: 400,
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 15,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            // Header
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: const BoxDecoration(
                                color: Color(0xFF2E7D32),
                                borderRadius: BorderRadius.only(
                                  topLeft: Radius.circular(20),
                                  topRight: Radius.circular(20),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    geminiService.isConfigured ? Icons.eco : Icons.offline_bolt,
                                    color: Colors.white,
                                    size: 24,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'AR Garden Assistant',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                        ),
                                        Text(
                                          geminiService.isConfigured ? 'AI Powered' : 'Offline Mode',
                                          style: TextStyle(
                                            color: Colors.white.withOpacity(0.8),
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.close, color: Colors.white),
                                    onPressed: chatbotNotifier.closeChat,
                                  ),
                                ],
                              ),
                            ),
                            // Messages
                            Expanded(
                              child: ListView.builder(
                                controller: _scrollController,
                                padding: const EdgeInsets.all(16),
                                itemCount: chatbotState.messages.length,
                                itemBuilder: (context, index) {
                                  final message = chatbotState.messages[index];
                                  return _buildMessageBubble(message);
                                },
                              ),
                            ),
                            // Loading indicator
                            if (chatbotState.isLoading)
                              Container(
                                padding: const EdgeInsets.all(16),
                                child: Row(
                                  children: [
                                    const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor: AlwaysStoppedAnimation<Color>(
                                          Color(0xFF2E7D32),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Assistant is typing...',
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                        fontStyle: FontStyle.italic,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            // Input field
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.grey[50],
                                borderRadius: const BorderRadius.only(
                                  bottomLeft: Radius.circular(20),
                                  bottomRight: Radius.circular(20),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: TextField(
                                      controller: _textController,
                                      decoration: InputDecoration(
                                        hintText: 'Ask about plants, care tips...',
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(25),
                                          borderSide: BorderSide.none,
                                        ),
                                        filled: true,
                                        fillColor: Colors.white,
                                        contentPadding: const EdgeInsets.symmetric(
                                          horizontal: 16,
                                          vertical: 12,
                                        ),
                                      ),
                                      onSubmitted: (text) => _sendMessage(
                                        chatbotNotifier,
                                        text,
                                        placedPlants.map((p) => p.plantInfo.displayName).toList(),
                                      ),
                                      enabled: !chatbotState.isLoading,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  CircleAvatar(
                                    backgroundColor: const Color(0xFF2E7D32),
                                    child: IconButton(
                                      icon: const Icon(Icons.send, color: Colors.white),
                                      onPressed: chatbotState.isLoading
                                          ? null
                                          : () => _sendMessage(
                                                chatbotNotifier,
                                                _textController.text,
                                                placedPlants.map((p) => p.plantInfo.displayName).toList(),
                                              ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      )
                    : const SizedBox.shrink(),
              );
            },
          ),
          // Floating action button with connection indicator
          AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: chatbotState.isOpen ? 1.0 : _pulseAnimation.value,
                child: Stack(
                  children: [
                    FloatingActionButton(
                      onPressed: chatbotNotifier.toggleChat,
                      backgroundColor: const Color(0xFF2E7D32),
                      child: Icon(
                        chatbotState.isOpen ? Icons.close : Icons.chat,
                        color: Colors.white,
                      ),
                    ),
                    // Connection indicator
                    Positioned(
                      top: 0,
                      right: 0,
                      child: Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: geminiService.isConfigured ? Colors.green : Colors.orange,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment:
            message.isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!message.isUser) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: const Color(0xFF2E7D32),
              child: const Icon(
                Icons.eco,
                color: Colors.white,
                size: 16,
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: message.isUser
                    ? const Color(0xFF2E7D32)
                    : Colors.grey[200],
                borderRadius: BorderRadius.circular(18),
              ),
              child: Text(
                message.text,
                style: TextStyle(
                  color: message.isUser ? Colors.white : Colors.black87,
                  fontSize: 14,
                ),
              ),
            ),
          ),
          if (message.isUser) ...[
            const SizedBox(width: 8),
            CircleAvatar(
              radius: 16,
              backgroundColor: Colors.blue[100],
              child: Icon(
                Icons.person,
                color: Colors.blue[700],
                size: 16,
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _sendMessage(ChatbotNotifier notifier, String text, List<String> placedPlants) {
    if (text.trim().isNotEmpty) {
      notifier.sendMessage(text, placedPlants: placedPlants);
      _textController.clear();
    }
  }
}