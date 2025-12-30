// lib/utils/file_helper.dart
// Xử lý file 

class FileHelper {
  static String getFileExtension(String fileName) {
    return fileName.split('.').last.toLowerCase();
  }

  static String getFileNameWithoutExtension(String fileName) {
    final parts = fileName.split('.');
    if (parts.length <= 1) return fileName;
    return parts.sublist(0, parts.length - 1).join('.');
  }

  static bool isPdf(String fileName) {
    return getFileExtension(fileName) == 'pdf';
  }

  static bool isDocx(String fileName) {
    final ext = getFileExtension(fileName);
    return ext == 'docx' || ext == 'doc';
  }

  static bool isTxt(String fileName) {
    return getFileExtension(fileName) == 'txt';
  }

  static bool isAudio(String fileName) {
    final ext = getFileExtension(fileName);
    return ['mp3', 'wav', 'm4a', 'aac', 'ogg'].contains(ext);
  }

  static String formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(2)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }
}