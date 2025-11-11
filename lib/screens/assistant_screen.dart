// lib/screens/assistant_screen.dart
import 'package:flutter/cupertino.dart';
import 'package:geolocator/geolocator.dart';
import 'ai_copilot_screen.dart';
import '../services/trip_data_service.dart';
import '../models/models.dart' show ChatMessage;
import '../services/ai_copilot_service.dart' hide ChatMessage;

class AssistantScreen extends StatefulWidget {
  const AssistantScreen({super.key});

  @override
  State<AssistantScreen> createState() => _AssistantScreenState();
}

class _AssistantScreenState extends State<AssistantScreen> {
  final TextEditingController _controller = TextEditingController();
  final AICopilotService _aiService = AICopilotService();
  final TripDataService _tripDataService = TripDataService();
  final ScrollController _scrollController = ScrollController();
  bool _isLoading = false;
  List<ChatMessage> _messages = [];

  @override
  void initState() {
    super.initState();
    _loadMessages();
    _initializeAIService();
  }

  Future<void> _initializeAIService() async {
    try {
      // Pre-initialize AI service in background for faster responses
      _aiService.loadApiKeyFromStorage().then((_) {
        if (mounted) {
          setState(() {
            // Service ready
          });
        }
      });
    } catch (e) {
      // Silent fail - will retry on first question
    }
  }

  Future<void> _loadMessages() async {
    try {
      await _tripDataService.initialize();
      if (mounted) {
        setState(() {
          _messages = _tripDataService.getChatMessages();
        });
      }
    } catch (e) {
      print('Error loading messages: $e');
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0.0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  Future<void> _sendMessage() async {
    if (_controller.text.isEmpty || _isLoading) return;
    
    final userMessage = _controller.text;
    _controller.clear();
    FocusScope.of(context).unfocus();
    
    final userMsg = ChatMessage(
      text: userMessage,
      isUser: true,
      time: DateTime.now().toString().substring(11, 16),
    );
    
    setState(() {
      _isLoading = true;
      _messages.add(userMsg);
    });
    await _tripDataService.addChatMessage(userMsg);
    _scrollToBottom();

    try {
      // Get location in parallel with API key loading for speed
      final futures = <Future>[];
      Position? currentLocation;
      
      // Load API key (may already be cached)
      futures.add(_aiService.loadApiKeyFromStorage());
      
      // Get location (non-blocking)
      futures.add(
        Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.low,
        ).then((pos) {
          currentLocation = pos;
        }).catchError((_) {
          // Location not critical
        })
      );
      
      // Wait for API key (location can be optional)
      await futures[0];
      
      // Build context
      final context = <String, dynamic>{};
      if (currentLocation != null) {
        context['location'] = '${currentLocation!.latitude}, ${currentLocation!.longitude}';
      }
      
      // Ask question with context (optimized for speed)
      final response = await _aiService.askQuestion(userMessage, context: context);
      
      if (mounted) {
        final aiMsg = ChatMessage(
          text: response,
          isUser: false,
          time: DateTime.now().toString().substring(11, 16),
        );
        setState(() {
          _messages.add(aiMsg);
          _isLoading = false;
        });
        await _tripDataService.addChatMessage(aiMsg);
        _scrollToBottom();
      }
    } catch (e) {
      if (mounted) {
        String errorText = "I'm sorry, I encountered an error. Please try again.";
        
        // Provide more specific error messages
        final errorString = e.toString().toLowerCase();
        if (errorString.contains('api key') || errorString.contains('authentication')) {
          errorText = "• AI Assistant requires Gemini API key.\n"
              "• Go to Settings > AI Configuration.\n"
              "• Get free key: https://makersuite.google.com/app/apikey";
        } else if (errorString.contains('timeout') || errorString.contains('network')) {
          errorText = "• Connection timeout. Please check your internet connection.\n"
              "• Try again in a moment.";
        } else if (errorString.contains('quota') || errorString.contains('limit')) {
          errorText = "• API quota exceeded. Please check your Gemini API key limits.\n"
              "• Try again later or check your API key settings.";
        }
        
        final errorMsg = ChatMessage(
          text: errorText,
          isUser: false,
          time: DateTime.now().toString().substring(11, 16),
        );
        setState(() {
          _messages.add(errorMsg);
          _isLoading = false;
        });
        await _tripDataService.addChatMessage(errorMsg);
        _scrollToBottom();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: const Text('Assistant'),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: () {
            Navigator.of(context).push(
              CupertinoPageRoute(
                builder: (context) => const AICopilotScreen(),
              ),
            );
          },
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(CupertinoIcons.sparkles),
              SizedBox(width: 4),
              Text('AI Copilot'),
            ],
          ),
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            if (_messages.isEmpty) _buildQuickActions(),
            Expanded(
              child: _messages.isEmpty
                  ? _buildEmptyState()
                  : ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.all(16.0),
                      reverse: true,
                      itemCount: _messages.length + (_isLoading ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index == 0 && _isLoading) {
                          return const Padding(
                            padding: EdgeInsets.all(16.0),
                            child: Center(
                              child: CupertinoActivityIndicator(),
                            ),
                          );
                        }
                        final messageIndex = _isLoading 
                            ? index - 1 
                            : index;
                        return _buildChatMessage(
                          context, 
                          _messages[_messages.length - 1 - messageIndex]
                        );
                      },
                    ),
            ),
            _buildMessageInput(context),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: CupertinoColors.systemBlue.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              CupertinoIcons.chat_bubble_2_fill,
              size: 64,
              color: CupertinoColors.systemBlue,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'How can I help you?',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Ask me about your trips, safety, or travel tips',
            style: TextStyle(
              fontSize: 16,
              color: CupertinoColors.secondaryLabel,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Quick Actions',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildQuickActionButton('Plan Trip', CupertinoIcons.map, () {
                _controller.text = 'Help me plan a trip';
                _sendMessage();
              }),
              _buildQuickActionButton('Safety Tips', CupertinoIcons.shield_fill, () {
                _controller.text = 'Give me safety tips';
                _sendMessage();
              }),
              _buildQuickActionButton('Nearby Hotels', CupertinoIcons.house_fill, () {
                _controller.text = 'Find nearby hotels';
                _sendMessage();
              }),
              _buildQuickActionButton('Weather', CupertinoIcons.cloud_sun, () {
                _controller.text = 'What\'s the weather like?';
                _sendMessage();
              }),
              _buildQuickActionButton('Expenses', CupertinoIcons.money_dollar_circle_fill, () {
                _controller.text = 'Show my trip expenses';
                _sendMessage();
              }),
              _buildQuickActionButton('Routes', CupertinoIcons.location_fill, () {
                _controller.text = 'Show my recent routes';
                _sendMessage();
              }),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionButton(String label, IconData icon, VoidCallback onTap) {
    return CupertinoButton(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      onPressed: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: CupertinoColors.systemBlue.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: CupertinoColors.systemBlue.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: CupertinoColors.systemBlue),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                color: CupertinoColors.systemBlue,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChatMessage(BuildContext context, ChatMessage message) {
    final bool isLightMode = CupertinoTheme.of(context).brightness == Brightness.light;
    return Align(
      alignment: message.isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: message.isUser
              ? CupertinoColors.systemBlue
              : isLightMode
                  ? CupertinoColors.white
                  : CupertinoColors.secondarySystemGroupedBackground,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment: message.isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Text(
              message.text,
              style: TextStyle(
                color: message.isUser
                    ? CupertinoColors.white
                    : isLightMode ? CupertinoColors.black : CupertinoColors.white,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              message.time,
              style: TextStyle(
                color: message.isUser ? CupertinoColors.white.withOpacity(0.7) : CupertinoColors.secondaryLabel,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageInput(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: CupertinoTheme.of(context).barBackgroundColor,
        border: const Border(top: BorderSide(color: CupertinoColors.separator, width: 0.5)),
      ),
      child: Row(
        children: [
          Expanded(
            child: CupertinoTextField(
              controller: _controller,
              placeholder: 'Ask about your travel...',
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: CupertinoTheme.of(context).scaffoldBackgroundColor,
                borderRadius: BorderRadius.circular(20),
              ),
              onSubmitted: (_) => _sendMessage(),
            ),
          ),
          const SizedBox(width: 8),
          CupertinoButton(
            padding: EdgeInsets.zero,
            onPressed: _isLoading ? null : _sendMessage,
            child: Icon(
              _isLoading ? CupertinoIcons.hourglass : CupertinoIcons.arrow_up_circle_fill,
              size: 36,
              color: _isLoading ? CupertinoColors.systemGrey : null,
            ),
          ),
        ],
      ),
    );
  }
}