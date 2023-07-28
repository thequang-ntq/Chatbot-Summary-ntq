import 'package:flutter/cupertino.dart';

import 'package:chatgpt/screens/home.dart';
import 'package:dart_openai/dart_openai.dart';
// import 'package:langchain/langchain.dart';
// import 'package:langchain_openai/langchain_openai.dart';
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
      // final llm = OpenAI(apiKey: GetV.apiKey.text, temperature: 0);
      // ConversationBufferMemory memo = ConversationBufferMemory();
      // final chatData = await FirebaseFirestore.instance.collection('Chat').get();
      // for(final item in chatData.docs){
      //   await memo.saveContext(inputValues: {'humanChat' : item.data()['humanChat'] }, outputValues: {'aiChat': item.data()['aiChat']});
      // }
      // var conversation = ConversationChain(llm: llm, memory: memo);
      // final result = await conversation.call(msg, returnOnlyOutputs: true);
      // chatList.add(result['response']);
      OpenAI.apiKey = GetV.apiKey.text;
      OpenAIChatCompletionModel chatCompletion =
        await OpenAI.instance.chat.create(
          model: "gpt-3.5-turbo",
          messages: [
            OpenAIChatCompletionChoiceMessageModel(
              content: msg,
              role: OpenAIChatMessageRole.user,
            ),
          ],
        );
      final result = chatCompletion.choices[0].message.content;
      chatList.add(result);
      await FirebaseFirestore.instance.collection('Chat').add({
        'humanChat' :  msg,
        'aiChat' : result, 
      });
    notifyListeners();
  }

  Future<void> sendMessageAndGetAnswersSummarize(
      {required String msg}) async {
      // final llm = OpenAI(apiKey: GetV.apiKey.text, temperature: 0);
      // ConversationBufferMemory memo = ConversationBufferMemory();
      // final chatData = await FirebaseFirestore.instance.collection('SummarizeChat').get();
      // for(final item in chatData.docs){
      //   await memo.saveContext(inputValues: {'humanChat' : item.data()['humanChat'] }, outputValues: {'aiChat': item.data()['aiChat']});
      // }
      // var conversation = ConversationChain(llm: llm, memory: memo);
      // final result = await conversation.call(msg, returnOnlyOutputs: true);
      // chatList.add(result['response']);
      OpenAI.apiKey = GetV.apiKey.text;
      OpenAIChatCompletionModel chatCompletion =
        await OpenAI.instance.chat.create(
          model: "gpt-3.5-turbo",
          messages: [
            OpenAIChatCompletionChoiceMessageModel(
              content: msg,
              role: OpenAIChatMessageRole.user,
            ),
          ],
        );
      final result = chatCompletion.choices[0].message.content;
      chatList.add(result);
      await FirebaseFirestore.instance.collection('SummarizeChat').add({
        'humanChat' :  msg,
        'aiChat' : result, 
      });
    notifyListeners();
  }

  Future<void> saveDocsSummarize(
      {required String msg}) async {
      // final llm = OpenAI(apiKey: GetV.apiKey.text, temperature: 0);
      // final promptTemplate = PromptTemplate.fromTemplate(
      //   'Summarize the following text: {subject}',
      // );
      // final prompt = promptTemplate.format({'subject': msg});
      // final result = await llm.call(prompt);
      String text = 'Summarize the following text: $msg';
      OpenAI.apiKey = GetV.apiKey.text;
      OpenAIChatCompletionModel chatCompletion =
        await OpenAI.instance.chat.create(
          model: "gpt-3.5-turbo",
          messages: [
            OpenAIChatCompletionChoiceMessageModel(
              content: text,
              role: OpenAIChatMessageRole.user,
            ),
          ],
        );
      final result = chatCompletion.choices[0].message.content;
      
      await FirebaseFirestore.instance.collection('SummarizeDocs').add({
        'humanChat' :  msg,
        'aiChat' : result, 
      });
      
    notifyListeners();
  }
}