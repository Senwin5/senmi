// main.dart
import 'package:flutter/material.dart';
import 'package:senmi/screen_pages/welcome/splash_screen.dart';
import 'package:senmi/services/api_service.dart';



void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ApiService.loadToken();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key}); 

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'SenMi',
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: Colors.black,
        cardColor: Colors.grey[900],
      ),
      home: const SplashScreen(), 
    );
  }
}