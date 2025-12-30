import 'package:flutter/material.dart';
// Hiển thị màn hình khi không có mạng
class InternetErr extends StatelessWidget {
  const InternetErr({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(14.0),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset('assets/images/brycen.png'),
            const SizedBox(height: 5,),
            const Icon(
              Icons.wifi_off,
              size: 30,
            ),
            const SizedBox(height: 5),
            const Text(
                'Please check your internet connection',
                textAlign: TextAlign.end,
                style: TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                  fontSize: 19,
                ),
              ),
          ],
        ),
      ),
    );
  }
}