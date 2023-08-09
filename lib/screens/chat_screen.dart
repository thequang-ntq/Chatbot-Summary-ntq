import 'dart:developer';
import 'package:chatgpt/providers/chats/chats_provider.dart';
import 'package:chatgpt/widgets/chats/chat_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:provider/provider.dart';
import 'package:chatgpt/screens/tabs.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:chatgpt/screens/home.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:chatgpt/menubar/menu.dart';
import 'package:intl/intl.dart';
class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  late stt.SpeechToText _speech;
  bool _isTyping = false;
  bool _isListening = false;

  late TextEditingController textEditingController;
  late ScrollController _listScrollController;
  late FocusNode focusNode;
  @override
  void initState() {
    _listScrollController = ScrollController();
    textEditingController = TextEditingController();
    focusNode = FocusNode();
    super.initState();
    _speech = stt.SpeechToText();
  }

  //////////////////////////
  //////////////////////
  //Speech to text Functions
  //////////////////////////
  //////////////////////////

  void onListen() async {
    if (!_isListening) {
      bool available = await _speech.initialize(
          onStatus: (val) {
            // print("OnStatus: $val");
            if (val == "done") {
              setState(() {
                _isListening = false;
                _speech.stop();
              });
            }
          },
          onError: (val) => print("error: $val"));
      if (available) {
        setState(() {
          _isListening = true;
        });
        _speech.listen(
            localeId: "vi_VN",
            listenFor: const Duration(hours: 24),
            onResult: (val) => setState(() {
                  textEditingController.text = val.recognizedWords;
                  if (_isTyping == true) {
                    textEditingController.clear();
                  }
                }));
      }
    } else {
      setState(() {
        _isListening = false;
        _speech.stop();
      });
    }
  }

  ///////////////////////////////
  ///////////////////////////////
  //Ending speech to text Functions
  ////////////////////////////////
  ////////////////////////////////
  
  @override
  void dispose() {
    _listScrollController.dispose();
    textEditingController.dispose();
    focusNode.dispose();
    super.dispose();
  }

  void toRefresh(){
    Navigator.pop(context);
    Navigator.pop(context);
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ChatScreen()),
    );
  }

  // List<ChatModel> chatList = [];
  @override
  Widget build(BuildContext context) {
    final chatProvider = Provider.of<ChatProvider>(context);
    return RefreshIndicator(
      color: Colors.white,
      backgroundColor: Colors.black,
      onRefresh: () async {
         return Future<void>.delayed(const Duration(seconds: 1));
      },
      child: StreamBuilder(
        stream: FirebaseFirestore.instance.collection(GetV.userName.text).doc(GetV.userChatID)
          .collection('Message').doc(GetV.messageChatID)
          .collection('ChatItem${GetV.chatNum}').orderBy('createdAt', descending: false).snapshots()
          ,
        builder: (BuildContext ctx, AsyncSnapshot snapshot) {
           if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }
    
          if (snapshot.hasError) {
            return const Center(
              child: Text('Something went wrong...'),
            );
          }
    
          final loadedMessages = snapshot.data!.docs;
    
          return Scaffold(
            appBar: AppBar(
              backgroundColor: Colors.grey[50],
              elevation: 2,
              leading: Builder(
                builder: (BuildContext context) {
                  return IconButton(
                    icon: const Icon(
                      Icons.menu,
                      color: Colors.black,
                    ),
                    onPressed: () {
                      Scaffold.of(context).openDrawer();
                    },
                    tooltip: MaterialLocalizations.of(context).openAppDrawerTooltip,
                  );
                },
              ),
              title: const Text("New Chat", style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.w500,
                fontSize:18,
              )),
              actions: [
                IconButton(
                  onPressed: () async{
                    GetV.title = '';
                    
                    final res = await FirebaseFirestore.instance.collection(GetV.userName.text).doc(GetV.userChatID).collection('Message')
                    .doc(GetV.messageChatID).get();
                    if(res['text'] == ''){
                      await FirebaseFirestore.instance.collection(GetV.userName.text).doc(GetV.userChatID).collection('Message')
                      .doc(GetV.messageChatID).delete();
                      
                    }
                    
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const Tabs()),
                    );
                  },
                  icon: const Icon(Icons.exit_to_app, color: Colors.black),
                ),
              ],
            ),
            drawer: Menu(toRefresh: toRefresh),
            body: SafeArea(
              child: Column(
                children: [
                  Flexible(
                    child: GetV.menuPressed? ListView.builder(
                        controller: _listScrollController,
                        itemCount: loadedMessages.length, 
                        itemBuilder: (context, index) {
                          final chatMessage = loadedMessages[index].data();
                          DateTime time = chatMessage['createdAt'].toDate();
                          String formattedDate = DateFormat('dd/MM/yyyy, hh:mm a').format(time);
                          return ChatWidget(
                            msg: chatMessage['text'],
                            dateTime: formattedDate,
                            chatIndex: chatMessage['index'], 
                            shouldAnimate:
                                chatMessage['index'] == 1,
                          );
                        })
                      :
                        ListView.builder(
                        controller: _listScrollController,
                        itemCount: loadedMessages.length, 
                        itemBuilder: (context, index) {
                          final chatMessage = loadedMessages[index].data();
                          DateTime time = chatMessage['createdAt'].toDate();
                          String formattedDate = DateFormat('dd/MM/yyyy, hh:mm a').format(time);
                          return ChatWidget(
                            msg: chatMessage['text'],
                            dateTime: formattedDate,
                            chatIndex: chatMessage['index'], 
                            shouldAnimate:
                                chatMessage['index'] == 1,
                          );
                        }),
                  ),
                  if (_isTyping) ...[
                    const SpinKitThreeBounce(
                      color: Colors.white,
                      size: 18,
                    ),
                  ],
                  const SizedBox(
                    height: 15,
                  ),
                  Material(
                    color: Colors.grey[600],
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              focusNode: focusNode,
                              style: const TextStyle(color: Colors.white),
                              controller: textEditingController,
                              onSubmitted: (value) async {
                                await sendMessageFCT(
                                    
                                    chatProvider: chatProvider);
                              },
                              decoration: const InputDecoration.collapsed(
                                  hintText: "How can I help you? ...",
                                  hintStyle: TextStyle(color: Colors.white)),
                            ),
                          ),
                          IconButton(
                              onPressed: () async {
                                await sendMessageFCT(
                                    
                                    chatProvider: chatProvider);
                              },
                              tooltip: 'Send message...',
                              icon: const Icon(
                                Icons.send,
                                color: Colors.white,
                              ),
                          ),
                          FloatingActionButton(
                            backgroundColor: Colors.white,
                            onPressed: () => onListen(),
                            tooltip: 'Click and speak something...',
                            child: Icon(
                              _isListening ? Icons.mic_off : Icons.mic,
                              color: Colors.black,
                            ),
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
      ),
    );
  }

  void scrollListToEND() {
    _listScrollController.animateTo(
        _listScrollController.position.maxScrollExtent,
        duration: const Duration(seconds: 2),
        curve: Curves.easeOut);
  }


  Future<void> sendMessageFCT(
      {
      required ChatProvider chatProvider}) async {
    if (_isTyping) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content:
            Text(
              "You can't send multiple messages at a time",
              style:TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
            ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    if (textEditingController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content:
            Text(
              "Please type a message",
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
            ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    try {
      String msg = textEditingController.text;
      if (_isListening) {
        setState(() {
          _isListening = false;
          _speech.stop();
        });
      }
      setState(() {
        _isTyping = true;
        // chatList.add(ChatModel(msg: textEditingController.text, chatIndex: 0));
        chatProvider.addUserMessage(msg: msg);
        textEditingController.clear();
        focusNode.unfocus();
      });
      await chatProvider.sendMessageAndGetAnswers(msg: msg);
      setState(() {});
    } catch (error) {
      log("error $error");
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: 
          Text(
            error.toString(),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
        backgroundColor: Colors.red,
      ));
    } finally {
      setState(() {
        scrollListToEND();
        _isTyping = false;
      });
    }
  }
}