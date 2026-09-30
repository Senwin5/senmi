// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:senmi/services/driver_api_service.dart';
import 'package:senmi/senmi_package_screens/package_features/customer/customer_home_bottom/customer_bottomnav.dart';
import 'package:senmi/senmi_ride_screen/ride_features/customers/customer_home/ride_customer_bottom_nav.dart';
import 'package:senmi/senmi_ride_screen/ride_features/customers/customer_map_tracking/ride_tracking_screen.dart';

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
                padding: const EdgeInsets.fromLTRB(22, 22, 22, 25),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(28),

                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: isDark
                        ? const [
                            Color(0xFF321348),
                            Color(0xFF21102D),
                            Color(0xFF160C1E),
                          ]
                        : const [
                            Color(0xFF581C87),
                            Color(0xFF6D28D9),
                            Color(0xFF7C3AED),
                          ],
                  ),

                  border: Border.all(
                    color: Colors.white.withOpacity(isDark ? 0.08 : 0.10),
                  ),

                  boxShadow: [
                    BoxShadow(
                      color: senmiPurple.withOpacity(isDark ? 0.22 : 0.18),
                      blurRadius: 28,
                      spreadRadius: -4,
                      offset: const Offset(0, 14),
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
                          width: 46,
                          height: 46,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(15),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.15),
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

                    const SizedBox(height: 25),

                    // ==================================================
                    // HERO TITLE
                    // ==================================================
                    const Text(
                      "Move what matters.",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 29,
                        height: 1.08,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.7,
                      ),
                    ),

                    const SizedBox(height: 10),

                    // ==================================================
                    // HERO SUBTITLE
                    // ==================================================
                    Text(
                      "Choose a Senmi service to get started.",
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.76),
                        fontSize: 14,
                        height: 1.55,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 29),

              // ==================================================
              // SECTION TITLE
              // ==================================================
              Text(
                "What would you like to do.",
                style: TextStyle(
                  fontSize: 14,
                  height: 1.4,
                  color: isDark
                      ? Colors.white.withOpacity(0.50)
                      : Colors.black.withOpacity(0.52),
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
                        image: "assets/mainhome/senmi_ride.png",
                        title: "Book a Ride",
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
                        image: "assets/mainhome/senmi_package.png",
                        title: "Deliver a Package",
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

              const SizedBox(height: 20),

              // ==================================================
              // FOOTER
              // ==================================================
              Center(
                child: Text(
                  "Senmi • Move what matters.",
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.15,
                    color: isDark
                        ? Colors.white.withOpacity(0.30)
                        : Colors.black.withOpacity(0.34),
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
      final isDark = Theme.of(context).brightness == Brightness.dark;

      return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withOpacity(0.045)
                      : senmiPurple.withOpacity(0.055),
                  shape: BoxShape.circle,
                  border: Border.all(color: senmiPurple.withOpacity(0.12)),
                ),
                padding: const EdgeInsets.all(17),
                child: const CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: senmiPurple,
                ),
              ),

              const SizedBox(height: 16),

              Text(
                "Getting things ready...",
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isDark
                      ? Colors.white.withOpacity(0.48)
                      : Colors.black.withOpacity(0.50),
                ),
              ),
            ],
          ),
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
  final String image;
  final String title;
  final String description;
  final String status;
  final Color statusColor;
  final Color iconColor;
  final bool isPrimary;
  final VoidCallback onTap;

  const _ServiceCard({
    required this.image,
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

    final cardColor = isDark ? const Color(0xFF18161D) : Colors.white;

    final borderColor = isDark
        ? Colors.white.withOpacity(0.075)
        : Colors.black.withOpacity(0.055);

    final secondaryText = isDark
        ? Colors.white.withOpacity(0.46)
        : Colors.black.withOpacity(0.50);

    final titleColor = isDark ? Colors.white : const Color(0xFF18181B);
    Colors.black.withOpacity(0.52);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(23),
        splashColor: senmiPurple.withOpacity(0.09),
        highlightColor: senmiPurple.withOpacity(0.035),
        child: Ink(
          padding: const EdgeInsets.fromLTRB(15, 15, 14, 14),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(23),

            border: Border.all(color: borderColor, width: 1),

            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isDark ? 0.24 : 0.055),
                blurRadius: 24,
                spreadRadius: -5,
                offset: const Offset(0, 10),
              ),
            ],
          ),

          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ==================================================
              // IMAGE ROW
              // ==================================================
              Row(
                children: [
                  Container(
                    width: 138,
                    height: 108,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          iconColor.withOpacity(isDark ? 0.20 : 0.15),
                          iconColor.withOpacity(isDark ? 0.055 : 0.045),
                        ],
                      ),

                      borderRadius: BorderRadius.circular(16),

                      border: Border.all(color: iconColor.withOpacity(0.075)),

                      boxShadow: [
                        BoxShadow(
                          color: iconColor.withOpacity(isDark ? 0.10 : 0.06),
                          blurRadius: 12,
                          spreadRadius: -4,
                        ),
                      ],
                    ),

                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: Image.asset(
                        image,
                        width: 108,
                        height: 108,
                        fit: BoxFit.contain,

                        // If the image path is wrong,
                        // show a fallback icon instead.
                        errorBuilder: (context, error, stackTrace) {
                          return Icon(
                            Icons.image_not_supported_outlined,
                            size: 25,
                            color: isDark ? senmiLightPurple : iconColor,
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 17),

              // ==================================================
              // TITLE
              // ==================================================
              Text(
                title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 16,
                  height: 1.18,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.3,
                  color: titleColor,
                ),
              ),

              const SizedBox(height: 7),

              // ==================================================
              // DESCRIPTION
              // ==================================================
              Text(
                description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11.5,
                  height: 1.42,
                  fontWeight: FontWeight.w400,
                  color: secondaryText,
                ),
              ),

              const SizedBox(height: 16),

              // ==================================================
              // STATUS
              // ==================================================
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(isDark ? 0.085 : 0.075),
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
                        boxShadow: [
                          BoxShadow(
                            color: statusColor.withOpacity(0.40),
                            blurRadius: 6,
                            spreadRadius: 0,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(width: 6),

                    Flexible(
                      child: Text(
                        status,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.05,
                          color: statusColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 14),

              // ==================================================
              // ACTION
              // ==================================================
              Row(
                children: [
                  Expanded(
                    child: Text(
                      isPrimary ? "Start a ride" : "Get started",
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.05,
                        color: isPrimary
                            ? senmiLightPurple
                            : (isDark
                                  ? Colors.white.withOpacity(0.68)
                                  : Colors.black.withOpacity(0.68)),
                      ),
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
