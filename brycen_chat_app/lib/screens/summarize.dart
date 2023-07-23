// import 'dart:async';
// import 'dart:io';

import 'package:flutter/material.dart';
import 'package:chatgpt/widgets/tabs.dart';
import 'package:file_picker/file_picker.dart';
import 'package:open_file/open_file.dart';
// import 'package:path_provider/path_provider.dart';

class SummarizeScreen extends StatefulWidget {
  const SummarizeScreen({super.key});

  @override
  State<SummarizeScreen> createState() => _SummarizeScreenState();
}

class _SummarizeScreenState extends State<SummarizeScreen> {
  final _askText = TextEditingController();
  var fileName = '';

  final _summarizeText = TextEditingController();
  bool _hasFiled = false;
  bool _hasSummarized = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _askText.dispose();
    super.dispose();
  }

  void openFile(PlatformFile file) {
    OpenFile.open(file.path!);
  }

  void _uploadFile() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.any);
    if (result == null) {
      return;
    } else {
      var file = result.files.single;
      openFile(file);
      fileName = file.name;
      setState(() {
        _hasFiled = true;
      });
    }
  }

  void _summarizeFile() {
    if (fileName.isNotEmpty) {
      setState(() {
        _hasSummarized = true;
      });
      _summarizeText.text =
          'This is an example of a summarize text. This century is the century of science!';
    } else {
      return;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text('Summarize...'),
          centerTitle: false,
          actions: [
            IconButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const Tabs()),
                );
              },
              icon: Icon(
                Icons.exit_to_app,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ],
        ),
        body: Padding(
          padding: const EdgeInsets.all(25),
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                const SizedBox(
                  height: 8,
                ),
                const Text(
                  'Upload a file to summarize',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                    fontSize: 24,
                  ),
                ),
                const SizedBox(
                  height: 3,
                ),
                Container(
                  constraints: const BoxConstraints(
                    maxWidth: 300,
                  ),
                  padding: const EdgeInsets.all(32),
                  alignment: Alignment.center,
                  child: ElevatedButton(
                    child: const Text('Pick File'),
                    onPressed: _uploadFile,
                  ),
                ),
                const SizedBox(
                  height: 0,
                ),
                Visibility(
                  visible: _hasFiled,
                  child: Column(
                    children: [
                      Text(fileName),
                      const SizedBox(
                        height: 5,
                      ),
                      ElevatedButton(
                        child: const Text('Summarize'),
                        onPressed: _summarizeFile,
                      ),
                      Visibility(
                        visible: _hasSummarized,
                        child: Column(
                          children: <Widget>[
                            const Text(
                              'Text after summarize:',
                              style: TextStyle(
                                fontSize: 20,
                                color: Colors.black,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(20.0),
                              child: TextField(
                                controller: _summarizeText,
                                obscureText: false,
                                decoration: const InputDecoration(
                                  border: OutlineInputBorder(),
                                ),
                              ),
                            ),
                            const SizedBox(
                              height: 20,
                            ),
                            const Text(
                              'Ask any question about the summarize text above:',
                              style: TextStyle(
                                fontSize: 20,
                                color: Colors.black,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.only(
                                  left: 15, right: 1, bottom: 14),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: TextField(
                                      controller: _askText,
                                      textCapitalization:
                                          TextCapitalization.sentences,
                                      autocorrect: true,
                                      enableSuggestions: true,
                                      decoration: const InputDecoration(
                                          labelText: 'Send a message...'),
                                    ),
                                  ),
                                  IconButton(
                                    color:
                                        Theme.of(context).colorScheme.primary,
                                    icon: const Icon(
                                      Icons.send,
                                    ),
                                    onPressed: () {},
                                  ),
                                ],
                              ),
                            )
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ));
  }
}
