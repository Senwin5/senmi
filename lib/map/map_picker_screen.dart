import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geocoding/geocoding.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {

  // 📍 Default position (Lagos)
  LatLng position = const LatLng(6.5244, 3.3792);

  // 🏠 Address text
  String address = "Move map to select location";

  // 🔄 Convert lat/lng → real address
  Future<void> getAddress() async {
    try {
      List<Placemark> placemarks =
          await placemarkFromCoordinates(
              position.latitude, position.longitude);

      final place = placemarks.first;

      setState(() {
        address =
            "${place.street}, ${place.locality}, ${place.country}";
      });

    } catch (e) {
      address = "Unable to get address";
    }
  }

  @override
  void initState() {
    super.initState();

    // 📍 Get address when screen loads
    getAddress();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Pick Location")),

      body: Stack(
        children: [

          // 🗺️ MAP
          GoogleMap(
            initialCameraPosition:
                CameraPosition(target: position, zoom: 14),

            // 👇 when user moves map
            onCameraMove: (pos) {
              position = pos.target;
            },

            // 👇 when user stops moving
            onCameraIdle: () {
              getAddress(); // update address
            },
          ),

          // 📍 CENTER PIN
          const Center(
            child: Icon(Icons.location_pin,
                size: 40, color: Colors.red),
          ),

          // 📦 BOTTOM CARD
          Positioned(
            bottom: 20,
            left: 20,
            right: 20,
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [

                    // 🏠 SHOW ADDRESS
                    Text(
                      address,
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: 10),

                    // ✅ CONFIRM BUTTON
                    ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context, {
                          "address": address, // ✅ real address
                          "lat": position.latitude,
                          "lng": position.longitude,
                        });
                      },
                      child: const Text("Confirm Location"),
                    )
                  ],
                ),
              ),
            ),
          )
        ],
      ),
    );
  }
}