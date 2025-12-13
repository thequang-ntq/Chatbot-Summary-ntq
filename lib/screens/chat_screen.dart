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
  bool _isTyping = false;
  bool _isListening = false;

  late TextEditingController textEditingController;
  late ScrollController _listScrollController;
  late FocusNode focusNode;

  // THÊM CÁC BIẾN NÀY
  final ImagePicker _imagePicker = ImagePicker();
  File? _selectedImage;
  String? _uploadedImageUrl;
  bool _isUploadingImage = false;
  
  @override
  void initState() {
    _listScrollController = ScrollController();
    textEditingController = TextEditingController();
    focusNode = FocusNode();
    super.initState();
    _speech = stt.SpeechToText();
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
        onError: (val) => debugPrint("error: $val"),
      );
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
          }),
        );
      }
    } else {
      setState(() {
        _isListening = false;
        _speech.stop();
      });
    }
  }

  // Hàm xử lý ảnh cho Chat
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
    } catch (e) {
      debugPrint('Error picking image: $e');
      if (!mounted) return;
      SnackbarHelper.showError(context, 'Failed to pick image');
    }
  }

  Future<String?> _uploadImageToCloudinary(File imageFile) async {
    try {
      setState(() {
        _isUploadingImage = true;
      });
      
      final String? downloadUrl = await CloudinaryService.uploadImage(imageFile);
      
      setState(() {
        _isUploadingImage = false;
      });
      
      return downloadUrl;
    } catch (e) {
      debugPrint('Error uploading image: $e');
      setState(() {
        _isUploadingImage = false;
      });
      return null;
    }
  }

  void _removeSelectedImage() {
    setState(() {
      _selectedImage = null;
      _uploadedImageUrl = null;
    });
  }

  @override
  void dispose() {
    _listScrollController.dispose();
    textEditingController.dispose();
    focusNode.dispose();
    super.dispose();
  }

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
    return RefreshIndicator(
      color: Colors.white,
      backgroundColor: Colors.black,
      onRefresh: () async {
        return Future<void>.delayed(const Duration(seconds: 1));
      },
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

          final loadedMessages = snapshot.data!.docs;

          return Scaffold(
            appBar: AppBar(
              leading: Builder(
                builder: (BuildContext context) {
                  return IconButton(
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
                IconButton(
                  onPressed: () async {
                    if (!mounted) return;
                    
                    //loading
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const Loadings()),
                    );

                    GetV.title = '';
                    GetV.submited = false;
                    GetV.summarized = false;
                    GetV.chated = false;
                    final res = await FirebaseFirestore.instance
                        .collection(GetV.userName.text)
                        .doc(GetV.userChatID)
                        .collection('Message')
                        .doc(GetV.messageChatID)
                        .get();
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
            drawer: Menu(toRefresh: toRefresh),
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
                          : ListView.builder(
                              controller: _listScrollController,
                              itemCount: loadedMessages.length,
                              itemBuilder: (context, index) {
                                final chatMessage = loadedMessages[index].data();
                                DateTime time = chatMessage['createdAt'].toDate();
                                String formattedDate =
                                    DateFormat('dd/MM/yyyy, hh:mm a').format(time);
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
                    if (_isTyping) ...[
                      const Padding(
                        padding: EdgeInsets.all(8.0),
                        child: SpinKitThreeBounce(
                          color: Colors.blue,
                          size: 20,
                        ),
                      ),
                    ],
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
          // THÊM PHẦN PREVIEW ẢNH
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
                // THÊM NÚT CHỌN ẢNH
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

  Future<void> sendMessageFCT({required ChatProvider chatProvider}) async {
    if (_isTyping) {
      if (!mounted) return;
      SnackbarHelper.showWarning(
        context,
        "You can't send multiple messages at a time",
      );
      return;
    }
    
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
      
      if (_isListening) {
        setState(() {
          _isListening = false;
          _speech.stop();
        });
      }
      
      setState(() {
        _isTyping = true;
        chatProvider.addUserMessage(msg: msg.isEmpty ? "[Image]" : msg);
        textEditingController.clear();
        _selectedImage = null; // Clear selected image
        focusNode.unfocus();
      });
      
      await chatProvider.sendMessageAndGetAnswers(
        msg: msg.isEmpty ? "I sent you an image" : msg,
        imageUrl: imageUrl,
      );
      
      if (mounted) {
        setState(() {});
      }
    } catch (error) {
      log("error $error");
      if (!mounted) return;
      SnackbarHelper.showError(context, error.toString());
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