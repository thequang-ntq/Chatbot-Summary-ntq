# chatbot-summary

THIS IS AN APP FOR BRYCEN COMPANY DURING INTERNSHIP TO CHAT AND SUMMARY WITH AI ASSISTANTS by NTQ

## HOW TO USE 
1. Download this code from Github. (.Zip files)
2. Extract the files.
3. Open VS Code, run 'flutter pub get' or simply just open 'pubspec.yaml' and 'Ctrl + S' to run.
4. Create a Firebase app and add databases related to what this app use. Remember to change the link databases in this code to your databases!
5. Set Rules of Realtime Database to 'true' all instead of 'false'. Set Rules of Firebase Firestore to 'true' instead of 'false'.
6. Get a ChatGPT API-KEY . You can log in to 'https://platform.openai.com/account/api-keys' to get one or simply just borrow ones.
7. Use that key to log into 'http://api.openai.com/v1/models' with username blanks (not insert anything) and password is your API-KEY.
8. In VS Code, Run -> Run without debugging.

## Getting Started

-The purpose of the app (project):
    + Home-Screen of the app, which have a submit API Key TextField, an Chat Button to swicth to Chat-Screen (Chat with AI) and Summary Button to switch to Summary-Screen (Summarize Text File, Audio File... and ask Question about it.)
-This app is for a small project and this is my first project SO It is not good and Have many places that not completed too. I am sorry for that. 

## UPDATE:
- 21/07/2023: First upload about the app. First code is about the UI of Home-Screen of the app, which have a submit API Key TextField, an Chat Button to swicth to Chat-Screen (Chat with AI) and Summary Button to switch to Summary-Screen (Summarize Text File, Audio File... and ask Question about it.). But I just have code about the UI of Home and Chat Screen, so it is not completed and just the beginning of project.
- 22/07/2023: I'm  update the project app. I fixed the chat screen and add code to the summarize screen. But I have two problems: First is in the chat screen, because I run on Flutter IDE online so it can not read the ".env" file_path, so the app can not run. Second is: in summary app, I am using the 'Visibility' Widget but the Widget is not appear even after I set visisble to setState((){_variable}).
- 23/07/2023: Fixed Chat Screen and add the first AI chatbot to chat with human in that Chat Screen. This chatbot not have memory yet.
- 24/07/2023: Fixed check condition for api_key at the home screen. Fixed chat screen and do the save API KEY when first submiited at home screen but not done yet. Fixed chat screen the second time: human chat to the left, AIBot chat to the right, but AIBot not have memory yet.
- 25/07/2023: Complete fixed the api key submit in home screen, not save to firebase yet(http error). Fixed chat app in chat screen(use langchain instead), but not have memory yet. Change depedencies, add micro icon to get speech to text from user (but not done yet).
- 26/07/2023: Complete add memory for chatbot while chat with human in chat screen, using firebase firestore. 