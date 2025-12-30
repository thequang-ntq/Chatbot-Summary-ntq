// Wrapper xử lý connection check cho cả web và mobile 
// •	Package connection_notifier không hỗ trợ web
// •	Tránh lỗi compile trên web
// •	Code linh hoạt cho nhiều platform


import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:connection_notifier/connection_notifier.dart' 
    if (dart.library.html) 'dart:html';

/// Widget wrapper để xử lý connection checking
/// Tự động bỏ qua trên web platform
class ConnectionWrapper extends StatelessWidget {
  final Widget connected;
  final Widget disconnected;
  final Function(bool?)? onConnectionStatusChanged;

  const ConnectionWrapper({
    super.key,
    required this.connected,
    required this.disconnected,
    this.onConnectionStatusChanged,
  });

  @override
  Widget build(BuildContext context) {
    // Trên web, luôn hiển thị connected widget
    if (kIsWeb) {
      return connected;
    }
    
    // Trên mobile, sử dụng ConnectionNotifierToggler
    return ConnectionNotifierToggler(
      onConnectionStatusChanged: onConnectionStatusChanged,
      disconnected: disconnected,
      connected: connected,
    );
  }
}