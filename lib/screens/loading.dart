import 'package:flutter/material.dart';

// Hiển thị màn hình Loading
class Loadings extends StatelessWidget {
  const Loadings({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[300],
      body: const Center(
        child: CircularProgressIndicator(
          color: Colors.black,
        ),
      ),
    );
  }
}