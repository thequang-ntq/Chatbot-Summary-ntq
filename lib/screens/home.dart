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
  bool _isObscured = true;

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

  void _togglePasswordVisibility() {
    setState(() {
      _isObscured = !_isObscured;
    });
  }


  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
        title: const Text('Chat GPT App'),
        centerTitle: false,
        backgroundColor: Colors.grey[50],
      ),
      backgroundColor: Colors.grey[400],
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Brycen Chat App',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                  fontSize: 35,
                ),
              ),
              const SizedBox(
                height: 18,
              ),
              Image.asset(
                'assets/images/brycen.png',
                height: 200,
                width: 200,
              ),
              const SizedBox(height: 17),
              Padding(
                padding: const EdgeInsets.all(12),
                child: GetV.isAPI ?
                TextField(
                  obscureText: true,
                  decoration: InputDecoration(
                    prefixIcon: IconButton(
                      icon: const Icon(Icons.key),
                      onPressed: () async {
                        final url = Uri.https('brycen-chat-app-default-rtdb.firebaseio.com', 'api-keys.json');
                        final response = await http.get(url);
                        final Map<String,dynamic> resData = json.decode(response.body);
                        for(final item in resData.entries){
                          GetV.apiKey.text = (item.value['api-key']);
                          widget.apiKeyValue.text = (item.value['api-key']);
                        }
                        setState(() {
                          GetV.isAPI = false;
                        });
                      }
                    ),
                    suffixIcon: const Icon(Icons.check, color: Colors.green,),
                    enabledBorder: const OutlineInputBorder(borderSide: BorderSide(width: 8, color: Colors.green)),   
                  ),
                  autofocus: false,
                  autocorrect: false,
                  controller: TextEditingController(text: GetV.apiKey.text),
                )
                :
                TextField(
                  obscureText: true,
                  decoration: InputDecoration(
                    prefixIcon: IconButton(
                      icon: const Icon(Icons.key),
                      onPressed: () async {
                        final url = Uri.https('brycen-chat-app-default-rtdb.firebaseio.com', 'api-keys.json');
                        final response = await http.get(url);
                        final Map<String, dynamic> resData = json.decode(response.body);
                        for(final item in resData.entries){
                          widget.apiKeyValue.text = (item.value['api-key']);
                        }
                        
                        // print(resData.entries);
                      },
                    ),
                    suffixIcon: IconButton(
                      onPressed: _togglePasswordVisibility,
                      icon: Icon(
                        _isObscured ? Icons.visibility : Icons.visibility_off,
                      ),
                    ),
                    border: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(25))),
                    hintText: 'Enter your Api Key',   
                  ),
                  autofocus: false,
                  autocorrect: false,
                  controller:  widget.apiKeyValue,               
                )
                  
              ),
              const SizedBox(
                height: 12,
              ),
              Center(
                child: TextButton(
                  onPressed: ()  async{
                    await checkApiKey(widget.apiKeyValue.text); 
                    const CircularProgressIndicator();
                    widget.toSubmit(widget.apiKeyValue);
                    
                    setState((){
                      GetV.apiKey = widget.apiKeyValue;
                      
                    });
                  },
                      style: TextButton.styleFrom(
                        backgroundColor: Colors.green[300],
                    ),
                    child: const Text('Submit', style: TextStyle(fontSize: 29, color: Colors.black)),
                ),                                
              ),
              const SizedBox(height: 19),
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        ElevatedButton(
                          onPressed: widget.toChat,
                          style: ButtonStyle(
                            fixedSize: MaterialStateProperty.all(
                              const Size(180, 50),
                            ),
                            backgroundColor: 
                              MaterialStateProperty.resolveWith<Color>(
                                (Set<MaterialState> states) {
                                  if (states.contains(MaterialState.pressed)) {
                                    return Colors.green; 
                                  }
                                  return Colors.orange; 
                              },
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              Image.asset(
                                'assets/images/chatbot.png',
                                height: 28,
                                width: 30,
                              ),
                              const SizedBox(width: 18),
                              const Text(
                                'Chatbot',
                                style: TextStyle(fontSize: 18),
                              ),
                            ],
                          ),
                        ),

                        ElevatedButton(
                          onPressed: widget.toSummarize,
                          style: ButtonStyle(
                            fixedSize: MaterialStateProperty.all(
                              const Size(180, 50),
                            ),
                            backgroundColor: 
                              MaterialStateProperty.resolveWith<Color>(
                                (Set<MaterialState> states) {
                                  if (states.contains(MaterialState.pressed)) {
                                    return Colors.green; 
                                  }
                                  return Colors.orange; 
                              },
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              Image.asset(
                                'assets/images/Docs.png',
                                height: 28,
                                width: 30,
                              ),
                              const SizedBox(width: 18),
                              const Text(
                                'Summarize',
                                style: TextStyle(fontSize: 18),
                              ),
                            ],
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
