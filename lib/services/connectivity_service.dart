import 'package:flutter/foundation.dart';

class ConnectivityService {
  static bool _isOnline = true;
  
  static bool get isOnline => _isOnline;
  
  static Future<void> initialize() async {
    if (kIsWeb) {
      // Trên web, giả định luôn có kết nối
      // Hoặc có thể sử dụng JavaScript để check
      _isOnline = true;
    } else {
      // Trên mobile, có thể sử dụng connection_notifier
      // Nhưng không import ở đây để tránh lỗi web
    }
  }
  
  static Stream<bool> get onStatusChange async* {
    if (kIsWeb) {
      // Trên web, luôn return true
      yield true;
    } else {
      // Xử lý cho mobile
      yield _isOnline;
    }
  }
}