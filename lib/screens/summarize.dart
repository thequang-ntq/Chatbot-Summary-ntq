import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:chatgpt/providers/chats/chats_provider.dart';
import 'package:chatgpt/screens/summarize_screen.dart';

class Summarize extends StatefulWidget {
  const Summarize({super.key});

  @override
  State<Summarize> createState() => _SummarizeState();
}

class _SummarizeState extends State<Summarize> {
  
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        
        ChangeNotifierProvider(
          create: (_) => ChatProvider(),
        ),
      ],
      child: MaterialApp(
        title: 'ChatBot',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
            scaffoldBackgroundColor: const Color.fromARGB(255, 201, 103, 160),
            appBarTheme: const AppBarTheme(
              color:  Color.fromARGB(255, 216, 144, 184),
            )),
        home: const SummarizeScreen(),
      ),
    );
  }
}
