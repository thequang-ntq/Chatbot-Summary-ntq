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

  //Submit function
  void toSubmit(TextEditingController apiKeyValue, TextEditingController userName) async{
    _apiKeyValue = apiKeyValue;
    _userName = userName;
    if (apiKeyValue.text.isEmpty || apiKeyValue.text == '' || apiKeyValue.text.trim().length < 120 ||
      apiKeyValue.text.substring(0,3) != "sk-" || GetV.isAPI == false)
    {
      showDialog(
        context: context,
        builder: (context) {
          Future.delayed(const Duration(milliseconds: 500), () {
                    const CircularProgressIndicator();
          });
          return const AlertDialog(
            content: Text('Please enter a valid Api Key'),
          );
        },
      );
    }
    else if (userName.text.isEmpty)
    {
      showDialog(
        context: context,
        builder: (context) {
          Future.delayed(const Duration(milliseconds: 500), () {
                    const CircularProgressIndicator();
          });
          return const AlertDialog(
            content: Text('Please enter a UserName'),
          );
        },
      );
    } 
    else {
      _enteredApiKey = apiKeyValue.text;
      _enteredUserName = userName.text;
      GetV.apiKey.text = _enteredApiKey;
      GetV.userName.text = _enteredUserName;
      showDialog(
        context: context,
        builder: (context) {
          Future.delayed(const Duration(milliseconds: 500), () {
                    const CircularProgressIndicator();
          });
          return const AlertDialog(
            content: Text('API Key and UserName corrected! Thanks for using our app!'),
          );
        },
      );
      final url = Uri.https('your-project-name-b1e6c-default-rtdb.firebaseio.com', 'api-keys.json');
      final response = await http.get(url);
      if(response.body.contains(apiKeyValue.text)==false){
        await http.post(url, 
        headers: {
          'Content-Type' : 'apikey/json',
        },
        body: json.encode({
          'api-key': apiKeyValue.text,
        }),
      );
      }
      
      final url2 = Uri.https('your-project-name-b1e6c-default-rtdb.firebaseio.com', 'userNames.json');
      final response2 = await http.get(url2);
      if(response2.body.contains(userName.text)==false){
        await http.post(url2, 
          headers: {
            'Content-Type' : 'userName/json',
          },
          body: json.encode({
            'user-name': userName.text,
          }),
        );
        await FirebaseFirestore.instance.collection(userName.text).add(
          {'Chat': 'Chat'}
        ).then((DocumentReference doc){
          GetV.userChatID = doc.id;
        });
        final url3 = Uri.https('your-project-name-b1e6c-default-rtdb.firebaseio.com', 'userChatID.json');
        await http.post(url3, 
          headers: {
            'Content-Type' : 'userchatid/json',
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
            'Content-Type' : 'usersummaryid/json',
          },
          body: json.encode({
            'user-summaryID': GetV.userSummaryID,
            'user-name': userName.text,
          }),
        );
        GetV.userName.text = _enteredUserName;
      }
      else if(response2.body.contains(userName.text)==true){
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
            // break;
          }
        } 
        GetV.userName.text = _enteredUserName;
      }
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
