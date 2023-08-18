//This is the summarize screen, the User Interface when you enter the Summary file part.
//Its important too.

import 'dart:async';
import 'dart:ui';
import 'dart:io';
import 'dart:developer';
import 'dart:convert';
import 'package:connection_notifier/connection_notifier.dart';
import 'package:chatgpt/screens/internet.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:flutter/material.dart';
import 'package:langchain/langchain.dart';
import 'package:langchain_openai/langchain_openai.dart';
import 'package:chatgpt/screens/tabs.dart';
import 'package:file_picker/file_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:chatgpt/providers/chats/chats_provider.dart';
import 'package:provider/provider.dart';
import 'package:pdf_text/pdf_text.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:chatgpt/screens/home.dart';
import 'package:chatgpt/widgets/chats/docs_widget.dart';
import 'package:docx_to_text/docx_to_text.dart';
import 'package:intl/intl.dart';
import 'package:chatgpt/widgets/chats/chat_widget.dart';
import 'package:chatgpt/menubar/menu_sum.dart';
import 'package:open_file/open_file.dart';

const template = '''
Detect language, Write a concise summary of the following context:

"{context}"

then give 3 short related questions. the Response Use Detected language with following:

"TOPIC
<br>
SUMMARY

<br>
QUESTION 1

<br>
QUESTION 2

<br>
QUESTION 3"
 ''';

const template2 = '''
Detect language, Summarize the following text {text} in 4 words or fewer.
''';

const templateX = '''
Detect language, Summarize the following text: {subject} in less than 250 words, then show 3 questions related to the paragraph just summarized in the following format:

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

const start = "SUMMARY:";
const start1 = "QUESTION 1:";
const start2 = "QUESTION 2:";
const start3 = "QUESTION 3:";

const starts1 = "Question 1:";
const starts2 = "Question 2:";
const starts3 = "Question 3:";

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
  String q1 = 'Empty';
  String q2 = 'Empty';
  String q3 = 'Empty';
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

  // Snackbar Notify message
  void notify(String message) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: Colors.black,
        content: Text('$message...', style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w400,
        )),
      ),
    );
  }


  //toRefresh function that defined in menu_sum.dart
  void toRefresh(){
    Navigator.pop(context);
    Navigator.pop(context);
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const SummarizeScreen()),
    );
  }

  //convert audio to text when upload audio file
   Future<String> convertSpeechToText(String filePath) async {
    String apiKey = GetV.apiKey.text;
    var url = Uri.https("api.openai.com", "v1/audio/transcriptions");
    var request = http.MultipartRequest('POST', url);
    request.headers.addAll(({"Authorization": "Bearer $apiKey"}));
    request.fields["model"] = 'whisper-1';
    request.fields["language"] = "en";
    request.files.add(await http.MultipartFile.fromPath('file', filePath));
    var response = await request.send();
    var newresponse = await http.Response.fromStream(response);
    final responseData = json.decode(newresponse.body);

    return responseData['text'];
  }

  //function when you upload a file
  Future<void> _uploadFile() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.any);
    if (result == null) {
      return ;
    } else {
      PlatformFile file = result.files.first;
      fileType = file.name.split('.').last;
      fileName = file.name;
      GetV.filetype = fileType;
      notify('Uploading file...');
      if(fileType == "txt"){
        final File txtFile = File(file.path!);
        fileText = await txtFile.readAsString();
        textLast = fileText;
      }
      else if (fileType == "pdf"){
        final File pdfFile = File(file.path!);
        PDFDoc doc = await PDFDoc.fromFile(pdfFile);
        fileText = await doc.text;
        textLast = fileText;
      }
      
      else if (fileType == "docx"){
        final fileDoc = File(file.path!);
        final Uint8List bytes = await fileDoc.readAsBytes();
        fileText = docxToText(bytes);
        textLast = fileText;
      }
      else{ //audio file
        convertSpeechToText(file.path!).then((value) {
          setState(() {
            fileText = value;
            textLast = fileText;
          });
        });
        textLast = fileText; 
      }
      setState(() {
        _hasFiled = true;
        GetV.text = fileText;
        GetV.filetype = fileType;
        GetV.filepath = file.path!;
        
      });
      GetV.filetype = fileType;
      GetV.filepath = file.path!;
      notify('Summarizing document...');
      await saveDocsSummarize(msg: textLast, file: file);  
      return ;
    }
  }

  //micro function (you talk then its appear in ask textfield)
  void onListen() async {
    if (!_isListening) {
      bool available = await _speech.initialize(
          onStatus: (val) {
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

  //Get the text of the suggest question to your ask textfield when you press the send icon in
  //the begin of those 3 questions
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
          backgroundColor: Colors.grey[50],
          title: const Text('Summarize', style: TextStyle(color: Colors.black, fontWeight: FontWeight.w600)),
          centerTitle: false,
          actions: [
            IconButton(
              onPressed: () async{
                GetV.title = '';

                final res = await FirebaseFirestore.instance.collection(GetV.userName.text).doc(GetV.userSummaryID).collection('Summarize')
                    .doc(GetV.messageSummaryID).get();
                if(res['text'] == ''){
                  await FirebaseFirestore.instance.collection(GetV.userName.text).doc(GetV.userSummaryID).collection('Summarize')
                  .doc(GetV.messageSummaryID).delete();
                  
                }
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const Tabs()),
                );
              },
              icon: const Icon(
                Icons.exit_to_app,
                color: Colors.black,
              ),
            ),
          ],
        ),
        drawer: MenuSum(toRefresh: toRefresh),
        backgroundColor: Colors.grey[300],
        body:  ConnectionNotifierToggler(
          onConnectionStatusChanged: (connected) {
            if (connected == null) return;
          },
          disconnected: const InternetErr(),
          connected: SafeArea(
            child: _hasFiled == false?
             
                Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children:[
                    const SizedBox(height: 50),
                    //Upload file button
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
                      color: Colors.black,
                      size: 20,
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
                                  hintStyle: TextStyle(color: Colors.white)),
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
                )
              
            : 
                
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      //Button that contains the main text content of the file
                      TextButton(
                        onPressed: () async{
                          if(fileName.isNotEmpty){
                            OpenFile.open(GetV.filepath);
                          }
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
                            .collection('Summarize').doc(GetV.messageSummaryID)
                            .collection('SummaryItem${GetV.summaryNum}')
                            .orderBy('createdAt', descending:false).snapshots(),
                          builder: (context, AsyncSnapshot snapshot) {
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
                                          false,
                                    )
                                  :
                                    ChatWidget(
                                      msg: chatMessage['text'],
                                      dateTime: formattedDate,
                                      chatIndex: chatMessage['index'], 
                                      shouldAnimate:
                                        false,
                                    );
                                }
                                  
                                  
                              );
                                
                          }
                        ),
                      ),
                      if (_isTyping) ...[
                        const SpinKitThreeBounce(
                          color: Colors.black,
                          size: 20,
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
                                //Ask textfield
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
                                //Send message button
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
        ),
    );
  }

  //scroll the ListView of the summarize chat
  void scrollListToEND() {
      _listScrollController.animateTo(
          _listScrollController.position.maxScrollExtent,
          duration: const Duration(seconds: 2),
          curve: Curves.easeOut);
  }

  // This function will get the summarize content of the file you uploaded
  Future<void> saveDocsSummarize(
      {required String msg, required PlatformFile file}) async {
      if(GetV.filetype == "txt" || GetV.filetype == "wav" || GetV.filetype == "docx"){
        TextLoader loader = TextLoader(GetV.filepath);
        const textSplitter = RecursiveCharacterTextSplitter();
        final docs = await loader.load();
        final docsChunks = textSplitter.splitDocuments(docs);
        notify('Store Document Embeddings...');
        final llm = ChatOpenAI(apiKey: GetV.apiKey.text, model: 'gpt-3.5-turbo-16k-0613',temperature: 0);
        final docPrompt = PromptTemplate.fromTemplate(
          template,
        );
        final summarizeChain = SummarizeChain.stuff(
          llm: llm,
          promptTemplate: docPrompt,
        );
        notify('Summarize Document...');
        final result = await summarizeChain.run(docsChunks);
        final textSum = result.substring(result.indexOf(start) + start.length, result.indexOf(start1));
        // print(result.indexOf(start1));
        q1 = result.substring(result.indexOf(start1) + start1.length, result.indexOf(start2));
        q2 = result.substring(result.indexOf(start2) + start2.length, result.indexOf(start3));
        q3 = result.substring(result.indexOf(start3) + start3.length, result.length);
        await FirebaseFirestore.instance.collection(GetV.userName.text).doc(GetV.userSummaryID)
          .collection('Summarize').doc(GetV.messageSummaryID).collection('SummaryItem${GetV.summaryNum}').add({
          'text' : textSum,
          'index' : 3,
          'createdAt': Timestamp.now(),
        });
        if(GetV.title == ''){
          final promptTemplate2 = PromptTemplate.fromTemplate(template2);
          final prompt2 = promptTemplate2.format({'text' : textSum});
          final result2 = await llm.predict(prompt2);
          GetV.title = result2;
          await FirebaseFirestore.instance.collection(GetV.userName.text).doc(GetV.userSummaryID).collection('Summarize')
          .doc(GetV.messageSummaryID).update(
            {
              'text' : result2,
              'Index' : GetV.summaryNum,
              'messageID': GetV.messageSummaryID,
            }
          );
        }
        GetV.summaryText = result;
      }
      else{
        final llm = ChatOpenAI(apiKey: GetV.apiKey.text, model: 'gpt-3.5-turbo-0613' ,temperature: 0);
        final promptTemplateX = PromptTemplate.fromTemplate(
          templateX,
        );
        String embeddedText = '';
        if(msg.length > 4000){
          embeddedText = msg.substring(0, 4000);
        }
        else{
          embeddedText = msg;
        }
        notify('Summarize documents...');
        final promptX = promptTemplateX.format({'subject': embeddedText});
        final result = await llm.predict(promptX);
        
        final textSum = result.substring(0, result.indexOf(starts1));
        // print(result.indexOf(start1));
        q1 = result.substring(result.indexOf(starts1) + starts1.length, result.indexOf(starts2));
        q2 = result.substring(result.indexOf(starts2) + starts2.length, result.indexOf(starts3));
        q3 = result.substring(result.indexOf(starts3) + starts3.length, result.length);
        await FirebaseFirestore.instance.collection(GetV.userName.text).doc(GetV.userSummaryID)
          .collection('Summarize').doc(GetV.messageSummaryID).collection('SummaryItem${GetV.summaryNum}').add({
          'text' : textSum,
          'index' : 3,
          'createdAt': Timestamp.now(),
        });
        if(GetV.title == ''){
          final promptTemplate2 = PromptTemplate.fromTemplate(template2);
          final prompt2 = promptTemplate2.format({'text' : textSum});
          final result2 = await llm.predict(prompt2);
          GetV.title = result2;
          await FirebaseFirestore.instance.collection(GetV.userName.text).doc(GetV.userSummaryID).collection('Summarize')
          .doc(GetV.messageSummaryID).update(
            {
              'text' : result2,
              'Index' : GetV.summaryNum,
              'messageID': GetV.messageSummaryID,
            }
          );
        }
        GetV.summaryText = result;
      }
      
    // notifyListeners();
  }

  //Get your question content and send response
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
