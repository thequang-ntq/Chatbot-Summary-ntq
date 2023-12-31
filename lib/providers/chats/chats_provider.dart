//This is the provider of AI ChatBot for chat and summarize, so its very important.
//This file contains the code for the response of the chatbot for both chat and summarize.

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:chatgpt/screens/home.dart';
import 'package:langchain/langchain.dart';
import 'package:langchain_openai/langchain_openai.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:collection/collection.dart';
const template = '''
---BEGIN Conversation---
Human chat : {humanChat}
AI chat : {aiChat}
---END Conversation---
Detect language, Summarize the conversation above in 5 words or fewer.
''';

const template2 = '''
Detect language, Answer this question: {question}, according to this text: {text}. Detect language, If the text does not contains information
about that question, just say you don't have information about it.
''';

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

  //Chat response function
  Future<void> sendMessageAndGetAnswers(
      {required String msg}) async {
      final llm = ChatOpenAI(apiKey: GetV.apiKey.text, model: 'gpt-3.5-turbo-0613' ,temperature: 0);
      ConversationBufferMemory memo = ConversationBufferMemory();
      final chatData = await FirebaseFirestore.instance.collection(GetV.userName.text).doc
        (GetV.userChatID).collection('Message').doc(GetV.messageChatID).collection('ChatItem${GetV.chatNum}').get();
      for(final item in chatData.docs){
        await memo.saveContext(inputValues: {'humanChat' : item.data()['text'] }, outputValues: {'aiChat': item.data()['text']});
      }
      var conversation = ConversationChain(llm: llm, memory: memo);
      final result = await conversation.call(msg, returnOnlyOutputs: true);
      chatList.add(result['response']);
      await FirebaseFirestore.instance.collection(GetV.userName.text).doc(GetV.userChatID).collection('Message').doc(GetV.messageChatID).collection('ChatItem${GetV.chatNum}').add({
        'text' : msg,
        'index' : 0,
        'createdAt': Timestamp.now(),
      });
      await FirebaseFirestore.instance.collection(GetV.userName.text).doc(GetV.userChatID).collection('Message').doc(GetV.messageChatID).collection('ChatItem${GetV.chatNum}').add({
        'text' : result['response'],
        'index' : 1,
        'createdAt': Timestamp.now(),
      });
      if(GetV.title == ''){
        GetV.humanChat = msg;
        GetV.aiChat = result['response'];
        final promptTemplate = PromptTemplate.fromTemplate(template);
        final prompt = promptTemplate.format({'humanChat' : GetV.humanChat , 'aiChat' : GetV.aiChat});
        final result2 = await llm.predict(prompt);
        GetV.title = result2;
        await FirebaseFirestore.instance.collection(GetV.userName.text).doc(GetV.userChatID).collection('Message')
        .doc(GetV.messageChatID).update(
          {
            'text' : result2,
            'Index' : GetV.chatNum,
            'messageID': GetV.messageChatID,
          }
        );
      }
      else{
        GetV.humanChat = '';
        GetV.aiChat = '';
      }
    notifyListeners();
  }

  //Summarize response function
  Future<void> sendMessageAndGetAnswersSummarize(
      {required String msg}) async {
      final llm = ChatOpenAI(apiKey: GetV.apiKey.text, model: 'gpt-3.5-turbo-0613' , temperature: 0);
      if(GetV.filetype == "txt"){
        TextLoader loader = TextLoader(GetV.filepath);
        final documents = await loader.load();
        const textSplitter = CharacterTextSplitter(
          chunkSize: 1200,
          chunkOverlap: 0,
        );
        final texts = textSplitter.splitDocuments(documents);
        final textsWithSources = texts
            .mapIndexed(
              (final i, final d) => d.copyWith(
                metadata: {
                  ...d.metadata,
                  'source': '$i-pl',
                },
              ),
            )
            .toList(growable: false);
        final embeddings = OpenAIEmbeddings(apiKey: GetV.apiKey.text);
        final docSearch = await MemoryVectorStore.fromDocuments(
          documents: textsWithSources,
          embeddings: embeddings,
        );
        final qaChain = OpenAIQAWithSourcesChain(llm: llm);
        final docPrompt = PromptTemplate.fromTemplate(
          'Please use the content from the txt file below to answer my question.\ncontent: {page_content}\nSource: {source}',
        );
        final finalQAChain = StuffDocumentsChain(
          llmChain: qaChain,
          documentPrompt: docPrompt,
        );
        final retrievalQA = RetrievalQAChain(
          retriever: docSearch.asRetriever(),
          combineDocumentsChain: finalQAChain,
        );
        final result = await retrievalQA(msg);
        await FirebaseFirestore.instance.collection(GetV.userName.text).doc(GetV.userSummaryID)
        .collection('Summarize').doc(GetV.messageSummaryID).collection('SummaryItem${GetV.summaryNum}').add({
          'text' : msg,
          'index' : 0,
          'createdAt': Timestamp.now(),
        });
        await FirebaseFirestore.instance.collection(GetV.userName.text).doc(GetV.userSummaryID).collection('Summarize')
        .doc(GetV.messageSummaryID).collection('SummaryItem${GetV.summaryNum}').add({
          'text' : result['result'].toString(),
          'index' : 1,
          'createdAt': Timestamp.now(),
        });
      }
      else{
        final llm = ChatOpenAI(apiKey: GetV.apiKey.text, model: 'gpt-3.5-turbo-0613' ,temperature: 0);
        ConversationBufferMemory memo = ConversationBufferMemory();
        final promptTemplate2 = PromptTemplate.fromTemplate(
        template2,
        );
        final prompt2 = promptTemplate2.format({'question': msg, 'text': GetV.text});
        final summaryData = await FirebaseFirestore.instance.collection(GetV.userName.text).doc
          (GetV.userSummaryID).collection('Summarize').doc(GetV.messageSummaryID).collection('SummaryItem${GetV.summaryNum}').get();
        for(final item in summaryData.docs){
          await memo.saveContext(inputValues: {'humanChat' : item.data()['text'] }, outputValues: {'aiChat': item.data()['text']});
        }
        var conversation = ConversationChain(llm: llm, memory: memo);
        final result = await conversation.call(prompt2, returnOnlyOutputs: true);
        await FirebaseFirestore.instance.collection(GetV.userName.text).doc(GetV.userSummaryID)
        .collection('Summarize').doc(GetV.messageSummaryID).collection('SummaryItem${GetV.summaryNum}').add({
          'text' : msg,
          'index' : 0,
          'createdAt': Timestamp.now(),
        });
        await FirebaseFirestore.instance.collection(GetV.userName.text).doc(GetV.userSummaryID).collection('Summarize')
        .doc(GetV.messageSummaryID).collection('SummaryItem${GetV.summaryNum}').add({
          'text' : result['response'],
          'index' : 1,
          'createdAt': Timestamp.now(),
        });
      }
    notifyListeners();
  }
}