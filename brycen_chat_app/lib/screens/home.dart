import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
// import 'package:firebase_auth/firebase_auth.dart';

// final _firebase = FirebaseAuth.instance;


class GetV{
  static late TextEditingController apiKey;
  static bool isAPI = false;
}

class HomeScreen extends StatefulWidget {
  const HomeScreen(
      {required this.apiKeyValue,
      required this.toSubmit,
      required this.toChat,
      required this.toSummarize,
      super.key});

  final TextEditingController apiKeyValue;
  final void Function(TextEditingController apiKeyValue) toSubmit;
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
  void initState(){
    super.initState();
  }

   Future<void> checkApiKey(String apiKey) async {
    final response = await http.get(
      Uri.parse("https://api.openai.com/v1/models"),
      headers: {"Authorization": "Bearer $apiKey"},
    );
    if (response.statusCode == 200) {
      setState((){
        GetV.isAPI = true;
      });
      
    } else {
       setState((){
        GetV.isAPI = false;
      });
      
    }
  }
  void getValue() async{
    final url = Uri.https('brycen-chat-app-default-rtdb.firebaseio.com', 'apikey.json');
    final response = await http.post(url);
    final Map<String, dynamic> resData = json.decode(response.body);
    if(resData.isNotEmpty){
      setState(() {
        widget.apiKeyValue.text = resData['api-key'];
        GetV.apiKey = resData['api-key'];
      });
    }
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
                child: GetV.isAPI ?
                TextField(
                  obscureText: true,
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.key),
                    suffixIcon: Icon(Icons.check, color: Colors.green,),
                    enabledBorder: OutlineInputBorder(borderSide: BorderSide(width: 8, color: Colors.green)),   
                  ),
                  autofocus: false,
                  autocorrect: false,
                  controller: TextEditingController(text: GetV.apiKey.text),
                )
                :
                TextField(
                  obscureText: true,
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.key),
                    border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(25))),
                    hintText: 'Enter your Api Key',   
                  ),
                  autofocus: false,
                  autocorrect: false,
                  controller: widget.apiKeyValue,
                )
                  
              ),
              const SizedBox(
                height: 12,
              ),
              Center(
                child: Row(
                  children: [
                    const SizedBox(width: 32,),
                    TextButton(
                      onPressed: getValue,
                          style: TextButton.styleFrom(
                            backgroundColor: Colors.pink[100],
                        ),
                        child: const Text('Previous key', style: TextStyle(fontSize: 30)),
                    ),
                    const SizedBox(width: 14,),
                    TextButton(
                      onPressed: ()  async{
                        await checkApiKey(widget.apiKeyValue.text); 
                        const CircularProgressIndicator();
                        widget.toSubmit(widget.apiKeyValue);
                        
                        setState((){
                          GetV.apiKey = widget.apiKeyValue;
                          
                        });
                      },
                          style: TextButton.styleFrom(
                            backgroundColor: Colors.pink[100],
                        ),
                        child: const Text('Submit', style: TextStyle(fontSize: 30)),
                    ),
                  ],
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
                  left: 34,
                ),
                child: Center(
                  child: Row(
                    children: [
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue[100],
                          textStyle: const TextStyle(
                            fontSize: 33,
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
                            fontSize: 33,
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
                  )
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
