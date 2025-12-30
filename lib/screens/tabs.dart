//This is an important code file that controls navigation between 
//home, chat and summarize screen.
//This is like the main UI for all the app.
// - Quản lý 3 màn hình: Home, Chat, Summarize
// - Xử lý submit API key và username
// - Khởi tạo dữ liệu Firebase cho user mới
// - Load dữ liệu cho user cũ
// FLow hoạt động:
// 1. User nhập API key + username
// 2. Validate API key (gọi OpenAI API)
// 3. Kiểm tra user đã tồn tại chưa:
//   - Nếu mới: Tạo collections trong Firestore
//   - Nếu cũ: Load userChatID và userSummaryID
// 4. Cho phép chuyển sang Chat hoặc Summarize

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:chatgpt/screens/loading.dart';
import 'package:chatgpt/screens/internet.dart';
import 'package:chatgpt/screens/chat.dart';
import 'package:chatgpt/screens/home.dart';
import 'package:chatgpt/screens/summarize.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connection_notifier/connection_notifier.dart';
import 'dart:convert';

class Tabs extends StatefulWidget {
  const Tabs({super.key});

  @override
  State<Tabs> createState() => _TabsState();
}

class _TabsState extends State<Tabs> {
  BuildContext? loadingDialogContext;
  var _activeScreen = 'home-screen';
  var _enteredApiKey = '';
  var _apiKeyValue = TextEditingController();
  var _userName = TextEditingController();
  var _enteredUserName = '';

  @override
  void initState() {
    setState(() {
      if(GetV.apiKey.text.isNotEmpty && GetV.userName.text.isNotEmpty){
        _enteredApiKey = GetV.apiKey.text;
        _enteredUserName = GetV.userName.text;
      }
    },);
    super.initState();
  }

  // Hàm kiểm tra API Key hợp lệ, dùng trong toSubmit
  Future<bool> checkApiKey(String apiKey) async {
    try {
      final response = await http.get(
        Uri.parse("https://api.openai.com/v1/models"),
        headers: {
          "Authorization": "Bearer $apiKey",
          "Content-Type": "application/json",
        },
      ).timeout(const Duration(seconds: 10));
      
      // Hợp lệ nếu mã trả về là 200
      if (response.statusCode == 200) {
        return true;
      } 
      else {
        debugPrint('API Key validation failed: ${response.statusCode}');
        return false;
      }
    } 
    catch (e) {
      debugPrint('Error checking API key: $e');
      return false;
    }
  }

  //Submit function - Fix
  // Xác thực và lưu thông tin User
  void toSubmit(TextEditingController apiKeyValue, TextEditingController userName) async {
    _apiKeyValue = apiKeyValue;
    _userName = userName;
    
    // Kiểm tra format cơ bản trước, API Key không rỗng và phải dài hơn 20 ký tự
    if (apiKeyValue.text.isEmpty || apiKeyValue.text.trim().length < 20) {
      setState(() {
        GetV.isAPI = false;
      });
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Row(
            children: [
              Icon(Icons.error_outline, color: Colors.red),
              SizedBox(width: 8),
              Text('Invalid API Key'),
            ],
          ),
          content: const Text('Please enter a valid API Key (must start with "sk-" and have correct length)'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      return;
    }
    
    // Không hợp format của API key -> Fail
    if (!apiKeyValue.text.startsWith("sk-")) {
      setState(() {
        GetV.isAPI = false;
      });
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Row(
            children: [
              Icon(Icons.error_outline, color: Colors.red),
              SizedBox(width: 8),
              Text('Invalid API Key Format'),
            ],
          ),
          content: const Text('API Key must start with "sk-"'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      return;
    }
    
    // User name không rỗng và lớn hơn 3 ký tự
    if (userName.text.isEmpty || userName.text.trim().length < 3) {
      setState(() {
        GetV.isAPI = false;
      });
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Row(
            children: [
              Icon(Icons.error_outline, color: Colors.red),
              SizedBox(width: 8),
              Text('Invalid Username'),
            ],
          ),
          content: const Text('Please enter a valid username (at least 3 characters)'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      return;
    }
    
    // Hiện loading
    loadingDialogContext = null;
    // Dialog đang kiểm tra API Key
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogCtx) {
        loadingDialogContext = dialogCtx;
        return const PopScope(
          canPop: false,
          child: Center(
            child: Card(
              child: Padding(
                padding: EdgeInsets.all(20.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Validating API Key...'),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );

    // Kiểm tra API sau khi validate sơ bộ
    final isValid = await checkApiKey(apiKeyValue.text.trim());

    // Đóng dialog đúng cách
    if (loadingDialogContext != null && mounted) {
      Navigator.of(loadingDialogContext!).pop();
      loadingDialogContext = null;
    }

    if (!mounted) return;
    // Lỗi Api Key đã expired hoặc invalid
    if (!isValid) {
      setState(() {
        GetV.isAPI = false;
      });
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Row(
            children: [
              Icon(Icons.error_outline, color: Colors.red),
              SizedBox(width: 8),
              Text('API Key Verification Failed'),
            ],
          ),
          content: const Text(
            'The API Key you entered is invalid or has expired. Please check:\n\n'
            '• The key is copied correctly\n'
            '• The key has not been revoked\n'
            '• You have an active OpenAI account\n'
            '• Your internet connection is stable'
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      return;
    }
    
    // API Key hợp lệ
    setState(() {
      GetV.isAPI = true;
      _enteredApiKey = apiKeyValue.text;
      _enteredUserName = userName.text;
      GetV.apiKey.text = _enteredApiKey;
      GetV.userName.text = _enteredUserName;
    });
    
    // Hiện thông báo thành công
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green),
            SizedBox(width: 8),
            Text('Success'),
          ],
        ),
        content: const Text('API Key and Username verified successfully! You can now use the app.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
    
    // Lưu vào Firebase
    final url = Uri.https('your-project-name-b1e6c-default-rtdb.firebaseio.com', 'api-keys.json');
    final response = await http.get(url);
    final Map<String, dynamic> resData = json.decode(response.body);
    
    bool apiExists = false;
    // Kiểm tra Api Key đã có trong Realtime DB chưa
    for (final item in resData.entries) {
      if (item.value['api-key'] == apiKeyValue.text) {
        apiExists = true;
        break;
      }
    }
    
    // Nếu chưa thì tạo mới.
    if (!apiExists) {
      await http.post(url, 
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'api-key': apiKeyValue.text,
        }),
      );
    }
    
    // Xử lý username trong Firebase, Realtime DB
    final url2 = Uri.https('your-project-name-b1e6c-default-rtdb.firebaseio.com', 'userNames.json');
    final response2 = await http.get(url2);
    final Map<String, dynamic> resData2 = json.decode(response2.body);
    
    bool userExists = false;
    // Kiểm tra Username đã có chưa
    for (final item in resData2.entries) {
      if (item.value['user-name'] == userName.text) {
        userExists = true;
        break;
      }
    }
    
    //Nếu chưa thì tạo mới username, userChatID và userSummaryID, chứa các đoạn chat và đoạn summary.
    if (!userExists) {
      await http.post(url2, 
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'user-name': userName.text,
        }),
      );
      
      // Tạo collections mới: Tạo collection Chat lưu các đoạn chat cho username trong Firestore
      // Username -> Chat
      await FirebaseFirestore.instance.collection(userName.text).add(
        {'Chat': 'Chat'}
      ).then((DocumentReference doc){
        GetV.userChatID = doc.id;
      });
      
      // Lấy UserChatID ở trên lưu vào realtime DB, phần userChatID với thông tin username và userChatID tương ứng. 
      final url3 = Uri.https('your-project-name-b1e6c-default-rtdb.firebaseio.com', 'userChatID.json');
      await http.post(url3, 
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'user-chatID': GetV.userChatID,
          'user-name': userName.text,
        }),
      );
      
      // Tương tự, tạo collection Summary lưu các đoạn Summary cho username trong Firestore
      await FirebaseFirestore.instance.collection(userName.text).add(
        {'Summary': 'Summary'}
      ).then((DocumentReference doc){
        GetV.userSummaryID = doc.id;
      });
      
      // Lấy userSummaryID ở trên lưu vào Realtime DB, phần userSummaryID.
      final url4 = Uri.https('your-project-name-b1e6c-default-rtdb.firebaseio.com', 'userSummaryID.json');
      await http.post(url4, 
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'user-summaryID': GetV.userSummaryID,
          'user-name': userName.text,
        }),
      );
      
      GetV.userName.text = _enteredUserName;
    }
    // Nếu đã có dữ liệu username thì lấy lại username, userChatID và userSummaryID trong Realtime DB. 
    else {
      // Load existing user data
      final url5 = Uri.https('your-project-name-b1e6c-default-rtdb.firebaseio.com', 'userChatID.json');
      final response5 = await http.get(url5);
      final resData5 = await json.decode(response5.body);
      for(final item in resData5.entries){
        if(_enteredUserName == item.value['user-name']){
          GetV.userChatID = item.value['user-chatID'];
          GetV.userName.text = _enteredUserName;
        }
      }

      final url6 = Uri.https('your-project-name-b1e6c-default-rtdb.firebaseio.com', 'userSummaryID.json');
      final response6 = await http.get(url6);
      final resData6 = await json.decode(response6.body);
      for(final item in resData6.entries){
        if(_enteredUserName == item.value['user-name']){
          GetV.userSummaryID = item.value['user-summaryID'];
          GetV.userName.text = _enteredUserName;
        }
      } 
      GetV.userName.text = _enteredUserName;
    }
  }

  // Change to chat screen
  // Khởi tạo ChatSession mới, chuyển qua trang Chat.
  void toChat() async{
    if(GetV.apiKey.text.isNotEmpty){
      setState(() {
        _enteredApiKey = GetV.apiKey.text;
      });
    }
    if(GetV.userName.text.isNotEmpty){
      setState(() {
        _enteredUserName = GetV.userName.text;
      });
    }
    // Kiểm tra API Key và Username chưa hợp lệ thì chưa cho chuyển
    if (_enteredApiKey == '' || _enteredApiKey.isEmpty || _enteredUserName.isEmpty) {
      showDialog(
        context: context,
        builder: (context) {
          return const AlertDialog(
            // Retrieve the text the that user has entered by using the
            // TextEditingController.
            content: Text('You are not entered the Api Key or not entered the Username. Please enter!'),
          );
        },
      );
    } 
    else {
        // Qua màn hình đợi
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const Loadings()),
        );
        // Lấy UserChatID được tạo hoặc đã có dữ liệu ở trên
        final urlChatID = Uri.https('your-project-name-b1e6c-default-rtdb.firebaseio.com', 'userChatID.json');
        final responseChatID = await http.get(urlChatID);
        final resDataChatID = await json.decode(responseChatID.body);
        for(final item in resDataChatID.entries){
          if(_enteredUserName == item.value['user-name']){
            GetV.userChatID = item.value['user-chatID'];
            GetV.userName.text = _enteredUserName;
          }
        }
        // Lấy dữ liệu chatNum, dữ liệu này cho biết index là số thứ tự của đoạn chat.
        // Để lấy ra được đoạn chat tương ứng. chatNum này khi mới vào trang Chat thì
        // sẽ lấy số trong chatNum trong dữ liệu realtime DB hiện tại + 1, bảo đảm ra index đoạn chat mới, không trùng
        // index những đoạn chat trước đó. Đây là trường hợp username đã có trong realtime DB, username cũ, 
        // đã có dùng và vào trang chat, chatNum đã có trước đó.
        final url2 = Uri.https('your-project-name-b1e6c-default-rtdb.firebaseio.com', 'chatNum.json');
        final response2 = await http.get(url2);
        if (response2.body.contains(_enteredUserName) == true){
          final Map<String,dynamic> resData2 = json.decode(response2.body);
          for(final item in resData2.entries){
            if(_enteredUserName == item.value['user-name']){
              // Cộng 1 tránh trùng, bảo đảm đoạn chat mới.
              int temp = item.value['chat-num'] + 1;
              // Xóa chatNum cũ
              await http.delete(url2, 
                headers: {
                  'Content-Type' : 'chatNum/json',
                },
              );
              // Thêm chatNum mới
              await http.post(url2, 
                headers: {
                  'Content-Type' : 'chatNum/json',
                },
                body: json.encode({
                  'chat-num': temp,
                  'user-name': _enteredUserName,
                }),
              );
              // Gán dữ liệu
              GetV.chatNum = temp;
              
              // break;
            }
          }
        }
        // Trường hợp tạo username lần đầu, chatNum = 1 là bắt đầu.
        else if (response2.body.contains(_enteredUserName) == false){
          await http.post(url2, 
            headers: {
              'Content-Type' : 'chatNum/json',
            },
            body: json.encode({
              'chat-num': 1,
              'user-name': _enteredUserName,
            }),
          );
          GetV.chatNum = 1;
        }
        // Tạm thêm đoạn chat với tiêu đề text rỗng, index = chatNum. messageChatID là ID đoạn chat trong Chat.
        await FirebaseFirestore.instance.collection(GetV.userName.text).doc(GetV.userChatID).collection('Message').add({
            'text' : '',
            'Index' : GetV.chatNum,
            'messageID': GetV.messageChatID,
            'createdAt': Timestamp.now(),
          }).then((DocumentReference doc){
            GetV.messageChatID = doc.id; // Gán dữ liệu ID Đoạn chat
          });
        // Cập nhật đoạn chat mới tạo ở trên, sửa lại messageChatID cho đúng với messageChatID của đoạn chat mới tạo sau khi gán dữ liệu.
        await FirebaseFirestore.instance.collection(GetV.userName.text).doc(GetV.userChatID).collection('Message').doc(GetV.messageChatID).update({
            'text' : '',
            'Index' : GetV.chatNum,
            'messageID': GetV.messageChatID,
            'createdAt': Timestamp.now(),
          }); 
        // Nguyên bản đây là chatItemNumber, là số thứ tự của đoạn chat được tạo sau khi vào trang, username và ID đoạn chat.
        // Kiểm tra xem cái số thứ tự đoạn chat hiện tại đã có trong chatItemNumber chưa, nếu chưa thì thêm vào.
        // Nhưng hiện tại không cần dùng vì có chatNum là đủ rồi.
        final url = Uri.https('your-project-name-b1e6c-default-rtdb.firebaseio.com', 'chatItemNumber.json');
        final response = await http.get(url);
        bool check = true;
        if(response.body != 'null'){
          final Map<String,dynamic> resData = json.decode(response.body);
          for(final item in resData.entries){
            if(GetV.chatNum == item.value['chat-ItemNumber']){
              check = false;
              break;
            }
          }
        }
        if(check == true){
          await http.post(url, 
            headers: {
              'Content-Type' : 'chatItemNumber/json',
            },
            body: json.encode({
              'chat-ItemNumber': GetV.chatNum,
              'user-name': _enteredUserName,
              'ID' : GetV.messageChatID,
            }),
          );
        }
      Navigator.pop(context);
      // Chuyển qua chat screen
      setState(() {
        _activeScreen = 'chat-screen';
      });
    }
  }

  // Change to summarize screen
  // Khởi tạo summarize session mới
  void toSummarize() async{
    if(GetV.apiKey.text.isNotEmpty){
      setState(() {
        _enteredApiKey = GetV.apiKey.text;
      });
    }
    if(GetV.userName.text.isNotEmpty){
      setState(() {
        _enteredUserName = GetV.userName.text;
      });
    }
    // Kiểm tra API Key và Username chưa hợp lệ thì chưa cho chuyển
    if (_enteredApiKey == '' || _enteredApiKey.isEmpty || _enteredUserName.isEmpty) {
      showDialog(
        context: context,
        builder: (context) {
          return const AlertDialog(
            content: Text('You are not entered the Api Key or not entered the Username. Please enter!'),
          );
        },
      );
    } 
    else {
      setState(() {
        GetV.loadingUploadFile = false;
      });
      // Chuyển qua trang đợi
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const Loadings()),
      );
      // Lấy UserSummaryID được tạo hoặc đã có dữ liệu ở trên
      final urlSummaryID = Uri.https('your-project-name-b1e6c-default-rtdb.firebaseio.com', 'userSummaryID.json');
      final responseSummaryID = await http.get(urlSummaryID);

      final resDataSummaryID = await json.decode(responseSummaryID.body);
      for(final item in resDataSummaryID.entries){
        if(_enteredUserName == item.value['user-name']){
          GetV.userSummaryID = item.value['user-summaryID'];
          GetV.userName.text = _enteredUserName;
        }
      }

      // summaryNum là số thứ tự đoạn summary.
      // Lấy dữ liệu summaryNum, dữ liệu này cho biết index là số thứ tự của đoạn summary.
      // Để lấy ra được đoạn summary tương ứng. summaryNum này khi mới vào trang Sumamry thì
      // sẽ lấy số trong summaryNum trong dữ liệu realtime DB hiện tại + 1, bảo đảm ra index đoạn sumamry mới, không trùng
      // index những đoạn summary trước đó. Đây là trường hợp username đã có trong realtime DB, username cũ, 
      // đã có dùng và vào trang summary, summaryNum đã có trước đó.
      final url2 = Uri.https('your-project-name-b1e6c-default-rtdb.firebaseio.com', 'summaryNum.json');
        final response2 = await http.get(url2);
        if (response2.body.contains(_enteredUserName) == true){
          final Map<String,dynamic> resData2 = json.decode(response2.body);
          for(final item in resData2.entries){
            if(_enteredUserName == item.value['user-name']){
              
              int temp = item.value['summary-num'] + 1;
              await http.delete(url2, 
                headers: {
                  'Content-Type' : 'summaryNum/json',
                },
              );

              await http.post(url2, 
                headers: {
                  'Content-Type' : 'summaryNum/json',
                },
                body: json.encode({
                  'summary-num': temp,
                  'user-name': _enteredUserName,
                }),
              );
              GetV.summaryNum = temp;
              
              // break;
            }
          }
        }
        // Chưa có thì tạo mới
        else if (response2.body.contains(_enteredUserName) == false){
          await http.post(url2, 
            headers: {
              'Content-Type' : 'summaryNum/json',
            },
            body: json.encode({
              'summary-num': 1,
              'user-name': _enteredUserName,
            }),
          );
          GetV.summaryNum = 1;
        }

        // Tạo collection đoạn summary mới, ban đầu tiêu đề text rỗng, index là ID đoạn summary.
        await FirebaseFirestore.instance.collection(GetV.userName.text).doc(GetV.userSummaryID).collection('Summarize').add({
            'text' : '',
            'Index' : GetV.summaryNum,
            'messageID': GetV.messageSummaryID,
            'createdAt': Timestamp.now(),
          }).then((DocumentReference doc){
            GetV.messageSummaryID = doc.id;
          }); 
        // Cập nhật gán lại ID đoạn summary cho đúng trong collection đoạn summary tạo ở trên.
        await FirebaseFirestore.instance.collection(GetV.userName.text).doc(GetV.userSummaryID).collection('Summarize').doc(GetV.messageSummaryID).update({
            'text' : '',
            'Index' : GetV.summaryNum,
            'messageID': GetV.messageSummaryID,
            'createdAt': Timestamp.now(),
          }); 

        // Nguyên bản đây là sumamryItemNumber, là số thứ tự của đoạn summary được tạo sau khi vào trang, username và ID đoạn sumamry.
        // Kiểm tra xem cái số thứ tự đoạn summary hiện tại đã có trong summaryItemNumber chưa, nếu chưa thì thêm vào.
        // Nhưng hiện tại không cần dùng vì có summaryNum là đủ rồi.
        final url = Uri.https('your-project-name-b1e6c-default-rtdb.firebaseio.com', 'summaryItemNumber.json');
        final response = await http.get(url);
        bool check = true;
        if(response.body != 'null'){
          final Map<String,dynamic> resData = json.decode(response.body);
          for(final item in resData.entries){
            if(GetV.summaryNum == item.value['summary-ItemNumber']){
              check = false;
              break;
            }
          }
        }
        if(check == true){
          await http.post(url, 
            headers: {
              'Content-Type' : 'summaryItemNumber/json',
            },
            body: json.encode({
              'summary-ItemNumber': GetV.summaryNum,
              'user-name': _enteredUserName,
              'ID' : GetV.messageSummaryID,
            }),
          );
        }
      Navigator.pop(context);
      setState(() {
        _activeScreen = 'summarize-screen';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Trang hiện tại là HomeScreen, của home.dart, trang chủ Home. Lấy các giá trị Widget Values và các hàm cần thiết trong
    // trang chủ là các biến ở đây.
    // Ban đầu qua trang Home.
    // Truyền biến từ tabs qua home.
    Widget screenWidget = HomeScreen(
      apiKeyValue: _apiKeyValue,
      name: _userName,
      toSubmit: toSubmit,
      toChat: toChat,
      toSummarize: toSummarize,
    );

    // Chuyển qua trang Chat
    if (_activeScreen == 'chat-screen') {
      screenWidget = const Chat();
    }

    // Chuyển qua trang Summary
    if (_activeScreen == 'summarize-screen') {
      screenWidget = const Summarize();
    }

    // Trả về screen hiện tại là Home, Chat hoặc Summary.
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: ConnectionNotifierToggler(
        onConnectionStatusChanged: (connected) {
          if (connected == null) return;
        },
        disconnected: const InternetErr(),
        connected: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.white,
                  Colors.grey,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: screenWidget,
          ),
        ),
      ),
    );
  }
}
