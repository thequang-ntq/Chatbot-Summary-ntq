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


## Table of Contents

- [Features](#features)
- [User Interface](#user-interface)
- [Screenshots](#screenshots)
- [Prerequisites](#i-prerequisites)
- [Setup](#ii-setup)
- [Run App](#iii-run-app)
- [Error](#error)
- [Time-tracking](#time-tracking)
- [Future Work](#future-work)

## Features

* Advanced AI-chatbot and summarize text / audio file
* Chat with AI: Chat with AI ChatBot, enable voice and message chat, copy and speak text.
* Summarize: Extract key / main information from a **.txt, .docx, or audio (.mp3, .wav, .mp4, .m4a)** file, and ask anything about that. 

## USER INTERFACE

https://github.com/thequang-ntq/Chatbot-Summary-ntq/assets/115056697/292b905a-49ed-47b9-88f6-77e05af03e1d

## Screenshots

| Home                          |        ............         | Chat                          |
|------------------------------------------|-----------------------------------|------------------------------------------|
| ![Home UI](screenshots/home.gif) | ......................... | ![Chat UI](screenshots/chat.gif) | 

| Summarize                       |
|-----------------------------------------------|
| ![Summarize UI](screenshots/summary.gif) |


# HOW TO RUN THIS APP 

## I. Prerequisites

- **SYSTEM:** 4GB RAM, At Least 12GB of Free Space in C Drive, And 3.5GB of Free Space in your App Folder.
- **INSTALLED:** [npm](https://nodejs.org/en) (v18.17.0), [Flutter](https://docs.flutter.dev/get-started/install)(version in "pubspec.lock"), [Git](https://git-scm.com/downloads)(v2.41.0)
[VSCode](https://code.visualstudio.com/)(v1.81.1)
- **You must have Wifi / Internet Access to run this app**

## II. Setup
### 1. Clone this github repository app

- Open a folder in your computer that you want to add this app.
- Open git (in step 2), then type:

```bash
git clone https://github.com/thequang-ntq/Chatbot-Summary-ntq.git
```
- Open your project terminal, then type:
```bash
flutter pub get
```
### 2. Setup flutterfire
- You can follow my **6 STEP** right below and also this link: 
```bash
https://firebase.google.com/docs/flutter/setup?hl=vi&platform=web
```
- **1, create your firebase project :**
![CreateProject](assets/files/createProject.gif)

- **2, setup FlutterFire CLI:**
![Cli](assets/files/cli.gif)

- **3, check if FlutterFire was installed:**
![check](assets/files/check.gif)

- **4, Activate flutterfire cli:**
![activate](assets/files/activate.gif)
- Remember if you meet an error like this:
![error](screenshots/error.png)
- You can follow this:
```bash
https://itslinuxfoss.com/export-path-something-path-mean-linux/#:~:text=The%20%E2%80%9Cexport%20PATH%3Dsomething%3A%24PATH%E2%80%9D%20command%20changes%20the,add%20multiple%20directories%20to%20PATH.
```
- or:
![error2](screenshots/error2.png)
- You can follow this link to fix:
```bash
https://stackoverflow.com/questions/70320263/error-the-term-flutterfire-is-not-recognized-as-the-name-of-a-cmdlet-functio
```

- After this a file call ```firebase_option.dart``` will be create in your folder. If not, you should repeat this step 4 again.

- **5, Create Realtime Database and Firestore Database**
![database](assets/files/database.gif)
- **6, Configure your flutterfire.**

- You can follow this video:
![configure](assets/files/configure.gif)
 

- Or you can read this:
    + Type this:
    ```
    flutterfire configure 
    ```
    + (CHOOSE THE FIREBASE PROJECT YOU JUST CREATE ABOVE TO LINK TO THIS APP)
    + (CHOOSE YES TO ALL TO REPLACE MY FIREBASE_OPTIONS.DART FILE WITH YOURS)


### 3. Follow these steps: 
- Follow this video:
![key](assets/files/key.gif)

- Or read this:
    + Get a ChatGPT API-KEY . You can log in to 'https://platform.openai.com/account/api-keys' to get one or simply just borrow ones.
    + Use that key to log into 'http://api.openai.com/v1/models' with username blanks (not insert anything) and password is your API-KEY.

### 4. Fill in the code
- In the lib folder contains the code of this app, you must update (change) my comments that has in **4 specific files: menu.dart, menu_sum.dart, home.dart, tabs.dart in that lib folder**, for example: 
```bash
'--YOUR HTTPS LINK TO THE REALTIME DATABASE WITHOUT "https://"--'
```
![update](screenshots/update.png)
- (and more places that the same with this image)

- with your https link **WITHOUT "https://" IN THE BEGINNING OF THE LINK**:
![name](screenshots/name.png)

## III. Run App

- This app can run on Web(recommended Chrome latest version) and Android( with **version 10 or later**).
- **To run this app on Web, just open your project terminal in your code editor (mine is VS Code) and type:**
```bash
flutter run lib/main.dart
```
- **To run this app on Android, you must have an .apk file of this app. To have that, follow this video:**
- **BECAUSE AFTER YOU FILL IN THE CODE WITH YOUR HTTPS LINKS, THE CODE CHANGED, SO YOU MUST BUILD YOUR APK FILE YOURSELF. I AM SO SORRY FOR THIS INCONVENIENCE STEPS.** :disappointed_relieved:
![apk](assets/files/apk.gif)
- After that, locale the 'app-release.apk' file in your project folder follow the video (or you can see in the image below):
![images](screenshots/apk.png)

- **Or if you want to use the .apk file version using my Firebase, just click the link below:**

- [Download .APK File](https://github.com/22T1020362/Chatbot-Summary-ntq/raw/master/outputs/apk/release/app-release.apk)

<details>
<summary>Download APK file on a connected Android device</summary>
<br>
Connect your Android device to your computer with a USB cable, then run the command line.

```bash
  flutter install
```

**Or if you have an Android mobile phone, just download the APK file above.**

</details>


## Error
<details>
   
<summary>Command not found: flutterfire</summary>

https://bobbyhadz.com/blog/flutterfire-is-not-recognized-as-internal-or-external-command

   - In your terminal and run this code to open <b>Advanced system settings</b>
   
   ```
      SystemPropertiesAdvanced
   ```
   - Click Environment Variables. In the section System Variables find the PATH environment variable and select it. Click Edit. If the PATH environment variable does not exist, click New.
   
   - In the Edit System Variable (or New System Variable) window, specify the value of the PATH environment variable
   ```
   C:\Users\YourUsername\AppData\Local\Pub\Cache\bin
   ```
   - Click OK. Close all remaining windows by clicking OK.
   - You might have to restart your computer to active path
</details>


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
| 15-19/08/2023     | Add comment, Fixed UI, write readme file     | Fixed submit, widget UI  |

##### Future Work
- [ ] Update app structure, optimize and clean code.
- [ ] User Config model: Let user decide the model they want
- [ ] Migrate database: from FireStore(firebase) to [SQLite](https://pub.dev/packages/sqflite)
- [ ] UI : Design the UI better, cleaner
- [ ] Adjust Speech recognition: Show [glowing animation](https://pub.dev/packages/avatar_glow) of the sentence listening
