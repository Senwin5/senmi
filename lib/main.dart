// main.dart
import 'package:flutter/material.dart';
import 'package:senmi/registration/auth/login.dart';
import 'package:senmi/screen_pages/admin/admin_dashboard.dart';
import 'package:senmi/screen_pages/features/customer/customer_bottomnav.dart';
import 'package:senmi/screen_pages/features/rider/rider_bottom_nav.dart';
import 'package:senmi/services/api_service.dart';



void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ApiService.loadToken(); // 🔥 THIS IS CRITICAL
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: ApiService.isLoggedIn, // listens to login state
      builder: (context, loggedIn, _) {
        Widget homeScreen;
        if (loggedIn) {
          // ✅ Determine home screen based on user role
          if (ApiService.isAdmin) {
            homeScreen = const AdminDashboard(); // Admin dashboard
          } else if (ApiService.userRole == "rider") {
            homeScreen = const RiderBottomNav(); // Rider 
          } else {
            homeScreen = const CustomerBottomNav(); // Customer 
          }
        } else {
          homeScreen = const LoginScreen(); // Not logged in → show login
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