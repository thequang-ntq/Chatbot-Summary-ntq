// lib/utils/validators.dart
class Validators {
  static bool isValidApiKey(String apiKey) {
    if (apiKey.isEmpty || apiKey.length != 51) return false;
    if (!apiKey.startsWith('sk-')) return false;
    return true;
  }

  static bool isValidUsername(String username) {
    if (username.isEmpty) return false;
    if (username.length < 3) return false;
    return true;
  }

  static String? validateApiKey(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter an API key';
    }
    if (!isValidApiKey(value)) {
      return 'Invalid API key format';
    }
    return null;
  }

  static String? validateUsername(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter a username';
    }
    if (!isValidUsername(value)) {
      return 'Username must be at least 3 characters';
    }
    return null;
  }
}