// Widget hiển thị một tin nhắn chat 
// Hiển thị Message Bubble
// Text To Speech
// Copy to Clipboard

import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:flutter_langdetect/flutter_langdetect.dart' as langdetect;
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:flutter/services.dart';
import 'package:chatgpt/theme/app_theme.dart';

class ChatWidget extends StatefulWidget {
  const ChatWidget({
    super.key,
    required this.msg,
    required this.chatIndex,
    required this.dateTime,
    this.imageUrl, // THÊM PARAMETER NÀY
    this.shouldAnimate = false,
  });

  final String msg;
  final int chatIndex;
  final bool shouldAnimate;
  final String dateTime;
  final String? imageUrl; // THÊM DÒNG NÀY

  @override
  State<ChatWidget> createState() => _ChatWidgetState();
}

class _ChatWidgetState extends State<ChatWidget> {
  FlutterTts flutterTts = FlutterTts();
  bool _isSpeaking = false;

  @override
  void dispose() {
    flutterTts.stop();
    super.dispose();
  }

  // Hàm text to speech
  void _speak() async {
    setState(() {
      _isSpeaking = !_isSpeaking;
    });

    if (_isSpeaking) {
      await langdetect.initLangDetect();
      var language = langdetect.detect(widget.msg);
      await flutterTts.setLanguage(language);
      await flutterTts.speak(widget.msg);
    } else {
      flutterTts.stop();
    }
  }

  // Hàm copy nội dung tin nhắn vào clip board
  void _copyToClipboard() {
    Clipboard.setData(ClipboardData(text: widget.msg));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white),
            SizedBox(width: 8),
            Text('Text copied to clipboard!'),
          ],
        ),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  // Giao diện 1 tin nhắn chat trong đoạn chat (Của người hoặc của Chatbot thì sẽ đổi bên)
  @override
  Widget build(BuildContext context) {
    final isUser = widget.chatIndex % 2 == 0;
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Time stamp
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                widget.dateTime,
                style: AppTheme.caption.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          
          // Message bubble
          Row(
            mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!isUser) _buildAvatar(false),
              if (!isUser) const SizedBox(width: 8),
              
              Flexible(
                child: Container(
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.75,
                  ),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isUser ? Colors.blue : Colors.grey[200],
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(20),
                      topRight: const Radius.circular(20),
                      bottomLeft: Radius.circular(isUser ? 20 : 5),
                      bottomRight: Radius.circular(isUser ? 5 : 20),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha:0.1),
                        blurRadius: 5,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // THÊM PHẦN HIỂN THỊ ẢNH
                      if (widget.imageUrl != null && widget.imageUrl!.isNotEmpty) ...[
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.network(
                            widget.imageUrl!,
                            width: 200,
                            fit: BoxFit.cover,
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return const SizedBox(
                                width: 200,
                                height: 200,
                                child: Center(child: CircularProgressIndicator()),
                              );
                            },
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                width: 200,
                                height: 200,
                                color: Colors.grey[300],
                                child: const Icon(Icons.broken_image, size: 50),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 8),
                      ],
                      widget.shouldAnimate && !isUser
                          ? DefaultTextStyle(
                              style: TextStyle(
                                color: isUser ? Colors.white : Colors.black87,
                                fontSize: 16,
                                fontWeight: FontWeight.w400,
                              ),
                              child: AnimatedTextKit(
                                isRepeatingAnimation: false,
                                repeatForever: false,
                                displayFullTextOnTap: true,
                                totalRepeatCount: 1,
                                animatedTexts: [
                                  TyperAnimatedText(
                                    widget.msg.trim(),
                                  ),
                                ],
                              ),
                            )
                          : Text(
                              widget.msg.trim(),
                              style: TextStyle(
                                color: isUser ? Colors.white : Colors.black87,
                                fontSize: 16,
                                fontWeight: FontWeight.w400,
                                height: 1.4,
                              ),
                            ),
                      
                      // Action buttons for AI messages
                      if (!isUser) ...[
                        const SizedBox(height: 12),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _buildActionButton(
                              icon: Icons.copy,
                              onTap: _copyToClipboard,
                              tooltip: 'Copy',
                            ),
                            const SizedBox(width: 8),
                            _buildActionButton(
                              icon: _isSpeaking ? Icons.volume_off : Icons.volume_up,
                              onTap: _speak,
                              tooltip: _isSpeaking ? 'Stop' : 'Read aloud',
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              
              if (isUser) const SizedBox(width: 8),
              if (isUser) _buildAvatar(true),
            ],
          ),
        ],
      ),
    );
  }

  // Avatar ở trước message bubble
  Widget _buildAvatar(bool isUser) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: isUser ? Colors.blue : Colors.grey[300],
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha:0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipOval(
        child: Image.asset(
          isUser ? 'assets/images/person.png' : 'assets/images/chat_logo.png',
          width: 40,
          height: 40,
          fit: BoxFit.cover,
        ),
      ),
    );
  }

  // Nút copy to clipboard và nút đọc tin nhắn bằng giọng AI
  Widget _buildActionButton({
    required IconData icon,
    required VoidCallback onTap,
    required String tooltip,
  }) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: Colors.grey[300],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            size: 18,
            color: Colors.black87,
          ),
        ),
      ),
    );
  }
}