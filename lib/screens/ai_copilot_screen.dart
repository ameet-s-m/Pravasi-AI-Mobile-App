// lib/screens/ai_copilot_screen.dart
import 'package:flutter/cupertino.dart';
import 'package:geolocator/geolocator.dart';
import '../services/ai_copilot_service.dart';

class AICopilotScreen extends StatefulWidget {
  const AICopilotScreen({super.key});

  @override
  State<AICopilotScreen> createState() => _AICopilotScreenState();
}

class _AICopilotScreenState extends State<AICopilotScreen> {
  final AICopilotService _copilot = AICopilotService();
  final _questionController = TextEditingController();
  final List<AICopilotMessage> _messages = [];
  bool _isLoading = false;
  Position? _currentLocation;

  @override
  void initState() {
    super.initState();
    _getLocation();
    _loadHistory();
    _initializeAI();
  }

  Future<void> _initializeAI() async {
    await _copilot.loadApiKeyFromStorage();
  }

  @override
  void dispose() {
    _questionController.dispose();
    super.dispose();
  }

  Future<void> _getLocation() async {
    try {
      _currentLocation = await Geolocator.getCurrentPosition();
    } catch (e) {
      print('Error getting location: $e');
    }
  }

  void _loadHistory() {
    final history = _copilot.getConversationHistory();
    _messages.addAll(history);
  }

  Future<void> _askQuestion() async {
    if (_questionController.text.isEmpty || _isLoading) return;

    final question = _questionController.text;
    _questionController.clear();

    setState(() {
      _messages.add(AICopilotMessage(
        question: question,
        answer: '',
        timestamp: DateTime.now(),
        isUser: true,
      ));
      _isLoading = true;
    });

    try {
      final context = <String, dynamic>{};
      if (_currentLocation != null) {
        context['location'] = '${_currentLocation!.latitude}, ${_currentLocation!.longitude}';
      }

      final answer = await _copilot.askQuestion(question, context: context);

      if (mounted) {
        setState(() {
          // Add AI response as a new message
          _messages.add(AICopilotMessage(
            question: question,
            answer: answer,
            timestamp: DateTime.now(),
            isUser: false,
          ));
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          // Add error message as AI response
          _messages.add(AICopilotMessage(
            question: question,
            answer: '• Error: ${e.toString()}\n• Please try again or check your API key settings.',
            timestamp: DateTime.now(),
            isUser: false,
          ));
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(
        middle: Text('AI Copilot'),
      ),
      child: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _messages.length + (_isLoading ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index == _messages.length && _isLoading) {
                    return const Padding(
                      padding: EdgeInsets.all(16.0),
                      child: CupertinoActivityIndicator(),
                    );
                  }
                  return _buildMessage(_messages[index]);
                },
              ),
            ),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: CupertinoColors.systemGrey6,
                border: Border(
                  top: BorderSide(color: CupertinoColors.separator),
                ),
              ),
              child: SafeArea(
                top: false,
                child: Row(
                  children: [
                    Expanded(
                      child: CupertinoTextField(
                        controller: _questionController,
                        placeholder: 'Ask me anything...',
                        padding: const EdgeInsets.all(12),
                      ),
                    ),
                    const SizedBox(width: 8),
                    CupertinoButton(
                      padding: EdgeInsets.zero,
                      onPressed: _isLoading ? null : _askQuestion,
                      child: const Icon(CupertinoIcons.paperplane_fill),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessage(AICopilotMessage message) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: message.isUser 
            ? MainAxisAlignment.end 
            : MainAxisAlignment.start,
        children: [
          if (!message.isUser)
            const Icon(CupertinoIcons.sparkles, size: 20),
          Flexible(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: message.isUser
                    ? CupertinoColors.systemBlue
                    : CupertinoColors.systemGrey6,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                message.isUser ? message.question : message.answer,
                style: TextStyle(
                  color: message.isUser 
                      ? CupertinoColors.white 
                      : CupertinoColors.black,
                ),
              ),
            ),
          ),
          if (message.isUser)
            const Icon(CupertinoIcons.person_fill, size: 20),
        ],
      ),
    );
  }
}

// ChatMessage is now imported from models.dart

