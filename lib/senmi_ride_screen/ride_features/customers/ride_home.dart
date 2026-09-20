// ignore_for_file: deprecated_member_use, use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:senmi/main.dart';
import 'package:senmi/senmi_shared_account/customer_profiles/account_profile_screen.dart';
import 'package:senmi/senmi_shared_account/map/map_picker_screen.dart';

const Color senmiRidePurple = Color(0xFF581C87);
const Color senmiRideLightPurple = Color(0xFF7C3AED);

class RideHome extends StatefulWidget {
  const RideHome({super.key});

  @override
  State<RideHome> createState() => _RideHomeState();
}

class _RideHomeState extends State<RideHome> {
  // ============================================================
  // RIDE STATE
  // ============================================================

  String selectedRideType = "basic";

  LatLng? pickupLocation;
  LatLng? destinationLocation;

  String pickupAddress = "";
  String destinationAddress = "";

  bool selectingPickup = false;
  bool selectingDestination = false;

  // Default Lagos location.
  static const LatLng defaultLagosLocation = LatLng(6.5244, 3.3792);

  // ============================================================
  // GET ADDRESS
  // ============================================================

  Future<String> _getAddressFromLatLng(LatLng position) async {
    try {
      final placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isEmpty) {
        return "Unknown location";
      }

      final place = placemarks.first;

      final parts = <String>[];

      if (place.street?.isNotEmpty == true) {
        parts.add(place.street!);
      }

      if (place.locality?.isNotEmpty == true) {
        parts.add(place.locality!);
      }

      if (place.administrativeArea?.isNotEmpty == true) {
        parts.add(place.administrativeArea!);
      }

      if (place.country?.isNotEmpty == true) {
        parts.add(place.country!);
      }

      if (parts.isEmpty) {
        return "Unknown location";
      }

      return parts.toSet().join(", ");
    } catch (e) {
      return "Unknown location";
    }
  }

  // ============================================================
  // PICK LOCATION
  // ============================================================
  Future<void> _pickLocation({required bool isPickup}) async {
    if (isPickup) {
      setState(() {
        selectingPickup = true;
      });
    } else {
      setState(() {
        selectingDestination = true;
      });
    }

    try {
      final LatLng startingLocation = isPickup
          ? (pickupLocation ?? defaultLagosLocation)
          : (destinationLocation ?? pickupLocation ?? defaultLagosLocation);

      final selected = await Navigator.of(context).push<LatLng>(
        MaterialPageRoute(
          builder: (_) => MapPickerScreen(
            initialLocation: startingLocation,
            useCurrentLocation: isPickup,
          ),
        ),
      );

      if (selected == null) {
        return;
      }

      final address = await _getAddressFromLatLng(selected);

      if (!mounted) return;

      setState(() {
        if (isPickup) {
          pickupLocation = selected;
          pickupAddress = address;
        } else {
          destinationLocation = selected;
          destinationAddress = address;
        }
      });

      // =========================================================
      // AFTER PICKUP IS CONFIRMED
      // AUTOMATICALLY OPEN DESTINATION MAP
      // =========================================================
      if (isPickup && mounted) {
        await _pickLocation(isPickup: false);
      }
    } finally {
      if (mounted) {
        setState(() {
          selectingPickup = false;
          selectingDestination = false;
        });
      }
    }
  }

  // ============================================================
  // CLEAR LOCATION
  // ============================================================

  void _clearPickup() {
    setState(() {
      pickupLocation = null;
      pickupAddress = "";

      // If pickup is cleared, destination is cleared too
      // because the destination should belong to the new trip.
      destinationLocation = null;
      destinationAddress = "";
    });
  }

  void _clearDestination() {
    setState(() {
      destinationLocation = null;
      destinationAddress = "";
    });
  }

  // ============================================================
  // RIDE READY CHECK
  // ============================================================

  bool get locationsSelected {
    return pickupLocation != null && destinationLocation != null;
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final backgroundColor = theme.scaffoldBackgroundColor;

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // ==================================================
            // TOP BAR
            // ==================================================
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 10),
              child: Row(
                children: [
                  // Back
                  _TopIconButton(
                    icon: Icons.arrow_back_rounded,
                    onTap: () {
                      Navigator.of(context).pop();
                    },
                  ),

                  const SizedBox(width: 14),

                  // Title
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Ride",
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          "Move where you need to go.",
                          style: TextStyle(
                            fontSize: 12.5,
                            color: isDark ? Colors.white54 : Colors.black54,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Shared account/profile
                  _TopIconButton(
                    icon: Icons.person_outline_rounded,
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => CustomerProfileScreen(
                            darkModeNotifier: isDarkMode,
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),

            // ==================================================
            // BODY
            // ==================================================
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ==================================================
                    // HERO
                    // ==================================================
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(24),
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: isDark
                              ? const [Color(0xFF2A123B), Color(0xFF17101C)]
                              : const [Color(0xFF581C87), Color(0xFF7C3AED)],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: senmiRidePurple.withOpacity(
                              isDark ? 0.16 : 0.18,
                            ),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 52,
                            height: 52,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.14),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Icon(
                              Icons.directions_car_rounded,
                              color: Colors.white,
                              size: 27,
                            ),
                          ),

                          const SizedBox(width: 14),

                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  "Ready for a ride?",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),

                                const SizedBox(height: 5),

                                Text(
                                  "Set your pickup and destination "
                                  "to get started.",
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.76),
                                    fontSize: 12.5,
                                    height: 1.45,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 26),

                    // ==================================================
                    // YOUR TRIP
                    // ==================================================
                    Text(
                      "Your trip",
                      style: TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.w800,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),

                    const SizedBox(height: 6),

                    Text(
                      "Choose where you are and where you "
                      "want to go.",
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark ? Colors.white54 : Colors.black54,
                      ),
                    ),

                    const SizedBox(height: 16),

                    // ==================================================
                    // PICKUP
                    // ==================================================
                    _LocationField(
                      icon: Icons.my_location_rounded,
                      iconColor: Colors.green,
                      title: "Pickup location",
                      value: pickupAddress.isEmpty
                          ? "Choose your pickup location"
                          : pickupAddress,
                      isDark: isDark,
                      loading: selectingPickup,
                      hasLocation: pickupLocation != null,
                      onTap: () {
                        _pickLocation(isPickup: true);
                      },
                      onClear: pickupLocation != null ? _clearPickup : null,
                    ),

                    const SizedBox(height: 10),

                    // ==================================================
                    // CONNECTING LINE
                    // ==================================================
                    Padding(
                      padding: const EdgeInsets.only(left: 29),
                      child: Container(
                        width: 2,
                        height: 16,
                        decoration: BoxDecoration(
                          color: isDark ? Colors.white12 : Colors.black12,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),

                    const SizedBox(height: 10),

                    // ==================================================
                    // DESTINATION
                    // ==================================================
                    _LocationField(
                      icon: Icons.location_on_rounded,
                      iconColor: Colors.redAccent,
                      title: "Destination",
                      value: destinationAddress.isEmpty
                          ? "Where do you want to go?"
                          : destinationAddress,
                      isDark: isDark,
                      loading: selectingDestination,
                      hasLocation: destinationLocation != null,
                      onTap: () {
                        _pickLocation(isPickup: false);
                      },
                      onClear: destinationLocation != null
                          ? _clearDestination
                          : null,
                    ),

                    const SizedBox(height: 28),

                    // ==================================================
                    // RIDE TYPE
                    // ==================================================
                    Text(
                      "Choose your ride",
                      style: TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.w800,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),

                    const SizedBox(height: 6),

                    Text(
                      "Select the ride that suits you.",
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark ? Colors.white54 : Colors.black54,
                      ),
                    ),

                    const SizedBox(height: 16),

                    Row(
                      children: [
                        Expanded(
                          child: _RideTypeCard(
                            title: "Basic",
                            subtitle: "Everyday ride",
                            icon: Icons.directions_car_outlined,
                            selected: selectedRideType == "basic",
                            isDark: isDark,
                            onTap: () {
                              setState(() {
                                selectedRideType = "basic";
                              });
                            },
                          ),
                        ),

                        const SizedBox(width: 12),

                        Expanded(
                          child: _RideTypeCard(
                            title: "Premium",
                            subtitle: "More comfort",
                            icon: Icons.star_outline_rounded,
                            selected: selectedRideType == "premium",
                            isDark: isDark,
                            onTap: () {
                              setState(() {
                                selectedRideType = "premium";
                              });
                            },
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // ==================================================
                    // FARE PREVIEW
                    // ==================================================
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF1B1B1F)
                            : const Color(0xFFF8F7FA),
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(
                          color: isDark
                              ? Colors.white.withOpacity(0.07)
                              : Colors.black.withOpacity(0.06),
                        ),
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "Estimated fare",
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: isDark
                                            ? Colors.white54
                                            : Colors.black54,
                                      ),
                                    ),

                                    const SizedBox(height: 5),

                                    Text(
                                      locationsSelected
                                          ? "Fare will be calculated"
                                          : "Select both locations first",
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: isDark
                                            ? Colors.white38
                                            : Colors.black38,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              Text(
                                "—",
                                style: TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.w800,
                                  color: isDark ? Colors.white : Colors.black87,
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 16),

                          Divider(
                            height: 1,
                            color: isDark ? Colors.white10 : Colors.black12,
                          ),

                          const SizedBox(height: 14),

                          Row(
                            children: [
                              Icon(
                                selectedRideType == "premium"
                                    ? Icons.star_rounded
                                    : Icons.check_circle_outline_rounded,
                                size: 18,
                                color: senmiRidePurple,
                              ),

                              const SizedBox(width: 8),

                              Text(
                                selectedRideType == "premium"
                                    ? "Premium selected"
                                    : "Basic selected",
                                style: TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w700,
                                  color: isDark
                                      ? Colors.white70
                                      : Colors.black87,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // ==================================================
                    // REQUEST RIDE
                    // ==================================================
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: locationsSelected
                            ? () {
                                _showRideSetupDialog(context);
                              }
                            : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: senmiRidePurple,
                          foregroundColor: Colors.white,
                          disabledBackgroundColor: isDark
                              ? Colors.white10
                              : Colors.black12,
                          disabledForegroundColor: isDark
                              ? Colors.white30
                              : Colors.black38,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(17),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.local_taxi_rounded, size: 21),
                            const SizedBox(width: 9),
                            Text(
                              locationsSelected
                                  ? "Request ${selectedRideType == "premium" ? "Premium" : "Basic"} Ride"
                                  : "Select Locations First",
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 14),

                    // ==================================================
                    // TRUST MESSAGE
                    // ==================================================
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.verified_user_outlined,
                          size: 15,
                          color: isDark ? Colors.white38 : Colors.black38,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          "Safe, reliable rides with Senmi",
                          style: TextStyle(
                            fontSize: 11.5,
                            color: isDark ? Colors.white38 : Colors.black38,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // TEMPORARY REQUEST DIALOG
  // ============================================================

  void _showRideSetupDialog(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: isDark ? const Color(0xFF1E1E22) : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
          title: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: senmiRidePurple.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.local_taxi_rounded,
                  color: senmiRidePurple,
                ),
              ),

              const SizedBox(width: 12),

              Expanded(
                child: Text(
                  "Ride ready",
                  style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
              ),
            ],
          ),
          content: Text(
            "Your pickup and destination have been "
            "selected. Ride fare calculation will be "
            "connected next.",
            style: TextStyle(
              fontSize: 14,
              height: 1.5,
              color: isDark ? Colors.white60 : Colors.black54,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },
              child: const Text(
                "Okay",
                style: TextStyle(
                  color: senmiRidePurple,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

// ============================================================
// TOP ICON BUTTON
// ============================================================

class _TopIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _TopIconButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Ink(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E1E22) : const Color(0xFFF6F4F8),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isDark
                  ? Colors.white.withOpacity(0.07)
                  : Colors.black.withOpacity(0.06),
            ),
          ),
          child: Icon(
            icon,
            size: 21,
            color: isDark ? Colors.white70 : Colors.black87,
          ),
        ),
      ),
    );
  }
}

// ============================================================
// LOCATION FIELD
// ============================================================

class _LocationField extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String value;
  final bool isDark;
  final bool loading;
  final bool hasLocation;
  final VoidCallback onTap;
  final VoidCallback? onClear;

  const _LocationField({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.value,
    required this.isDark,
    required this.loading,
    required this.hasLocation,
    required this.onTap,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(19),
        child: Ink(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E1E22) : Colors.white,
            borderRadius: BorderRadius.circular(19),
            border: Border.all(
              color: hasLocation
                  ? senmiRidePurple
                  : (isDark
                        ? Colors.white.withOpacity(0.08)
                        : Colors.black.withOpacity(0.07)),
              width: hasLocation ? 1.2 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isDark ? 0.10 : 0.04),
                blurRadius: 12,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(icon, color: iconColor, size: 21),
              ),

              const SizedBox(width: 13),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white54 : Colors.black54,
                      ),
                    ),

                    const SizedBox(height: 4),

                    if (loading)
                      Row(
                        children: [
                          SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: senmiRidePurple,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            "Opening map...",
                            style: TextStyle(
                              fontSize: 13,
                              color: isDark ? Colors.white54 : Colors.black54,
                            ),
                          ),
                        ],
                      )
                    else
                      Text(
                        value,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: hasLocation
                              ? (isDark ? Colors.white : Colors.black87)
                              : (isDark ? Colors.white54 : Colors.black54),
                        ),
                      ),
                  ],
                ),
              ),

              if (hasLocation && onClear != null)
                IconButton(
                  visualDensity: VisualDensity.compact,
                  icon: Icon(
                    Icons.close_rounded,
                    size: 19,
                    color: isDark ? Colors.white38 : Colors.black38,
                  ),
                  onPressed: onClear,
                )
              else
                Icon(
                  Icons.chevron_right_rounded,
                  color: isDark ? Colors.white38 : Colors.black38,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================
// RIDE TYPE CARD
// ============================================================

class _RideTypeCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final bool selected;
  final bool isDark;
  final VoidCallback onTap;

  const _RideTypeCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.selected,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final background = selected
        ? senmiRidePurple.withOpacity(0.08)
        : (isDark ? const Color(0xFF1E1E22) : Colors.white);

    final border = selected
        ? senmiRidePurple
        : (isDark
              ? Colors.white.withOpacity(0.08)
              : Colors.black.withOpacity(0.07));

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Ink(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: background,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: border, width: selected ? 1.4 : 1),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: selected
                          ? senmiRidePurple
                          : senmiRidePurple.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      icon,
                      size: 20,
                      color: selected ? Colors.white : senmiRidePurple,
                    ),
                  ),

                  const Spacer(),

                  if (selected)
                    Container(
                      width: 22,
                      height: 22,
                      decoration: const BoxDecoration(
                        color: senmiRidePurple,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check_rounded,
                        size: 15,
                        color: Colors.white,
                      ),
                    ),
                ],
              ),

              const SizedBox(height: 14),

              Text(
                title,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),

              const SizedBox(height: 4),

              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 11.5,
                  color: isDark ? Colors.white54 : Colors.black54,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
