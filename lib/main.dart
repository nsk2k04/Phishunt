import 'package:flutter/material.dart';
import 'Pages/home_page.dart';
import 'Pages/sms_page.dart';

void main() {
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: PhishingDetectionDashboard(), // Point to PhishingDetectionDashboard
    );
  }
}