// Drawer menu cho Chat screen 
// Hiển thị lịch sử Chat
// Tạo chat mới
// Xóa chat
// Highlight chat đang chọn

import 'package:flutter/material.dart';
import 'package:chatgpt/screens/home.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:chatgpt/theme/app_theme.dart';

class Menu extends StatefulWidget {
  const Menu({super.key, required this.toRefresh});
  final void Function() toRefresh;
  
  @override
  State<Menu> createState() => _MenuState();
}

class _MenuState extends State<Menu> with SingleTickerProviderStateMixin {
  late ScrollController _listScrollController;
  late AnimationController _animationController;

  @override
  void initState() {
    _listScrollController = ScrollController();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _animationController.forward();
    super.initState();
  }

  @override
  void dispose() {
    _listScrollController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  // Hàm tạo đoạn chat mới
  Future<void> _createNewChat() async {
    final upURL = Uri.https(
      'your-project-name-b1e6c-default-rtdb.firebaseio.com', 'chatNum.json'
    );
    final res = await http.get(upURL);
    final Map<String, dynamic> dat = json.decode(res.body);
    int maxNum = 1;
    // Lấy ra đoạn chat mới nhất với số index lớn nhất
    for (final item in dat.entries) {
      if (GetV.userName.text == item.value['user-name']) {
        if (maxNum < item.value['chat-num']) {
          maxNum = item.value['chat-num'];
        }
      }
    }
    
    // Lấy ra đoạn chat hiện tại, nếu tiêu đề rỗng thì xóa
    final resd = await FirebaseFirestore.instance
        .collection(GetV.userName.text)
        .doc(GetV.userChatID)
        .collection('Message')
        .doc(GetV.messageChatID)
        .get();
    if (resd['text'] == '') {
      await FirebaseFirestore.instance
          .collection(GetV.userName.text)
          .doc(GetV.userChatID)
          .collection('Message')
          .doc(GetV.messageChatID)
          .delete();
    }

    // Đoạn chat mới có số index lớn hơn số index của đoạn chat mới nhất hiện tại = +1.
    setState(() {
      GetV.title = '';
      GetV.chatNum = maxNum + 1;
      GetV.menuPressed = true;
    });
    
    // Tạo doc đoạn chat mới với ID đoạn chat mới nhất ở trên (= +1)
    await FirebaseFirestore.instance
        .collection(GetV.userName.text)
        .doc(GetV.userChatID)
        .collection('Message')
        .add({
      'text': '',
      'Index': GetV.chatNum,
      'messageID': GetV.messageChatID,
      'createdAt': Timestamp.now(),
    }).then((DocumentReference doc) {
      GetV.messageChatID = doc.id;
    });
    
    // Cập nhập lại cho đúng ID đoạn chat
    await FirebaseFirestore.instance
        .collection(GetV.userName.text)
        .doc(GetV.userChatID)
        .collection('Message')
        .doc(GetV.messageChatID)
        .update({
      'text': '',
      'Index': GetV.chatNum,
      'messageID': GetV.messageChatID,
      'createdAt': Timestamp.now(),
    });
    
    // Cập nhật lại số chat num mới nhất cho user name hiện tại
    final url2 = Uri.https(
      'your-project-name-b1e6c-default-rtdb.firebaseio.com', 'chatNum.json'
    );
    final response2 = await http.get(url2);
    final Map<String, dynamic> resData2 = json.decode(response2.body);
    for (final item in resData2.entries) {
      if (GetV.userName.text == item.value['user-name']) {
        item.value['chat-num'] = GetV.chatNum;
      }
    }

    // Cập nhật lại chat item number là số chat num mới nhất hiện tại.
    // Nhưng hiện tại cái này không dùng, nên thừa.
    final url = Uri.https('your-project-name-b1e6c-default-rtdb.firebaseio.com',
      'chatItemNumber.json');
    final response = await http.get(url);
    final Map<String, dynamic> resData = json.decode(response.body);
    for (final item in resData.entries) {
      if (GetV.userName.text == item.value['user-name']) {
        item.value['chat-ItemNumber'] = GetV.chatNum;
      }
    }
    widget.toRefresh();
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: Colors.white,
      child: Column(
        children: [
          _buildDrawerHeader(),
          _buildNewChatButton(),
          const Divider(height: 1),
          Expanded(child: _buildChatHistory()),
          const Divider(height: 1),
          _buildUserInfo(),
        ],
      ),
    );
  }

  // Tạo header cho menu
  Widget _buildDrawerHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 50, 20, 20),
      decoration: const BoxDecoration(
        gradient: AppTheme.primaryGradient,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Image.asset(
                  'assets/images/chat_logo.png',
                  width: 32,
                  height: 32,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Chat History',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Tạo nút New Chat
  Widget _buildNewChatButton() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          // Tạo đoạn chat mới
          onPressed: _createNewChat,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 2,
          ),
          icon: const Icon(Icons.add_circle_outline, size: 22),
          label: const Text(
            'New Chat',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  // Tạo lịch sử đoạn chat
  Widget _buildChatHistory() {
    return StreamBuilder(
      stream: FirebaseFirestore.instance
          .collection(GetV.userName.text)
          .doc(GetV.userChatID)
          .collection('Message')
          .orderBy('createdAt', descending: true)
          .snapshots(),
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

        if (loadedMessages.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.chat_bubble_outline,
                  size: 64,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  'No chat history',
                  style: AppTheme.bodyText1.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          );
        }
        
        // Danh sách đoạn chat
        return ListView.builder(
          controller: _listScrollController,
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: loadedMessages.length,
          itemBuilder: (context, index) {
            final chatMessage = loadedMessages[index].data();
            
            if (chatMessage['text'] == '') {
              return const SizedBox.shrink();
            }

            // Tạo giao diện các đoạn chat
            return _buildChatHistoryItem(chatMessage);
          },
        );
      },
    );
  }

  // Tạo giao diện các đoạn chat
  Widget _buildChatHistoryItem(Map<String, dynamic> chatMessage) {
    // THÊM: Kiểm tra xem item này có đang được chọn không
    final bool isSelected = chatMessage['messageID'] == GetV.messageChatID;
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        // ĐỔI MÀU: Gradient xanh dương khi được chọn
        gradient: isSelected
            ? LinearGradient(
                colors: [Colors.blue[400]!, Colors.blue[600]!],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : null,
        color: isSelected ? null : Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          // ĐỔI MÀU VIỀN: Xanh đậm khi được chọn
          color: isSelected ? Colors.blue[700]! : Colors.grey[200]!,
          width: isSelected ? 2 : 1,
        ),
        // THÊM SHADOW: Shadow mạnh hơn khi được chọn
        boxShadow: isSelected
            ? [
                BoxShadow(
                  color: Colors.blue.withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ]
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          // Nhấn vào đoạn chat lịch sử thì tiện thể xóa đoạn chat hiện tại nếu không có tiêu đề.
          onTap: () async {
            final resd = await FirebaseFirestore.instance
                .collection(GetV.userName.text)
                .doc(GetV.userChatID)
                .collection('Message')
                .doc(GetV.messageChatID)
                .get();
            if (resd['text'] == '') {
              await FirebaseFirestore.instance
                  .collection(GetV.userName.text)
                  .doc(GetV.userChatID)
                  .collection('Message')
                  .doc(GetV.messageChatID)
                  .delete();
            }
            setState(() {
              GetV.chatNum = chatMessage['Index'];
              GetV.messageChatID = chatMessage['messageID'];
              GetV.refreshIndicatorKey.currentState?.show();
              GetV.menuPressed = true;
            });
            widget.toRefresh();
          },
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    // ĐỔI MÀU ICON: Trắng khi được chọn
                    color: isSelected 
                        ? Colors.white.withValues(alpha: 0.3)
                        : Colors.blue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.chat_bubble_outline,
                    // ĐỔI MÀU ICON: Trắng khi được chọn
                    color: isSelected ? Colors.white : Colors.blue,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: AutoSizeText(
                    chatMessage['text'],
                    style: AppTheme.bodyText1.copyWith(
                      fontWeight: FontWeight.w500,
                      // ĐỔI MÀU CHỮ: Trắng khi được chọn
                      color: isSelected ? Colors.white : Colors.black87,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.delete_outline, size: 20),
                  // ĐỔI MÀU NÚT XÓA: Trắng/hồng khi được chọn
                  color: isSelected ? Colors.white : Colors.red[400],
                  onPressed: () => _deleteChat(chatMessage),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Hàm xóa đoạn chat (Nút thùng rác)
  Future<void> _deleteChat(Map<String, dynamic> chatMessage) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.orange),
            SizedBox(width: 8),
            Text('Delete Chat'),
          ],
        ),
        // Thông báo xác nhận xóa
        content: const Text('Are you sure you want to delete this chat?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    // Nếu bấm Cancel thì hủy
    if (confirm != true) return;

    // Ngược lại bấm Delete thì xóa.
    // Lấy đoạn chat
    final res = await FirebaseFirestore.instance
        .collection(GetV.userName.text)
        .doc(GetV.userChatID)
        .collection('Message')
        .doc(chatMessage['messageID'])
        .get();

    // Nếu không phải đoạn chat hiện tại là đoạn chat cần xóa thì chỉ xóa ở menu
    if (GetV.messageChatID != res['messageID']) {
      String text = res['messageID'];
      await FirebaseFirestore.instance
          .collection(GetV.userName.text)
          .doc(GetV.userChatID)
          .collection('Message')
          .doc(text)
          .delete();
      widget.toRefresh();
    } 
    // Ngược lại thì xóa và tạo 1 đoạn chat mới và đổi qua đoạn chat mới đó
    else {
      // Delete current chat and create new one
      final upURL = Uri.https(
          'your-project-name-b1e6c-default-rtdb.firebaseio.com', 'chatNum.json');
      final res = await http.get(upURL);
      final Map<String, dynamic> dat = json.decode(res.body);
      int maxNum = 1;
      for (final item in dat.entries) {
        if (GetV.userName.text == item.value['user-name']) {
          if (maxNum < item.value['chat-num']) {
            maxNum = item.value['chat-num'];
          }
        }
      }
      
      // Xóa
      await FirebaseFirestore.instance
          .collection(GetV.userName.text)
          .doc(GetV.userChatID)
          .collection('Message')
          .doc(GetV.messageChatID)
          .delete();

      setState(() {
        GetV.title = '';
        GetV.chatNum = maxNum + 1;
        GetV.menuPressed = true;
      });
      
      // Tạo đoạn chat mới
      await FirebaseFirestore.instance
          .collection(GetV.userName.text)
          .doc(GetV.userChatID)
          .collection('Message')
          .add({
        'text': '',
        'Index': GetV.chatNum,
        'messageID': GetV.messageChatID,
        'createdAt': Timestamp.now(),
      }).then((DocumentReference doc) {
        GetV.messageChatID = doc.id;
      });
      
      await FirebaseFirestore.instance
          .collection(GetV.userName.text)
          .doc(GetV.userChatID)
          .collection('Message')
          .doc(GetV.messageChatID)
          .update({
        'text': '',
        'Index': GetV.chatNum,
        'messageID': GetV.messageChatID,
        'createdAt': Timestamp.now(),
      });
      
      // Cập nhật chat Num của đoạn chat mới
      final url2 = Uri.https(
          'your-project-name-b1e6c-default-rtdb.firebaseio.com', 'chatNum.json');
      final response2 = await http.get(url2);
      final Map<String, dynamic> resData2 = json.decode(response2.body);
      for (final item in resData2.entries) {
        if (GetV.userName.text == item.value['user-name']) {
          item.value['chat-num'] = GetV.chatNum;
        }
      }

      // Cập nhật chat item number, hiện không dùng.
      final url = Uri.https('your-project-name-b1e6c-default-rtdb.firebaseio.com',
          'chatItemNumber.json');
      final response = await http.get(url);
      final Map<String, dynamic> resData = json.decode(response.body);
      for (final item in resData.entries) {
        if (GetV.userName.text == item.value['user-name']) {
          item.value['chat-ItemNumber'] = GetV.chatNum;
        }
      }
      widget.toRefresh();
    }
  }

  // Thông tin người dùng
  Widget _buildUserInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[100],
      ),
      child: Row(
        children: [
          const CircleAvatar(
            backgroundColor: Colors.blue,
            radius: 20,
            child: Text(
              'U',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Logged in as',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 2),
                AutoSizeText(
                  GetV.userName.text,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}