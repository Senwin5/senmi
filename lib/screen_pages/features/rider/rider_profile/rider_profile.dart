import 'package:flutter/material.dart';
import 'package:senmi/screen_pages/features/rider/rider_profile/rider_details_profile.dart';
import 'package:senmi/services/api_service.dart';

class RiderProfileScreen extends StatefulWidget {
  const RiderProfileScreen({super.key});

  @override
  State<RiderProfileScreen> createState() => _RiderProfileScreenState();
}

class _RiderProfileScreenState extends State<RiderProfileScreen> {
  Map<String, dynamic>? rider;
  bool loading = true;

  @override
  void initState() {
    super.initState();
    fetchRider();
  }

  Future<void> fetchRider() async {
    setState(() => loading = true);
    try {
      final data = await ApiService.getRiderProfile();
      setState(() {
        rider = data;
        loading = false;
      });
    } catch (e) {
      setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text("Rider Profile"),
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        foregroundColor: Theme.of(context).textTheme.bodyLarge?.color,
        elevation: 1,
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : rider == null
          ? const Center(child: Text("Failed to load profile"))
          : Center(
              child: GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => RiderDetailsProfile(rider: rider),
                    ),
                  );
                },
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircleAvatar(
                      radius: 55,
                      backgroundColor: Colors.deepPurple,
                      backgroundImage: rider!['profile_picture'] != null
                          ? NetworkImage(
                              ApiService.baseUrl.replaceAll('/api', '') +
                                  rider!['profile_picture'],
                            )
                          : null,
                      child: rider!['profile_picture'] == null
                          ? Text(
                              rider!['username'] != null &&
                                      rider!['username'].isNotEmpty
                                  ? rider!['username'][0].toUpperCase()
                                  : "R",
                              style: const TextStyle(
                                fontSize: 40,
                                color: Colors.white,
                              ),
                            )
                          : null,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      rider!['username'] ?? "Rider",
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      "Tap to view full profile",
                      style: TextStyle(color: Colors.deepPurple),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
