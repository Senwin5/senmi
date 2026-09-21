// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:senmi/services/driver_api_service.dart';
import 'package:senmi/senmi_package_screens/package_features/customer/customer_home_bottom/customer_bottomnav.dart';
import 'package:senmi/senmi_ride_screen/ride_features/customers/ride_customer_bottom_nav.dart';
import 'package:senmi/senmi_ride_screen/ride_features/customers/ride_tracking_screen.dart';

const Color senmiPurple = Color(0xFF581C87);
const Color senmiLightPurple = Color(0xFF7C3AED);

class MainCustomerHome extends StatefulWidget {
  const MainCustomerHome({super.key});

  @override
  State<MainCustomerHome> createState() => _MainCustomerHomeState();
}

class _MainCustomerHomeState extends State<MainCustomerHome> {
  bool checkingActiveRide = true;
  bool _openedActiveRide = false;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkActiveRide();
    });
  }

  // ============================================================
  // CHECK FOR ACTIVE RIDE
  // ============================================================

  Future<void> _checkActiveRide() async {
    try {
      final activeRides = await RideService.getActiveRides();

      if (!mounted) return;

      // --------------------------------------------------------
      // NO ACTIVE RIDE
      // --------------------------------------------------------

      if (activeRides.isEmpty) {
        setState(() {
          checkingActiveRide = false;
        });
        return;
      }

      // --------------------------------------------------------
      // PREVENT DUPLICATE NAVIGATION
      // --------------------------------------------------------

      if (_openedActiveRide) {
        return;
      }

      // --------------------------------------------------------
      // GET MOST RECENT ACTIVE RIDE
      // --------------------------------------------------------

      final firstRide = activeRides.first;

      if (firstRide is! Map) {
        setState(() {
          checkingActiveRide = false;
        });
        return;
      }

      final ride = Map<String, dynamic>.from(firstRide);

      final rideId = ride["ride_id"]?.toString();

      if (rideId == null || rideId.isEmpty || rideId == "null") {
        setState(() {
          checkingActiveRide = false;
        });
        return;
      }

      _openedActiveRide = true;

      // --------------------------------------------------------
      // OPEN TRACKING DIRECTLY
      // --------------------------------------------------------

      await Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => RideTrackingScreen(rideId: rideId)),
      );

      if (!mounted) return;

      setState(() {
        checkingActiveRide = false;
      });
    } catch (_) {
      // --------------------------------------------------------
      // IF ACTIVE-RIDE CHECK FAILS,
      // LET CUSTOMER CONTINUE NORMALLY.
      // --------------------------------------------------------

      if (!mounted) return;

      setState(() {
        checkingActiveRide = false;
      });
    }
  }

  // ============================================================
  // NORMAL CUSTOMER HOME
  // ============================================================

  Widget _buildHome(BuildContext context) {
    final theme = Theme.of(context);

    final isDark = theme.brightness == Brightness.dark;

    final backgroundColor = theme.scaffoldBackgroundColor;

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ==================================================
              // TOP BRAND / HERO
              // ==================================================
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(22, 22, 22, 24),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(28),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: isDark
                        ? const [Color(0xFF2B123F), Color(0xFF170B22)]
                        : const [Color(0xFF581C87), Color(0xFF7C3AED)],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: senmiPurple.withOpacity(isDark ? 0.18 : 0.20),
                      blurRadius: 22,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ==================================================
                    // BRAND
                    // ==================================================
                    Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.14),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.16),
                            ),
                          ),
                          child: const Icon(
                            Icons.navigation_rounded,
                            color: Colors.white,
                            size: 23,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          "Senmi",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 25,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.2,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // ==================================================
                    // HERO TITLE
                    // ==================================================
                    const Text(
                      "Move what matters.",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        height: 1.1,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                      ),
                    ),

                    const SizedBox(height: 10),

                    // ==================================================
                    // HERO SUBTITLE
                    // ==================================================
                    Text(
                      "One place for the things, trips and moments "
                      "that matter to you.",
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.78),
                        fontSize: 14,
                        height: 1.55,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 28),

              // ==================================================
              // SECTION TITLE
              // ==================================================
              Text(
                "What would you like to do?",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.2,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),

              const SizedBox(height: 7),

              Text(
                "Choose a Senmi service to get started.",
                style: TextStyle(
                  fontSize: 14,
                  color: isDark ? Colors.white60 : Colors.black54,
                ),
              ),

              const SizedBox(height: 18),

              // ==================================================
              // SERVICES
              // RIDE FIRST
              // PACKAGE SECOND
              // ==================================================
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // ==================================================
                    // RIDE
                    // ==================================================
                    Expanded(
                      child: _ServiceCard(
                        icon: Icons.directions_car_rounded,
                        title: "Ride",
                        description: "Get where you need to go.",
                        status: "Available now",
                        statusColor: Colors.green,
                        iconColor: senmiPurple,
                        isPrimary: true,
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const RideCustomerBottomNav(),
                            ),
                          );
                        },
                      ),
                    ),

                    const SizedBox(width: 14),

                    // ==================================================
                    // PACKAGE DELIVERY
                    // ==================================================
                    Expanded(
                      child: _ServiceCard(
                        icon: Icons.two_wheeler,
                        title: "Package Delivery",
                        description: "Send packages safely across Lagos.",
                        status: "Available now",
                        statusColor: Colors.green,
                        iconColor: senmiPurple,
                        isPrimary: false,
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) =>
                                  const CustomerBottomNav(initialIndex: 0),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 18),

              // ==================================================
              // FOOTER
              // ==================================================
              Center(
                child: Text(
                  "Senmi • Move what matters.",
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: isDark ? Colors.white38 : Colors.black38,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    // ----------------------------------------------------------
    // WHILE WE CHECK THE SERVER FOR AN ACTIVE RIDE
    // ----------------------------------------------------------

    if (checkingActiveRide) {
      return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: const Center(
          child: CircularProgressIndicator(color: senmiPurple),
        ),
      );
    }

    return _buildHome(context);
  }
}

// ============================================================
// SERVICE CARD
// ============================================================

class _ServiceCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final String status;
  final Color statusColor;
  final Color iconColor;
  final bool isPrimary;
  final VoidCallback onTap;

  const _ServiceCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.status,
    required this.statusColor,
    required this.iconColor,
    required this.isPrimary,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final cardColor = isDark ? const Color(0xFF1E1E22) : Colors.white;

    final borderColor = isDark
        ? Colors.white.withOpacity(0.08)
        : Colors.black.withOpacity(0.07);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Ink(
          padding: const EdgeInsets.all(17),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: borderColor),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isDark ? 0.18 : 0.07),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ==================================================
              // ICON
              // ==================================================
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      iconColor.withOpacity(0.16),
                      iconColor.withOpacity(0.07),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(icon, size: 29, color: iconColor),
              ),

              const SizedBox(height: 18),

              // ==================================================
              // TITLE
              // ==================================================
              Text(
                title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 17,
                  height: 1.2,
                  fontWeight: FontWeight.w800,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),

              const SizedBox(height: 8),

              // ==================================================
              // DESCRIPTION
              // ==================================================
              Text(
                description,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12.5,
                  height: 1.45,
                  color: isDark ? Colors.white54 : Colors.black54,
                ),
              ),

              const SizedBox(height: 20),

              // ==================================================
              // STATUS
              // ==================================================
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: statusColor.withOpacity(0.10)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: statusColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 7),
                    Text(
                      status,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: statusColor,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // ==================================================
              // ACTION INDICATOR
              // ==================================================
              Row(
                children: [
                  Text(
                    isPrimary ? "Start a ride" : "Get started",
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white70 : Colors.black87,
                    ),
                  ),

                  const Spacer(),

                  Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: senmiPurple.withOpacity(0.08),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.arrow_forward_rounded,
                      size: 16,
                      color: iconColor,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
