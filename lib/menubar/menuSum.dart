import 'dart:js_interop';

import 'package:flutter/material.dart';
import 'package:sidebarx/sidebarx.dart';
import 'package:chatgpt/screens/home.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:chatgpt/screens/home.dart';
import 'package:auto_size_text/auto_size_text.dart';
class MenuSum extends StatefulWidget {
  const MenuSum({super.key});
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
        padding: EdgeInsets.all(14),
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                onPressed: () {
                  Navigator.pop(context);
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
                onPressed: () {
                  Navigator.pop(context);
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
                              IconButton(
                                onPressed: () { 
                    
                                  setState(() {
                                    GetV.summaryNum =  chatMessage['Index'];
                                    GetV.messageSummaryID = chatMessage['messageID'];
                                  });
                                  Navigator.pop(context);
                                },
                                icon: const Icon(Icons.message_outlined, color: Colors.black),
                              ),
                              const SizedBox(width: 5),
                              TextButton(
                                child: AutoSizeText(
                                  chatMessage['text'], 
                                  style: const TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.black,
                                  ),
                                  maxLines: 2,
                                ),
                                onPressed: () {
                                  setState(() {
                                    GetV.summaryNum = chatMessage['Index'];
                                    GetV.messageSummaryID = chatMessage['messageID'];
                                  });
                                }
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
              ),
              maxLines: 2,
            ),
          ),
        ],
      ),
    );
    
  }
}
