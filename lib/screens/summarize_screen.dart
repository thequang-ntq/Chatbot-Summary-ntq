// Màn hình summarize tóm tắt tài liệu
// 

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
import 'package:chatgpt/services/file_storage_service.dart';
import 'package:path_provider/path_provider.dart';

// Các template được dùng

// Template này dùng để tóm tắt nội dung file được gửi.
// Trả lời theo ngôn ngữ được phát hiện trong nội dung file, rồi gửi 3 câu hỏi liên quan.
// Tất cả tóm lại thành 1 câu trả lời từ Chatbot.
const template = '''
Detect language and respond in that language.

Summarize this context concisely:
"{context}"

Then provide 3 related questions.

Format your response EXACTLY like this:
SUMMARY:
[Your summary here]

QUESTION 1:
[Question here]

QUESTION 2:
[Question here]

QUESTION 3:
[Question here]
''';

// Tương tự template trên nhưng tóm tắt trong dưới 250 từ.
const templateX = '''
Detect language and respond in that language.

Summarize this text in less than 250 words:
{subject}

Then provide 3 related questions.

Format your response EXACTLY like this:
[Your summary here]

Question 1:
[Question here]

Question 2:
[Question here]

Question 3:
[Question here]
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
    // Load lại thông tin khi vào từ menu
    if (GetV.menuSumPressed) {
      setState(() {
        GetV.menuSumPressed = false;
        // Load lại fileName và fileType
        fileName = GetV.fileName;
        fileType = GetV.fileType;
        
        // KHÔNG CẦN CHECK fileName nữa
        // Vì GetV.hasFiled đã được set đúng trong menu_sum.dart
        
        // Load lại questions từ Firestore
        _loadQuestionsFromFirestore();
      });
    }
  }

  // Thêm hàm này sau hàm didChangeDependencies, tải lại question từ firestore
  // Nội dung tin trả lời AI cho Chatbot:
  // createdAt: Thời điểm tạo
  // q1: Câu hỏi 1
  // q2: Câu hỏi 2
  // q3: Câu hỏi 3
  // text: Nội dung tóm tắt
  // index = 3 cho biết là nội dung tóm tắt chứ không phải câu hỏi câu trả lời sau khi tóm tắt.
  Future<void> _loadQuestionsFromFirestore() async {
    try {
      final summaryData = await FirebaseFirestore.instance
          .collection(GetV.userName.text)
          .doc(GetV.userSummaryID)
          .collection('Summarize')
          .doc(GetV.messageSummaryID)
          .collection('SummaryItem${GetV.summaryNum}')
          .where('index', isEqualTo: 3) // Lấy document tóm tắt
          .limit(1)
          .get();
      
      if (summaryData.docs.isNotEmpty) {
        final doc = summaryData.docs.first.data();
        
        // Lấy questions từ document
        if (doc.containsKey('q1')) {
          setState(() {
            q1 = doc['q1'] ?? 'Empty';
            q2 = doc['q2'] ?? 'Empty';
            q3 = doc['q3'] ?? 'Empty';
            _first = true;  // THÊM: Đảm bảo hiển thị DocsWidget
          });
        }
      }
    } 
    catch (e) {
      debugPrint('Error loading questions: $e');
    }
  }

  @override
  void dispose() {
    _listScrollController.dispose();
    _summarizeText.dispose();
    _askText.dispose();
    super.dispose();
  }

  // Thông báo
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

  // Tải lại từ menu
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
      
      // THÊM: Reset GetV file info
      GetV.fileName = '';
      GetV.fileType = '';
      GetV.filepath = '';
    });
    
    Navigator.pop(context);
    Navigator.pop(context);
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const SummarizeScreen()),
    );
  }

  // Updated PDF text extraction using syncfusion_flutter_pdf
  // Hàm tách nội dung trong file PDF
  Future<String> extractTextFromPdf(String filePath) async {
    try {
      final File pdfFile = File(filePath);
      final PdfDocument document = PdfDocument(inputBytes: await pdfFile.readAsBytes());
      
      String text = PdfTextExtractor(document).extractText();
      document.dispose();
      
      return text;
    } 
    catch (e) {
      debugPrint('Error extracting PDF text: $e');
      return '';
    }
  }

  // Speech to Text, chuyển nội dung nói thành nội dung chữ viết.
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

  // Hàm upload file ngoại trừ loại file txt lên cloudinary
  // File txt thì không upload không có file url
  Future<void> _uploadFile() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.any);
    if (result == null) {
      return;
    }
    
    PlatformFile file = result.files.first;
    fileType = file.name.split('.').last;
    fileName = file.name;
    
    GetV.filetype = fileType;
    GetV.fileName = fileName;
    GetV.fileType = fileType;
    
    notify('Uploading file');
    
    String? fileUrl;
    
    // Upload file lên Cloudinary
    if (fileType != "txt") {
      final File uploadFile = File(file.path!);
      fileUrl = await FileStorageService.uploadFile(uploadFile, fileType);
      
      if (fileUrl == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to upload file'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }
      GetV.fileurl = fileUrl;
    }
    
    // Đọc nội dung file
    if (fileType == "txt") {
      final File txtFile = File(file.path!);
      fileText = await txtFile.readAsString();
      textLast = fileText;
    } else if (fileType == "pdf") {
      fileText = await extractTextFromPdf(file.path!);
      textLast = fileText;
    } else if (fileType == "docx") {
      final fileDoc = File(file.path!);
      final Uint8List bytes = await fileDoc.readAsBytes();
      fileText = docxToText(bytes);
      textLast = fileText;
    } else {
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
        GetV.loadingUploadFile = false;
      });
    }
    
    notify('Summarizing document');
    
    // Lưu tin nhắn tóm tắt + 3 câu hỏi vào Firestore
    await saveDocsSummarize(msg: textLast, file: file, fileUrl: fileUrl);
    
    if (mounted) {
      setState(() {
        GetV.loadingUploadFile = true;
      });
    }
  }

  // Hàm mở FileOption dialog 
  void _showFileOptionsDialog(String fileName, String fileType) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Icon(_getFileIconForType(fileType), color: Colors.blue),
            const SizedBox(width: 8),
            const Flexible(
              child: Text(
                'File Options',
                style: TextStyle(fontSize: 18),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              fileName,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Type: ${fileType.toUpperCase()}',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'The original file is no longer on this device, but it\'s stored online.',
              style: TextStyle(fontSize: 14),
            ),
          ],
        ),
        actions: [
          // Nút thoát Dialog
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          // Nút copy URL file
          ElevatedButton.icon(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: GetV.fileurl));
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Row(
                    children: [
                      Icon(Icons.check_circle, color: Colors.white),
                      SizedBox(width: 8),
                      Text('File URL copied to clipboard!'),
                    ],
                  ),
                  backgroundColor: Colors.green,
                ),
              );
            },
            icon: const Icon(Icons.copy),
            label: const Text('Copy URL'),
          ),
          // Nút tải file
          ElevatedButton.icon(
            onPressed: () async {
              Navigator.pop(context);
              _downloadAndOpenFile();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
            ),
            icon: const Icon(Icons.download),
            label: const Text('Download & Open'),
          ),
        ],
      ),
    );
  }

  // Hàm tải file trong FileOption Dialog, tải xong mở file
  Future<void> _downloadAndOpenFile() async {
    if (GetV.fileurl.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('File URL not available'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      // Show loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: Card(
            child: Padding(
              padding: EdgeInsets.all(20.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Downloading file...'),
                ],
              ),
            ),
          ),
        ),
      );

      // Download file
      final response = await http.get(Uri.parse(GetV.fileurl));
      
      if (response.statusCode == 200) {
        // Lấy thư mục Downloads hoặc temp
        final directory = await getTemporaryDirectory();
        final fileName = GetV.fileName.isNotEmpty 
            ? GetV.fileName 
            : 'downloaded_file.${GetV.fileType}';
        final filePath = '${directory.path}/$fileName';
        
        // Lưu file
        final file = File(filePath);
        await file.writeAsBytes(response.bodyBytes);
        
        // Close loading
        if (mounted) Navigator.pop(context);
        
        // Mở file với app mặc định của điện thoại
        final result = await OpenFilex.open(filePath);
        
        if (result.type != ResultType.done) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Cannot open file: ${result.message}'),
                backgroundColor: Colors.orange,
              ),
            );
          }
        }
      } 
      else {
        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Download failed: ${response.statusCode}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } 
    catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error downloading file: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Hàm Speech to Text
  void onListen() async {
    if (!_isListening) {
      bool available = await _speech.initialize(
        onStatus: (val) {
          debugPrint("Speech status: $val");
          if (val == "done" || val == "notListening") {
            if (mounted) {
              setState(() {
                _isListening = false;
              });
            }
          }
        },
        onError: (val) {
          debugPrint("Speech error: $val");
          if (mounted) {
            setState(() {
              _isListening = false;
            });
            if (val.errorMsg != 'error_speech_timeout') {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Speech error: ${val.errorMsg}')),
              );
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('No speech detected. Please speak clearly into the microphone.'),
                  duration: Duration(seconds: 2),
                ),
              );
            }
          }
        },
      );
      
      if (available) {
        setState(() {
          _isListening = true;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('🎤 Listening... Please speak now'),
            duration: Duration(seconds: 2),
            backgroundColor: Colors.green,
          ),
        );
        
        await _speech.listen(
          localeId: "vi_VN",
          listenFor: const Duration(seconds: 10),
          pauseFor: const Duration(seconds: 3),
          listenOptions: stt.SpeechListenOptions(
            partialResults: true, // Hiển thị kết quả từng phần khi đang nói
            autoPunctuation: true, // Tự động thêm dấu câu (. , ? !)
            enableHapticFeedback: true, // Rung khi bắt đầu/kết thúc ghi âm
            cancelOnError: true, // Tự động cancel khi có lỗi
          ),
          onResult: (val) {
            if (mounted) {
              setState(() {
                _askText.text = val.recognizedWords;
              });
            }
          },
        );
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Speech recognition not available. Please check microphone permissions.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } else {
      setState(() {
        _isListening = false;
      });
      await _speech.stop();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Stopped listening'),
            duration: Duration(seconds: 1),
          ),
        );
      }
    }
  }

  // Hàm nhấn vào thì lấy nội dung câu hỏi
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
              // Nút mở menu
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
          // Nút thoát khỏi trang summary, về lại trang chủ (Home)
          IconButton(
            onPressed: () async{
              if (!mounted) return;
              // LOADING
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const Loadings()),
              );
              setState(() {
                GetV.title = '';
                GetV.submited = false;
                GetV.summarized =false;
                GetV.chated = false;
                GetV.loadingUploadFile = false;
                GetV.hasFiled = false; // Reset về trạng thái chưa có file
              });
              // Lấy đoạn summary hiện tại, nếu chưa có tiêu đề thì xóa (Chưa thực hiện tóm tắt)
              final res = await FirebaseFirestore.instance.collection(GetV.userName.text).doc(GetV.userSummaryID).collection('Summarize')
                  .doc(GetV.messageSummaryID).get();
              if(res.exists && res['text'] == ''){
                await FirebaseFirestore.instance.collection(GetV.userName.text).doc(GetV.userSummaryID).collection('Summarize')
                .doc(GetV.messageSummaryID).delete();
              }
              if (!mounted) return;
              // POP LOADING TRƯỚC
              Navigator.pop(context);
              // SAU ĐÓ POP VỀ TABS
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

  // Chưa có file -> Chưa tóm tắt -> Trạng thái ban đầu sẽ có nút Chọn file to ở chính giữa
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

  // Đã gửi file -> Hiện nội dung các tin nhắn, và tin tóm tắt sẽ ở đầu.
  Widget _buildChatView(ChatProvider chatProvider) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Nút để xem nội dung file
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

  // Nút xem nội dung file
  Widget _buildFileNameButton() {
    if (fileName.isEmpty && GetV.fileName.isEmpty) {
      return const SizedBox.shrink();
    }
    
    final displayFileName = fileName.isNotEmpty ? fileName : GetV.fileName;
    final displayFileType = fileType.isNotEmpty ? fileType : GetV.fileType;
    
    // Check nếu file còn tồn tại local
    // Local ở file path
    // Server ở file url
    final bool hasLocalFile = GetV.filepath.isNotEmpty && File(GetV.filepath).existsSync();
    final bool hasCloudFile = GetV.fileurl.isNotEmpty;
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () async {
                // Nếu có file name
                if (displayFileName.isNotEmpty) {
                  // Nếu có file path
                  if (hasLocalFile) {
                    // Mở file local
                    OpenFilex.open(GetV.filepath);
                  } 
                  // Nếu có file server thì có file option dialog để tải về máy điện thoại
                  else if (hasCloudFile) {
                    // Hiển thị dialog với options
                    _showFileOptionsDialog(displayFileName, displayFileType);
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('File not available'),
                        backgroundColor: Colors.orange,
                      ),
                    );
                  }
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
              icon: Icon(_getFileIconForType(displayFileType), size: 20),
              label: Row(
                children: [
                  Expanded(
                    child: Text(
                      displayFileName,
                      style: const TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 16,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 4),
                  // Hiển thị icon status
                  Icon(
                    // Nếu file local thì icon tick, file server thì icon tick cloud, không có thì icon lỗi.
                    hasLocalFile 
                        ? Icons.check_circle 
                        : hasCloudFile 
                            ? Icons.cloud_done 
                            : Icons.error_outline,
                    size: 16,
                    // Tương tự màu local là xanh lá, server là xanh dương, không thì cam.
                    color: hasLocalFile 
                        ? Colors.green 
                        : hasCloudFile 
                            ? Colors.blue 
                            : Colors.orange,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Thêm helper function
  // Lấy ảnh dựa vào loại file: file type.
  IconData _getFileIconForType(String type) {
    switch (type.toLowerCase()) {
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

  // Tạo danh sách tin nhắn, bao gồm tin tóm tắt và tin hỏi trả lời về nội dung tóm tắt.
  Widget _buildMessagesList() {
    return StreamBuilder(
      // Lấy các tin nhắn của đoạn summary
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
            // DocsWidget để hiển thị tin tóm tắt
            // ChatWidgets để hiển thị tin hỏi và trả lời của user và chatbot.
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

  // Tạo khu vực nhập câu hỏi sau khi đã chọn file và tóm tắt file xong.
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
                    // Đã có file thì gửi và nhận câu trả lời AI
                    if (GetV.hasFiled) {
                      await sendMessageFCT(chatProvider: Provider.of<ChatProvider>(context, listen: false));
                    } 
                    // Không thì 
                    else {
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
                // Tương tự cho nút gửi tin nhắn, giống khi enter submit từ text input field ở trên
                if (GetV.hasFiled) {
                  await sendMessageFCT(chatProvider: Provider.of<ChatProvider>(context, listen: false));
                } 
                else {
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

  // Hàm hiển thị thông báo lỗi khi chưa gửi file để tóm tắt mà đã hỏi trong input area.
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
  // Tạo nội dung trả lời tóm tắt, tách các câu hỏi ra và lưu vào Firestore
  Future<void> saveDocsSummarize({
    required String msg, 
    required PlatformFile file,
    String? fileUrl,
  }) async {
    try {
      final llm = ChatOpenAI(
        apiKey: GetV.apiKey.text,
        defaultOptions: const ChatOpenAIOptions(
          model: 'gpt-4o-mini',
          temperature: 0,
        ),
      );

      // Nếu là file txt thì tải nội dung thủ công từ file path trên cloudinary
      if (GetV.filetype == "txt") {
        // Load file manually
        final fileObj = File(GetV.filepath);
        final content = await fileObj.readAsString();
        final documents = [
          Document(pageContent: content, metadata: {'source': GetV.filepath}),
        ];

        // RAG cho txt
        // Tách text, chia tài liệu thành chunks nhỏ
        const textSplitter = RecursiveCharacterTextSplitter(
          chunkSize: 1000,
          chunkOverlap: 200,
        );
        // Nhóm
        final docsChunks = textSplitter.splitDocuments(documents);

        notify('Store Document Embeddings');

        // Create summarization prompt
        // Dùng template tóm tắt thông thường
        final docContents = docsChunks.map((doc) => doc.pageContent).join('\n\n');
        final prompt = template.replaceAll('{context}', docContents);

        notify('Summarize Document');

        final response = await llm.invoke(PromptValue.string(prompt));
        // Trả lời AI
        final result = response.outputAsString;

        // PARSE KẾT QUẢ AN TOÀN HƠN
        String textSum = '';
        String q1Text = 'What is the main topic?';
        String q2Text = 'What are the key points?';
        String q3Text = 'What conclusions can be drawn?';

        try {
          // Thử parse với các marker tiêu chuẩn
          // Tách câu hỏi từ câu trả lời theo ký tự phân tách, chỉ để lại nội dung tóm tắt.
          if (result.contains(start) && result.contains(start1)) {
            textSum = _extractSection(result, start, start1);
            
            if (result.contains(start1) && result.contains(start2)) {
              q1Text = _extractSection(result, start1, start2);
            }
            
            if (result.contains(start2) && result.contains(start3)) {
              q2Text = _extractSection(result, start2, start3);
            }
            
            final q3Index = result.indexOf(start3);
            if (q3Index != -1) {
              q3Text = result.substring(q3Index + start3.length).trim();
            }
          } 
          else {
            // Nếu không tìm thấy marker, tách thủ công
            final lines = result.split('\n');
            textSum = lines.take(3).join('\n').trim(); // Lấy 3 dòng đầu làm summary
            
            // Tìm các dòng có "?" để làm câu hỏi
            final questionLines = lines.where((line) => line.contains('?')).toList();
            if (questionLines.isNotEmpty) {
              q1Text = questionLines.length > 0 ? questionLines[0].trim() : q1Text;
              q2Text = questionLines.length > 1 ? questionLines[1].trim() : q2Text;
              q3Text = questionLines.length > 2 ? questionLines[2].trim() : q3Text;
            }
          }
        } 
        catch (e) {
          debugPrint('Error parsing with markers: $e');
          // Fallback: dùng toàn bộ text làm summary
          textSum = result.length > 500 
              ? '${result.substring(0, 500)}...' 
              : result;
        }

        setState(() {
          q1 = q1Text;
          q2 = q2Text;
          q3 = q3Text;
        });

        // Save to Firestore
        // Lưu tin nhắn tóm tắt vào đoạn sumamry với index = 3
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
          'q1': q1Text,
          'q2': q2Text,
          'q3': q3Text,
        });

        // Generate title if needed
        // Nếu chưa có tiêu đề thì tạo (Mới tóm tắt) dựa vào nội dung tóm tắt đã tách câu hỏi ra
        if (GetV.title == '') {
          final titlePrompt = template2.replaceAll('{text}', textSum);
          final titleResponse = await llm.invoke(PromptValue.string(titlePrompt));
          GetV.title = titleResponse.outputAsString;

          // Cập nhật tiêu đề đoạn summary
          await FirebaseFirestore.instance
              .collection(GetV.userName.text)
              .doc(GetV.userSummaryID)
              .collection('Summarize')
              .doc(GetV.messageSummaryID)
              .update({
            'text': GetV.title,
            'Index': GetV.summaryNum,
            'messageID': GetV.messageSummaryID,
            'fileName': GetV.fileName,
            'fileType': GetV.fileType,
            'filePath': GetV.filepath,
            'fileUrl': fileUrl ?? '',
          });
        }

        GetV.summaryText = result;
      } 
      else {
        // Nếu không phải file txt
        // For other file types (PDF, DOCX, etc.)
        String embeddedText = '';
        if (msg.length > 4000) {
          embeddedText = msg.substring(0, 4000);
        } 
        else {
          embeddedText = msg;
        }

        notify('Summarize documents');

        // Dùng templateX tóm tắt < 250 từ
        final prompt = templateX.replaceAll('{subject}', embeddedText);
        final response = await llm.invoke(PromptValue.string(prompt));
        final result = response.outputAsString;

        // PARSE KẾT QUẢ AN TOÀN HƠN
        String textSum = '';
        String q1Text = 'What is discussed in this document?';
        String q2Text = 'What are the main findings?';
        String q3Text = 'What should I know?';

        try {
          // Thử parse với các marker
          // Tách 3 câu hỏi ra nội dung tóm tắt tin nhắn AI
          if (result.contains(starts1)) {
            final summaryEndIndex = result.indexOf(starts1);
            if (summaryEndIndex != -1) {
              textSum = result.substring(0, summaryEndIndex).trim();
            }
            
            if (result.contains(starts1) && result.contains(starts2)) {
              q1Text = _extractSection(result, starts1, starts2);
            }
            
            if (result.contains(starts2) && result.contains(starts3)) {
              q2Text = _extractSection(result, starts2, starts3);
            }
            
            final q3Index = result.indexOf(starts3);
            if (q3Index != -1) {
              q3Text = result.substring(q3Index + starts3.length).trim();
            }
          } else {
            // Fallback parsing
            final lines = result.split('\n');
            final nonEmptyLines = lines.where((l) => l.trim().isNotEmpty).toList();
            
            if (nonEmptyLines.isNotEmpty) {
              textSum = nonEmptyLines.take(5).join('\n').trim();
            }
            
            final questionLines = nonEmptyLines.where((line) => line.contains('?')).toList();
            if (questionLines.isNotEmpty) {
              q1Text = questionLines.length > 0 ? questionLines[0].trim() : q1Text;
              q2Text = questionLines.length > 1 ? questionLines[1].trim() : q2Text;
              q3Text = questionLines.length > 2 ? questionLines[2].trim() : q3Text;
            }
          }
        } catch (e) {
          debugPrint('Error parsing result: $e');
          textSum = result.length > 500 
              ? '${result.substring(0, 500)}...' 
              : result;
        }

        setState(() {
          q1 = q1Text;
          q2 = q2Text;
          q3 = q3Text;
        });

        // Save to Firestore
        // Lưu nội dung tóm tắt + 3 câu hỏi vào đoạn summary dưới dạng tin nhắn
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
          'q1': q1Text,
          'q2': q2Text,
          'q3': q3Text,
        });

        // Generate title if needed
        // Tạo tiêu đề nếu chưa có (Mới tóm tắt)
        if (GetV.title == '') {
          final titlePrompt = template2.replaceAll('{text}', textSum);
          final titleResponse = await llm.invoke(PromptValue.string(titlePrompt));
          GetV.title = titleResponse.outputAsString;
          
          // Cập nhật tiêu đề
          await FirebaseFirestore.instance
              .collection(GetV.userName.text)
              .doc(GetV.userSummaryID)
              .collection('Summarize')
              .doc(GetV.messageSummaryID)
              .update({
            'text': GetV.title,
            'Index': GetV.summaryNum,
            'messageID': GetV.messageSummaryID,
            'fileName': GetV.fileName,
            'fileType': GetV.fileType,
            'filePath': GetV.filepath,
            'fileUrl': fileUrl ?? '',
          });
        }

        GetV.summaryText = result;
      }
    } 
    catch (e) {
      debugPrint('Error in saveDocsSummarize: $e');
      if (mounted) {
        setState(() {
          GetV.loadingUploadFile = true;
        });
      }
      rethrow;
    }
  }

  // Hàm dùng để tách câu hỏi từ những vị trí được đánh dấu và đoạn text nhập vào.
  String _extractSection(String text, String startMarker, String endMarker) {
    try {
      final startIndex = text.indexOf(startMarker);
      final endIndex = text.indexOf(endMarker);
      
      if (startIndex == -1) {
        debugPrint('Start marker not found: $startMarker');
        return '';
      }
      
      if (endIndex == -1 || endIndex <= startIndex) {
        // Nếu không tìm thấy endMarker, lấy đến cuối text
        final extracted = text.substring(startIndex + startMarker.length).trim();
        // Giới hạn độ dài
        return extracted.length > 200 
            ? '${extracted.substring(0, 200)}...' 
            : extracted;
      }
      
      return text.substring(startIndex + startMarker.length, endIndex).trim();
    } 
    catch (e) {
      debugPrint('Error extracting section: $e');
      return '';
    }
  }

  // Hàm gửi và nhận câu trả lời AI
  Future<void> sendMessageFCT({required ChatProvider chatProvider}) async {
    if (_isTyping) {
      // Gửi tin nhắn khi đang chờ câu trả lời
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
            // Chưa có nội dung câu hỏi
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
      
      // Nhận và gửi câu trả lời, lưu câu hỏi và câu trả lời vào Firestore.
      await chatProvider.sendMessageAndGetAnswersSummarize(msg: msg);
      if (mounted) {
        setState(() {});
      }
    } 
    catch (error) {
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