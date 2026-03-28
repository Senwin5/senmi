// main.dart
import 'package:flutter/material.dart';
import 'package:senmi/registration/auth/login.dart';
import 'package:senmi/screen_pages/features/customer/customer_bottomnav.dart';
import 'package:senmi/screen_pages/features/rider/rider_bottom_nav.dart';
import 'package:senmi/services/api_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ApiService.loadToken(); // ✅ LOAD TOKEN & ROLE
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: ApiService.isLoggedIn,
      builder: (context, loggedIn, _) {
        Widget homeScreen;

        if (loggedIn) {
          // Navigate based on role
          if (ApiService.userRole == "rider") {
            homeScreen = const RiderBottomNav();
          } else {
            homeScreen = const CustomerBottomNav();
          }
        } else {
          homeScreen = const LoginScreen();
        }

        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'SenMi',
          theme: ThemeData.dark().copyWith(
            scaffoldBackgroundColor: Colors.black,
            cardColor: Colors.grey[900],
          ),
          home: homeScreen,
        );
      },
    );
  }
}