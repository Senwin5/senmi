// ignore_for_file: deprecated_member_use, use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:senmi/main.dart';
import 'package:senmi/senmi_ride_screen/ride_features/customers/ride_tracking_screen.dart';
import 'package:senmi/services/api_service.dart';
import 'package:senmi/senmi_shared_account/customer_profiles/account_profile_screen.dart';
import 'package:senmi/senmi_shared_account/map/map_picker_screen.dart';
import 'package:senmi/services/ride_driver_service.dart';

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

  // ============================================================
  // FARE STATE
  // ============================================================

  double? estimatedFare;
  double? estimatedDistanceKm;
  int? estimatedDurationMinutes;

  bool calculatingFare = false;
  String fareError = "";

  static const LatLng defaultLagosLocation = LatLng(6.5244, 3.3792);

  // ============================================================
  // GET RIDE FARE QUOTE
  // ============================================================

  Future<Map<String, dynamic>> _getRideFareQuote() async {
    if (pickupLocation == null || destinationLocation == null) {
      throw Exception("Select pickup and destination first.");
    }

    final token = ApiService.token;

    if (token == null || token.isEmpty) {
      throw Exception("Your session has expired. Please log in again.");
    }

    return RideService.getFareQuote(
      pickupLat: pickupLocation!.latitude,
      pickupLng: pickupLocation!.longitude,
      destinationLat: destinationLocation!.latitude,
      destinationLng: destinationLocation!.longitude,
      serviceType: selectedRideType,
    );
  }

  // ============================================================
  // CALCULATE FARE
  // ============================================================

  Future<void> _calculateFare() async {
    if (!locationsSelected) {
      return;
    }

    if (mounted) {
      setState(() {
        calculatingFare = true;
        fareError = "";
      });
    }

    try {
      final data = await _getRideFareQuote();

      final fareValue = double.tryParse(data["fare"]?.toString() ?? "");

      final distanceValue = double.tryParse(
        data["estimated_distance_km"]?.toString() ?? "",
      );

      final durationValue = int.tryParse(
        data["estimated_duration_minutes"]?.toString() ?? "",
      );

      if (!mounted) return;

      if (fareValue == null) {
        throw Exception("Invalid fare returned by the server.");
      }

      setState(() {
        estimatedFare = fareValue;
        estimatedDistanceKm = distanceValue;
        estimatedDurationMinutes = durationValue;
        fareError = "";
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        estimatedFare = null;
        estimatedDistanceKm = null;
        estimatedDurationMinutes = null;
        fareError = e.toString().replaceFirst("Exception: ", "");
      });
    } finally {
      if (mounted) {
        setState(() {
          calculatingFare = false;
        });
      }
    }
  }

  // ============================================================
  // REQUEST RIDE
  // ============================================================

  Future<void> _requestRide() async {
    if (!locationsSelected ||
        estimatedFare == null ||
        estimatedDistanceKm == null ||
        estimatedDurationMinutes == null) {
      return;
    }

    final token = ApiService.token;

    if (token == null || token.isEmpty) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Your session has expired. Please log in again."),
          backgroundColor: Colors.redAccent,
        ),
      );

      return;
    }

    setState(() {
      calculatingFare = true;
    });

    try {
      final data = await RideService.createRideRequest(
        pickupAddress: pickupAddress,
        destinationAddress: destinationAddress,
        pickupLat: pickupLocation!.latitude,
        pickupLng: pickupLocation!.longitude,
        destinationLat: destinationLocation!.latitude,
        destinationLng: destinationLocation!.longitude,
        estimatedDistanceKm: estimatedDistanceKm!,
        estimatedDurationMinutes: estimatedDurationMinutes!,
        serviceType: selectedRideType,
        paymentMethod: "cash",
      );

      if (!mounted) return;

      final rideId = data["ride_id"]?.toString() ?? "";

      if (rideId.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Ride was created, but no ride ID was returned."),
            backgroundColor: Colors.redAccent,
          ),
        );

        return;
      }

      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => RideTrackingScreen(rideId: rideId)),
      );
    } catch (e) {
      if (!mounted) return;

      final message = e.toString().replaceFirst("Exception: ", "");

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message.isEmpty ? "Unable to request ride." : message),
          backgroundColor: Colors.redAccent,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          calculatingFare = false;
        });
      }
    }
  }

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
    } catch (_) {
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
          builder: (_) => RideMapPicker(
            initialLocation: startingLocation,
            useCurrentLocation: isPickup,
            selectionType: isPickup ? "Pickup" : "Destination",
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

          if (destinationLocation != null) {
            estimatedFare = null;
            estimatedDistanceKm = null;
            estimatedDurationMinutes = null;
            fareError = "";
          }
        } else {
          destinationLocation = selected;
          destinationAddress = address;
        }
      });

      // =========================================================
      // AFTER PICKUP
      // AUTOMATICALLY OPEN DESTINATION
      // =========================================================

      if (isPickup && mounted) {
        await _pickLocation(isPickup: false);
      }

      // =========================================================
      // CALCULATE FARE
      // =========================================================

      if (!isPickup &&
          pickupLocation != null &&
          destinationLocation != null &&
          mounted) {
        await _calculateFare();
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

      destinationLocation = null;
      destinationAddress = "";

      estimatedFare = null;
      estimatedDistanceKm = null;
      estimatedDurationMinutes = null;

      fareError = "";
    });
  }

  void _clearDestination() {
    setState(() {
      destinationLocation = null;
      destinationAddress = "";

      estimatedFare = null;
      estimatedDistanceKm = null;
      estimatedDurationMinutes = null;

      fareError = "";
    });
  }

  // ============================================================
  // RIDE READY
  // ============================================================

  bool get locationsSelected {
    return pickupLocation != null && destinationLocation != null;
  }

  // ============================================================
  // FARE FORMAT
  // ============================================================

  String _formatFare(double? value) {
    if (value == null) {
      return "—";
    }

    return "₦${value.toStringAsFixed(0)}";
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,

      body: SafeArea(
        child: Column(
          children: [
            // ==================================================
            // TOP BAR
            // ==================================================
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 8),
              child: Row(
                children: [
                  _TopIconButton(
                    icon: Icons.arrow_back_rounded,
                    onTap: () {
                      Navigator.of(context).pop();
                    },
                  ),

                  const SizedBox(width: 14),

                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Ride",
                          style: TextStyle(
                            fontSize: 21,
                            fontWeight: FontWeight.w800,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          "Where are you going?",
                          style: TextStyle(
                            fontSize: 12.5,
                            color: isDark ? Colors.white54 : Colors.black54,
                          ),
                        ),
                      ],
                    ),
                  ),

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
            // CONTENT
            // ==================================================
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ==================================================
                    // LOCATION CARD
                    // ==================================================
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E1E22) : Colors.white,
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(
                          color: isDark
                              ? Colors.white.withOpacity(0.07)
                              : Colors.black.withOpacity(0.06),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(
                              isDark ? 0.12 : 0.04,
                            ),
                            blurRadius: 14,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          _LocationField(
                            icon: Icons.my_location_rounded,
                            iconColor: Colors.green,
                            title: "Pickup",
                            value: pickupAddress.isEmpty
                                ? "Choose pickup location"
                                : pickupAddress,
                            isDark: isDark,
                            loading: selectingPickup,
                            hasLocation: pickupLocation != null,
                            onTap: () {
                              _pickLocation(isPickup: true);
                            },
                            onClear: pickupLocation != null
                                ? _clearPickup
                                : null,
                          ),

                          Padding(
                            padding: const EdgeInsets.only(left: 24),
                            child: Row(
                              children: [
                                Container(
                                  width: 2,
                                  height: 20,
                                  color: isDark
                                      ? Colors.white12
                                      : Colors.black12,
                                ),
                              ],
                            ),
                          ),

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
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // ==================================================
                    // RIDE TYPE
                    // ==================================================
                    Text(
                      "Choose your ride",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),

                    const SizedBox(height: 5),

                    Text(
                      "Pick the option that works for you.",
                      style: TextStyle(
                        fontSize: 12.5,
                        color: isDark ? Colors.white54 : Colors.black54,
                      ),
                    ),

                    const SizedBox(height: 14),

                    Row(
                      children: [
                        Expanded(
                          child: _RideTypeCard(
                            title: "Basic",
                            subtitle: "Everyday ride",
                            icon: Icons.directions_car_outlined,
                            selected: selectedRideType == "basic",
                            isDark: isDark,
                            onTap: () async {
                              if (selectedRideType == "basic") {
                                return;
                              }

                              setState(() {
                                selectedRideType = "basic";
                              });

                              if (locationsSelected) {
                                await _calculateFare();
                              }
                            },
                          ),
                        ),

                        const SizedBox(width: 10),

                        Expanded(
                          child: _RideTypeCard(
                            title: "Premium",
                            subtitle: "More comfort",
                            icon: Icons.star_outline_rounded,
                            selected: selectedRideType == "premium",
                            isDark: isDark,
                            onTap: () async {
                              if (selectedRideType == "premium") {
                                return;
                              }

                              setState(() {
                                selectedRideType = "premium";
                              });

                              if (locationsSelected) {
                                await _calculateFare();
                              }
                            },
                          ),
                        ),
                      ],
                    ),

                    // ==================================================
                    // FARE
                    // ==================================================
                    if (locationsSelected) ...[
                      const SizedBox(height: 20),

                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF1E1E22)
                              : const Color(0xFFF8F7FA),
                          borderRadius: BorderRadius.circular(20),
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
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        "Estimated fare",
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: isDark
                                              ? Colors.white54
                                              : Colors.black54,
                                        ),
                                      ),

                                      const SizedBox(height: 5),

                                      if (fareError.isNotEmpty)
                                        Text(
                                          fareError,
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: Colors.redAccent,
                                          ),
                                        )
                                      else
                                        Text(
                                          selectedRideType == "premium"
                                              ? "Premium ride"
                                              : "Basic ride",
                                          style: TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w700,
                                            color: isDark
                                                ? Colors.white
                                                : Colors.black87,
                                          ),
                                        ),
                                    ],
                                  ),
                                ),

                                if (calculatingFare)
                                  const SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.5,
                                      color: senmiRidePurple,
                                    ),
                                  )
                                else
                                  Text(
                                    _formatFare(estimatedFare),
                                    style: TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.w800,
                                      color: isDark
                                          ? Colors.white
                                          : senmiRidePurple,
                                    ),
                                  ),
                              ],
                            ),

                            if (estimatedDistanceKm != null ||
                                estimatedDurationMinutes != null) ...[
                              const SizedBox(height: 15),

                              Divider(
                                height: 1,
                                color: isDark ? Colors.white10 : Colors.black12,
                              ),

                              const SizedBox(height: 13),

                              Row(
                                children: [
                                  if (estimatedDistanceKm != null)
                                    Expanded(
                                      child: _FareInfo(
                                        icon: Icons.route_rounded,
                                        label:
                                            "${estimatedDistanceKm!.toStringAsFixed(2)} km",
                                        isDark: isDark,
                                      ),
                                    ),

                                  if (estimatedDistanceKm != null &&
                                      estimatedDurationMinutes != null)
                                    const SizedBox(width: 10),

                                  if (estimatedDurationMinutes != null)
                                    Expanded(
                                      child: _FareInfo(
                                        icon: Icons.schedule_rounded,
                                        label: "$estimatedDurationMinutes min",
                                        isDark: isDark,
                                      ),
                                    ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),

                      const SizedBox(height: 18),

                      // ==================================================
                      // REQUEST BUTTON
                      // ==================================================
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed:
                              estimatedFare != null &&
                                  estimatedDistanceKm != null &&
                                  estimatedDurationMinutes != null &&
                                  !calculatingFare
                              ? _requestRide
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

                              const SizedBox(width: 8),

                              Text(
                                estimatedFare != null
                                    ? "Request ${selectedRideType == "premium" ? "Premium" : "Basic"} Ride"
                                    : "Calculating fare...",
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],

                    const SizedBox(height: 18),

                    // ==================================================
                    // FOOTER
                    // ==================================================
                    Center(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.verified_user_outlined,
                            size: 14,
                            color: isDark ? Colors.white38 : Colors.black38,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            "Safe, reliable rides with Senmi",
                            style: TextStyle(
                              fontSize: 11,
                              color: isDark ? Colors.white38 : Colors.black38,
                            ),
                          ),
                        ],
                      ),
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
}

// ============================================================
// RIDE MAP PICKER
//
// This wraps the existing shared MapPickerScreen.
// MapPickerScreen itself is NOT changed.
// ============================================================

class RideMapPicker extends StatelessWidget {
  final LatLng initialLocation;
  final bool useCurrentLocation;
  final String selectionType;

  const RideMapPicker({
    super.key,
    required this.initialLocation,
    required this.useCurrentLocation,
    required this.selectionType,
  });

  @override
  Widget build(BuildContext context) {
    final isPickup = selectionType == "Pickup";

    return Stack(
      children: [
        MapPickerScreen(
          initialLocation: initialLocation,
          useCurrentLocation: useCurrentLocation,
        ),

        Positioned(
          left: 16,
          right: 16,
          bottom: 150,
          child: IgnorePointer(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor.withOpacity(0.96),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: isPickup
                      ? Colors.green.withOpacity(0.20)
                      : Colors.redAccent.withOpacity(0.20),
                ),
                boxShadow: const [
                  BoxShadow(
                    blurRadius: 15,
                    offset: Offset(0, 5),
                    color: Colors.black26,
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: isPickup
                          ? Colors.green.withOpacity(0.10)
                          : Colors.redAccent.withOpacity(0.10),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      isPickup
                          ? Icons.my_location_rounded
                          : Icons.location_on_rounded,
                      color: isPickup ? Colors.green : Colors.redAccent,
                      size: 21,
                    ),
                  ),

                  const SizedBox(width: 12),

                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isPickup ? "Choose Pickup" : "Choose Destination",
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: Theme.of(context).textTheme.bodyLarge?.color,
                          ),
                        ),

                        const SizedBox(height: 3),

                        Text(
                          isPickup
                              ? "Move the pin to where you want to be picked up."
                              : "Move the pin to where you want to go.",
                          style: TextStyle(
                            fontSize: 11.5,
                            height: 1.35,
                            color: Theme.of(
                              context,
                            ).textTheme.bodyMedium?.color?.withOpacity(0.60),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(width: 8),

                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: isPickup
                          ? Colors.green.withOpacity(0.10)
                          : Colors.redAccent.withOpacity(0.10),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      isPickup ? "1 of 2" : "2 of 2",
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: isPickup ? Colors.green : Colors.redAccent,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
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
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF25252A) : const Color(0xFFF9F8FA),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: hasLocation
                  ? senmiRidePurple
                  : isDark
                  ? Colors.white.withOpacity(0.06)
                  : Colors.black.withOpacity(0.05),
              width: hasLocation ? 1.2 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),

              const SizedBox(width: 11),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white54 : Colors.black54,
                      ),
                    ),

                    const SizedBox(height: 3),

                    if (loading)
                      Row(
                        children: [
                          const SizedBox(
                            width: 13,
                            height: 13,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: senmiRidePurple,
                            ),
                          ),
                          const SizedBox(width: 7),
                          Text(
                            "Opening map...",
                            style: TextStyle(
                              fontSize: 12.5,
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
                          fontSize: 13.5,
                          fontWeight: FontWeight.w600,
                          color: hasLocation
                              ? isDark
                                    ? Colors.white
                                    : Colors.black87
                              : isDark
                              ? Colors.white54
                              : Colors.black54,
                        ),
                      ),
                  ],
                ),
              ),

              if (hasLocation && onClear != null)
                IconButton(
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                  icon: Icon(
                    Icons.close_rounded,
                    size: 18,
                    color: isDark ? Colors.white38 : Colors.black38,
                  ),
                  onPressed: onClear,
                )
              else
                Icon(
                  Icons.chevron_right_rounded,
                  size: 20,
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
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: selected
                ? senmiRidePurple.withOpacity(0.08)
                : isDark
                ? const Color(0xFF1E1E22)
                : Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: selected
                  ? senmiRidePurple
                  : isDark
                  ? Colors.white.withOpacity(0.07)
                  : Colors.black.withOpacity(0.06),
              width: selected ? 1.3 : 1,
            ),
          ),
          child: Row(
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

              const SizedBox(width: 10),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),

                    const SizedBox(height: 3),

                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 10.5,
                        color: isDark ? Colors.white54 : Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),

              if (selected)
                const Icon(
                  Icons.check_circle_rounded,
                  color: senmiRidePurple,
                  size: 20,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================
// FARE INFO
// ============================================================

class _FareInfo extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isDark;

  const _FareInfo({
    required this.icon,
    required this.label,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withOpacity(0.04)
            : Colors.black.withOpacity(0.025),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: senmiRidePurple),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white70 : Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
