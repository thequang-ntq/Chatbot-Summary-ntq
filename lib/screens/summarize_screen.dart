import 'dart:async';
import 'dart:ui';
import 'dart:io';
import 'dart:developer';
import 'dart:convert';
import 'package:connection_notifier/connection_notifier.dart';
import 'package:chatgpt/screens/internet.dart';
import 'package:flutter/services.dart';
import 'package:chatgpt/screens/loading.dart';
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
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:chatgpt/screens/home.dart';
import 'package:chatgpt/widgets/chats/docs_widget.dart';
import 'package:docx_to_text/docx_to_text.dart';
import 'package:intl/intl.dart';
import 'package:chatgpt/widgets/chats/chat_widget.dart';
import 'package:chatgpt/menubar/menu_sum.dart';
import 'package:open_filex/open_filex.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';

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
Summarize the following text {text} in 4 words or fewer.
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
  bool _isTyping = false;
  bool _isListening = false;
  bool _first = true;

  @override
  void initState() {
    _askText = TextEditingController();
    _summarizeText = TextEditingController();
    _listScrollController = ScrollController();
    focusNode = FocusNode();
    _speech = stt.SpeechToText();
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Kiểm tra nếu đang load lại conversation cũ
    if (GetV.menuSumPressed) {
      setState(() {
        GetV.menuSumPressed = false;
      });
    }
  }

  @override
  void dispose() {
    _listScrollController.dispose();
    _summarizeText.dispose();
    _askText.dispose();
    super.dispose();
  }

  void notify(String message) {
    if (!mounted) return;
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

  void toRefresh(){
    if (!mounted) return;
    // Reset state
    setState(() {
      _first = true;
      fileName = '';
      fileType = '';
      fileText = '';
      textLast = '';
      q1 = 'Empty';
      q2 = 'Empty';
      q3 = 'Empty';
    });
    
    Navigator.pop(context);
    Navigator.pop(context);
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const SummarizeScreen()),
    );
  }

  // Updated PDF text extraction using syncfusion_flutter_pdf
  Future<String> extractTextFromPdf(String filePath) async {
    try {
      final File pdfFile = File(filePath);
      final PdfDocument document = PdfDocument(inputBytes: await pdfFile.readAsBytes());
      
      String text = PdfTextExtractor(document).extractText();
      document.dispose();
      
      return text;
    } catch (e) {
      debugPrint('Error extracting PDF text: $e');
      return '';
    }
  }

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

  Future<void> _uploadFile() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.any);
    if (result == null) {
      return;
    } else {
      PlatformFile file = result.files.first;
      fileType = file.name.split('.').last;
      fileName = file.name;
      GetV.filetype = fileType;
      notify('Uploading file');
      
      if(fileType == "txt"){
        final File txtFile = File(file.path!);
        fileText = await txtFile.readAsString();
        textLast = fileText;
      }
      else if (fileType == "pdf"){
        fileText = await extractTextFromPdf(file.path!);
        textLast = fileText;
      }
      else if (fileType == "docx"){
        final fileDoc = File(file.path!);
        final Uint8List bytes = await fileDoc.readAsBytes();
        fileText = docxToText(bytes);
        textLast = fileText;
      }
      else {
        convertSpeechToText(file.path!).then((value) {
          if (mounted) {
            setState(() {
              fileText = value;
              textLast = fileText;
            });
          }
        });
        textLast = fileText;
      }
      
      if (mounted) {
        setState(() {
          GetV.hasFiled = true;
          GetV.text = fileText;
          GetV.filetype = fileType;
          GetV.filepath = file.path!;
          GetV.loadingUploadFile = false; // Đặt false để hiển thị loading
        });
      }
      
      GetV.filetype = fileType;
      GetV.filepath = file.path!;
      notify('Summarizing document');
      
      // Chỉ gọi saveDocsSummarize 1 lần duy nhất
      await saveDocsSummarize(msg: textLast, file: file);
      
      // Sau khi lưu xong mới set loadingUploadFile = true
      if (mounted) {
        setState(() {
          GetV.loadingUploadFile = true;
        });
      }
      return;
    }
  }

  void onListen() async {
    if (!_isListening) {
      bool available = await _speech.initialize(
          onStatus: (val) {
            if (val == "done") {
              if (mounted) {
                setState(() {
                  _isListening = false;
                  _speech.stop();
                });
              }
            }
          },
          onError: (val) => debugPrint("error: $val"));
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
              if (!mounted) return;
              const Center(
                child: CircularProgressIndicator()
              );
              setState(() {
                GetV.title = '';
                GetV.submited = false;
                GetV.summarized =false;
                GetV.chated = false;
                GetV.loadingUploadFile = false;
                GetV.hasFiled = false; // Reset về trạng thái chưa có file
              });
              final res = await FirebaseFirestore.instance.collection(GetV.userName.text).doc(GetV.userSummaryID).collection('Summarize')
                  .doc(GetV.messageSummaryID).get();
              if(res.exists && res['text'] == ''){
                await FirebaseFirestore.instance.collection(GetV.userName.text).doc(GetV.userSummaryID).collection('Summarize')
                .doc(GetV.messageSummaryID).delete();
              }
              if (!mounted) return;
              Navigator.pop(context);
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
      body: ConnectionNotifierToggler(
        onConnectionStatusChanged: (connected) {
          if (connected == null) return;
        },
        disconnected: const InternetErr(),
        connected: SafeArea(
          child: GetV.hasFiled == false
            ? _buildUploadView()
            : _buildChatView(chatProvider),
        ),
      ),
    );
  }

  Widget _buildUploadView() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const SizedBox(height: 50),
        Flexible(
          child: Center(
            child: ElevatedButton(
              onPressed: () {
                _uploadFile();
              },
              style: ElevatedButton.styleFrom(
                fixedSize: const Size(180, 200),
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20.0),
                ),
                elevation: 5,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(15.0),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
                      child: Container(
                        height: 120,
                        width: 160,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(15.0),
                          color: Colors.black.withValues(alpha: 0.2),
                        ),
                        child: Image.asset(
                          'assets/images/upload_pic.png',
                          height: 120,
                          width: 160,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 19),
                  const Text(
                    'Upload a file',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (_isTyping) ...[
          const SpinKitThreeBounce(
            color: Colors.black,
            size: 20,
          ),
        ],
        const SizedBox(height: 15),
        _buildInputArea(),
      ],
    );
  }

  Widget _buildChatView(ChatProvider chatProvider) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildFileNameButton(),
        const SizedBox(height: 10),
        Flexible(
          child: GetV.loadingUploadFile == false
              ? const Center(
                  child: CircularProgressIndicator(
                    color: Colors.black,
                  ),
                )
              : _buildMessagesList(),
        ),
        if (_isTyping) ...[
          const SpinKitThreeBounce(
            color: Colors.black,
            size: 20,
          ),
        ],
        const SizedBox(height: 15),
        _buildInputArea(),
      ],
    );
  }

  Widget _buildFileNameButton() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: ElevatedButton.icon(
        onPressed: () async {
          if (fileName.isNotEmpty) {
            OpenFilex.open(GetV.filepath);
          }
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.grey[100],
          foregroundColor: Colors.black,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        icon: Icon(_getFileIcon(), size: 20),
        label: Text(
          fileName,
          style: const TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 16,
          ),
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }

  IconData _getFileIcon() {
    switch (fileType.toLowerCase()) {
      case 'pdf':
        return Icons.picture_as_pdf;
      case 'docx':
      case 'doc':
        return Icons.description;
      case 'txt':
        return Icons.text_snippet;
      default:
        return Icons.audio_file;
    }
  }

  Widget _buildMessagesList() {
    return StreamBuilder(
      stream: FirebaseFirestore.instance
          .collection(GetV.userName.text)
          .doc(GetV.userSummaryID)
          .collection('Summarize')
          .doc(GetV.messageSummaryID)
          .collection('SummaryItem${GetV.summaryNum}')
          .orderBy('createdAt', descending: false)
          .snapshots(),
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
        return ListView.builder(
          controller: _listScrollController,
          itemCount: loadedMessages.length,
          itemBuilder: (context, index) {
            final chatMessage = loadedMessages[index].data();
            DateTime time = chatMessage['createdAt'].toDate();
            String formattedDate = DateFormat('dd/MM/yyyy, hh:mm a').format(time);
            
            return _first
                ? DocsWidget(
                    msg: chatMessage['text'],
                    q1: q1,
                    q2: q2,
                    q3: q3,
                    chatIndex: chatMessage['index'],
                    dateTime: formattedDate,
                    onPress: onPress,
                    shouldAnimate: false,
                  )
                : ChatWidget(
                    msg: chatMessage['text'],
                    dateTime: formattedDate,
                    chatIndex: chatMessage['index'],
                    shouldAnimate: false,
                  );
          },
        );
      },
    );
  }

  Widget _buildInputArea() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[600],
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(25),
                ),
                child: TextField(
                  focusNode: focusNode,
                  style: const TextStyle(color: Colors.white),
                  controller: _askText,
                  onSubmitted: (value) async {
                    if (GetV.hasFiled) {
                      await sendMessageFCT(chatProvider: Provider.of<ChatProvider>(context, listen: false));
                    } else {
                      _showNoFileDialog();
                    }
                  },
                  decoration: const InputDecoration.collapsed(
                    hintText: "Ask something...",
                    hintStyle: TextStyle(color: Colors.white70),
                  ),
                  maxLines: null,
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              onPressed: () async {
                if (GetV.hasFiled) {
                  await sendMessageFCT(chatProvider: Provider.of<ChatProvider>(context, listen: false));
                } else {
                  _showNoFileDialog();
                }
              },
              tooltip: 'Send message...',
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(
                  Icons.send,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
            const SizedBox(width: 4),
            FloatingActionButton(
              mini: true,
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
    );
  }

  void _showNoFileDialog() {
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          title: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.orange),
              SizedBox(width: 8),
              Text('No File Selected'),
            ],
          ),
          content: const Text('You have not chosen a file yet! Please choose a file first.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  void scrollListToEND() {
    _listScrollController.animateTo(
      _listScrollController.position.maxScrollExtent,
      duration: const Duration(seconds: 2),
      curve: Curves.easeOut,
    );
  }

  // Updated saveDocsSummarize function
  Future<void> saveDocsSummarize({required String msg, required PlatformFile file}) async {
    try {
      final llm = ChatOpenAI(
        apiKey: GetV.apiKey.text,
        defaultOptions: const ChatOpenAIOptions(
          model: 'gpt-4o-mini',
          temperature: 0,
        ),
      );

      if (GetV.filetype == "txt") {
        // Load and split documents
        // Load file manually
        final file = File(GetV.filepath);
        final content = await file.readAsString();
        final documents = [
          Document(pageContent: content, metadata: {'source': GetV.filepath}),
        ];

        const textSplitter = RecursiveCharacterTextSplitter(
          chunkSize: 1000,
          chunkOverlap: 200,
        );
        final docsChunks = textSplitter.splitDocuments(documents);

        notify('Store Document Embeddings');

        // Create summarization prompt
        final docContents = docsChunks.map((doc) => doc.pageContent).join('\n\n');
        final prompt = template.replaceAll('{context}', docContents);

        notify('Summarize Document');

        final response = await llm.invoke(PromptValue.string(prompt));
        final result = response.outputAsString;

        // Extract summary and questions
        try {
          final textSum = _extractSection(result, start, start1);
          q1 = _extractSection(result, start1, start2);
          q2 = _extractSection(result, start2, start3);
          q3 = result.substring(result.indexOf(start3) + start3.length).trim();

          // Save to Firestore - CHỈ LƯU 1 LẦN
          await FirebaseFirestore.instance
              .collection(GetV.userName.text)
              .doc(GetV.userSummaryID)
              .collection('Summarize')
              .doc(GetV.messageSummaryID)
              .collection('SummaryItem${GetV.summaryNum}')
              .add({
            'text': textSum,
            'index': 3,
            'createdAt': Timestamp.now(),
          });

          // Generate title if needed
          if (GetV.title == '') {
            final titlePrompt = template2.replaceAll('{text}', textSum);
            final titleResponse = await llm.invoke(PromptValue.string(titlePrompt));
            GetV.title = titleResponse.outputAsString;

            await FirebaseFirestore.instance
                .collection(GetV.userName.text)
                .doc(GetV.userSummaryID)
                .collection('Summarize')
                .doc(GetV.messageSummaryID)
                .update({
              'text': GetV.title,
              'Index': GetV.summaryNum,
              'messageID': GetV.messageSummaryID,
            });
          }

          GetV.summaryText = result;
        } catch (e) {
          debugPrint('Error parsing summary result: $e');
          // Fallback if parsing fails
          q1 = 'What is the main topic?';
          q2 = 'What are the key points?';
          q3 = 'What conclusions can be drawn?';
        }
      } else {
        // For other file types
        String embeddedText = '';
        if (msg.length > 4000) {
          embeddedText = msg.substring(0, 4000);
        } else {
          embeddedText = msg;
        }

        notify('Summarize documents');

        final prompt = templateX.replaceAll('{subject}', embeddedText);
        final response = await llm.invoke(PromptValue.string(prompt));
        final result = response.outputAsString;

        // Extract summary and questions
        try {
          final textSum = result.substring(0, result.indexOf(starts1)).trim();
          q1 = _extractSection(result, starts1, starts2);
          q2 = _extractSection(result, starts2, starts3);
          q3 = result.substring(result.indexOf(starts3) + starts3.length).trim();

          // Save to Firestore - CHỈ LƯU 1 LẦN
          await FirebaseFirestore.instance
              .collection(GetV.userName.text)
              .doc(GetV.userSummaryID)
              .collection('Summarize')
              .doc(GetV.messageSummaryID)
              .collection('SummaryItem${GetV.summaryNum}')
              .add({
            'text': textSum,
            'index': 3,
            'createdAt': Timestamp.now(),
          });

          // Generate title if needed
          if (GetV.title == '') {
            final titlePrompt = template2.replaceAll('{text}', textSum);
            final titleResponse = await llm.invoke(PromptValue.string(titlePrompt));
            GetV.title = titleResponse.outputAsString;

            await FirebaseFirestore.instance
                .collection(GetV.userName.text)
                .doc(GetV.userSummaryID)
                .collection('Summarize')
                .doc(GetV.messageSummaryID)
                .update({
              'text': GetV.title,
              'Index': GetV.summaryNum,
              'messageID': GetV.messageSummaryID,
            });
          }

          GetV.summaryText = result;
        } catch (e) {
          debugPrint('Error parsing summary result: $e');
          q1 = 'What is discussed in this document?';
          q2 = 'What are the main findings?';
          q3 = 'What should I know?';
        }
      }
      
      // QUAN TRỌNG: Không gọi setState ở đây
      // Chỉ notify completion thông qua các biến GetV đã set ở trên
      
    } catch (e) {
      debugPrint('Error in saveDocsSummarize: $e');
      // Nếu có lỗi, vẫn set loadingUploadFile = true để không bị loading mãi
      if (mounted) {
        setState(() {
          GetV.loadingUploadFile = true;
        });
      }
      rethrow;
    }
  }

  String _extractSection(String text, String startMarker, String endMarker) {
    try {
      final startIndex = text.indexOf(startMarker);
      final endIndex = text.indexOf(endMarker);
      
      if (startIndex != -1 && endIndex != -1) {
        return text.substring(startIndex + startMarker.length, endIndex).trim();
      }
      return '';
    } catch (e) {
      return '';
    }
  }

  Future<void> sendMessageFCT({required ChatProvider chatProvider}) async {
    if (_isTyping) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "You can't send multiple messages at a time",
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    if (_askText.text.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Please type a message",
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
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
      if (_isListening) {
        setState(() {
          _isListening = false;
          _speech.stop();
        });
      }
      
      setState(() {
        _isTyping = true;
        _first = false;
        chatProvider.addUserMessage(msg: msg);
        _askText.clear();
        focusNode.unfocus();
      });
      
      await chatProvider.sendMessageAndGetAnswersSummarize(msg: msg);
      if (mounted) {
        setState(() {});
      }
    } catch (error) {
      log("error $error");
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            error.toString(),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          scrollListToEND();
          _isTyping = false;
        });
      }
    }
  }
}