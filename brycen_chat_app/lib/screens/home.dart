import 'package:flutter/material.dart';
// import 'package:firebase_auth/firebase_auth.dart';

// final _firebase = FirebaseAuth.instance;
class getV{
  static late var apiKey;
}

class HomeScreen extends StatefulWidget {
  const HomeScreen(
      {required this.apiKeyValue,
      required this.toSubmit,
      required this.toChat,
      required this.toSummarize,
      super.key});

  final TextEditingController apiKeyValue;
  final void Function(TextEditingController _apiKeyValue) toSubmit;
  final void Function() toChat;
  final void Function() toSummarize;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void dispose() {
    // Clean up the controller when the widget is disposed.
    widget.apiKeyValue.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chat GPT App'),
        centerTitle: false,
        backgroundColor: Colors.blueAccent,
      ),
      backgroundColor: Colors.white,
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'API-KEY',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                  fontSize: 30,
                ),
              ),
              const SizedBox(
                height: 18,
              ),
              Padding(
                padding: const EdgeInsets.only(left: 22, right: 22),
                child: TextField(
                  obscureText: true,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    hintText: 'Enter your Api Key',
                  ),
                  controller: widget.apiKeyValue,
                ),
              ),
              const SizedBox(
                height: 12,
              ),
              TextButton(
                onPressed: () {
                  widget.toSubmit(widget.apiKeyValue);
                  setState(() {
                    getV.apiKey = widget.apiKeyValue;
                  });
                },
                child: const Text('Submit', style: TextStyle(fontSize: 25)),
                style: TextButton.styleFrom(
                  backgroundColor: Colors.pink[100],
                ),
              ),
              Container(
                margin: const EdgeInsets.only(
                  top: 20,
                  bottom: 20,
                  left: 20,
                  right: 20,
                ),
                width: 200,
                child: Image.asset('assets/images/brycen.png'),
              ),
              const SizedBox(height: 7),
              Padding(
                padding: const EdgeInsets.only(
                  left: 32,
                ),
                child: Row(
                  children: [
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue[100],
                        textStyle: const TextStyle(
                          fontSize: 30,
                          color: Colors.black,
                        ),
                      ),
                      onPressed: widget.toChat,
                      child: const Text(
                        'Chat',
                        style: TextStyle(
                          color: Colors.black,
                        ),
                      ),
                    ),
                    const SizedBox(width: 35),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue[100],
                        textStyle: const TextStyle(
                          fontSize: 30,
                          color: Colors.black,
                        ),
                      ),
                      onPressed: widget.toSummarize,
                      child: const Text(
                        'Summary',
                        style: TextStyle(
                          color: Colors.black,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
