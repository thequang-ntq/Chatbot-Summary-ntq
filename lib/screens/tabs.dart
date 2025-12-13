//This is an important code file that controls navigation between 
//home, chat and summarize screen.
//This is like the main UI for all the app.

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

  Future<bool> checkApiKey(String apiKey) async {
    try {
      final response = await http.get(
        Uri.parse("https://api.openai.com/v1/models"),
        headers: {
          "Authorization": "Bearer $apiKey",
          "Content-Type": "application/json",
        },
      ).timeout(const Duration(seconds: 10));
      
      if (response.statusCode == 200) {
        return true;
      } else {
        debugPrint('API Key validation failed: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      debugPrint('Error checking API key: $e');
      return false;
    }
  }

  //Submit function - Fix
  void toSubmit(TextEditingController apiKeyValue, TextEditingController userName) async {
    _apiKeyValue = apiKeyValue;
    _userName = userName;
    
    // Kiểm tra format cơ bản trước
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

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogCtx) {
        loadingDialogContext = dialogCtx;
        return const PopScope(
          canPop: false,
          child: const Center(
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

    // Kiểm tra API
    final isValid = await checkApiKey(apiKeyValue.text.trim());

    // Đóng dialog đúng cách
    if (loadingDialogContext != null && mounted) {
      Navigator.of(loadingDialogContext!).pop();
      loadingDialogContext = null;
    }

    if (!mounted) return;
    
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
    for (final item in resData.entries) {
      if (item.value['api-key'] == apiKeyValue.text) {
        apiExists = true;
        break;
      }
    }
    
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
    
    // Xử lý username trong Firebase (giữ nguyên phần này)
    final url2 = Uri.https('your-project-name-b1e6c-default-rtdb.firebaseio.com', 'userNames.json');
    final response2 = await http.get(url2);
    final Map<String, dynamic> resData2 = json.decode(response2.body);
    
    bool userExists = false;
    for (final item in resData2.entries) {
      if (item.value['user-name'] == userName.text) {
        userExists = true;
        break;
      }
    }
    
    if (!userExists) {
      await http.post(url2, 
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'user-name': userName.text,
        }),
      );
      
      // Tạo collections mới
      await FirebaseFirestore.instance.collection(userName.text).add(
        {'Chat': 'Chat'}
      ).then((DocumentReference doc){
        GetV.userChatID = doc.id;
      });
      
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
      
      await FirebaseFirestore.instance.collection(userName.text).add(
        {'Summary': 'Summary'}
      ).then((DocumentReference doc){
        GetV.userSummaryID = doc.id;
      });
      
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
    } else {
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

  //Change to chat screen
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
    if (_enteredApiKey == '' || _enteredApiKey.isEmpty || _enteredUserName.isEmpty) {
      showDialog(
        context: context,
        builder: (context) {
          return const AlertDialog(
            // Retrieve the text the that user has entered by using the
            // TextEditingController.
            content: Text('You are not entered the Api Key. Please enter one!'),
          );
        },
      );
    } else {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const Loadings()),
        );
        final urlChatID = Uri.https('your-project-name-b1e6c-default-rtdb.firebaseio.com', 'userChatID.json');
        final responseChatID = await http.get(urlChatID);
        final resDataChatID = await json.decode(responseChatID.body);
        for(final item in resDataChatID.entries){
          if(_enteredUserName == item.value['user-name']){
            GetV.userChatID = item.value['user-chatID'];
            GetV.userName.text = _enteredUserName;
          }
        }
        final url2 = Uri.https('your-project-name-b1e6c-default-rtdb.firebaseio.com', 'chatNum.json');
        final response2 = await http.get(url2);
        if (response2.body.contains(_enteredUserName) == true){
          final Map<String,dynamic> resData2 = json.decode(response2.body);
          for(final item in resData2.entries){
            if(_enteredUserName == item.value['user-name']){
              
              int temp = item.value['chat-num'] + 1;
              await http.delete(url2, 
                headers: {
                  'Content-Type' : 'chatNum/json',
                },
              );

              await http.post(url2, 
                headers: {
                  'Content-Type' : 'chatNum/json',
                },
                body: json.encode({
                  'chat-num': temp,
                  'user-name': _enteredUserName,
                }),
              );
              GetV.chatNum = temp;
              
              // break;
            }
          }
        }
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

        await FirebaseFirestore.instance.collection(GetV.userName.text).doc(GetV.userChatID).collection('Message').add({
            'text' : '',
            'Index' : GetV.chatNum,
            'messageID': GetV.messageChatID,
            'createdAt': Timestamp.now(),
          }).then((DocumentReference doc){
            GetV.messageChatID = doc.id;
          });
        await FirebaseFirestore.instance.collection(GetV.userName.text).doc(GetV.userChatID).collection('Message').doc(GetV.messageChatID).update({
            'text' : '',
            'Index' : GetV.chatNum,
            'messageID': GetV.messageChatID,
            'createdAt': Timestamp.now(),
          }); 

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
      setState(() {
        _activeScreen = 'chat-screen';
      });
    }
  }

  //Change to summarize screen
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
    if (_enteredApiKey == '' || _enteredApiKey.isEmpty || _enteredUserName.isEmpty) {
      showDialog(
        context: context,
        builder: (context) {
          return const AlertDialog(
            content: Text('You are not entered the Api Key. Please enter one!'),
          );
        },
      );
    } else {
      setState(() {
        GetV.loadingUploadFile = false;
      });
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const Loadings()),
      );
      final urlSummaryID = Uri.https('your-project-name-b1e6c-default-rtdb.firebaseio.com', 'userSummaryID.json');
      final responseSummaryID = await http.get(urlSummaryID);

      final resDataSummaryID = await json.decode(responseSummaryID.body);
      for(final item in resDataSummaryID.entries){
        if(_enteredUserName == item.value['user-name']){
          GetV.userSummaryID = item.value['user-summaryID'];
          GetV.userName.text = _enteredUserName;
        }
      }

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

        await FirebaseFirestore.instance.collection(GetV.userName.text).doc(GetV.userSummaryID).collection('Summarize').add({
            'text' : '',
            'Index' : GetV.summaryNum,
            'messageID': GetV.messageSummaryID,
            'createdAt': Timestamp.now(),
          }).then((DocumentReference doc){
            GetV.messageSummaryID = doc.id;
          }); 
        await FirebaseFirestore.instance.collection(GetV.userName.text).doc(GetV.userSummaryID).collection('Summarize').doc(GetV.messageSummaryID).update({
            'text' : '',
            'Index' : GetV.summaryNum,
            'messageID': GetV.messageSummaryID,
            'createdAt': Timestamp.now(),
          }); 

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
    Widget screenWidget = HomeScreen(
      apiKeyValue: _apiKeyValue,
      name: _userName,
      toSubmit: toSubmit,
      toChat: toChat,
      toSummarize: toSummarize,
    );

    if (_activeScreen == 'chat-screen') {
      screenWidget = const Chat();
    }

    if (_activeScreen == 'summarize-screen') {
      screenWidget = const Summarize();
    }

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
