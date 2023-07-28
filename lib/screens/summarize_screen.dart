// import 'dart:async';
import 'dart:ui';
import 'dart:developer';
import 'dart:convert';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:flutter/material.dart';
import 'package:chatgpt/screens/tabs.dart';
import 'package:file_picker/file_picker.dart';
import 'package:open_file/open_file.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:chatgpt/providers/chats/chats_provider.dart';
import 'package:chatgpt/widgets/chats/chat_widget.dart';
import 'package:provider/provider.dart';
// import 'package:path_provider/path_provider.dart';

class SummarizeScreen extends StatefulWidget {
  const SummarizeScreen({super.key});

  @override
  State<SummarizeScreen> createState() => _SummarizeScreenState();
}

class _SummarizeScreenState extends State<SummarizeScreen> {
  late TextEditingController _askText;
  String fileName = '';
  String fileType = '';
  String fileText = '';
  String textLast = '';
  String answerSummary = 'Not have text';
  late ScrollController _listScrollController;
  late FocusNode focusNode;

  late TextEditingController _summarizeText;
  bool _hasFiled = false;
  bool _hasSummarized = false;
  bool _isTyping = false;

  @override
  void initState() {
    _askText = TextEditingController();
    _summarizeText = TextEditingController();
    _listScrollController = ScrollController();
    focusNode = FocusNode();
    super.initState();
  }

  @override
  void dispose() {
    _listScrollController.dispose();
    _summarizeText.dispose();
    _askText.dispose();
    super.dispose();
  }

  void openFile(PlatformFile file) {
    OpenFile.open(file.path!);
  }

  void _uploadFile() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.any);
    if (result == null) {
      return;
    } else {
      PlatformFile file = result.files.first;
      fileType = file.name.split('.').last;
      fileName = file.name;
      fileText = utf8.decode(file.bytes!);
      textLast = fileText;
      // FirebaseFirestore.instance.collection('SummarizeDocs').add({
      //   'Documents' : utf8.decode(file.bytes!),   
      // });
      setState(() {
        _hasFiled = true;
      });
    }
  }

  void _summarizeFile() async {
    if (fileName.isNotEmpty) {
      setState(() {                       
        _hasSummarized = true;
      });
      final docsData = await FirebaseFirestore.instance.collection('SummarizeDocs').get();
      for(final item in docsData.docs){
        answerSummary = item.data()['aiChat'];
      }
      String humanChatFirst = 'Summarize the text: $textLast';
      await FirebaseFirestore.instance.collection('SummarizeChat').add({
        'humanChat' :  humanChatFirst,
        'aiChat' : answerSummary, 
      });
      _summarizeText.text = answerSummary ;
    } else {
      return;
    }
  }

  @override
  Widget build(BuildContext context) {
    final chatProvider = Provider.of<ChatProvider>(context);
    return Scaffold(
        appBar: AppBar(
          elevation: 2,
          leading: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Image.asset('assets/images/Docs.jpg'),
          ),
          backgroundColor: Colors.grey[50],
          title: const Text('Summarize App'),
          centerTitle: false,
          actions: [
            IconButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const Tabs()),
                );
              },
              icon: Icon(
                Icons.exit_to_app,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ],
        ),
        backgroundColor: Colors.grey[400],
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(25),
            child: SingleChildScrollView(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    const SizedBox(
                      height: 21,
                    ),
                    const Text(
                      'Upload a file to summarize',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                        fontSize: 28,
                      ),
                    ),
                    const SizedBox(
                      height: 5,
                    ),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(15.0), // Đặt borderRadius
                      child: BackdropFilter(
                        filter: ImageFilter.blur(
                            sigmaX: 5.0, sigmaY: 5.0), // Điều chỉnh độ mờ của viền
                        child: Container(
                          height: 100,
                          width: 150,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(15.0),
                            color: Colors.black.withOpacity(0.2), // Đặt màu của viền mờ
                          ),
                          child: Image.asset(
                            'assets/images/upload_pic.png',
                            height: 100,
                            width: 150,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    ),
                    Visibility(
                      visible: _hasFiled,
                      child: Column(
                        children: [
                          Text(fileName, style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            color: Colors.black,
                            backgroundColor: Colors.amber[300],
                      
                          )),
                          const SizedBox(
                            height: 45,
                          ),
                          ElevatedButton(
                            style: ButtonStyle(
                              backgroundColor: MaterialStateProperty.all<Color>(
                                const Color.fromARGB(255, 52, 63, 189)),
                                side: MaterialStateProperty.all<BorderSide>(
                                  const BorderSide(
                                    color: const Color.fromARGB(255, 47, 60, 143),
                                    width: 3.0,
                                  ),
                                ),
                              minimumSize: MaterialStateProperty.all<Size>(
                                const Size(300,50),
                              ),
                            ),
                            onPressed: () async{                          
                              if(textLast.isNotEmpty){
                                await chatProvider.saveDocsSummarize(msg: textLast);
                              }
                              _summarizeFile();
                            },
                            child: const Text('Summarize', style: TextStyle(
                              color: Colors.white, fontSize: 25,
                            )),
                          ),
                          const SizedBox(height: 25,),
                          Visibility(
                            visible: _hasSummarized,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: <Widget>[
                                const Text(
                                  'Text after summarize:',
                                  style: TextStyle(
                                    fontSize: 24,
                                    color: Colors.black,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(20.0),
                                  child: TextField(
                                    cursorColor: Colors.black,
                                    controller: _summarizeText,
                                    obscureText: false,
                                    decoration: const InputDecoration(
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.all(Radius.circular(30.0)),
                                        borderSide: BorderSide(width: 20, color: Colors.black),
                                      ),
                                      filled: true,
                                      focusColor: Colors.white,
                                      fillColor: Colors.white,
                                      hoverColor: Colors.white,
                                    ),
                                  ),
                                ),
                                const SizedBox(
                                  height: 20,
                                ),
                                const Text(
                                  'Ask any question about the summarize text above:',
                                  style: TextStyle(
                                    fontSize: 25,
                                    color: Colors.black,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 15,),
                                Padding(
                                  padding: const EdgeInsets.only(
                                      left: 15, right: 1, bottom: 14),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: TextField(
                                          cursorColor: Colors.black,
                                          controller: _askText,
                                          style: const TextStyle(
                                            color: Colors.black,
                                            fontWeight: FontWeight.w600,
                                          ),
                                          textCapitalization:
                                              TextCapitalization.sentences,
                                          autocorrect: false,
                                          enableSuggestions: false,
                                          onSubmitted: (value) async {
                                            await sendMessageFCT(
                                                
                                                chatProvider: chatProvider);
                                          },
                                          decoration: InputDecoration(
                                              hintText: 'Send a message...',
                                              hintStyle: const TextStyle(
                                                color: Colors.black,
                                                fontWeight: FontWeight.w600,
                                              ),
                                              border: const OutlineInputBorder(
                                                borderRadius: BorderRadius.all(Radius.circular(30.0)),
                                                borderSide: BorderSide(width: 20, color: Colors.blueAccent),
                                              ),
                                            filled: true,
                                            focusColor: Colors.white,
                                            fillColor: Colors.white,
                                            hoverColor: Colors.white,
                                            suffixIcon: IconButton(
                                              onPressed: () async{
                                                
                                                await sendMessageFCT(chatProvider: chatProvider);
                                              },
                                              icon: const Icon(Icons.send, color: Colors.blue,)
                                            ),
                                          ),
                                          
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                  SizedBox(
                                    height: 200,
                                    child: ListView.builder(
                                      shrinkWrap: true,
                                      controller: _listScrollController,
                                      itemCount: chatProvider.getChatList.length, //chatList.length,
                                      itemBuilder: (context, index) {
                                        return ChatWidget(
                                          msg: chatProvider
                                              .getChatList[index], // chatList[index].msg,
                                          chatIndex: index, //chatList[index].chatIndex,
                                          shouldAnimate:
                                              chatProvider.getChatList.length - 1 == index,
                                                                          );
                                      }),
                                  ),
                  
                                if (_isTyping) ...[
                                  const SpinKitThreeBounce(
                                    color: Colors.white,
                                    size: 18,
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ));
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
      if (_askText.text.isEmpty) {
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
        String msg = _askText.text;
        setState(() {
          _isTyping = true;
          // chatList.add(ChatModel(msg: textEditingController.text, chatIndex: 0));
          chatProvider.addUserMessage(msg: msg);
          _askText.clear();
          focusNode.unfocus();
        });
        await chatProvider.sendMessageAndGetAnswersSummarize(msg: msg);
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

