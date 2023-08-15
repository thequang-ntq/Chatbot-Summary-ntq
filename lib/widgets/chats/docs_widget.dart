//This is the widget that contains the first response for summarize text.
//It is the display of summarize text going with 3 suggest question
//for the first response when you upload a file to summarize 
//in summarize screen

import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:flutter/services.dart';
class DocsWidget extends StatelessWidget {
  DocsWidget(
      {super.key,
      required this.msg,
      required this.q1,
      required this.q2,
      required this.q3,
      required this.dateTime,
      required this.chatIndex,
      required this.onPress,
      this.shouldAnimate = false});
  FlutterTts flutterTts = FlutterTts();
  final void Function(String question) onPress;
  final String msg;
  final String q1;
  final String q2;
  final String q3;
  final int chatIndex;
  final bool shouldAnimate;
  final String dateTime;
  bool _isSpeaking = false;

  void _speak() async {
      _isSpeaking = !_isSpeaking;
      if (_isSpeaking) {
        await flutterTts.setLanguage("en-US");
        await flutterTts.speak(msg);
      } else {
        flutterTts.stop();
      }
  }

  String? _getLanguage() {
    RegExp regExp = RegExp(r"```(\w+)");
    Match? match = regExp.firstMatch(msg);
    String? languageName = match?.group(1);
    return languageName;
  }

  @override
  Widget build(BuildContext context) {
    return Column(

      children: [
        Material(
          color: chatIndex%2 == 0 ? Colors.white : Colors.grey[500],
          child: 
              Padding(
                padding: const EdgeInsets.all(10.0),
                child:
                chatIndex%2==0?
                 Column(
                  children: [
                    Text('-------  $dateTime  -----------', style: const TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    )),
                    const SizedBox(height: 6,),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Image.asset('assets/images/person.png', width: 40,),
                        const SizedBox(width: 8,),
                        Expanded(
                          child: Text(
                            msg,
                            style: const TextStyle(
                              color: Colors.black,
                              fontSize: 18,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        const SizedBox.shrink(),
                      ],
                    ),
                  ],
                )
              :
            
              Column(
                children: [   
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const SizedBox(width: 10,),                  
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
                      
                      SingleChildScrollView(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              onPressed: () {
                                Clipboard.setData(ClipboardData(text: msg));
                                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                  content: const Text('Text Copied to Clipboard!'),
                                  duration: const Duration(milliseconds: 1000),
                                  action: SnackBarAction(
                                    label: 'ok',
                                    onPressed: () {},
                                  ),
                                ));
                              },
                              icon: const Icon(Icons.copy),
                              color: Colors.white,
                            ),
                            const SizedBox(height: 5,),
                            IconButton(
                              padding: EdgeInsets.zero,
                              onPressed: _speak,
                              icon:
                                  Icon(_isSpeaking ? Icons.volume_mute : Icons.volume_up),
                              color: Colors.white,
                            ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(width: 8,),
                      Image.asset('assets/images/chat_logo.png', width: 40,),
                    ],
                  ),
                  // const SizedBox(height: 4),
                  
                  Visibility(
                    visible: chatIndex==3,
                    child: DefaultTextStyle(
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
                            '--------------------------------------------',
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  // const SizedBox(height: 4),
                  Visibility(
                    visible: chatIndex==3,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          onPressed:() {
                            onPress(q1);
                          },
                          style: const ButtonStyle(
                            backgroundColor: MaterialStatePropertyAll(Colors.blue),
                            foregroundColor: MaterialStatePropertyAll(Colors.blue),
                          ),
                          icon: const Icon(Icons.send, color: Colors.blue),
                        ),
                        const SizedBox(width: 5),
                        Expanded(
                          child: DefaultTextStyle(
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
                                  q1.trim(),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                      // const SizedBox(height: 4),
                  Visibility(
                    visible: chatIndex==3,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          onPressed:() {
                            onPress(q2);
                          },
                          style: const ButtonStyle(
                            backgroundColor: MaterialStatePropertyAll(Colors.blue),
                            foregroundColor: MaterialStatePropertyAll(Colors.blue),
                          ),
                          icon: const Icon(Icons.send, color: Colors.blue),
                        ),
                        const SizedBox(width: 5),
                        Expanded(
                          child: DefaultTextStyle(
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
                                  q2.trim(),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                      // const SizedBox(height: 4),
                  Visibility(
                    visible: chatIndex==3,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          onPressed:() {
                            onPress(q3);
                          },
                          style: const ButtonStyle(
                            backgroundColor: MaterialStatePropertyAll(Colors.blue),
                            foregroundColor: MaterialStatePropertyAll(Colors.blue),
                          ),
                          icon: const Icon(Icons.send, color: Colors.blue),
                        ),
                        const SizedBox(width: 5),
                        Expanded(
                          child: DefaultTextStyle(
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
                                  q3.trim(),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],    
              ),
          ),
        ),

      ],
    );
  }
}

            