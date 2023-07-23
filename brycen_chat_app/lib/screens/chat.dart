import 'package:chatgpt/chat_gpt_file/providers/models_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:chatgpt/chat_gpt_file/constants/constants.dart';
import 'package:chatgpt/chat_gpt_file/providers/chats_provider.dart';
import 'package:chatgpt/chat_gpt_file/screens/chat_screen.dart';

class Chat extends StatefulWidget {
  const Chat({super.key});

  @override
  State<Chat> createState() => _ChatState();
}

class _ChatState extends State<Chat> {
  
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => ModelsProvider(),
        ),
        ChangeNotifierProvider(
          create: (_) => ChatProvider(),
        ),
      ],
      child: MaterialApp(
        title: 'ChatBot',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
            scaffoldBackgroundColor: scaffoldBackgroundColor,
            appBarTheme: AppBarTheme(
              color: cardColor,
            )),
        home: const ChatScreen(),
      ),
    );
  }
}
