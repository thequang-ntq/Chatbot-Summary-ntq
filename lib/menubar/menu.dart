import 'package:flutter/material.dart';
import 'package:sidebarx/sidebarx.dart';
import 'package:chatgpt/screens/home.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
class Menu extends StatefulWidget {
  const Menu({super.key});
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
                child: const Text('New Chat', style: TextStyle(
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
              return Flexible(
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
                                    GetV.chatNum =  chatMessage['index'];
                                  });
                                  Navigator.pop(context);
                                },
                                icon: const Icon(Icons.message_outlined, color: Colors.black),
                              ),
                              const SizedBox(width: 5),
                              TextButton(
                                child: Text(chatMessage['text'], style: const TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.black,
                                ),),
                                onPressed: () {
                                  setState(() {
                                    GetV.chatNum = chatMessage['index'];
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
          Center(
            child: Text('Hello ${GetV.userName.text}', style: const TextStyle(
              backgroundColor: Colors.black,
              color: Colors.white,
              fontSize: 17,
              fontWeight: FontWeight.w500,
            ),),
          ),
        ],
      ),
    );
    
  }
}
