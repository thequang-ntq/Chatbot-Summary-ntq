// lib/utils/constants.dart
class AppConstants {
  // API
  static const String firebaseUrl = 'your-project-name-b1e6c-default-rtdb.firebaseio.com';
  static const String openAIModelsUrl = 'https://api.openai.com/v1/models';
  static const String openAITranscriptionsUrl = 'https://api.openai.com/v1/audio/transcriptions';
  
  // Models
  static const String gpt35Turbo = 'gpt-4o-mini';
  static const String gpt35Turbo16k = 'gpt-4o-mini';
  static const String whisper1 = 'whisper-1';
  
  // Limits
  static const int maxApiKeyLength = 51;
  static const int minUsernameLength = 3;
  static const int maxTextLength = 4000;
  static const int maxChunkSize = 1200;
  static const int chunkOverlap = 200;
  
  // Timeouts
  static const Duration apiTimeout = Duration(seconds: 60);
  static const Duration shortDelay = Duration(milliseconds: 500);
  static const Duration mediumDelay = Duration(seconds: 1);
  static const Duration longDelay = Duration(seconds: 3);
}