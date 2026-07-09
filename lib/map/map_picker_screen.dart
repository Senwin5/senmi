// ignore_for_file: use_build_context_synchronously

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_places_flutter/model/prediction.dart';
import 'package:google_places_flutter/google_places_flutter.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' as maps;

class MapPickerScreen extends StatefulWidget {
  final maps.LatLng initialLocation;

  const MapPickerScreen({super.key, required this.initialLocation});

  @override
  State<MapPickerScreen> createState() => _MapPickerScreenState();
}

class _MapPickerScreenState extends State<MapPickerScreen> {
  late maps.LatLng position;

  String address = "Go to address";
  bool loadingAddress = false;
  bool userMovedMap = false;
  bool isFirstLoad = true;
  bool isAutoSearching = false;

  final TextEditingController searchController = TextEditingController();
  maps.GoogleMapController? mapController;

  Timer? _debounce;

  List<Prediction> predictions = [];

  final String apiKey = "AIzaSyANfJatY_6y8gzmUrvV2_n2aR9ms7Xe_ZY";

  @override
  void initState() {
    super.initState();

    position = widget.initialLocation;

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (position.latitude == 0 && position.longitude == 0) {
        await useMyLocation();
      } else {
        await getAddress();
      }
    });
  }

  @override
  void dispose() {
    searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  // ---------------- ADDRESS ----------------
  Future<void> getAddress() async {
    if (!mounted) return;

    try {
      setState(() => loadingAddress = true);

      final placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isEmpty) return;

      final place = placemarks.first;

      final parts = <String>[];

      if (place.street?.isNotEmpty == true) parts.add(place.street!);
      if (place.locality?.isNotEmpty == true) parts.add(place.locality!);
      if (place.country?.isNotEmpty == true) parts.add(place.country!);

      setState(() {
        address = parts.join(", ");
        loadingAddress = false;
      });
    } catch (e) {
      setState(() {
        address = "Go to address";
        loadingAddress = false;
      });
    }
  }

  // ---------------- SEARCH LOCATION ----------------
  Future<void> searchLocation(String value) async {
    final query = value.trim();
    if (query.isEmpty) return;

    try {
      isAutoSearching = true;

      List<Location> locations = await locationFromAddress(query);

      if (locations.isEmpty) return;

      final loc = locations.first;

      final newPos = maps.LatLng(loc.latitude, loc.longitude);

      setState(() => position = newPos);

      await mapController?.animateCamera(maps.CameraUpdate.newLatLng(newPos));

      await getAddress();

      isAutoSearching = false;
    } catch (e) {
      isAutoSearching = false;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("⚠️ Location not found")));
    }
  }

  // ---------------- LOCATION ----------------
  Future<void> useMyLocation() async {
    try {
      final permission = await Geolocator.requestPermission();

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return;
      }

      final pos = await Geolocator.getCurrentPosition(
        // ignore: deprecated_member_use
        desiredAccuracy: LocationAccuracy.high,
      );

      final newPos = maps.LatLng(pos.latitude, pos.longitude);

      setState(() => position = newPos);

      await mapController?.animateCamera(maps.CameraUpdate.newLatLng(newPos));

      await getAddress();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("⚠️ Could not get location")),
      );
    }
  }

  // ---------------- UI ----------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Waypoint")),
      body: Stack(
        children: [
          maps.GoogleMap(
            initialCameraPosition: maps.CameraPosition(
              target: position,
              zoom: 14,
            ),

            // ADDED ONLY
            myLocationEnabled: true,
            myLocationButtonEnabled: false,

            // CHANGED ONLY THIS PART
            onMapCreated: (c) {
              mapController = c;
            },

            onCameraMove: (pos) {
              position = pos.target;
              userMovedMap = true;
            },

            onCameraIdle: () {
              if (isFirstLoad) {
                isFirstLoad = false;
                return;
              }

              if (userMovedMap && !isAutoSearching) {
                getAddress();
                userMovedMap = false;
              }
            },
          ),

          const Center(
            child: Icon(Icons.location_pin, size: 50, color: Colors.red),
          ),

          // ---------------- SEARCH ----------------
          Positioned(
            top: 12,
            left: 16,
            right: 16,
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: GooglePlaceAutoCompleteTextField(
                    textEditingController: searchController,
                    googleAPIKey: apiKey,
                    debounceTime: 500,
                    countries: const ["ng"],
                    isLatLngRequired: false,

                    getPlaceDetailWithLatLng: (prediction) {},

                    itemClick: (Prediction prediction) async {
                      searchController.text = prediction.description ?? "";

                      searchController.selection = TextSelection.fromPosition(
                        TextPosition(offset: searchController.text.length),
                      );

                      await searchLocation(prediction.description ?? "");
                    },

                    itemBuilder:
                        (
                          BuildContext context,
                          int index,
                          Prediction prediction,
                        ) {
                          return Container(
                            padding: const EdgeInsets.all(10),
                            child: Row(
                              children: [
                                const Icon(Icons.location_on),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(prediction.description ?? ""),
                                ),
                              ],
                            ),
                          );
                        },

                    seperatedBuilder: const Divider(),

                    isCrossBtnShown: true,

                    inputDecoration: const InputDecoration(
                      hintText: "Search location...",
                      border: InputBorder.none,
                      prefixIcon: Icon(Icons.search),
                    ),
                  ),
                ),
              ],
            ),
          ),

          Positioned(
            bottom: 120,
            right: 16,
            child: FloatingActionButton(
              onPressed: useMyLocation,
              child: const Icon(Icons.my_location),
            ),
          ),

          Positioned(
            bottom: 20,
            left: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  loadingAddress
                      ? const LinearProgressIndicator()
                      : Text(address, textAlign: TextAlign.center),

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
        ],
      ),
    );
  }
}
