// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geocoding/geocoding.dart';

class MapPickerScreen extends StatefulWidget {
  final LatLng initialLocation;

  const MapPickerScreen({
    super.key,
    required this.initialLocation,
  });

  @override
  State<MapPickerScreen> createState() => _MapPickerScreenState();
}

class _MapPickerScreenState extends State<MapPickerScreen> {
  late LatLng position;
  String address = "Move map to get address";
  bool loadingAddress = false;

  final TextEditingController searchController = TextEditingController();
  GoogleMapController? mapController;

  @override
  void initState() {
    super.initState();
    position = widget.initialLocation;

    // ❌ DO NOT auto-fetch address (prevents Abuja default issue)
  }

  // ✅ CLEAN & SAFE GET ADDRESS
  Future<void> getAddress() async {
    if (!mounted) return;

    try {
      setState(() => loadingAddress = true);

      final placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (!mounted) return;

      if (placemarks.isEmpty) {
        setState(() {
          address = "Move map to get address";
          loadingAddress = false;
        });
        return;
      }

      final place = placemarks.first;

      setState(() {
        address =
            "${place.name ?? ''}, ${place.street ?? ''}, ${place.locality ?? ''}, ${place.country ?? ''}";
        loadingAddress = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        address = "Move map to get address";
        loadingAddress = false;
      });
    }
  }

  // 🔍 SEARCH LOCATION
  Future<void> searchLocation(String value) async {
    if (value.isEmpty) return;

    try {
      List<Location> locations = await locationFromAddress(value);
      final loc = locations.first;

      final newPos = LatLng(loc.latitude, loc.longitude);

      setState(() => position = newPos);

      mapController?.animateCamera(
        CameraUpdate.newLatLng(newPos),
      );

      getAddress();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Location not found")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Pick Location")),

      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: position,
              zoom: 14,
            ),
            onMapCreated: (c) => mapController = c,

            // 📍 track movement
            onCameraMove: (pos) => position = pos.target,

            // 🔥 only fetch when user stops moving
            onCameraIdle: getAddress,
          ),

          const Center(
            child: Icon(Icons.location_pin, size: 45, color: Colors.red),
          ),

          // 🔍 SEARCH BAR
          Positioned(
            top: 10,
            left: 10,
            right: 10,
            child: Card(
              child: TextField(
                controller: searchController,
                decoration: const InputDecoration(
                  hintText: "Search location...",
                  border: InputBorder.none,
                  prefixIcon: Icon(Icons.search),
                ),
                onSubmitted: searchLocation,
              ),
            ),
          ),

          // 📍 BOTTOM CARD
          Positioned(
            bottom: 20,
            left: 16,
            right: 16,
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    loadingAddress
                        ? const LinearProgressIndicator()
                        : Text(
                            address,
                            textAlign: TextAlign.center,
                          ),

                    const SizedBox(height: 10),

                    ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context, position);
                      },
                      child: const Text("Confirm Location"),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}