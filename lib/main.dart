import 'package:flutter/material.dart';
import 'screens/login_screen.dart';

void main() {
  runApp(const SafestoreApp());
}

class SafestoreApp extends StatelessWidget {
  const SafestoreApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Safestore',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
        scaffoldBackgroundColor: Colors.white, // 배경색 흰색으로 통일
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 1,
        ),
      ),
      home: LoginScreen(), // 로그인 화면부터 시작
    );
  }
}