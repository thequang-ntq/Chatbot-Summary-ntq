import 'package:flutter/material.dart';
import 'package:langchain/langchain.dart';
import 'package:langchain_openai/langchain_openai.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:chatgpt/screens/home.dart';

const template = '''
---BEGIN Conversation---
Human chat : {humanChat}
AI chat : {aiCHat}
---END Conversation---
Summarize the conversation above in 5 words or fewer.
''';

class MenuTitle with ChangeNotifier {

  Future<void> getTitle() async {
      if(GetV.title == ''){
        final llm = ChatOpenAI(apiKey: GetV.apiKey.text ,temperature: 0);
        final promptTemplate = PromptTemplate.fromTemplate(template);
        final prompt = promptTemplate.format({'humanChat' : GetV.humanChat , 'aiChat' : GetV.aiChat});
        final result = await llm.predict(prompt);
        GetV.title = result;
        await FirebaseFirestore.instance.collection(GetV.userName.text).doc(GetV.userChatID).collection('Message')
        .doc(GetV.messageChatID).update(
          {
            'text' : result,
            'Index' : GetV.summaryNum,
            'createdAt': Timestamp.now(),
          }
        );
      } 
      
    notifyListeners();
  }

}