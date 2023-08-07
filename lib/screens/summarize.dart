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
        title: 'Summarize',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
            scaffoldBackgroundColor: Colors.grey[300],
            appBarTheme: AppBarTheme(
              color: Colors.grey[50],
            )),
        home: const SummarizeScreen(),
      ),
    );
  }
}
