import 'package:flutter/material.dart';
import 'login_screen.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ACOSENAR Finanzas',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: const Color(0xFF0066CC),
        useMaterial3: true,
      ),
      home: const LoginScreen(),
    );
  }
}