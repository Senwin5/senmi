// ignore_for_file: use_build_context_synchronously

import 'dart:async';
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

  Future<void> _refreshMap() async {
    setState(() {
      position = widget.initialLocation;
      address = "Go to address";
      loadingAddress = false;
      userMovedMap = false;
      isFirstLoad = true;
    });

    await mapController?.animateCamera(CameraUpdate.newLatLng(position));

    await getAddress();
  }

  final TextEditingController searchController = TextEditingController();
  GoogleMapController? mapController;

  Timer? _debounce;

  bool isAutoSearching = false;

  @override
  void initState() {
    super.initState();
    position = widget.initialLocation;
    address = "Go to address";
  }

  @override
  void dispose() {
    searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

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

  Future<void> searchLocation(String value) async {
    final query = value.trim();

    if (query.isEmpty) return;

    try {
      isAutoSearching = true;

      List<Location> locations = await locationFromAddress(query);

      if (locations.isEmpty) {
        isAutoSearching = false;
        return;
      }

      final loc = locations.first;

      final newPos = LatLng(loc.latitude, loc.longitude);

      setState(() => position = newPos);

      await mapController?.animateCamera(CameraUpdate.newLatLng(newPos));

      await getAddress();

      isAutoSearching = false;
    } catch (e) {
      isAutoSearching = false;

      if (query.length > 5) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("⚠️ Location not found. Try a different search."),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

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

      await mapController?.animateCamera(CameraUpdate.newLatLng(newPos));

      await getAddress();
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
      backgroundColor: Theme.of(context).colorScheme.surface,

      appBar: AppBar(
        title: const Text("Pick Location"),
        backgroundColor: Theme.of(context).colorScheme.surface,
        foregroundColor: Theme.of(context).colorScheme.onSurface,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () async {
              await _refreshMap();

              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text("Map refreshed")));
            },
          ),
        ],
      ),

      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(target: position, zoom: 14),
            onMapCreated: (c) => mapController = c,

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
            child: Icon(Icons.location_pin, size: 45, color: Colors.red),
          ),

          Positioned(
            top: 10,
            left: 10,
            right: 10,
            child: Card(
              color: Theme.of(context).colorScheme.surface,
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: searchController,
                      decoration: InputDecoration(
                        hintText: "Search location...",
                        border: InputBorder.none,
                        prefixIcon: const Icon(Icons.search),
                        hintStyle: TextStyle(
                          color: Theme.of(context).hintColor,
                        ),
                      ),

                      onChanged: (value) {
                        if (isAutoSearching) return;

                        if (_debounce?.isActive ?? false) {
                          _debounce!.cancel();
                        }

                        final query = value.trim();

                        if (query.length < 4) return;

                        _debounce = Timer(
                          const Duration(milliseconds: 900),
                          () {
                            searchLocation(query);
                          },
                        );
                      },

                      onSubmitted: searchLocation,
                    ),
                  ),

                  IconButton(
                    icon: const Icon(Icons.send),
                    onPressed: () {
                      final value = searchController.text.trim();

                      if (value.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text("Type a location first"),
                          ),
                        );
                        return;
                      }

                      searchLocation(value);
                    },
                  ),
                ],
              ),
            ),
          ),

          Positioned(
            bottom: 120,
            right: 16,
            child: FloatingActionButton(
              heroTag: "loc",
              onPressed: useMyLocation,
              child: const Icon(Icons.my_location),
            ),
          ),

          Positioned(
            bottom: 20,
            left: 16,
            right: 16,
            child: Card(
              color: Theme.of(context).colorScheme.surface,
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
                              color: Theme.of(context).colorScheme.onSurface,
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
