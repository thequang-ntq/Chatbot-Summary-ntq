// import 'dart:async';
import 'dart:ui';
import 'dart:io';
import 'dart:developer';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:flutter/material.dart';
import 'package:langchain/langchain.dart';
import 'package:langchain_openai/langchain_openai.dart';
import 'package:chatgpt/screens/tabs.dart';
import 'package:file_picker/file_picker.dart';
import 'package:open_file/open_file.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:chatgpt/providers/chats/chats_provider.dart';
import 'package:provider/provider.dart';
import 'package:pdf_text/pdf_text.dart';
import 'package:google_speech/google_speech.dart';
import 'package:path_provider/path_provider.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:chatgpt/screens/home.dart';
import 'package:chatgpt/widgets/chats/docs_widget.dart';
import 'package:intl/intl.dart';
import 'package:chatgpt/widgets/chats/chat_widget.dart';
import 'package:docx_to_text/docx_to_text.dart';


const template = '''
Summarize the following text: {subject} in less than 260 words, then show 3 questions related to the paragraph just summarized in the following format:

<br>
Question1:
</br>

<br>
Question2:
</br>

<br>
Question3:
</br>

''';

const start1 = "Question 1:";
const start2 = "Question 2:";
const start3 = "Question 3:";

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
  String q1 = 'What is the main topic of this document?';
  String q2 = 'What areas can this document be applied to?';
  String q3 = 'Can I use this document to practice\n creating my own PDFs?';
  String answerSummary = 'Not have text';
  late ScrollController _listScrollController;
  late FocusNode focusNode;
  late stt.SpeechToText _speech;

  late TextEditingController _summarizeText;
  bool _hasFiled = false;
  bool _isTyping = false;
  bool _isListening = false;
  bool _first = true;

  @override
  void initState() {
    _askText = TextEditingController();
    _summarizeText = TextEditingController();
    _listScrollController = ScrollController();
    focusNode = FocusNode();
    super.initState();
    _speech = stt.SpeechToText();
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

  Future<List<int>> _getAudioContent(String name) async {
    
   final directory = await getApplicationDocumentsDirectory();
   final path = directory.path + '/$name';
   return File(path).readAsBytesSync().toList();
 }


  void _uploadFile() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.any);
    if (result == null) {
      return ;
    } else {
      PlatformFile file = result.files.first;
      fileType = file.name.split('.').last;
      fileName = file.name;
      if(fileType == "txt"){
        fileText = utf8.decode(file.bytes!);
        textLast = fileText;
      }
      else if (fileType == "pdf"){
        final File pdfFile = File(file.path!);
        PDFDoc doc = await PDFDoc.fromFile(pdfFile);
        fileText = await doc.text;
        textLast = fileText;
      }
      else if (fileType == "mp3" || fileType == "wav"){
         final config = RecognitionConfig(
          encoding: AudioEncoding.LINEAR16,
          model: RecognitionModel.basic,
          enableAutomaticPunctuation: true,
          sampleRateHertz: 16000,
          languageCode: 'en-US');
          final serviceAccount = ServiceAccount.fromFile(File('assets/service_account/brycen-chat-app-ntq-e5fd13b4cad3.json'));
          final speechToText = SpeechToText.viaServiceAccount(serviceAccount);

          final audio = await _getAudioContent(fileName);
          await speechToText.recognize(config, audio).then((value) {
            setState(() {
              fileText = value.results
                  .map((e) => e.alternatives.first.transcript)
                  .join('\n');
            });
          });
          textLast = fileText;
      }
      else if (fileType == "docx"){
        final File _doc = File(file.path!);
        final bytes = await _doc.readAsBytes();
        fileText = docxToText(bytes);
        textLast = fileText;
      }
      setState(() {
        _hasFiled = true;
      });
      await saveDocsSummarize(msg: textLast);  
      return ;
    }
  }


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
            listenFor: const Duration(hours: 12),
            onResult: (val) => setState(() {
                  _askText.text = val.recognizedWords;
                  if (_isTyping == true) {
                    _askText.clear();
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

  void onPress(String question){
    setState(() {
      _askText.text = question;
    });
  }

  @override
  Widget build(BuildContext context) {
    final chatProvider = Provider.of<ChatProvider>(context);
    return Scaffold(
        appBar: AppBar(
          elevation: 2,
          leading: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Image.asset('assets/images/Docs.png'),
          ),
          backgroundColor: Colors.grey[50],
          title: const Text('Summarize', style: TextStyle(color: Colors.black, fontWeight: FontWeight.w600)),
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
        backgroundColor: const Color(0xFF343541),
        body: SafeArea(
          child: _hasFiled == false?
           
              Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children:[
                  const SizedBox(height: 50),
                  Flexible(
                    child: ElevatedButton(
                      onPressed: () {
                        _uploadFile();                                              
                      },
                      style: ButtonStyle(
                        fixedSize: MaterialStateProperty.all(
                          const Size(150, 170),
                        ),
                        backgroundColor: MaterialStateProperty.resolveWith<Color>(
                          (Set<MaterialState> states) {
                            if (states.contains(MaterialState.pressed)) {
                              return Colors.green;
                            }
                            return Colors.orange;
                          },
                        ),
                        shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                          RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20.0),
                          ),
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(15.0), 
                            child: BackdropFilter(
                              filter: ImageFilter.blur(
                                  sigmaX: 5.0, sigmaY: 5.0), 
                              child: Container(
                                height: 110,
                                width: 155,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(15.0),
                                  color: Colors.black.withOpacity(0.2), 
                                ),
                                child: Image.asset(
                                  'assets/images/upload_pic.png',
                                  height: 110,
                                  width: 155,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 19),
                          const Text(
                              'Upload a file',
                              style: TextStyle(fontSize: 18),
                            ),
                        ],
                      ),
                    ),
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
                  color: const Color(0xFF444654),
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            focusNode: focusNode,
                            style: const TextStyle(color: Colors.white),
                            controller: _askText,
                            onSubmitted: (value){
                              showDialog(
                                context: context,
                                builder: (context) {
                                  return const AlertDialog(
                                    content: Text('You are not choose file yet ! Please choose a file'),
                                  );
                                },
                              );
                            },
                            decoration: const InputDecoration.collapsed(
                                hintText: "Ask something...",
                                hintStyle: TextStyle(color: Colors.grey)),
                          ),
                        ),
                        IconButton(
                            onPressed: (){
                              showDialog(
                                context: context,
                                builder: (context) {
                                  return const AlertDialog(
                                    content: Text('You are not choose file yet ! Please choose a file'),
                                  );
                                },
                              );
                            },
                            tooltip: 'Send message...',
                            icon: const Icon(
                              Icons.send,
                              color: Colors.white,
                            ),
                        ),
                        FloatingActionButton(
                          backgroundColor: Colors.grey,
                          onPressed: () => onListen(),
                          tooltip: 'Click and speak something...',
                          child: Icon(
                            _isListening ? Icons.mic_off : Icons.mic,
                            color: Colors.white,
                          ),
                        ),
                      ],
                      
                    ),
                  ),
                ),
                ],
              )
            
          : 
              Column(
                children: [
                  TextButton(
                    onPressed: () {
                      final snackBar = SnackBar(
                        backgroundColor: Colors.white,
                        content: Padding(
                          padding: const EdgeInsets.all(5.0),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const SizedBox(height: 2),
                              Text('FileName: $fileName', style: const TextStyle(
                                color: Colors.black,
                                fontWeight: FontWeight.w500,
                                fontSize: 14,
                              )),
                              const SizedBox(width: 40,),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                mainAxisSize: MainAxisSize.min,
                                children:[
                                  
                                  const Text('Topic', style:TextStyle(
                                    color: Colors.black,
                                    fontWeight: FontWeight.w500,
                                    fontSize: 14,
                                  )),
                                  IconButton(
                                    onPressed: () {
                                      Clipboard.setData(ClipboardData(text: fileText));
                                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                        content: const Text('Text Copied to Clipboard!'),
                                        duration: const Duration(milliseconds: 1000),
                                        action: SnackBarAction(
                                          label: 'ok',
                                          onPressed: () {},
                                        ),
                                      ));
                                    },
                                    icon: const Icon(Icons.text_snippet_sharp),
                                    color: Colors.black,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 3,),
                              Flexible(
                                child: Text(fileText, style: const TextStyle(
                                  backgroundColor: Color.fromARGB(255, 173, 172, 172),
                                  color: Colors.black,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                )),
                              ),
                            ]
                          ),
                        ),
                        action: SnackBarAction(
                          label: 'Ok',
                          textColor: Colors.blue,
                          onPressed: () {
                          },
                        ),
                      );
                      ScaffoldMessenger.of(context).showSnackBar(snackBar);
                    },
                    style: ButtonStyle(backgroundColor: MaterialStateProperty.all(Colors.grey[100])),
                    child: Text(
                      fileName, style: const TextStyle(
                        fontWeight: FontWeight.w400,
                        color: Colors.black,
                        fontSize: 19,
                        
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Flexible(
                    child: StreamBuilder(
                      stream: FirebaseFirestore.instance.collection(GetV.userName.text).doc(GetV.userSummaryID)
                        .collection('Summarize').orderBy('createdAt', descending:false).snapshots(),
                      builder: (context, snapshot) {
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
                        return 
                          ListView.builder(
                            controller: _listScrollController,
                            itemCount: loadedMessages.length, 
                            itemBuilder: (context, index) {
                              final chatMessage = loadedMessages[index].data();
                              DateTime time = chatMessage['createdAt'].toDate();
                              String formattedDate = DateFormat('dd/MM/yyyy, hh:mm a').format(time);
                              return _first?
                                DocsWidget(
                                  msg: chatMessage['text'],
                                  q1: q1,
                                  q2: q2,
                                  q3: q3,
                                  chatIndex: chatMessage['index'],
                                  dateTime: formattedDate,
                                  onPress: onPress,
                                  shouldAnimate:
                                      chatMessage['index']%2 == 1,
                                )
                              :
                                ChatWidget(
                          msg: chatMessage['text'],
                          dateTime: formattedDate,
                          chatIndex: chatMessage['index'], 
                          shouldAnimate:
                              chatMessage['index'] == 1,
                        );
                            }
                              
                              
                          );
                            
                      }
                    ),
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
                    color: const Color(0xFF444654),
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              focusNode: focusNode,
                              style: const TextStyle(color: Colors.white),
                              controller: _askText,
                              onSubmitted: (value) async {
                                await sendMessageFCT(
                                    
                                    chatProvider: chatProvider);
                              },
                              decoration: const InputDecoration.collapsed(
                                  hintText: "Ask something ...",
                                  hintStyle: TextStyle(color: Colors.grey)),
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
                            backgroundColor: Colors.grey,
                            onPressed: () => onListen(),
                            tooltip: 'Click and speak something...',
                            child: Icon(
                              _isListening ? Icons.mic_off : Icons.mic,
                              color: Colors.white,
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

  void scrollListToEND() {
      _listScrollController.animateTo(
          _listScrollController.position.maxScrollExtent,
          duration: const Duration(seconds: 2),
          curve: Curves.easeOut);
  }

  Future<void> saveDocsSummarize(
      {required String msg}) async {
      final llm = ChatOpenAI(apiKey: GetV.apiKey.text, temperature: 0);
      final promptTemplate = PromptTemplate.fromTemplate(
        template,
      );
      final prompt = promptTemplate.format({'subject': msg});
      final result = await llm.predict(prompt);
      final textSum = result.substring(0, result.indexOf(start1));
      // print(result.indexOf(start1));
      q1 = result.substring(result.indexOf(start1) + start1.length, result.indexOf(start2));
      q2 = result.substring(result.indexOf(start2) + start2.length, result.indexOf(start3));
      q3 = result.substring(result.indexOf(start3) + start3.length, result.length);
      await FirebaseFirestore.instance.collection(GetV.userName.text).doc(GetV.userSummaryID).collection('Summarize').add({
        'text' : textSum,
        'index' : 3,
        'createdAt': Timestamp.now(),
      });
      GetV.summaryText = result;
      
    // notifyListeners();
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
          _first = false;
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
