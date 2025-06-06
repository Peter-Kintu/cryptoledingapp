import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'home_page.dart';
import 'login_page.dart';
import 'utils/constants.dart'; // Import constants

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final _storage = const FlutterSecureStorage();
  Widget _initialPage = const LoginPage(); // Default to login page

  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    final token = await _storage.read(key: AUTH_TOKEN_KEY);
    if (token != null) {
      // Potentially validate token with backend before navigating
      setState(() {
        _initialPage = HomePage(title: 'Money Lending App', token: token);
      });
    } else {
      setState(() {
        _initialPage = const LoginPage();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Money Lending App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: _initialPage,
    );
  }
}