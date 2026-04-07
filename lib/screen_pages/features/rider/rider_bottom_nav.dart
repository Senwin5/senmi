import 'package:flutter/material.dart';
import 'package:senmi/screen_pages/features/rider/rider_deliveries_screen.dart';
import 'package:senmi/screen_pages/features/rider/rider_history_screen.dart';
import 'package:senmi/screen_pages/features/rider/rider_home.dart';
import 'package:senmi/screen_pages/features/rider/wallet_screen.dart';
import '../../../services/api_service.dart';
import '../../../registration/auth/login.dart';
import 'package:senmi/widgets/custom_buttom.dart';
import 'package:senmi/screen_pages/features/rider/rider_profile.dart';
import 'package:url_launcher/url_launcher.dart';

/// Rider Settings Screen (Functional + Dark Mode)
class RiderSettingsScreen extends StatefulWidget {
  final ValueNotifier<bool> darkModeNotifier;
  const RiderSettingsScreen({super.key, required this.darkModeNotifier});

  @override
  State<RiderSettingsScreen> createState() => _RiderSettingsScreenState();
}

class _RiderSettingsScreenState extends State<RiderSettingsScreen> {
  bool loading = false;
  bool notificationsEnabled = true; // Notifications toggle

  void logout() async {
    setState(() => loading = true);
    await ApiService.logout();
    setState(() => loading = false);
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  void openWhatsApp() async {
    final phone = "+2347016087680"; // Replace with your WhatsApp number
    final url = "https://wa.me/$phone";
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Could not open WhatsApp")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Settings"), centerTitle: true),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Links Section
                ListTile(
                  leading: const Icon(Icons.person),
                  title: const Text("Profile"),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const RiderProfileScreen()),
                    );
                  },
                ),
                const Divider(),

                ListTile(
                  leading: const Icon(Icons.support_agent),
                  title: const Text("Support"),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () {},
                ),
                const Divider(),

                ListTile(
                  leading: const Icon(Icons.question_answer),
                  title: const Text("FAQ"),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () {},
                ),
                const Divider(),

                ListTile(
                  leading: const Icon(Icons.privacy_tip),
                  title: const Text("App Privacy"),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () {},
                ),
                const Divider(),

                ListTile(
                  leading: const Icon(Icons.article),
                  title: const Text("Terms & Conditions"),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () {},
                ),
                const Divider(),

                ListTile(
                  leading: const Icon(Icons.chat),
                  title: const Text("Chat Me"),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: openWhatsApp,
                ),
                const Divider(),

                // Settings Section
                ListTile(
                  leading: const Icon(Icons.lock),
                  title: const Text("Change Password"),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () {},
                ),
                const Divider(),

                SwitchListTile(
                  secondary: const Icon(Icons.notifications),
                  title: const Text("Notifications"),
                  value: notificationsEnabled,
                  onChanged: (val) => setState(() => notificationsEnabled = val),
                ),
                const Divider(),

                SwitchListTile(
                  secondary: const Icon(Icons.dark_mode),
                  title: const Text("Dark Mode"),
                  value: widget.darkModeNotifier.value,
                  onChanged: (val) => widget.darkModeNotifier.value = val,
                ),

                const SizedBox(height: 16),

                CustomButton(
                  text: "Logout",
                  onPressed: logout,
                  fullWidth: true,
                  padding: const EdgeInsets.all(16),
                  color: Colors.red,
                ),
              ],
            ),
    );
  }
}

/// Updated Rider Bottom Navigation with Dark Mode
class RiderBottomNav extends StatefulWidget {
  const RiderBottomNav({super.key});

  @override
  State<RiderBottomNav> createState() => _RiderBottomNavState();
}

class _RiderBottomNavState extends State<RiderBottomNav> {
  int _currentIndex = 0;
  final darkModeNotifier = ValueNotifier<bool>(false);

  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [
      const RiderHome(),
      const RiderDeliveriesScreen(),
      const RiderWalletScreen(),
      const RiderHistoryScreen(),
      RiderSettingsScreen(darkModeNotifier: darkModeNotifier),
    ];
  }

  final List<BottomNavigationBarItem> _navItems = const [
    BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
    BottomNavigationBarItem(icon: Icon(Icons.local_shipping), label: "Deliveries"),
    BottomNavigationBarItem(icon: Icon(Icons.account_balance_wallet), label: "Wallet"),
    BottomNavigationBarItem(icon: Icon(Icons.history), label: "History"),
    BottomNavigationBarItem(icon: Icon(Icons.settings), label: "Settings"),
  ];

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: darkModeNotifier,
      builder: (context, isDark, _) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: ThemeData.light(),
          darkTheme: ThemeData.dark(),
          themeMode: isDark ? ThemeMode.dark : ThemeMode.light,
          home: Scaffold(
            body: _screens[_currentIndex],
            bottomNavigationBar: BottomNavigationBar(
              currentIndex: _currentIndex,
              items: _navItems,
              type: BottomNavigationBarType.fixed,
              onTap: (index) => setState(() => _currentIndex = index),
            ),
          ),
        );
      },
    );
  }
}