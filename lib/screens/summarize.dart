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
            scaffoldBackgroundColor: const Color(0xFF343541),
            appBarTheme: const AppBarTheme(
              color: Color(0xFF444654),
            )),
        home: const SummarizeScreen(),
      ),
    );
  }
}
