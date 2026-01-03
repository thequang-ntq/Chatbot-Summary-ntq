// Màn hình Chat chính
// •	_buildEmptyState(): Hiển thị khi chưa có tin nhắn
// •	_buildInputArea(): Thanh nhập tin nhắn + nút gửi + nút mic + nút chọn ảnh
// •	StreamBuilder: Lắng nghe realtime từ Firestore

import 'dart:developer';
import 'package:connection_notifier/connection_notifier.dart';
import 'package:chatgpt/screens/internet.dart';
import 'package:chatgpt/providers/chats/chats_provider.dart';
import 'package:chatgpt/screens/loading.dart';
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
import 'package:chatgpt/theme/app_theme.dart';
import 'package:chatgpt/utils/snackbar_helper.dart';
import 'package:image_picker/image_picker.dart';
// import 'package:firebase_storage/firebase_storage.dart';
// Import Cloudinary service:
import 'package:chatgpt/services/cloudinary_service.dart';
import 'dart:io';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  late stt.SpeechToText _speech;
  bool _isTyping = false; // Đang chờ AI trả lời
  bool _isListening = false; // Đang ghi âm

  late TextEditingController textEditingController;
  late ScrollController _listScrollController;
  late FocusNode focusNode;

  // THÊM CÁC BIẾN NÀY
  final ImagePicker _imagePicker = ImagePicker();
  File? _selectedImage; // Ảnh đã chọn
  // String? _uploadedImageUrl;
  bool _isUploadingImage = false; // Đang upload ảnh
  
  @override
  void initState() {
    _listScrollController = ScrollController();
    textEditingController = TextEditingController();
    focusNode = FocusNode();
    super.initState();
    _speech = stt.SpeechToText();
  }

  // Hàm ghi âm speech to text
  // Thực hiện khi bấm vào nút Microphone để mở / dừng ghi âm
  void onListen() async {
    if (!_isListening) {
      // Khởi tọa speech recognition
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
            // Chỉ hiện error nếu không phải timeout
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
      
      // Nếu nghe thành công
      if (available) {
        setState(() {
          _isListening = true;
        });
        
        // Hiện thông báo hướng dẫn
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('🎤 Listening... Please speak now'),
            duration: Duration(seconds: 2),
            backgroundColor: Colors.green,
          ),
        );
        
        // Bắt đầu lắng nghe 10 giây
        await _speech.listen(
          localeId: "vi_VN",
          listenFor: const Duration(seconds: 10), // Giảm xuống 10s
          pauseFor: const Duration(seconds: 3),   // Giảm xuống 3s
          listenOptions: stt.SpeechListenOptions(
            partialResults: true, // Hiển thị kết quả từng phần khi đang nói
            autoPunctuation: true, // Tự động thêm dấu câu (. , ? !)
            enableHapticFeedback: true, // Rung khi bắt đầu/kết thúc ghi âm
            cancelOnError: true, // Tự động cancel khi có lỗi
          ),
          onResult: (val) {
            if (mounted) {
              setState(() {
                textEditingController.text = val.recognizedWords;
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
      
      // Hiện thông báo dừng
      // mounted = true: Widget đang hiển thị trên màn hình, State còn active
      // mounted = false: Widget đã bị dispose (đã rời khỏi widget tree)
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

  // Hàm xử lý ảnh cho Chat. Lấy ảnh từ local lên.
  Future<void> _pickImage() async {
    try {
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      
      if (pickedFile != null) {
        setState(() {
          _selectedImage = File(pickedFile.path);
        });
      }
    } 
    catch (e) {
      debugPrint('Error picking image: $e');
      if (!mounted) return;
      SnackbarHelper.showError(context, 'Failed to pick image');
    }
  }

  // Gửi ảnh lấy được lên server cloudinary.
  Future<String?> _uploadImageToCloudinary(File imageFile) async {
    try {
      setState(() {
        _isUploadingImage = true;
      });
      
      final String? downloadUrl = await CloudinaryService.uploadImage(imageFile);
      
      setState(() {
        _isUploadingImage = false;
      });
      // Trả về đường link url của ảnh để tải về.
      return downloadUrl;
    } 
    catch (e) {
      debugPrint('Error uploading image: $e');
      setState(() {
        _isUploadingImage = false;
      });
      return null;
    }
  }

  // Xóa ảnh được chọn
  void _removeSelectedImage() {
    setState(() {
      _selectedImage = null;
      // _uploadedImageUrl = null;
    });
  }

  @override
  void dispose() {
    _listScrollController.dispose();
    textEditingController.dispose();
    focusNode.dispose();
    super.dispose();
  }

  // Tải lại của Menu
  // Đang từ Menu thoát ra về lại trang Chat ban đầu.
  void toRefresh() {
    if (!mounted) return;
    Navigator.pop(context);
    Navigator.pop(context);
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ChatScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Có thể tải lại
    return RefreshIndicator(
      color: Colors.white,
      backgroundColor: Colors.black,
      onRefresh: () async {
        return Future<void>.delayed(const Duration(seconds: 1));
      },
      // Cập nhật liên tục theo thời gian thực.
      // Lấy các document - ở đây là các tin nhắn của người và Chatbot của 1 đoạn chat trong collection Chat
      // sắp xếp theo thời điểm tạo, từ trên xuống dưới là thời điểm tạo tăng dần, tạo sớm nhất ở trên nhất.
      child: StreamBuilder(
        stream: FirebaseFirestore.instance
            .collection(GetV.userName.text)
            .doc(GetV.userChatID)
            .collection('Message')
            .doc(GetV.messageChatID)
            .collection('ChatItem${GetV.chatNum}')
            .orderBy('createdAt', descending: false)
            .snapshots(),
        builder: (BuildContext ctx, AsyncSnapshot snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(
                child: CircularProgressIndicator(),
              ),
            );
          }

          if (snapshot.hasError) {
            return const Scaffold(
              body: Center(
                child: Text('Something went wrong...'),
              ),
            );
          }

          // Dữ liệu các tin nhắn
          final loadedMessages = snapshot.data!.docs;

          return Scaffold(
            appBar: AppBar(
              leading: Builder(
                builder: (BuildContext context) {
                  return IconButton(
                    // Nút Menu
                    icon: const Icon(Icons.menu),
                    onPressed: () {
                      Scaffold.of(context).openDrawer();
                    },
                    tooltip: MaterialLocalizations.of(context).openAppDrawerTooltip,
                  );
                },
              ),
              title: const Text("New Chat"),
              actions: [
                // Nút thoát khỏi trang chat, về lại trang chủ có tác dụng:
                IconButton(
                  onPressed: () async {
                    if (!mounted) return;
                    
                    //loading
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const Loadings()),
                    );
                    // Reset các giá trị về ban đầu
                    GetV.title = '';
                    GetV.submited = false;
                    GetV.summarized = false;
                    GetV.chated = false;
                    // Lấy ra doc là đoạn chat tương ứng
                    final res = await FirebaseFirestore.instance
                        .collection(GetV.userName.text)
                        .doc(GetV.userChatID)
                        .collection('Message')
                        .doc(GetV.messageChatID)
                        .get();
                    // Nếu doc chưa tiêu đề -> doc mới, chưa có tin nhắn trong đoạn chat này, thì xóa doc.
                    if (res['text'] == '') {
                      await FirebaseFirestore.instance
                          .collection(GetV.userName.text)
                          .doc(GetV.userChatID)
                          .collection('Message')
                          .doc(GetV.messageChatID)
                          .delete();
                    }
                    if (!mounted) return;
                    
                    // POP LOADING TRƯỚC
                    Navigator.pop(context);
                    // SAU ĐÓ POP VỀ TABS
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const Tabs()),
                    );
                  },
                  icon: const Icon(Icons.exit_to_app),
                ),
              ],
            ),
            // Thanh kéo
            drawer: Menu(toRefresh: toRefresh),
            // Yêu cầu có mạng để tải tin nhắn
            body: ConnectionNotifierToggler(
              onConnectionStatusChanged: (connected) {
                if (connected == null) return;
              },
              disconnected: const InternetErr(),
              connected: SafeArea(
                child: Column(
                  children: [
                    Flexible(
                      child: loadedMessages.isEmpty
                          ? _buildEmptyState()
                          // Danh sách tin nhắn
                          : ListView.builder(
                              controller: _listScrollController,
                              itemCount: loadedMessages.length,
                              itemBuilder: (context, index) {
                                final chatMessage = loadedMessages[index].data();
                                DateTime time = chatMessage['createdAt'].toDate();
                                String formattedDate =
                                    DateFormat('dd/MM/yyyy, hh:mm a').format(time);
                                // mỗi tin nhắn được biểu diễn bởi một ChatWidget
                                return ChatWidget(
                                  msg: chatMessage['text'],
                                  dateTime: formattedDate,
                                  chatIndex: chatMessage['index'],
                                  imageUrl: chatMessage['imageUrl'] ?? '',
                                  shouldAnimate: false,
                                );
                              },
                            ),
                    ),
                    // Nếu là đang chờ trả lời thì hiện ra dấu 3 chấm xanh ở trên thanh gửi tin nhắn
                    if (_isTyping) ...[
                      const Padding(
                        padding: EdgeInsets.all(8.0),
                        child: SpinKitThreeBounce(
                          color: Colors.blue,
                          size: 20,
                        ),
                      ),
                    ],
                    // Khu vực thanh nhập tin nhắn
                    _buildInputArea(),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // Tạo ra giao diện khi chưa có dữ liệu (Chưa có tin nhắn nào trong đoạn chat)
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.chat_bubble_outline,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Start a conversation',
            style: AppTheme.heading3.copyWith(color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          Text(
            'Type a message below to begin',
            style: AppTheme.bodyText1.copyWith(color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  // Tạo thanh gửi tin nhắn
  Widget _buildInputArea() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        children: [
          // THÊM PHẦN PREVIEW ẢNH ở trên text input field
          if (_selectedImage != null)
            Container(
              padding: const EdgeInsets.all(8),
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.file(
                      _selectedImage!,
                      height: 150,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: IconButton(
                      onPressed: _removeSelectedImage,
                      icon: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.close,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          
          // PHẦN INPUT HIỆN TẠI
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              children: [
                // THÊM NÚT CHỌN ẢNH ở đầu, chỉ được chọn 1 ảnh 1 lần
                IconButton(
                  onPressed: _isUploadingImage ? null : _pickImage,
                  icon: _isUploadingImage
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.image, color: Colors.blue),
                  tooltip: 'Select image',
                ),
                
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(25),
                    ),
                    child: TextField(
                      focusNode: focusNode,
                      controller: textEditingController,
                      onSubmitted: (value) async {
                        final provider = Provider.of<ChatProvider>(context, listen: false);
                        await sendMessageFCT(chatProvider: provider);
                      },
                      decoration: const InputDecoration.collapsed(
                        hintText: "How can I help you?",
                      ),
                      maxLines: null,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // Nút gửi tin nhắn
                IconButton(
                  onPressed: () async {
                    final provider = Provider.of<ChatProvider>(context, listen: false);
                    await sendMessageFCT(chatProvider: provider);
                  },
                  tooltip: 'Send message',
                  icon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(
                      color: Colors.blue,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.send,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                // Nút ghi âm speech to text
                FloatingActionButton(
                  mini: true,
                  backgroundColor: _isListening ? Colors.red : Colors.blue,
                  onPressed: () => onListen(),
                  tooltip: 'Voice input',
                  child: Icon(
                    _isListening ? Icons.mic_off : Icons.mic,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void scrollListToEND() {
    _listScrollController.animateTo(
      _listScrollController.position.maxScrollExtent,
      duration: const Duration(seconds: 2),
      curve: Curves.easeOut,
    );
  }

  // Hàm xử ly gửi tin nhắn
  Future<void> sendMessageFCT({required ChatProvider chatProvider}) async {
    // Đang nhắn
    if (_isTyping) {
      if (!mounted) return;
      SnackbarHelper.showWarning(
        context,
        "You can't send multiple messages at a time",
      );
      return;
    }
    
    // Không có chữ và ảnh
    if (textEditingController.text.isEmpty && _selectedImage == null) {
      if (!mounted) return;
      SnackbarHelper.showWarning(context, "Please type a message or select an image");
      return;
    }
    
    try {
      String msg = textEditingController.text;
      String? imageUrl;
      
      // Upload ảnh nếu có
      if (_selectedImage != null) {
        imageUrl = await _uploadImageToCloudinary(_selectedImage!); // Đổi tên hàm
        if (imageUrl == null) {
          if (!mounted) return;
          SnackbarHelper.showError(context, "Failed to upload image");
          return;
        }
      }
      
      // Đang ghi âm thì dừng ghi âm
      if (_isListening) {
        setState(() {
          _isListening = false;
          _speech.stop();
        });
      }
      
      // Hiện trạng thái đang xử lý tin nhắn
      setState(() {
        _isTyping = true;
        // Thêm tin nhắn người dùng vào chatList để hiển thị
        chatProvider.addUserMessage(msg: msg.isEmpty ? "[Image]" : msg);
        textEditingController.clear();
        _selectedImage = null; // Dọn dẹp ảnh được chọn
        focusNode.unfocus();
      });
      
      // Lấy câu trả lời từ Chatbot
      await chatProvider.sendMessageAndGetAnswers(
        msg: msg.isEmpty ? "I sent you an image" : msg,
        imageUrl: imageUrl,
      );
      
      if (mounted) {
        setState(() {});
      }
    } 
    catch (error) {
      log("error $error");
      if (!mounted) return;
      SnackbarHelper.showError(context, error.toString());
    } 
    finally {
      if (mounted) {
        setState(() {
          scrollListToEND();
          _isTyping = false;
        });
      }
    }
  }
}