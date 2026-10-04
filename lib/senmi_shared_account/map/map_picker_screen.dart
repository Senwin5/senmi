// ignore_for_file: use_build_context_synchronously

import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_places_flutter/model/prediction.dart';
import 'package:google_places_flutter/google_places_flutter.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' as maps;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

class MapPickerScreen extends StatefulWidget {
  final maps.LatLng initialLocation;
  final bool useCurrentLocation;

  const MapPickerScreen({
    super.key,
    required this.initialLocation,
    this.useCurrentLocation = false,
  });

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
  final FocusNode searchFocusNode = FocusNode();

  maps.GoogleMapController? mapController;

  Timer? _debounce;

  List<Prediction> predictions = [];

  // ---------------- RECENT LOCATIONS ----------------
  List<Map<String, dynamic>> recentLocations = [];

  static const String _recentLocationsKey = "recent_locations";

  final String apiKey = "AIzaSyANfJatY_6y8gzmUrvV2_n2aR9ms7Xe_ZY";

  @override
  void initState() {
    super.initState();

    position = widget.initialLocation;

    searchFocusNode.addListener(() {
      if (mounted) {
        setState(() {});
      }
    });

    _loadRecentLocations();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!widget.useCurrentLocation) {
        await getAddress();
      }
    });
  }

  @override
  void dispose() {
    searchController.dispose();
    searchFocusNode.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  // ---------------- RECENT LOCATIONS ----------------

  Future<void> _loadRecentLocations() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final saved = prefs.getStringList(_recentLocationsKey);

      if (saved == null) return;

      final loaded = saved
          .map((item) => Map<String, dynamic>.from(jsonDecode(item)))
          .toList();

      if (!mounted) return;

      setState(() {
        recentLocations = loaded;
      });
    } catch (e) {
      // Ignore corrupted recent-location data.
    }
  }

  Future<void> _saveRecentLocation() async {
    final cleanAddress = address.trim();

    if (cleanAddress.isEmpty || cleanAddress == "Go to address") {
      return;
    }

    try {
      final prefs = await SharedPreferences.getInstance();

      final newLocation = <String, dynamic>{
        "address": cleanAddress,
        "latitude": position.latitude,
        "longitude": position.longitude,
      };

      // Remove an existing copy of the same address.
      recentLocations.removeWhere(
        (item) =>
            item["address"]?.toString().toLowerCase() ==
            cleanAddress.toLowerCase(),
      );

      // Put newest location at the top.
      recentLocations.insert(0, newLocation);

      // Keep only the 10 most recent locations.
      if (recentLocations.length > 10) {
        recentLocations = recentLocations.sublist(0, 10);
      }

      final encoded = recentLocations.map((item) => jsonEncode(item)).toList();

      await prefs.setStringList(_recentLocationsKey, encoded);
    } catch (e) {
      // Ignore storage errors.
    }
  }

  Future<void> _selectRecentLocation(
    Map<String, dynamic> recentLocation,
  ) async {
    try {
      final latitude = (recentLocation["latitude"] as num).toDouble();
      final longitude = (recentLocation["longitude"] as num).toDouble();

      final newPos = maps.LatLng(latitude, longitude);

      setState(() {
        position = newPos;
        address = recentLocation["address"]?.toString() ?? "Go to address";
      });

      searchController.text = address;

      searchController.selection = TextSelection.fromPosition(
        TextPosition(offset: searchController.text.length),
      );

      searchFocusNode.unfocus();

      await mapController?.animateCamera(maps.CameraUpdate.newLatLng(newPos));
    } catch (e) {
      // Ignore invalid recent-location data.
    }
  }

  // ---------------- ADDRESS HELPERS ----------------

  bool _isPlusCode(String value) {
    final text = value.trim();

    return RegExp(
      r'^[23456789CFGHJMPQRVWX]{4,8}\+[23456789CFGHJMPQRVWX]{2,}',
      caseSensitive: false,
    ).hasMatch(text);
  }

  String _getComponent(List<dynamic> components, List<String> types) {
    for (final component in components) {
      final componentTypes = List<String>.from(component["types"] ?? []);

      for (final type in types) {
        if (componentTypes.contains(type)) {
          return component["long_name"]?.toString().trim() ?? "";
        }
      }
    }

    return "";
  }

  String _buildFullAddress(Map<String, dynamic> result) {
    final components = result["address_components"] as List<dynamic>? ?? [];

    final streetNumber = _getComponent(components, ["street_number"]);

    final route = _getComponent(components, ["route"]);

    final premise = _getComponent(components, ["premise"]);

    final subPremise = _getComponent(components, ["subpremise"]);

    final neighborhood = _getComponent(components, [
      "neighborhood",
      "sublocality_level_1",
      "sublocality",
    ]);

    final locality = _getComponent(components, ["locality", "postal_town"]);

    final state = _getComponent(components, ["administrative_area_level_1"]);

    final country = _getComponent(components, ["country"]);

    final parts = <String>[];

    // Street number + street name.
    if (streetNumber.isNotEmpty && route.isNotEmpty) {
      parts.add("$streetNumber $route");
    } else if (route.isNotEmpty) {
      parts.add(route);
    }

    // Building/premise.
    if (premise.isNotEmpty &&
        !parts.any((item) => item.toLowerCase() == premise.toLowerCase())) {
      parts.add(premise);
    }

    // Apartment/sub-premise.
    if (subPremise.isNotEmpty &&
        !parts.any((item) => item.toLowerCase() == subPremise.toLowerCase())) {
      parts.add(subPremise);
    }

    // Neighborhood / area.
    if (neighborhood.isNotEmpty &&
        !parts.any(
          (item) => item.toLowerCase() == neighborhood.toLowerCase(),
        )) {
      parts.add(neighborhood);
    }

    // City.
    if (locality.isNotEmpty &&
        !parts.any((item) => item.toLowerCase() == locality.toLowerCase())) {
      parts.add(locality);
    }

    // State.
    if (state.isNotEmpty &&
        !parts.any((item) => item.toLowerCase() == state.toLowerCase())) {
      parts.add(state);
    }

    // Country.
    if (country.isNotEmpty &&
        !parts.any((item) => item.toLowerCase() == country.toLowerCase())) {
      parts.add(country);
    }

    return parts.join(", ");
  }

  // ---------------- ADDRESS ----------------

  Future<void> getAddress() async {
    if (!mounted) return;

    try {
      setState(() => loadingAddress = true);

      final url = Uri.parse(
        "https://maps.googleapis.com/maps/api/geocode/json"
        "?latlng=${position.latitude},${position.longitude}"
        "&key=$apiKey"
        "&language=en"
        "&region=ng",
      );

      final response = await http.get(url);

      if (response.statusCode != 200) {
        throw Exception("Google Geocoding request failed");
      }

      final data = jsonDecode(response.body);

      if (data["status"] != "OK") {
        throw Exception(
          data["error_message"]?.toString() ??
              "Google could not find this address",
        );
      }

      final results = data["results"] as List<dynamic>? ?? [];

      if (results.isEmpty) {
        throw Exception("No address found");
      }

      String? fullAddress;

      // First look for a detailed street-level result.
      for (final result in results) {
        final resultMap = Map<String, dynamic>.from(result);

        final types = List<String>.from(resultMap["types"] ?? []);

        final formattedAddress =
            resultMap["formatted_address"]?.toString().trim() ?? "";

        if (formattedAddress.isEmpty) {
          continue;
        }

        if (_isPlusCode(formattedAddress)) {
          continue;
        }

        if (types.contains("street_address") ||
            types.contains("premise") ||
            types.contains("subpremise") ||
            types.contains("route")) {
          final builtAddress = _buildFullAddress(resultMap);

          if (builtAddress.isNotEmpty && !_isPlusCode(builtAddress)) {
            fullAddress = builtAddress;
            break;
          }

          fullAddress = formattedAddress;
          break;
        }
      }

      // If a street-level address wasn't found, inspect all results.
      if (fullAddress == null) {
        for (final result in results) {
          final resultMap = Map<String, dynamic>.from(result);

          final formattedAddress =
              resultMap["formatted_address"]?.toString().trim() ?? "";

          if (formattedAddress.isEmpty) {
            continue;
          }

          if (_isPlusCode(formattedAddress)) {
            continue;
          }

          final builtAddress = _buildFullAddress(resultMap);

          if (builtAddress.isNotEmpty && !_isPlusCode(builtAddress)) {
            fullAddress = builtAddress;
            break;
          }

          fullAddress = formattedAddress;
          break;
        }
      }

      // Final fallback.
      if (fullAddress == null || fullAddress.trim().isEmpty) {
        fullAddress = "Address unavailable";
      }

      if (!mounted) return;

      setState(() {
        address = fullAddress!;
        loadingAddress = false;
      });
    } catch (e) {
      if (!mounted) return;

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

      // ignore: duplicate_ignore
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.location_off_rounded, color: Colors.white),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  "Location not found",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          backgroundColor: Colors.deepPurple,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          duration: const Duration(seconds: 3),
        ),
      );
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
        const SnackBar(
          content: Text("⚠️ Could not get location"),
          backgroundColor: Colors.deepPurple,
        ),
      );
    }
  }

  // ---------------- UI ----------------

  @override
  Widget build(BuildContext context) {
    final showRecentLocations =
        searchFocusNode.hasFocus &&
        searchController.text.trim().isEmpty &&
        recentLocations.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        surfaceTintColor: Colors.white,
        centerTitle: false,
        title: const Text(
          "Waypoint",
          style: TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
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

            onMapCreated: (c) async {
              mapController = c;

              if (widget.useCurrentLocation) {
                await useMyLocation();
              }
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
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: GooglePlaceAutoCompleteTextField(
                    textEditingController: searchController,
                    googleAPIKey: apiKey,
                    debounceTime: 500,
                    countries: const ["ng"],
                    isLatLngRequired: false,

                    boxDecoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),

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
                            color: Colors.white,
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.location_on,
                                  color: Colors.black87,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    prediction.description ?? "",
                                    style: const TextStyle(color: Colors.black),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },

                    seperatedBuilder: const Divider(
                      color: Color(0xFFE5E7EB),
                      height: 1,
                    ),

                    isCrossBtnShown: true,

                    inputDecoration: const InputDecoration(
                      hintText: "Search location...",
                      border: InputBorder.none,
                      prefixIcon: Icon(Icons.search, color: Colors.black87),
                    ),

                    focusNode: searchFocusNode,
                  ),
                ),

                // ---------------- RECENT LOCATIONS ----------------
                if (showRecentLocations)
                  Container(
                    margin: const EdgeInsets.only(top: 4),
                    constraints: const BoxConstraints(maxHeight: 350),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: const [
                        BoxShadow(
                          blurRadius: 8,
                          offset: Offset(0, 3),
                          color: Colors.black26,
                        ),
                      ],
                    ),
                    child: ListView.separated(
                      shrinkWrap: true,
                      padding: EdgeInsets.zero,
                      itemCount: recentLocations.length,
                      separatorBuilder: (context, index) {
                        return const Divider(height: 1);
                      },
                      itemBuilder: (context, index) {
                        final recent = recentLocations[index];

                        final recentAddress =
                            recent["address"]?.toString() ?? "";

                        return ListTile(
                          dense: true,
                          leading: const Icon(
                            Icons.history,
                            color: Colors.grey,
                          ),
                          title: Text(
                            recentAddress,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          onTap: () {
                            _selectRecentLocation(recent);
                          },
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),

          Positioned(
            top: 80,
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
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 20,
                    offset: Offset(0, -4),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  loadingAddress
                      ? const LinearProgressIndicator()
                      : Text(
                          address,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Theme.of(context).textTheme.bodyLarge?.color,
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                          ),
                        ),

                  const SizedBox(height: 10),

                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: () async {
                        await _saveRecentLocation();

                        if (!mounted) return;

                        Navigator.pop(context, position);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF581C87),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Text(
                        "Confirm Location",
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
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
