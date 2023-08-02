import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:chatgpt/screens/chat.dart';
import 'package:chatgpt/screens/home.dart';
import 'package:chatgpt/screens/summarize.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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
    super.initState();
  }

  void toSubmit(TextEditingController apiKeyValue, TextEditingController userName) async{
    _apiKeyValue = apiKeyValue;
    _userName = userName;
    if (apiKeyValue.text.isEmpty || apiKeyValue.text == '' || apiKeyValue.text.trim().length != 51 ||
      apiKeyValue.text.substring(0,3) != "sk-" || GetV.isAPI == false)
    {
      showDialog(
        context: context,
        builder: (context) {
          Future.delayed(const Duration(milliseconds: 500), () {
                    const CircularProgressIndicator();
          });
          return const AlertDialog(
            // Retrieve the text the that user has entered by using the
            // TextEditingController.
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
            // Retrieve the text the that user has entered by using the
            // TextEditingController.
            content: Text('Please enter a UserName'),
          );
        },
      );
    } 
    else {
      _enteredApiKey = apiKeyValue.text;
      _enteredUserName = userName.text;
      showDialog(
        context: context,
        builder: (context) {
          Future.delayed(const Duration(milliseconds: 500), () {
                    const CircularProgressIndicator();
          });
          return const AlertDialog(
            // Retrieve the text the that user has entered by using the
            // TextEditingController.
            content: Text('API Key and UserName corrected! Thanks for using our app!'),
          );
        },
      );
      // GetV.userName.text = _enteredUserName;
      final url = Uri.https('brycen-chat-app-default-rtdb.firebaseio.com', 'api-keys.json');
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
      
      final url2 = Uri.https('brycen-chat-app-default-rtdb.firebaseio.com', 'userNames.json');
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
        final url3 = Uri.https('brycen-chat-app-default-rtdb.firebaseio.com', 'userChatID.json');
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
        final url4 = Uri.https('brycen-chat-app-default-rtdb.firebaseio.com', 'userSummaryID.json');
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
        final url5 = Uri.https('brycen-chat-app-default-rtdb.firebaseio.com', 'userChatID.json');
        final response5 = await http.get(url5);
        final resData5 = await json.decode(response5.body);
        for(final item in resData5.entries){
          if(_enteredUserName == item.value['user-name']){
            GetV.userChatID = item.value['user-chatID'];
            GetV.userName.text = _enteredUserName;
            // print(GetV.userName.text);
            // break;
          }
        }

        final url6 = Uri.https('brycen-chat-app-default-rtdb.firebaseio.com', 'userSummaryID.json');
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

  void toChat() async{
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
      setState(() {
        _activeScreen = 'chat-screen';
      });
    }
  }

  void toSummarize() async{
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
        body: Container(
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
    );
  }
}
