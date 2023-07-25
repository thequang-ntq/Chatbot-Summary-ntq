import 'package:flutter/cupertino.dart';

import 'package:chatgpt/screens/home.dart';
import 'package:langchain/langchain.dart';
import 'package:langchain_openai/langchain_openai.dart';
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
      var conversation = ConversationChain(llm: llm, memory: memo);
      final result = await conversation.call(msg, returnOnlyOutputs: true);
      memo.saveContext(inputValues: {result['response'] : 'msg' }, outputValues: {'msg': result['response']});
      await memo.loadMemoryVariables();
      chatList.add(result['response']);
      conversation = ConversationChain(llm: llm, memory: memo);
    notifyListeners();
  }
}