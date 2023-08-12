import 'package:flutter/material.dart';
import 'package:chatgpt/screens/home.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:auto_size_text/auto_size_text.dart';
class Menu extends StatefulWidget {
  const Menu({super.key, required this.toRefresh});
  final void Function() toRefresh;
  @override
  _MenuState createState() => _MenuState();
}

class _MenuState extends State<Menu> {
  late ScrollController _listScrollController;
  // int _selectedIndex = 0;
  @override
  void initState() {
    _listScrollController = ScrollController();
    super.initState();
  }

  @override
  void dispose() {
    _listScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: Colors.white,
      child: ListView(
        padding: const EdgeInsets.all(17),
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                onPressed: () async{
                  final upURL = Uri.https('--YOUR HTTPS LINK TO THE REALTIME DATABASE--', 'chatNum.json');
                  final res = await http.get(upURL);
                  final Map<String,dynamic> dat = json.decode(res.body);
                  int maxNum = 1;
                  for(final item in dat.entries){
                    if(GetV.userName.text == item.value['user-name']){
                      if(maxNum < item.value['chat-num']){
                        maxNum = item.value['chat-num'];
                      }
                    }
                    
                  }
                  final resd = await FirebaseFirestore.instance.collection(GetV.userName.text).doc(GetV.userChatID).collection('Message')
                    .doc(GetV.messageChatID).get();
                  if(resd['text'] == ''){
                    await FirebaseFirestore.instance.collection(GetV.userName.text).doc(GetV.userChatID).collection('Message')
                    .doc(GetV.messageChatID).delete();
                    
                  }
                
                  setState(() {
                    GetV.title = '';
                    GetV.chatNum = maxNum+1;
                    GetV.menuPressed = true;
                  });
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
                  final url2 = Uri.https('--YOUR HTTPS LINK TO THE REALTIME DATABASE--', 'chatNum.json');
                  final response2 = await http.get(url2);
                  final Map<String,dynamic> resData2 = json.decode(response2.body);
                  for(final item in resData2.entries){
                    if(GetV.userName.text == item.value['user-name']){
                      item.value['chat-num'] = GetV.chatNum;
                    }
                  }
                  
                  final url = Uri.https('--YOUR HTTPS LINK TO THE REALTIME DATABASE--', 'chatItemNumber.json');
                  final response = await http.get(url);
                  final Map<String,dynamic> resData = json.decode(response.body);
                  for(final item in resData.entries){
                    if(GetV.userName.text == item.value['user-name']){
                      item.value['chat-ItemNumber'] = GetV.chatNum;
                    }
                  }
                  widget.toRefresh();
                  // Navigator.pop(context);
                  
                },
                icon: const Icon(Icons.add, color: Colors.black),
              ),
              const SizedBox(width: 5),
              TextButton(
                child: const Text('New Chat', style: TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 18,
                  color: Colors.black,
                )),
                onPressed: () async{
                  final upURL = Uri.https('--YOUR HTTPS LINK TO THE REALTIME DATABASE--', 'chatNum.json');
                  final res = await http.get(upURL);
                  final Map<String,dynamic> dat = json.decode(res.body);
                  int maxNum = 1;
                  for(final item in dat.entries){
                    if(GetV.userName.text == item.value['user-name']){
                      if(maxNum < item.value['chat-num']){
                        maxNum = item.value['chat-num'];
                      }
                    }
                    
                  }
                  final resd = await FirebaseFirestore.instance.collection(GetV.userName.text).doc(GetV.userChatID).collection('Message')
                    .doc(GetV.messageChatID).get();
                    if(resd['text'] == ''){
                      await FirebaseFirestore.instance.collection(GetV.userName.text).doc(GetV.userChatID).collection('Message')
                      .doc(GetV.messageChatID).delete();
                      
                    }
                  setState(() {
                    GetV.title = '';
                    GetV.chatNum = maxNum+1;
                    GetV.menuPressed = true;
                  });
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
                  final url2 = Uri.https('--YOUR HTTPS LINK TO THE REALTIME DATABASE--', 'chatNum.json');
                  final response2 = await http.get(url2);
                  final Map<String,dynamic> resData2 = json.decode(response2.body);
                  for(final item in resData2.entries){
                    if(GetV.userName.text == item.value['user-name']){
                      item.value['chat-num'] = GetV.chatNum;
                    }
                  }
                  
                  final url = Uri.https('--YOUR HTTPS LINK TO THE REALTIME DATABASE--', 'chatItemNumber.json');
                  final response = await http.get(url);
                  final Map<String,dynamic> resData = json.decode(response.body);
                  for(final item in resData.entries){
                    if(GetV.userName.text == item.value['user-name']){
                      item.value['chat-ItemNumber'] = GetV.chatNum;
                    }
                  }
                  widget.toRefresh();
                  // Navigator.pop(context);
                  
                },
              ),
            ],
          ),
          const Divider(
            height: 4,
            thickness: 2,
            indent: 30,
            endIndent: 30,
            color: Colors.black,
          ),
          const SizedBox(height:7),
          StreamBuilder(
            stream: FirebaseFirestore.instance.collection(GetV.userName.text).doc(GetV.userChatID)
            .collection('Message').orderBy('createdAt', descending: false).snapshots(),
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
              return Container(
                width: 100,
                height: 400,
                child: ListView.builder(
                  
                  controller: _listScrollController,
                  itemCount: loadedMessages.length, 
                  itemBuilder: (context, index) {
                    final chatMessage = loadedMessages[index].data();
                    return SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            // mainAxisSize: MainAxisSize.min,
                            children: [
                              Visibility(
                                visible: chatMessage['text'] != '',
                                child: IconButton(
                                  onPressed: () async{ 
                                    final resd = await FirebaseFirestore.instance.collection(GetV.userName.text).doc(GetV.userChatID).collection('Message')
                                      .doc(GetV.messageChatID).get();
                                    if(resd['text'] == ''){
                                      await FirebaseFirestore.instance.collection(GetV.userName.text).doc(GetV.userChatID).collection('Message')
                                      .doc(GetV.messageChatID).delete();
                                      
                                    }             
                                    setState(() {
                                      GetV.chatNum =  chatMessage['Index'];
                                      GetV.messageChatID = chatMessage['messageID'];
                                      GetV.refreshIndicatorKey.currentState?.show();
                                      GetV.menuPressed =true;
                                    });
                                    widget.toRefresh();
                                    // Navigator.pop(context);
                                    
                                  },
                                  icon: const Icon(Icons.message_outlined, color: Colors.black),
                                ),
                              ),
                              const SizedBox(width: 5),
                              Expanded(
                                child: TextButton(
                                  child: AutoSizeText(
                                    chatMessage['text'], 
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.black,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    maxLines: 3,
                                  ),
                                  onPressed: () async{
                                    final resd = await FirebaseFirestore.instance.collection(GetV.userName.text).doc(GetV.userChatID).collection('Message')
                                      .doc(GetV.messageChatID).get();
                                    if(resd['text'] == ''){
                                      await FirebaseFirestore.instance.collection(GetV.userName.text).doc(GetV.userChatID).collection('Message')
                                      .doc(GetV.messageChatID).delete();
                                      
                                    }
                                    setState(() {
                                      // print(chatMessage['messageID']);
                                      GetV.chatNum = chatMessage['Index'];
                                      GetV.messageChatID = chatMessage['messageID'];
                                      GetV.refreshIndicatorKey.currentState?.show();
                                      GetV.menuPressed = true;
                                    });
                                    widget.toRefresh();
                                    // Navigator.pop(context);
                                    
                                  }
                                ),
                              ),
                              Visibility(
                                visible: chatMessage['text'] != '',
                                child: IconButton(
                                  onPressed: () async{
                                    // print(chatMessage['messageID']);
                                    final res = await FirebaseFirestore.instance.collection(GetV.userName.text).doc(GetV.userChatID).collection('Message')
                                      .doc(chatMessage['messageID']).get();
                                    if(GetV.messageChatID != res['messageID']){
                                      String text = res['messageID'];
                                      await FirebaseFirestore.instance.collection(GetV.userName.text).doc(GetV.userChatID).collection('Message')
                                        .doc(text).delete();
                                      widget.toRefresh();
                                      
                                    }
                                    else{
                                      final upURL = Uri.https('--YOUR HTTPS LINK TO THE REALTIME DATABASE--', 'chatNum.json');
                                      final res = await http.get(upURL);
                                      final Map<String,dynamic> dat = json.decode(res.body);
                                      int maxNum = 1;
                                      for(final item in dat.entries){
                                        if(GetV.userName.text == item.value['user-name']){
                                          if(maxNum < item.value['chat-num']){
                                            maxNum = item.value['chat-num'];
                                          }
                                        }
                                        
                                      }
                                      await FirebaseFirestore.instance.collection(GetV.userName.text).doc(GetV.userChatID).collection('Message')
                                        .doc(GetV.messageChatID).delete();
                                      
                                      
                                      setState(() {
                                        GetV.title = '';
                                        GetV.chatNum = maxNum+1;
                                        GetV.menuPressed = true;
                                      });
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
                                      final url2 = Uri.https('--YOUR HTTPS LINK TO THE REALTIME DATABASE--', 'chatNum.json');
                                      final response2 = await http.get(url2);
                                      final Map<String,dynamic> resData2 = json.decode(response2.body);
                                      for(final item in resData2.entries){
                                        if(GetV.userName.text == item.value['user-name']){
                                          item.value['chat-num'] = GetV.chatNum;
                                        }
                                      }
                                      
                                      final url = Uri.https('--YOUR HTTPS LINK TO THE REALTIME DATABASE--', 'chatItemNumber.json');
                                      final response = await http.get(url);
                                      final Map<String,dynamic> resData = json.decode(response.body);
                                      for(final item in resData.entries){
                                        if(GetV.userName.text == item.value['user-name']){
                                          item.value['chat-ItemNumber'] = GetV.chatNum;
                                        }
                                      }
                                      widget.toRefresh();
                                    }
                                  },
                                  icon: const Icon(Icons.delete, color: Colors.black),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                        ],
                      ),
                    );
                  }
                  
                ),
              );
            }
          ),
          const Divider(
            height: 4,
            thickness: 2,
            indent: 30,
            endIndent: 30,
            color: Colors.black,
          ),
          const SizedBox(height: 20),
          Center(
            child: AutoSizeText(
              'Hello ${GetV.userName.text}', 
              style: const TextStyle(
                backgroundColor: Colors.black,
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w500,
                overflow: TextOverflow.ellipsis,
              ),
              maxLines: 2,
            ),
          ),
        ],
      ),
    );
    
  }
}
