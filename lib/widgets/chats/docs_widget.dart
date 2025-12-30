// Widget hiển thị summary message với 3 câu hỏi gợi ý 
// Hiển thị nội dung tóm tắt

import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:flutter_langdetect/flutter_langdetect.dart' as langdetect;
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:flutter/services.dart';
import 'package:chatgpt/theme/app_theme.dart';

class DocsWidget extends StatefulWidget {
  const DocsWidget({
    super.key,
    required this.msg,
    required this.q1,
    required this.q2,
    required this.q3,
    required this.dateTime,
    required this.chatIndex,
    required this.onPress,
    this.shouldAnimate = false,
  });

  final void Function(String question) onPress;
  final String msg;
  final String q1;
  final String q2;
  final String q3;
  final int chatIndex;
  final bool shouldAnimate;
  final String dateTime;

  @override
  State<DocsWidget> createState() => _DocsWidgetState();
}

class _DocsWidgetState extends State<DocsWidget> {
  FlutterTts flutterTts = FlutterTts();
  bool _isSpeaking = false;

  @override
  void dispose() {
    flutterTts.stop();
    super.dispose();
  }

  // Hàm speech to text
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

  void _copyToClipboard() {
    Clipboard.setData(ClipboardData(text: widget.msg));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white),
            SizedBox(width: 8),
            Text('Summary copied to clipboard!'),
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

  @override
  Widget build(BuildContext context) {
    final isUser = widget.chatIndex % 2 == 0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Time stamp
          if (!isUser)
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
          if (!isUser) const SizedBox(height: 8),

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
                    maxWidth: MediaQuery.of(context).size.width * 0.85,
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
                      // Message content
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

                      // Suggested Questions (only for summary - index 3)
                      // Câu hỏi gợi ý
                      if (widget.chatIndex == 3) ...[
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.blue.withValues(alpha:0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.blue.withValues(alpha:0.3),
                              width: 1,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.help_outline,
                                    size: 20,
                                    color: Colors.blue[700],
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Suggested Questions',
                                    style: AppTheme.bodyText1.copyWith(
                                      fontWeight: FontWeight.w600,
                                      color: Colors.blue[700],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              _buildQuestionButton(
                                question: widget.q1,
                                icon: Icons.chat_bubble_outline,
                                number: 1,
                              ),
                              const SizedBox(height: 8),
                              _buildQuestionButton(
                                question: widget.q2,
                                icon: Icons.chat_bubble_outline,
                                number: 2,
                              ),
                              const SizedBox(height: 8),
                              _buildQuestionButton(
                                question: widget.q3,
                                icon: Icons.chat_bubble_outline,
                                number: 3,
                              ),
                            ],
                          ),
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

  // Nút này để tạo cho chức năng copy to clipboard và chức năng đọc tin nhắn bằng giọng AI
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

  // Nút này để điền nội dung câu hỏi gợi ý được chọn vào text input
  Widget _buildQuestionButton({
    required String question,
    required IconData icon,
    required int number,
  }) {
    if (question.trim().isEmpty || question == 'Empty') {
      return const SizedBox.shrink();
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => widget.onPress(question),
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: Colors.blue.withValues(alpha:0.3),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: const BoxDecoration(
                  color: Colors.blue,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    '$number',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  question.trim(),
                  style: AppTheme.bodyText1.copyWith(
                    color: Colors.black87,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: Colors.blue[700],
              ),
            ],
          ),
        ),
      ),
    );
  }
}