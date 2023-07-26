import 'package:flutter/cupertino.dart';

import 'package:chatgpt/screens/home.dart';
import 'package:langchain/langchain.dart';
import 'package:langchain_openai/langchain_openai.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:chatgpt/models/chats/chat_model.dart';
// import '../../services/chats/api_service.dart';

class ChatProvider with ChangeNotifier {
  List<String> chatList = [];
  final String _voiceMessage = '';
  List<String> get getChatList {
    return chatList;
  }
  String get getVoiceMes{
    return _voiceMessage;
  }
  void addUserMessage({required String msg}) {
    chatList.add(msg);
    notifyListeners();
  }

  Future<void> sendMessageAndGetAnswers(
      {required String msg}) async {
      final llm = OpenAI(apiKey: GetV.apiKey.text, temperature: 0);
      ConversationBufferMemory memo = ConversationBufferMemory();
      final chatData = await FirebaseFirestore.instance.collection('Chat').get();
      for(final item in chatData.docs){
        await memo.saveContext(inputValues: {'humanChat' : item.data()['humanChat'] }, outputValues: {'aiChat': item.data()['aiChat']});
      }
      var conversation = ConversationChain(llm: llm, memory: memo);
      final result = await conversation.call(msg, returnOnlyOutputs: true);
      chatList.add(result['response']);
      await FirebaseFirestore.instance.collection('Chat').add({
        'humanChat' :  msg,
        'aiChat' : result['response'], 
      });
    notifyListeners();
  }
}