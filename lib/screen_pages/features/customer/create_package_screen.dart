// ignore_for_file: use_build_context_synchronously

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:senmi/screen_pages/features/customer/create_package_details.dart';
import 'package:senmi/services/api_service.dart';
import 'package:http/http.dart' as http;

class CreatePackageScreen extends StatefulWidget {
  const CreatePackageScreen({super.key});

  @override
  State<CreatePackageScreen> createState() => _CreatePackageScreenState();
}

class _CreatePackageScreenState extends State<CreatePackageScreen> {
  final _formKey = GlobalKey<FormState>();

  String senderName = '';
  String senderPhone = '';
  String receiverName = '';
  String receiverPhone = '';
  String description = '';
  String pickupAddress = '';
  String deliveryAddress = '';

  LatLng? pickupLocation;
  LatLng? deliveryLocation;

  bool loading = false;

  Future<void> _createPackage() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    if (pickupLocation == null || deliveryLocation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "⚠️ Please select pickup and delivery locations on the map.",
          ),
        ),
      );
      return;
    }

    setState(() => loading = true);

    try {
      /// ==============================
      /// ONLY BACKEND REQUIRED FIELDS
      /// ==============================
      final payload = {
        'description': description.trim(),
        'pickup_address': pickupAddress.trim(),
        'delivery_address': deliveryAddress.trim(),
        'receiver_name': receiverName.trim(),
        'receiver_phone': receiverPhone.trim(),

        'pickup_lat': pickupLocation!.latitude,
        'pickup_lng': pickupLocation!.longitude,
        'delivery_lat': deliveryLocation!.latitude,
        'delivery_lng': deliveryLocation!.longitude,
      };

      debugPrint("📦 Creating package with payload: $payload");

      final packageId = await ApiService.createPackage(payload);

      debugPrint("📦 FULL RESPONSE: $packageId");

      if (packageId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("❌ Package creation failed")),
        );
      }

      debugPrint("📦 Returned packageId: $packageId");

      if (!mounted) return;

      if (packageId != null) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => PackageDetailsScreen(packageId: packageId),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("❌ Failed to create package. Try again."),
          ),
        );
      }
    } catch (e) {
      debugPrint("❌ Create package error: $e");

      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      if (mounted) {
        setState(() => loading = false);
      }
    }
  }

  Widget _buildTextField(
    String label, {
    TextInputType type = TextInputType.text,
    Function(String?)? onSaved,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        keyboardType: type,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
        onSaved: onSaved,
      ),
    );
  }

  Future<void> _pickLocation({required bool isPickup}) async {
    final selected = await Navigator.push<LatLng>(
      context,
      MaterialPageRoute(
        builder: (_) => MapPickerScreen(
          initialLocation: isPickup
              ? pickupLocation ?? const LatLng(6.5244, 3.3792)
              : deliveryLocation ?? const LatLng(6.5244, 3.3792),
        ),
      ),
    );

    if (selected != null) {
      setState(() {
        if (isPickup) {
          pickupLocation = selected;
        } else {
          deliveryLocation = selected;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Create Package")),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    _buildTextField(
                      "Receiver Name",
                      onSaved: (v) => receiverName = v ?? '',
                    ),
                    _buildTextField(
                      "Receiver Phone",
                      type: TextInputType.phone,
                      onSaved: (v) => receiverPhone = v ?? '',
                    ),

                    _buildTextField(
                      "Description",
                      onSaved: (v) => description = v ?? '',
                    ),
                    _buildTextField(
                      "Pickup Address",
                      onSaved: (v) => pickupAddress = v ?? '',
                    ),
                    _buildTextField(
                      "Delivery Address",
                      onSaved: (v) => deliveryAddress = v ?? '',
                    ),

                    const SizedBox(height: 20),

                    ElevatedButton(
                      onPressed: () => _pickLocation(isPickup: true),
                      child: const Text("Select Pickup Location"),
                    ),

                    ElevatedButton(
                      onPressed: () => _pickLocation(isPickup: false),
                      child: const Text("Select Delivery Location"),
                    ),

                    const SizedBox(height: 20),

                    ElevatedButton(
                      onPressed: _createPackage,
                      child: const Text("Create Package"),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}

//
// ---------------- MAP PICKER ----------------
//
class MapPickerScreen extends StatefulWidget {
  final LatLng initialLocation;
  const MapPickerScreen({super.key, required this.initialLocation});

  @override
  State<MapPickerScreen> createState() => _MapPickerScreenState();
}

class _MapPickerScreenState extends State<MapPickerScreen> {
  late LatLng selectedLocation;
  GoogleMapController? mapController;

  final TextEditingController searchController = TextEditingController();
  final String apiKey = "YOUR_GOOGLE_MAPS_API_KEY";

  @override
  void initState() {
    super.initState();
    selectedLocation = widget.initialLocation;
  }

  Future<void> searchLocation(String text) async {
    final url =
        "https://maps.googleapis.com/maps/api/geocode/json?address=$text&key=$apiKey";

    final res = await http.get(Uri.parse(url));
    final data = jsonDecode(res.body);

    if (data["status"] == "OK" && data["results"].isNotEmpty) {
      final loc = data["results"][0]["geometry"]["location"];
      final latLng = LatLng(loc["lat"], loc["lng"]);

      setState(() => selectedLocation = latLng);
      mapController?.animateCamera(CameraUpdate.newLatLng(latLng));
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
              target: selectedLocation,
              zoom: 15,
            ),
            onMapCreated: (controller) => mapController = controller,
            onTap: (latLng) => setState(() => selectedLocation = latLng),
            markers: {
              Marker(
                markerId: const MarkerId("selected"),
                position: selectedLocation,
              ),
            },
          ),

          Positioned(
            top: 10,
            left: 10,
            right: 10,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
              ),
              child: TextField(
                controller: searchController,
                decoration: const InputDecoration(
                  hintText: "Search location",
                  border: InputBorder.none,
                ),
                onSubmitted: searchLocation,
              ),
            ),
          ),

          Positioned(
            bottom: 20,
            left: 16,
            right: 16,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context, selectedLocation),
              child: const Text("Confirm Location"),
            ),
          ),
        ],
      ),
    );
  }
}
