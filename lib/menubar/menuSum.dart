import 'package:flutter/material.dart';
import 'package:chatgpt/screens/home.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:auto_size_text/auto_size_text.dart';
class MenuSum extends StatefulWidget {
  const MenuSum({super.key, required this.toRefresh});
  final void Function() toRefresh;
  @override
  _MenuSumState createState() => _MenuSumState();
}

class _MenuSumState extends State<MenuSum> {
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
                  final upURL = Uri.https('--YOUR HTTPS LINK TO THE REALTIME DATABASE--', 'summaryNum.json');
                  final res = await http.get(upURL);
                  final Map<String,dynamic> dat = json.decode(res.body);
                  int maxNum = 1;
                  for(final item in dat.entries){
                    if(maxNum < item.value['summary-num']){
                      maxNum = item.value['summary-num'];
                    }
                  }

                  final resd = await FirebaseFirestore.instance.collection(GetV.userName.text).doc(GetV.userSummaryID).collection('Summarize')
                    .doc(GetV.messageSummaryID).get();
                  if(resd['text'] == ''){
                    await FirebaseFirestore.instance.collection(GetV.userName.text).doc(GetV.userSummaryID).collection('Summarize')
                    .doc(GetV.messageSummaryID).delete();
                    
                  }
                  setState(() {
                    GetV.title = '';
                    GetV.summaryNum = maxNum + 1;
                    GetV.menuSumPressed = true;
                  });

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

                  final url2 = Uri.https('--YOUR HTTPS LINK TO THE REALTIME DATABASE--', 'summaryNum.json');
                  final response2 = await http.get(url2);
                  final Map<String,dynamic> resData2 = json.decode(response2.body);
                  for(final item in resData2.entries){
                    if(GetV.userName.text == item.value['user-name']){
                      item.value['summary-num'] = GetV.summaryNum;
                    }
                  }
                  
                  final url = Uri.https('--YOUR HTTPS LINK TO THE REALTIME DATABASE--', 'summaryItemNumber.json');
                  final response = await http.get(url);
                  final Map<String,dynamic> resData = json.decode(response.body);
                  for(final item in resData.entries){
                    if(GetV.userName.text == item.value['user-name']){
                      item.value['summary-ItemNumber'] = GetV.summaryNum;
                    }
                  }
                  widget.toRefresh();
                  // Navigator.pop(context);
                },
                icon: const Icon(Icons.add, color: Colors.black),
              ),
              const SizedBox(width: 5),
              TextButton(
                child: const Text('New Summary', style: TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 18,
                  color: Colors.black,
                )),
                onPressed: () async{
                  final upURL = Uri.https('--YOUR HTTPS LINK TO THE REALTIME DATABASE--', 'summaryNum.json');
                  final res = await http.get(upURL);
                  final Map<String,dynamic> dat = json.decode(res.body);
                  int maxNum = 1;
                  for(final item in dat.entries){
                    if(maxNum < item.value['summary-num']){
                      maxNum = item.value['summary-num'];
                    }
                  }

                  final resd = await FirebaseFirestore.instance.collection(GetV.userName.text).doc(GetV.userSummaryID).collection('Summarize')
                    .doc(GetV.messageSummaryID).get();
                  if(resd['text'] == ''){
                    await FirebaseFirestore.instance.collection(GetV.userName.text).doc(GetV.userSummaryID).collection('Summarize')
                    .doc(GetV.messageSummaryID).delete();
                    
                  }
                  setState(() {
                    GetV.title = '';
                    GetV.summaryNum = maxNum + 1;
                    GetV.menuSumPressed = true;
                  });

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

                  final url2 = Uri.https('--YOUR HTTPS LINK TO THE REALTIME DATABASE--', 'summaryNum.json');
                  final response2 = await http.get(url2);
                  final Map<String,dynamic> resData2 = json.decode(response2.body);
                  for(final item in resData2.entries){
                    if(GetV.userName.text == item.value['user-name']){
                      item.value['summary-num'] = GetV.summaryNum;
                    }
                  }
                  
                  final url = Uri.https('--YOUR HTTPS LINK TO THE REALTIME DATABASE--', 'summaryItemNumber.json');
                  final response = await http.get(url);
                  final Map<String,dynamic> resData = json.decode(response.body);
                  for(final item in resData.entries){
                    if(GetV.userName.text == item.value['user-name']){
                      item.value['summary-ItemNumber'] = GetV.summaryNum;
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
            stream: FirebaseFirestore.instance.collection(GetV.userName.text).doc(GetV.userSummaryID)
            .collection('Summarize').orderBy('createdAt', descending: false).snapshots(),
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
                                    final resd = await FirebaseFirestore.instance.collection(GetV.userName.text).doc(GetV.userSummaryID).collection('Summarize')
                                      .doc(GetV.messageSummaryID).get();
                                    if(resd['text'] == ''){
                                      await FirebaseFirestore.instance.collection(GetV.userName.text).doc(GetV.userSummaryID).collection('Summarize')
                                      .doc(GetV.messageSummaryID).delete();
                                      
                                    }              
                                    setState(() {
                                      GetV.summaryNum =  chatMessage['Index'];
                                      GetV.messageSummaryID = chatMessage['messageID'];
                                      GetV.menuSumPressed =true;
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
                                    final resd = await FirebaseFirestore.instance.collection(GetV.userName.text).doc(GetV.userSummaryID).collection('Summarize')
                                      .doc(GetV.messageSummaryID).get();
                                    if(resd['text'] == ''){
                                      await FirebaseFirestore.instance.collection(GetV.userName.text).doc(GetV.userSummaryID).collection('Summarize')
                                      .doc(GetV.messageSummaryID).delete();
                                      
                                    }   
                                    setState(() {
                                      GetV.summaryNum = chatMessage['Index'];
                                      GetV.messageSummaryID = chatMessage['messageID'];
                                      GetV.menuSumPressed = true;
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
                                    final res = await FirebaseFirestore.instance.collection(GetV.userName.text).doc(GetV.userSummaryID).collection('Summarize')
                                      .doc(chatMessage['messageID']).get();
                                    if(GetV.messageSummaryID != res['messageID']){
                                      String text = res['messageID'];
                                      await FirebaseFirestore.instance.collection(GetV.userName.text).doc(GetV.userSummaryID).collection('Summarize')
                                        .doc(text).delete();
                                      widget.toRefresh();
                                      
                                    }
                                    else{
                                      final upURL = Uri.https('--YOUR HTTPS LINK TO THE REALTIME DATABASE--', 'summaryNum.json');
                                      final res = await http.get(upURL);
                                      final Map<String,dynamic> dat = json.decode(res.body);
                                      int maxNum = 1;
                                      for(final item in dat.entries){
                                        if(maxNum < item.value['summary-num']){
                                          maxNum = item.value['summary-num'];
                                        }
                                      }
                              
                                      await FirebaseFirestore.instance.collection(GetV.userName.text).doc(GetV.userSummaryID).collection('Summarize')
                                        .doc(GetV.messageSummaryID).delete();
                                      
                                      setState(() {
                                        GetV.title = '';
                                        GetV.summaryNum = maxNum + 1;
                                        GetV.menuSumPressed = true;
                                      });
                              
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
                              
                                      final url2 = Uri.https('--YOUR HTTPS LINK TO THE REALTIME DATABASE--', 'summaryNum.json');
                                      final response2 = await http.get(url2);
                                      final Map<String,dynamic> resData2 = json.decode(response2.body);
                                      for(final item in resData2.entries){
                                        if(GetV.userName.text == item.value['user-name']){
                                          item.value['summary-num'] = GetV.summaryNum;
                                        }
                                      }
                                      
                                      final url = Uri.https('--YOUR HTTPS LINK TO THE REALTIME DATABASE--', 'summaryItemNumber.json');
                                      final response = await http.get(url);
                                      final Map<String,dynamic> resData = json.decode(response.body);
                                      for(final item in resData.entries){
                                        if(GetV.userName.text == item.value['user-name']){
                                          item.value['summary-ItemNumber'] = GetV.summaryNum;
                                        }
                                      }
                                      widget.toRefresh();
                                      // Navigator.pop(context);
                                    
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
