import 'package:flutter/material.dart';
import 'package:senmi/registration/auth/login.dart';

void main() {
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

      //home: const Homepage( ),
      home: const LoginScreen(),
      //home: const SignupScreen(),
      //home: const SplashScreen (),
      //home: const BottomNav(),
      //home: const SwipePage(),
      //home: const UploadProfileImagePage(),
      //home: const CompleteProfilePage(),
      //home: const OnboardingScreen()
    );
  }
}

