import 'package:flutter/material.dart';
import 'package:chatgpt/screens/tabs.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'dart:io';
import 'package:connection_notifier/connection_notifier.dart';

void main() async{
  //check internet connection
  await ConnectionNotifierTools.initialize();
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const App());
}

class App extends StatelessWidget {
  const App({super.key});
  @override
  Widget build(BuildContext context) {
    return ConnectionNotifier(
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Chat GPT App',
        theme: ThemeData().copyWith(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
              seedColor: const Color.fromARGB(255, 63, 17, 177)),
        ),
        home: const Tabs(),
      ),
    );
  }
}
