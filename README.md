# chatbot-summary - ntq

<div style="display: flex;">
  <div style="flex: 1;">
    <a href="https://www.facebook.com/quang.nguyenthe.710">
      <img src="assets/images/myface.png" width="27%" height="27%">
    </a>
  </div>
  
  <div style="flex: 2;">
    <p>THIS IS AN APP FOR BRYCEN COMPANY DURING INTERNSHIP TO CHAT AND SUMMARY WITH AI ASSISTANTS by NTQ
</p>
  </div>
</div>

* Advanced AI-chatbot and summarize text / audio file
* My first projects -_-
* Chat with AI: Enjoy dynamic conversations with AI Chatbot, enable voice and message chat.
* Summarize: Extract key information from a .txt, .docx, or audio (.mp3, .wav, .mp4, .m4a) file, and ask anything about that. 

## Screenshots

| Home                                 | Chat                                 | Summarize                                 |
|----------------------------------------------|----------------------------------------------|----------------------------------------------|
| ![Home UI](screenshots/screenshot1.png) | ![Chat UI](screenshots/screenshot2.png) | ![Summarize UI](screenshots/screenshot3.png) |


# HOW TO RUN THIS APP 

## I. Prerequisites

- **SYSTEM:** 4GB RAM, At Least 10GB of Free Space in C Drive, And 2GB of Free Space in your App Folder.
- **INSALLED:** [npm](https://nodejs.org/en) (v18.17.0), [Flutter](https://docs.flutter.dev/get-started/install)(version in "pubspec.lock"), [Git](https://git-scm.com/downloads)(v2.41.0)
[VSCode](https://code.visualstudio.com/)(v1.81.1)

## II. Setup
### 1. Clone this github repository app

- Open a folder in your computer that you want to add this app.
- Open git (in step 2), then type:

```bash
git clone https://github.com/22T1020362/Chatbot-Summary-ntq
```
- Open your project terminal, then type:
```bash
flutter pub get
```
### 2. Setup flutterfire
- You can follow this link: 
```bash
https://firebase.google.com/docs/flutter/setup?hl=vi&platform=web
```
- First, create your firebase project :
![CreateProject](assets/files/createProject.gif)

- Second, setup FlutterFire CLI:
![Cli](assets/files/cli.gif)


After this a file call ```firebase_option.dart``` will be create in your folder. If not, you should repeat this step 4 again.

- Close terminal, open terminal in VS CODE in your project app (step 3). Type this:
```
flutterfire configure 
```
(choose a project on your firebase to link to this app)
(choose yes to all)
```
flutter pub add firebase_core
```
Run this again to make sure everything installed in your computer 
```
flutterfire configure
```
(choose yes to all to replace my firebase_options.dart file with yours)

### 3. Follow these steps: 

- Get a ChatGPT API-KEY . You can log in to 'https://platform.openai.com/account/api-keys' to get one or simply just borrow ones.
- Use that key to log into 'http://api.openai.com/v1/models' with username blanks (not insert anything) and password is your API-KEY.

### 4. Fill in the code
- In the lib folder contains the code of this app, must update (change) my comment, for example: 
```bash
'--YOUR HTTPS LINK TO THE REALTIME DATABASE--'

```
with your https link.

## Time Tracking

| Date         | Task                | Notes                                               |
|--------------|---------------------|-----------------------------------------------------|
| 20/07/2023     | Project setup       |                                                     |
| 21/07/2023 | First Setup     | First upload about the app. |
| 22-23/07/2023 | Create Chat Screen  | Create the Chat Screen, add ChatBot     |
| 24/07/2023     | Update Home Screen and Chat Screen        | Fixed check condition for api_key at the Home Screen. Update Chat Screen and Save Api Key when Submit at Home Screen : Human chat at Left, AI chat at Right.   |
| 25/07/2023 | Firebase Connection And Update App | Set up Firebase_CIL and implemented file upload to Firebase. Chat Screen: use LangChain, not have memory yet. Fixed API Key submit  |
| 26-27/07/2023     | Update Chat Screen       |   Complete add memory for chatbot. Change Android SDK minVersion, fixed the UI for micro in chat app. Complete fixed microphone. Add pick file and summarize text for summarize screen      |
| 28/07/2023     | Update UI for all / Chat Screen and Summarize Screen       |  Completed fixed the UI for all. Fixed language recognition for ChatBot response(response same language for what user ask)  |
| 29/07/2023     | Update Summarize Screen       | Upload pick .txt and .pdf files. Need to find a way to upload audio file? And ask logic?    |
| 31/07/2023     | Fix BackEnd Firebase       | Fixed Firebase BackEnd for Chat App and complete chat screen. Fixed UI for summarize screen  |
| 01-03/08/2023     | Fixed UI for Summarize Screen, Firebase       |     |
| 04/08/2023     | Fixed Summarize  |   Fix QA & summarize  |
| 05-06/08/2023     | Menu Bar      |   Fixing...  |
| 07-09/08/2023     | UI     |  Save apiKey and username when start home screen, add expanded to text   |   
| 10/08/2023     | MenuBar     |  Add Delete Button to Menu   | 
| 11/08/2023     | Firebase     |  Fixed firebase   |
| 12-14/08/2023     | Write readme file     |  |
