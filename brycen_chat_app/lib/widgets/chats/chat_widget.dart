import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:flutter/material.dart';

class ChatWidget extends StatelessWidget {
  const ChatWidget(
      {super.key,
      required this.msg,
      required this.chatIndex,
      this.shouldAnimate = false});

  final String msg;
  final int chatIndex;
  final bool shouldAnimate;
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Material(
          color: chatIndex%2 == 0 ? const Color(0xFF343541) : const Color(0xFF444654),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child:
              chatIndex%2 == 0 ?
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Image.asset('assets/images/person.png', width: 40,),
                    const SizedBox(width: 8,),
                    Expanded(
                      child: Text(
                        msg,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox.shrink(),
                  ],
                )
              : 
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(width: 55,),                  
                    Expanded(
                      child: shouldAnimate ?
                        DefaultTextStyle(
                          textAlign: TextAlign.end,
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                              ),
                          child: AnimatedTextKit(
                              isRepeatingAnimation: false,
                              repeatForever: false,
                              displayFullTextOnTap: true,
                              totalRepeatCount: 1,
                              animatedTexts: [
                                TyperAnimatedText(
                                  textAlign: TextAlign.end,
                                  msg.trim(),
                                ),
                              ]
                          ),
                        )
                      :
                        Text(
                          textAlign: TextAlign.end,
                          msg.trim(),
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                          ),
                        ),
                    ),
                    
                    const SizedBox(width: 8,),
                    Image.asset('assets/images/chat_logo.png', width: 40,),
                  ],
                ),
          ),
          
        ),
      ],
    );
  }
}

            