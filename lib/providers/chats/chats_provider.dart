import 'dart:io';

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
  
  String get getVoiceMes {
    return _voiceMessage;
  }
  
  void addUserMessage({required String msg}) {
    chatList.add(msg);
    notifyListeners();
  }

  // Chat response function - Updated & Fixed, Add Image
  Future<void> sendMessageAndGetAnswers({
    required String msg,
    String? imageUrl, // THÊM PARAMETER NÀY
  }) async {
    try {
      final llm = ChatOpenAI(
        apiKey: GetV.apiKey.text,
        defaultOptions: const ChatOpenAIOptions(
          model: 'gpt-4o-mini', // hoặc 'gpt-4-vision-preview' nếu cần analyze ảnh
          temperature: 0,
        ),
      );
      
      // Build conversation history
      final chatData = await FirebaseFirestore.instance
          .collection(GetV.userName.text)
          .doc(GetV.userChatID)
          .collection('Message')
          .doc(GetV.messageChatID)
          .collection('ChatItem${GetV.chatNum}')
          .orderBy('createdAt')
          .get();
      
      // Create chat messages from history
      final messages = <ChatMessage>[];
      for (final item in chatData.docs) {
        final data = item.data();
        if (data['index'] == 0) {
          messages.add(ChatMessage.humanText(data['text']));
        } else {
          messages.add(ChatMessage.ai(data['text']));
        }
      }
      
      // Add current message
      messages.add(ChatMessage.humanText(msg));
      
      // Get response
      final response = await llm.invoke(
        PromptValue.chat(messages),
      );
      
      final aiResponse = response.outputAsString;
      chatList.add(aiResponse);
      
      // Save to Firestore - THÊM imageUrl
      await FirebaseFirestore.instance
          .collection(GetV.userName.text)
          .doc(GetV.userChatID)
          .collection('Message')
          .doc(GetV.messageChatID)
          .collection('ChatItem${GetV.chatNum}')
          .add({
        'text': msg,
        'index': 0,
        'createdAt': Timestamp.now(),
        'imageUrl': imageUrl ?? '', // THÊM DÒNG NÀY
      });
      
      await FirebaseFirestore.instance
          .collection(GetV.userName.text)
          .doc(GetV.userChatID)
          .collection('Message')
          .doc(GetV.messageChatID)
          .collection('ChatItem${GetV.chatNum}')
          .add({
        'text': aiResponse,
        'index': 1,
        'createdAt': Timestamp.now(),
        'imageUrl': '', // AI không có ảnh
      });
      
      // Generate title if first message
      if (GetV.title == '') {
        final titlePrompt = template
            .replaceAll('{humanChat}', msg)
            .replaceAll('{aiChat}', aiResponse);
        
        final titleResponse = await llm.invoke(
          PromptValue.string(titlePrompt),
        );
        
        GetV.title = titleResponse.outputAsString;
        
        await FirebaseFirestore.instance
            .collection(GetV.userName.text)
            .doc(GetV.userChatID)
            .collection('Message')
            .doc(GetV.messageChatID)
            .update({
          'text': GetV.title,
          'Index': GetV.chatNum,
          'messageID': GetV.messageChatID,
        });
      } else {
        GetV.humanChat = '';
        GetV.aiChat = '';
      }
      
      notifyListeners();
    } catch (e) {
      debugPrint('Error in sendMessageAndGetAnswers: $e');
      rethrow;
    }
  }

  // Summarize response function - Updated & Fixed
  Future<void> sendMessageAndGetAnswersSummarize({required String msg}) async {
    try {
      final llm = ChatOpenAI(
        apiKey: GetV.apiKey.text,
        defaultOptions: const ChatOpenAIOptions(
          model: 'gpt-4o-mini',
          temperature: 0,
        ),
      );
      
      if (GetV.filetype == "txt") {
        // For TXT files - use RAG approach
        // Load file manually
        final file = File(GetV.filepath);
        final content = await file.readAsString();
        final documents = [
          Document(pageContent: content, metadata: {'source': GetV.filepath}),
        ];
        
        const textSplitter = CharacterTextSplitter(
          chunkSize: 1200,
          chunkOverlap: 0,
        );
        final texts = textSplitter.splitDocuments(documents);
        
        final textsWithSources = texts.mapIndexed(
          (i, d) => d.copyWith(
            metadata: {
              ...d.metadata,
              'source': '$i-pl',
            },
          ),
        ).toList(growable: false);
        
        final embeddings = OpenAIEmbeddings(apiKey: GetV.apiKey.text);
        final docSearch = await MemoryVectorStore.fromDocuments(
          documents: textsWithSources,
          embeddings: embeddings,
        );
        
        // Create QA chain
        final retriever = docSearch.asRetriever();
        final retrievedDocs = await retriever.invoke(msg);
        
        // Build context from retrieved documents
        final context = retrievedDocs
            .map((doc) => doc.pageContent)
            .join('\n\n');
        
        // Create prompt with context
        final prompt = '''
Context information:
$context

Question: $msg

Please answer the question based on the context above. If you cannot find the answer in the context, say so.
''';
        
        final response = await llm.invoke(PromptValue.string(prompt));
        final result = response.outputAsString;
        
        // Save to Firestore
        await FirebaseFirestore.instance
            .collection(GetV.userName.text)
            .doc(GetV.userSummaryID)
            .collection('Summarize')
            .doc(GetV.messageSummaryID)
            .collection('SummaryItem${GetV.summaryNum}')
            .add({
          'text': msg,
          'index': 0,
          'createdAt': Timestamp.now(),
        });
        
        await FirebaseFirestore.instance
            .collection(GetV.userName.text)
            .doc(GetV.userSummaryID)
            .collection('Summarize')
            .doc(GetV.messageSummaryID)
            .collection('SummaryItem${GetV.summaryNum}')
            .add({
          'text': result,
          'index': 1,
          'createdAt': Timestamp.now(),
        });
      } else {
        // For other file types - use conversation with context
        final summaryData = await FirebaseFirestore.instance
            .collection(GetV.userName.text)
            .doc(GetV.userSummaryID)
            .collection('Summarize')
            .doc(GetV.messageSummaryID)
            .collection('SummaryItem${GetV.summaryNum}')
            .orderBy('createdAt')
            .get();
        
        // Build conversation history
        final messages = <ChatMessage>[];
        for (final item in summaryData.docs) {
          final data = item.data();
          if (data['index'] == 0) {
            messages.add(ChatMessage.humanText(data['text']));
          } else {
            messages.add(ChatMessage.ai(data['text']));
          }
        }
        
        // Add context and question
        final promptText = template2
            .replaceAll('{question}', msg)
            .replaceAll('{text}', GetV.text);
        
        messages.add(ChatMessage.humanText(promptText));
        
        final response = await llm.invoke(PromptValue.chat(messages));
        final result = response.outputAsString;
        
        // Save to Firestore
        await FirebaseFirestore.instance
            .collection(GetV.userName.text)
            .doc(GetV.userSummaryID)
            .collection('Summarize')
            .doc(GetV.messageSummaryID)
            .collection('SummaryItem${GetV.summaryNum}')
            .add({
          'text': msg,
          'index': 0,
          'createdAt': Timestamp.now(),
        });
        
        await FirebaseFirestore.instance
            .collection(GetV.userName.text)
            .doc(GetV.userSummaryID)
            .collection('Summarize')
            .doc(GetV.messageSummaryID)
            .collection('SummaryItem${GetV.summaryNum}')
            .add({
          'text': result,
          'index': 1,
          'createdAt': Timestamp.now(),
        });
      }
      
      notifyListeners();
    } catch (e) {
      debugPrint('Error in sendMessageAndGetAnswersSummarize: $e');
      rethrow;
    }
  }
}