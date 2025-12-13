import 'dart:convert';
import 'package:chatgpt/screens/loading.dart';
import 'package:flutter/material.dart';
import 'package:connection_notifier/connection_notifier.dart';
import 'package:chatgpt/screens/internet.dart';
import 'package:http/http.dart' as http;
import 'package:chatgpt/theme/app_theme.dart';

class GetV {
  static TextEditingController apiKey = TextEditingController();
  static bool isAPI = false;
  static TextEditingController userName = TextEditingController();
  static String userChatID = '';
  static String userSummaryID = '';
  static String summaryText = '';
  static String messageChatID = '';
  static String messageSummaryID = '';
  static late String filetype;
  static late int chatNum;
  static late int summaryNum;
  static late String filepath;
  static late String fileurl;
  static String text = '';
  static String title = '';
  static String humanChat = '';
  static String aiChat = '';
  static bool loadingMenuSum = false;
  static bool loadingMenu = false;
  static bool loadingUploadFile = false;
  static bool submited = false;
  static bool chated = false;
  static bool summarized = false;
  static bool hasFiled = false;
  static bool menuPressed = false;
  static bool menuSumPressed = false;
  // File summarize
  static String fileName = '';
  static String fileType = '';
  // Image chat
  static String imageUrl = '';
  static bool isImageMessage = false;
  static GlobalKey<RefreshIndicatorState> refreshIndicatorKey =
      GlobalKey<RefreshIndicatorState>();
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    required this.apiKeyValue,
    required this.toSubmit,
    required this.toChat,
    required this.toSummarize,
    required this.name,
    super.key,
  });

  final TextEditingController apiKeyValue;
  final TextEditingController name;
  final void Function(TextEditingController apiKeyValue, TextEditingController username) toSubmit;
  final void Function() toChat;
  final void Function() toSummarize;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  bool _isObscured = true;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );
    _animationController.forward();
    
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _name();
      await _api();
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _api() async {
    final url = Uri.https('your-project-name-b1e6c-default-rtdb.firebaseio.com', 'api-keys.json');
    final response = await http.get(url);
    final Map<String, dynamic> resData = json.decode(response.body);
    late String value;
    for (final item in resData.entries) {
      value = (item.value['api-key']);
    }
    setState(() {
      widget.apiKeyValue.text = value;
      GetV.apiKey.text = value;
    });
  }

  Future<void> _name() async {
    final url = Uri.https('your-project-name-b1e6c-default-rtdb.firebaseio.com', 'userNames.json');
    final response = await http.get(url);
    final Map<String, dynamic> resData = json.decode(response.body);
    late var value;
    for (final item in resData.entries) {
      value = (item.value['user-name']);
    }
    setState(() {
      widget.name.text = value;
      GetV.userName.text = value;
    });
  }

  Future<bool> checkApiKey(String apiKey) async {
    try {
      final response = await http.get(
        Uri.parse("https://api.openai.com/v1/models"),
        headers: {
          "Authorization": "Bearer $apiKey",
          "Content-Type": "application/json",
        },
      ).timeout(const Duration(seconds: 10));
      
      if (response.statusCode == 200) {
        return true;
      } else {
        debugPrint('API Key validation failed: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      debugPrint('Error checking API key: $e');
      return false;
    }
  }

  void _togglePasswordVisibility() {
    setState(() {
      _isObscured = !_isObscured;
    });
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isWideScreen = size.width > 600;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Brycen Chat App'),
        centerTitle: true,
      ),
      body: ConnectionNotifierToggler(
        onConnectionStatusChanged: (connected) {
          if (connected == null) return;
        },
        disconnected: const InternetErr(),
        connected: Container(
          decoration: const BoxDecoration(
            gradient: AppTheme.backgroundGradient,
          ),
          child: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(
                  horizontal: isWideScreen ? size.width * 0.2 : AppSpacing.lg,
                ),
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildHeader(),
                      SizedBox(height: isWideScreen ? AppSpacing.xxl : AppSpacing.xl),
                      _buildLogo(),
                      SizedBox(height: isWideScreen ? AppSpacing.xxl : AppSpacing.xl),
                      _buildInputFields(isWideScreen),
                      const SizedBox(height: AppSpacing.lg),
                      _buildSubmitButton(),
                      const SizedBox(height: AppSpacing.xl),
                      _buildActionButtons(isWideScreen),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Text(
          'Welcome to',
          style: AppTheme.bodyText1.copyWith(color: Colors.grey[700]),
        ),
        const SizedBox(height: AppSpacing.sm),
        const Text(
          'Brycen Chat App',
          style: AppTheme.heading1,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildLogo() {
    return Hero(
      tag: 'app_logo',
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppRadius.xl),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha:0.1),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Image.asset(
          'assets/images/brycen.png',
          height: 150,
          width: 150,
        ),
      ),
    );
  }

  Widget _buildInputFields(bool isWideScreen) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: AppTheme.getCardDecoration(),
      child: Column(
        children: [
          if (GetV.isAPI) ...[
            _buildVerifiedField(
              controller: TextEditingController(text: GetV.userName.text.isNotEmpty ? GetV.userName.text : widget.name.text),
              icon: Icons.person,
              label: 'Username',
              onClear: () async {
                final url2 = Uri.https('your-project-name-b1e6c-default-rtdb.firebaseio.com', 'userNames.json');
                final response = await http.get(url2);
                final Map<String, dynamic> resData = json.decode(response.body);
                for (final item in resData.entries) {
                  GetV.userName.text = (item.value['user-name']);
                  widget.name.text = (item.value['user-name']);
                }
                setState(() {
                  GetV.isAPI = false;
                });
              },
            ),
            const SizedBox(height: AppSpacing.md),
            _buildVerifiedField(
              controller: TextEditingController(text: GetV.apiKey.text.isNotEmpty ? GetV.apiKey.text : widget.apiKeyValue.text),
              icon: Icons.key,
              label: 'API Key',
              isPassword: true,
              onClear: () async {
                final url = Uri.https('your-project-name-b1e6c-default-rtdb.firebaseio.com', 'api-keys.json');
                final response = await http.get(url);
                final Map<String, dynamic> resData = json.decode(response.body);
                for (final item in resData.entries) {
                  GetV.apiKey.text = (item.value['api-key']);
                  widget.apiKeyValue.text = (item.value['api-key']);
                }
                setState(() {
                  GetV.isAPI = false;
                });
              },
            ),
          ] else ...[
            _buildInputField(
              controller: widget.name,
              icon: Icons.person,
              hintText: 'Enter your Username',
              onReload: () async {
                final url2 = Uri.https('your-project-name-b1e6c-default-rtdb.firebaseio.com', 'userNames.json');
                final response = await http.get(url2);
                final Map<String, dynamic> resData = json.decode(response.body);
                for (final item in resData.entries) {
                  widget.name.text = (item.value['user-name']);
                }
                setState(() {
                  GetV.isAPI = false;
                });
              },
            ),
            const SizedBox(height: AppSpacing.md),
            _buildInputField(
              controller: widget.apiKeyValue,
              icon: Icons.key,
              hintText: 'Enter your API Key',
              isPassword: true,
              onReload: () async {
                final url = Uri.https('your-project-name-b1e6c-default-rtdb.firebaseio.com', 'api-keys.json');
                final response = await http.get(url);
                final Map<String, dynamic> resData = json.decode(response.body);
                for (final item in resData.entries) {
                  widget.apiKeyValue.text = (item.value['api-key']);
                }
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required IconData icon,
    required String hintText,
    bool isPassword = false,
    VoidCallback? onReload,
  }) {
    return TextField(
      controller: controller,
      obscureText: isPassword ? _isObscured : false,
      decoration: InputDecoration(
        prefixIcon: IconButton(
          icon: Icon(icon),
          onPressed: onReload,
        ),
        suffixIcon: isPassword
            ? IconButton(
                icon: Icon(_isObscured ? Icons.visibility : Icons.visibility_off),
                onPressed: _togglePasswordVisibility,
              )
            : null,
        hintText: hintText,
      ),
    );
  }

  Widget _buildVerifiedField({
    required TextEditingController controller,
    required IconData icon,
    required String label,
    bool isPassword = false,
    VoidCallback? onClear,
  }) {
    return TextField(
      controller: controller,
      enabled: false,
      obscureText: isPassword,
      decoration: InputDecoration(
        prefixIcon: IconButton(
          icon: Icon(icon),
          onPressed: onClear,
        ),
        suffixIcon: const Icon(Icons.check_circle, color: Colors.green),
        border: const OutlineInputBorder(
          borderSide: BorderSide(color: Colors.green, width: 2),
        ),
        enabledBorder: const OutlineInputBorder(
          borderSide: BorderSide(color: Colors.green, width: 2),
        ),
        disabledBorder: const OutlineInputBorder(
          borderSide: BorderSide(color: Colors.green, width: 2),
        ),
      ),
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton.icon(
        onPressed: () async {
          widget.toSubmit(widget.apiKeyValue, widget.name);
          setState(() {
            GetV.apiKey = widget.apiKeyValue;
            GetV.userName = widget.name;
            GetV.submited = true;
          });
        },
        icon: const Icon(Icons.check_circle_outline),
        label: const Text('Submit', style: TextStyle(fontSize: 18)),
      ),
    );
  }

  Widget _buildActionButtons(bool isWideScreen) {
    return Column(
      children: [
        Text(
          'Choose an option',
          style: AppTheme.bodyText1.copyWith(color: Colors.grey[600]),
        ),
        const SizedBox(height: AppSpacing.md),
        isWideScreen
            ? Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Expanded(child: _buildChatButton()),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(child: _buildSummaryButton()),
                ],
              )
            : Column(
                children: [
                  _buildChatButton(),
                  const SizedBox(height: AppSpacing.md),
                  _buildSummaryButton(),
                ],
              ),
      ],
    );
  }

  Widget _buildChatButton() {
    return SizedBox(
      width: double.infinity,
      height: 60,
      child: ElevatedButton(
        onPressed: widget.toChat,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset('assets/images/chatbot.png', height: 32, width: 32),
            const SizedBox(width: AppSpacing.md),
            const Text('Chatbot', style: TextStyle(fontSize: 18, color: Colors.white)),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryButton() {
    return SizedBox(
      width: double.infinity,
      height: 60,
      child: ElevatedButton(
        onPressed: widget.toSummarize,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.deepPurple,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset('assets/images/Docs.png', height: 32, width: 32),
            const SizedBox(width: AppSpacing.md),
            const Text('Summary', style: TextStyle(fontSize: 18, color: Colors.white)),
          ],
        ),
      ),
    );
  }
}