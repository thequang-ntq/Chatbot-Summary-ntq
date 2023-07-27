# chatbot-summary - ntq

<div style="display: flex;">
  <div style="flex: 1;">
    <a href="https://www.facebook.com/quang.nguyenthe.710">
      <img src="assets/images/myface.png" width="35%" height="35%">
    </a>
  </div>
  
  <div style="flex: 2;">
    <p>THIS IS AN APP FOR BRYCEN COMPANY DURING INTERNSHIP TO CHAT AND SUMMARY WITH AI ASSISTANTS by NTQ
</p>
  </div>
</div>

## Features

* Advanced AI-chatbot and summarize text / audio file
* My first projects -_-

## Screenshots

| Screenshot 1                                 | Screenshot 2                                 | Screenshot 3                                 |
|----------------------------------------------|----------------------------------------------|----------------------------------------------|
| ![Home UI](screenshots/screenshot1.png) | ![Chat UI](screenshots/screenshot2.png) | ![Customize API](screenshots/screenshot3.png) |

## Getting Started

-The purpose of the app (project):
    + Home-Screen of the app, which have a submit API Key TextField, an Chat Button to swicth to Chat-Screen (Chat with AI) and Summary Button to switch to Summary-Screen (Summarize Text File, Audio File... and ask Question about it.)
-This app is for a small project and this is my first project SO It is not good and Have many places that not completed too. I am sorry for that. 

## HOW TO USE 

You can download the APK file from the releases section of this repository or build the app from source using the
instructions below:

```bash
git clone https://github.com/22T1020362/Chatbot-Summary-ntq
cd chatgpt
flutter build apk
```

# After that, follow these steps: 

1. Get a ChatGPT API-KEY . You can log in to 'https://platform.openai.com/account/api-keys' to get one or simply just borrow ones.
2. Use that key to log into 'http://api.openai.com/v1/models' with username blanks (not insert anything) and password is your API-KEY.
3. Use this app.

## Usage
To use this app, you must enter a GPT Api-key created before or borrowed, submit it by button 'submit' for first time. After that, you can press the key button on the begin of textfield to take that key again. After submit, press 'Chat' to have chat with ChatBot, or press 'Summarize' to Summmarize a text or audio file, and ask question about it.

## UPDATE:
- 21/07/2023: First upload about the app. First code is about the UI of Home-Screen of the app, which have a submit API Key TextField, an Chat Button to swicth to Chat-Screen (Chat with AI) and Summary Button to switch to Summary-Screen (Summarize Text File, Audio File... and ask Question about it.). But I just have code about the UI of Home and Chat Screen, so it is not completed and just the beginning of project.
- 22/07/2023: I'm  update the project app. I fixed the chat screen and add code to the summarize screen. But I have two problems: First is in the chat screen, because I run on Flutter IDE online so it can not read the ".env" file_path, so the app can not run. Second is: in summary app, I am using the 'Visibility' Widget but the Widget is not appear even after I set visisble to setState((){_variable}).
- 23/07/2023: Fixed Chat Screen and add the first AI chatbot to chat with human in that Chat Screen. This chatbot not have memory yet.
- 24/07/2023: Fixed check condition for api_key at the home screen. Fixed chat screen and do the save API KEY when first submiited at home screen but not done yet. Fixed chat screen the second time: human chat to the left, AIBot chat to the right, but AIBot not have memory yet.
- 25/07/2023: Complete fixed the api key submit in home screen, not save to firebase yet(http error). Fixed chat app in chat screen(use langchain instead), but not have memory yet. Change depedencies, add micro icon to get speech to text from user (but not done yet).
- 26/07/2023: Complete add memory for chatbot while chat with human in chat screen, using firebase firestore. Change Android SDK minVersion, fixed the UI for micro in chat app.