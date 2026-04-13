// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';

class MapPickerScreen extends StatefulWidget {
  final LatLng initialLocation;

  const MapPickerScreen({super.key, required this.initialLocation});

  @override
  State<MapPickerScreen> createState() => _MapPickerScreenState();
}

class _MapPickerScreenState extends State<MapPickerScreen> {
  late LatLng position;
  String address = "Go to address";
  bool loadingAddress = false;
  bool userMovedMap = false;
  bool isFirstLoad = true;

  final TextEditingController searchController = TextEditingController();
  GoogleMapController? mapController;

  @override
  void initState() {
    super.initState();
    position = widget.initialLocation;

    // 🔥 FORCE CLEAN START STATE (prevents Abuja/Lagos ghost address)
    address = "Go to address";
  }

  // ✅ CLEAN ADDRESS FETCH
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
          address = "Go to address";
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
      setState(() {
        address = "Go to address";
        loadingAddress = false;
      });
    }
  }

  // 🔍 SEARCH LOCATION (IMPROVED ERROR UI)
  Future<void> searchLocation(String value) async {
    if (value.isEmpty) return;

    try {
      List<Location> locations = await locationFromAddress(value);
      final loc = locations.first;

      final newPos = LatLng(loc.latitude, loc.longitude);

      setState(() => position = newPos);

      mapController?.animateCamera(CameraUpdate.newLatLng(newPos));

      getAddress();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("⚠️ Location not found. Try a different search."),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // 📍 CURRENT LOCATION (OPTIONAL BUT CLEAN)
  Future<void> useMyLocation() async {
    try {
      final permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("⚠️ Location permission required"),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      final pos = await Geolocator.getCurrentPosition();

      final newPos = LatLng(pos.latitude, pos.longitude);

      setState(() {
        position = newPos;
        userMovedMap = true;
      });

      mapController?.animateCamera(CameraUpdate.newLatLng(newPos));

      getAddress();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("⚠️ Could not get current location"),
          backgroundColor: Colors.red,
        ),
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
            initialCameraPosition: CameraPosition(target: position, zoom: 14),
            onMapCreated: (c) => mapController = c,

            // 📍 track movement
            onCameraMove: (pos) {
              position = pos.target;
              userMovedMap = true;
            },

            // 🔥 FIX: prevent default auto-fetch on first load
            onCameraIdle: () {
              if (isFirstLoad) {
                isFirstLoad = false;
                return;
              }

              if (userMovedMap) {
                getAddress();
                userMovedMap = false;
              }
            },
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

          // 📍 CURRENT LOCATION BUTTON
          Positioned(
            bottom: 120,
            right: 16,
            child: FloatingActionButton(
              heroTag: "loc",
              onPressed: useMyLocation,
              child: const Icon(Icons.my_location),
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
                            style: TextStyle(
                              color: address == "Go to address"
                                  ? Colors.grey
                                  : Colors.black,
                            ),
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