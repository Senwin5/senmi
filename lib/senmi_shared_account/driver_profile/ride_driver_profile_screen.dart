// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:senmi/senmi_shared_account/driver_profile/ride_driver_security_screen.dart';
import 'package:senmi/services/driver_api_service.dart';


const Color senmiRidePurple = Color(0xFF581C87);

class RideDriverProfileScreen extends StatefulWidget {
  const RideDriverProfileScreen({super.key});

  @override
  State<RideDriverProfileScreen> createState() =>
      _RideDriverProfileScreenState();
}

class _RideDriverProfileScreenState
    extends State<RideDriverProfileScreen> {
  Map<String, dynamic>? driver;
  bool loading = true;

  @override
  void initState() {
    super.initState();
    fetchDriverProfile();
  }

  Future<void> fetchDriverProfile() async {
    setState(() => loading = true);

    try {
      final response = await RideService.getDriverProfile();

      if (!mounted) return;

      setState(() {
        driver = response;
        loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        loading = false;
      });
    }
  }

  String value(
    String key, [
    String fallback = "Not available",
  ]) {
    final data = driver?[key];

    if (data == null || data.toString().trim().isEmpty) {
      return fallback;
    }

    return data.toString();
  }

  // ----------------------------------------------------------
  // PROFILE PHOTO
  // ----------------------------------------------------------

  String? get profilePhotoUrl {
    final photo = driver?["profile_photo"];

    if (photo == null) {
      return null;
    }

    final photoString = photo.toString().trim();

    if (photoString.isEmpty) {
      return null;
    }

    // Cloudinary URL returned directly by the API
    return photoString;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF121212)
          : const Color(0xFFF8F9FD),
      appBar: AppBar(
        title: const Text("Driver Profile"),
        centerTitle: true,
        foregroundColor: Colors.white,
        backgroundColor: senmiRidePurple,
      ),
      body: RefreshIndicator(
        onRefresh: fetchDriverProfile,
        child: loading
            ? const Center(
                child: CircularProgressIndicator(
                  color: senmiRidePurple,
                ),
              )
            : driver == null
                ? ListView(
                    children: [
                      const SizedBox(height: 180),
                      Center(
                        child: Text(
                          "Failed to load profile",
                          style: TextStyle(
                            color: theme.textTheme.bodyLarge?.color,
                          ),
                        ),
                      ),
                      const SizedBox(height: 15),
                      Center(
                        child: ElevatedButton(
                          onPressed: fetchDriverProfile,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: senmiRidePurple,
                            foregroundColor: Colors.white,
                          ),
                          child: const Text("Retry"),
                        ),
                      ),
                    ],
                  )
                : ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      _profileHeader(),

                      const SizedBox(height: 20),

                      _sectionTitle("Personal Information"),

                      _profileCard(
                        Icons.person_outline,
                        "Full Name",
                        value("full_name"),
                      ),

                      _profileCard(
                        Icons.phone_outlined,
                        "Phone Number",
                        value("phone_number"),
                      ),

                      _profileCard(
                        Icons.location_on_outlined,
                        "Address",
                        value("address"),
                      ),

                      _profileCard(
                        Icons.location_city_outlined,
                        "City",
                        value("city"),
                      ),

                      _profileCard(
                        Icons.map_outlined,
                        "State",
                        value("state"),
                      ),

                      _profileCard(
                        Icons.flag_outlined,
                        "Country",
                        value("country"),
                      ),

                      const SizedBox(height: 10),

                      _sectionTitle("Vehicle Information"),

                      _profileCard(
                        Icons.directions_car_outlined,
                        "Vehicle Brand",
                        value("vehicle_brand"),
                      ),

                      _profileCard(
                        Icons.car_repair_outlined,
                        "Vehicle Model",
                        value("vehicle_model"),
                      ),

                      _profileCard(
                        Icons.palette_outlined,
                        "Vehicle Color",
                        value("vehicle_color"),
                      ),

                      _profileCard(
                        Icons.calendar_today_outlined,
                        "Vehicle Year",
                        value("vehicle_year"),
                      ),

                      _profileCard(
                        Icons.confirmation_number_outlined,
                        "Plate Number",
                        value("plate_number"),
                      ),

                      const SizedBox(height: 10),

                      _sectionTitle("Driver Status"),

                      _profileCard(
                        Icons.verified_user_outlined,
                        "Status",
                        value("status"),
                      ),

                      _profileCard(
                        Icons.star_outline_rounded,
                        "Rating",
                        value(
                          "rating",
                          "0.0",
                        ),
                      ),

                      const SizedBox(height: 20),

                      // ACCOUNT & SECURITY
                      Card(
                        color: isDark
                            ? const Color(0xFF1E1E1E)
                            : Colors.white,
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 18,
                            vertical: 8,
                          ),
                          leading: const Icon(
                            Icons.security,
                            color: senmiRidePurple,
                          ),
                          title: Text(
                            "Account & Security",
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: isDark
                                  ? Colors.white
                                  : Colors.black87,
                            ),
                          ),
                          subtitle: Text(
                            "Password, logout and account settings",
                            style: TextStyle(
                              color: isDark
                                  ? Colors.white70
                                  : Colors.black54,
                            ),
                          ),
                          trailing: Icon(
                            Icons.arrow_forward_ios,
                            size: 18,
                            color: isDark
                                ? Colors.white70
                                : Colors.black54,
                          ),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    const RideDriverSecurityScreen(),
                              ),
                            );
                          },
                        ),
                      ),

                      const SizedBox(height: 20),
                    ],
                  ),
      ),
    );
  }

  // ----------------------------------------------------------
  // PROFILE HEADER
  // ----------------------------------------------------------

  Widget _profileHeader() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final name = value(
      "full_name",
      "Ride Driver",
    );

    final photoUrl = profilePhotoUrl;

    return Card(
      color: isDark
          ? const Color(0xFF1E1E1E)
          : Colors.white,
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // ------------------------------------------------
            // PROFILE PHOTO
            // ------------------------------------------------

            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: senmiRidePurple.withOpacity(0.12),
                border: Border.all(
                  color: senmiRidePurple.withOpacity(0.25),
                  width: 2,
                ),
              ),
              child: ClipOval(
                child: photoUrl != null
                    ? Image.network(
                        photoUrl,
                        width: 96,
                        height: 96,
                        fit: BoxFit.cover,
                        errorBuilder: (
                          context,
                          error,
                          stackTrace,
                        ) {
                          return const Icon(
                            Icons.person,
                            size: 52,
                            color: senmiRidePurple,
                          );
                        },
                        loadingBuilder: (
                          context,
                          child,
                          loadingProgress,
                        ) {
                          if (loadingProgress == null) {
                            return child;
                          }

                          return const Center(
                            child: CircularProgressIndicator(
                              color: senmiRidePurple,
                              strokeWidth: 2,
                            ),
                          );
                        },
                      )
                    : const Icon(
                        Icons.person,
                        size: 52,
                        color: senmiRidePurple,
                      ),
              ),
            ),

            const SizedBox(height: 12),

            Text(
              name,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 21,
                fontWeight: FontWeight.bold,
                color: isDark
                    ? Colors.white
                    : Colors.black87,
              ),
            ),

            const SizedBox(height: 5),

            Text(
              "Ride Driver",
              style: TextStyle(
                color: isDark
                    ? Colors.white70
                    : Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ----------------------------------------------------------
  // SECTION TITLE
  // ----------------------------------------------------------

  Widget _sectionTitle(String title) {
    final isDark =
        Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.only(
        left: 4,
        bottom: 8,
        top: 8,
      ),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.bold,
          color: isDark
              ? Colors.deepPurple.shade200
              : senmiRidePurple,
        ),
      ),
    );
  }

  // ----------------------------------------------------------
  // PROFILE CARD
  // ----------------------------------------------------------

  Widget _profileCard(
    IconData icon,
    String title,
    String value,
  ) {
    final theme = Theme.of(context);
    final isDark =
        theme.brightness == Brightness.dark;

    return Card(
      color: isDark
          ? const Color(0xFF1E1E1E)
          : Colors.white,
      margin: const EdgeInsets.symmetric(vertical: 6),
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor:
              senmiRidePurple.withOpacity(0.10),
          child: Icon(
            icon,
            color: isDark
                ? Colors.deepPurple.shade200
                : senmiRidePurple,
          ),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontSize: 13,
            color: isDark
                ? Colors.white70
                : Colors.grey,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 3),
          child: Text(
            value,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: isDark
                  ? Colors.white
                  : Colors.black87,
            ),
          ),
        ),
      ),
    );
  }
}