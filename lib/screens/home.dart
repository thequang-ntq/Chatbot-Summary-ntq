import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
// import 'package:shared_preferences/shared_preferences.dart';
// import 'package:firebase_auth/firebase_auth.dart';

// final _firebase = FirebaseAuth.instance;


class GetV{
  static TextEditingController apiKey = TextEditingController();
  static bool isAPI = false;
  static TextEditingController userName = TextEditingController();
  static String userChatID = '';
  static String userSummaryID = '';
  static String summaryText = '';
  static String messageChatID = '';
  static String messageSummaryID = '';
  static late int chatNum;
  static late int summaryNum;
  static late String filepath;
  static String title = '';
  static String humanChat = '';
  static String aiChat = '';
  static bool menuPressed = false;
  static bool menuSumPressed = false;
  static GlobalKey<RefreshIndicatorState> refreshIndicatorKey =
    GlobalKey<RefreshIndicatorState>();
}

class HomeScreen extends StatefulWidget {
  const HomeScreen(
      {required this.apiKeyValue,
      required this.toSubmit,
      required this.toChat,
      required this.toSummarize,
      required this.name,
      super.key});

  final TextEditingController apiKeyValue;
  final TextEditingController name;
  final void Function(TextEditingController apiKeyValue, TextEditingController username) toSubmit;
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
    // widget.apiKeyValue.dispose();
    // widget.name.dispose();
    super.dispose();
  }

  

  Future<void> _api() async{
    // final prefsName = await SharedPreferences.getInstance();
    final url = Uri.https('brycen-chat-app-default-rtdb.firebaseio.com', 'api-keys.json');
    final response = await http.get(url);
    final Map<String, dynamic> resData = json.decode(response.body);
    late var value;
    for(final item in resData.entries){
      value = (item.value['api-key']);
    }
    setState(() {
      widget.apiKeyValue.text = value;
    });
  }

  Future<void> _name() async{
    // final prefsName = await SharedPreferences.getInstance();
    final url = Uri.https('brycen-chat-app-default-rtdb.firebaseio.com', 'userNames.json');
    final response = await http.get(url);
    final Map<String, dynamic> resData = json.decode(response.body);
    late var value;
    for(final item in resData.entries){
      value = (item.value['user-name']);
    }
    setState(() {
      widget.name.text = value;
    });
  }

  @override
  void initState(){
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _name();
      await _api();
    });
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
        title: const Text('Home Screen', style: TextStyle(color: Colors.black, fontWeight: FontWeight.w600)),
        centerTitle: false,
        backgroundColor: Colors.grey[50],
      ),
      backgroundColor: Colors.grey[300],
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
                  fontSize: 32,
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
                Column(
                  children: [
                    TextField(
                      obscureText: false,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Colors.white,
                        prefixIcon: IconButton(
                          onPressed: () async {
                            final url2 = Uri.https('brycen-chat-app-default-rtdb.firebaseio.com', 'userNames.json');
                            final response = await http.get(url2);
                            final Map<String,dynamic> resData = json.decode(response.body);
                            for(final item in resData.entries){
                              GetV.userName.text = (item.value['user-name']);
                              widget.name.text = (item.value['user-name']);
                            }
                            setState(() {
                              GetV.isAPI = false;
                            });
                          },
                          icon: const Icon(Icons.person),
                        ),
                        suffixIcon: Icon(Icons.check, color: Colors.green,),
                        enabledBorder: OutlineInputBorder(borderSide: BorderSide(width: 8, color: Colors.green)),   
                      ),
                      autofocus: false,
                      autocorrect: false,
                      controller: TextEditingController(
                        text: GetV.userName.text.isNotEmpty? 
                        GetV.userName.text
                        : widget.name.text,
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      obscureText: true,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Colors.white,
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
                      controller: TextEditingController(
                        text: GetV.apiKey.text.isNotEmpty?
                        GetV.apiKey.text : widget.apiKeyValue.text
                      ),
                    ),
                  ],
                )
                :
                Column(
                  children: [
                    TextField(
                      obscureText: false,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Colors.white,
                        prefixIcon: IconButton(
                          onPressed: () async {
                            final url2 = Uri.https('brycen-chat-app-default-rtdb.firebaseio.com', 'userNames.json');
                            final response = await http.get(url2);
                            final Map<String,dynamic> resData = json.decode(response.body);
                            for(final item in resData.entries){
                              widget.name.text = (item.value['user-name']);
                            }
                            setState(() {
                              GetV.isAPI = false;
                            });
                          },
                          icon: const Icon(Icons.person),
                        ),
                        border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(25))),
                        hintText: 'Enter your UserName',   
                      ),
                      autofocus: false,
                      autocorrect: false,
                      controller:  widget.name,

                    ),
                    const SizedBox(height: 10),
                    TextField(
                      obscureText: _isObscured,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Colors.white,
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
                    ),
                  ],
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
                    widget.toSubmit(widget.apiKeyValue, widget.name);
                    
                    setState((){
                      GetV.apiKey = widget.apiKeyValue;
                      GetV.userName = widget.name;
                      
                    });
                  },
                    style: ButtonStyle(
                      fixedSize: MaterialStateProperty.all(
                        const Size(111, 41),
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
                    child: const Text('Submit', style: TextStyle(fontSize: 25, color: Colors.black)),
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
                              const Size(160, 40),
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
                                style: TextStyle(fontSize: 17),
                              ),
                            ],
                          ),
                        ),

                        ElevatedButton(
                          onPressed: widget.toSummarize,
                          style: ButtonStyle(
                            fixedSize: MaterialStateProperty.all(
                              const Size(160, 40),
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
