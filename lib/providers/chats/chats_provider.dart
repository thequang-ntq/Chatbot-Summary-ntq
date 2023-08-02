import 'dart:html';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:chatgpt/screens/home.dart';
// import 'package:dart_openai/dart_openai.dart';
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
      final llm = ChatOpenAI(apiKey: GetV.apiKey.text,temperature: 0);
      ConversationBufferMemory memo = ConversationBufferMemory();
      final chatData = await FirebaseFirestore.instance.collection(GetV.userName.text).doc
        (GetV.userChatID).collection('Message').get();
      for(final item in chatData.docs){
        await memo.saveContext(inputValues: {'humanChat' : item.data()['text'] }, outputValues: {'aiChat': item.data()['text']});
      }
      var conversation = ConversationChain(llm: llm, memory: memo);
      final result = await conversation.call(msg, returnOnlyOutputs: true);
      chatList.add(result['response']);
      await FirebaseFirestore.instance.collection(GetV.userName.text).doc(GetV.userChatID).collection('Message').add({
        'text' : msg,
        'index' : 0,
        'createdAt': Timestamp.now(),
      });
      await FirebaseFirestore.instance.collection(GetV.userName.text).doc(GetV.userChatID).collection('Message').add({
        'text' : result['response'],
        'index' : 1,
        'createdAt': Timestamp.now(),
      });
    notifyListeners();
  }

  Future<void> sendMessageAndGetAnswersSummarize(
      {required String msg}) async {
      final llm = ChatOpenAI(apiKey: GetV.apiKey.text, temperature: 0);
      ConversationBufferMemory memo = ConversationBufferMemory();
      final summaryData = await FirebaseFirestore.instance.collection(GetV.userName.text).doc
        (GetV.userSummaryID).collection('Summarize').get();
      for(final item in summaryData.docs){
        await memo.saveContext(inputValues: {'humanChat' : item.data()['text'] }, outputValues: {'aiChat': item.data()['text']});
      }
      var conversation = ConversationChain(llm: llm, memory: memo);
      final result = await conversation.call(msg, returnOnlyOutputs: true);
      chatList.add(result['response']);
      await FirebaseFirestore.instance.collection(GetV.userName.text).doc(GetV.userSummaryID).collection('Summarize').add({
        'text' : msg,
        'index' : 0,
        'createdAt': Timestamp.now(),
      });
      await FirebaseFirestore.instance.collection(GetV.userName.text).doc(GetV.userSummaryID).collection('Summarize').add({
        'text' : result['response'],
        'index' : 1,
        'createdAt': Timestamp.now(),
      });
    notifyListeners();
  }

  Future<void> saveDocsSummarize(
      {required String msg}) async {
      final llm = ChatOpenAI(apiKey: GetV.apiKey.text, temperature: 0);
      final promptTemplate = PromptTemplate.fromTemplate(
        'Summarize the following text: {subject}',
      );
      final prompt = promptTemplate.format({'subject': msg});
      final result = await llm.predict(prompt);
      await FirebaseFirestore.instance.collection(GetV.userName.text).doc(GetV.userSummaryID).collection('Summarize').add({
        'text' : result,
        'index' : 1,
        'createdAt': Timestamp.now(),
      });
      GetV.summaryText = result;
      
    notifyListeners();
  }
}