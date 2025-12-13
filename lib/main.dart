import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:chatgpt/screens/tabs.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:chatgpt/theme/app_theme.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

// Chỉ import connection_notifier khi không phải web
import 'package:connection_notifier/connection_notifier.dart' 
    if (dart.library.html) 'dart:html';

Future<void> main() async {
  await dotenv.load(fileName: ".env");
  WidgetsFlutterBinding.ensureInitialized();
  
  // Khởi tạo Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  // Chỉ khởi tạo connection notifier khi không phải web
  if (!kIsWeb) {
    await ConnectionNotifierTools.initialize();
  }
  
  runApp(const App());
}

class App extends StatelessWidget {
  const App({super.key});
  
  @override
  Widget build(BuildContext context) {
    // Wrap với ConnectionNotifier chỉ khi không phải web
    if (kIsWeb) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Brycen Chat App',
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.light,
        home: const Tabs(),
        builder: (context, child) {
          return ScrollConfiguration(
            behavior: CustomScrollBehavior(),
            child: child ?? const SizedBox(),
          );
        },
      );
    } else {
      return ConnectionNotifier(
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Brycen Chat App',
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: ThemeMode.light,
          home: const Tabs(),
          builder: (context, child) {
            return ScrollConfiguration(
              behavior: CustomScrollBehavior(),
              child: child ?? const SizedBox(),
            );
          },
        ),
      );
    }
  }
}

// Custom scroll behavior for better web support
class CustomScrollBehavior extends ScrollBehavior {
  @override
  Widget buildOverscrollIndicator(
    BuildContext context,
    Widget child,
    ScrollableDetails details,
  ) {
    return child;
  }

  @override
  ScrollPhysics getScrollPhysics(BuildContext context) {
    return const BouncingScrollPhysics();
  }
}