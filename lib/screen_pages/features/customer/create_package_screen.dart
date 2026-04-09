// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:senmi/screen_pages/features/customer/create_package_details.dart';
import 'package:senmi/services/api_service.dart';

class CreatePackageScreen extends StatefulWidget {
  const CreatePackageScreen({super.key});

  @override
  State<CreatePackageScreen> createState() => _CreatePackageScreenState();
}

class _CreatePackageScreenState extends State<CreatePackageScreen> {
  final _formKey = GlobalKey<FormState>();

  // Package fields
  String senderName = '';
  String senderPhone = '';
  String receiverName = '';
  String receiverPhone = '';
  String description = '';
  String pickupAddress = '';
  String deliveryAddress = '';

  // Coordinates
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
            "Please select pickup and delivery locations on the map.",
          ),
        ),
      );
      return;
    }

    setState(() => loading = true);

    try {
      final packageId = await ApiService.createPackage({
        'sender_name': senderName,
        'sender_phone': senderPhone,
        'receiver_name': receiverName,
        'receiver_phone': receiverPhone,
        'description': description,
        'pickup_address': pickupAddress,
        'delivery_address': deliveryAddress,
        'pickup_lat': pickupLocation!.latitude,
        'pickup_lng': pickupLocation!.longitude,
        'delivery_lat': deliveryLocation!.latitude,
        'delivery_lng': deliveryLocation!.longitude,
      });

      if (packageId != null) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => PackageDetailsScreen(packageId: packageId),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Failed to create package.")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Failed to create package: $e")));
    } finally {
      setState(() => loading = false);
    }
  }

  Widget _buildTextField(
    String label, {
    TextInputType type = TextInputType.text,
    Function(String?)? onSaved,
    String? Function(String?)? validator,
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
        validator: validator,
      ),
    );
  }

  // Open map to pick a location
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
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Sender Information",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    _buildTextField(
                      "Sender Name",
                      onSaved: (v) => senderName = v ?? '',
                      validator: (v) =>
                          (v == null || v.isEmpty) ? "Required" : null,
                    ),
                    _buildTextField(
                      "Sender Phone",
                      type: TextInputType.phone,
                      onSaved: (v) => senderPhone = v ?? '',
                      validator: (v) =>
                          (v == null || v.isEmpty) ? "Required" : null,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      "Receiver Information",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    _buildTextField(
                      "Receiver Name",
                      onSaved: (v) => receiverName = v ?? '',
                      validator: (v) =>
                          (v == null || v.isEmpty) ? "Required" : null,
                    ),
                    _buildTextField(
                      "Receiver Phone",
                      type: TextInputType.phone,
                      onSaved: (v) => receiverPhone = v ?? '',
                      validator: (v) =>
                          (v == null || v.isEmpty) ? "Required" : null,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      "Package Information",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
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
                    const SizedBox(height: 16),
                    const Text(
                      "Select Locations on Map",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () => _pickLocation(isPickup: true),
                      child: Text(
                        pickupLocation != null
                            ? "Pickup: (${pickupLocation!.latitude.toStringAsFixed(4)}, ${pickupLocation!.longitude.toStringAsFixed(4)})"
                            : "Select Pickup Location",
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () => _pickLocation(isPickup: false),
                      child: Text(
                        deliveryLocation != null
                            ? "Delivery: (${deliveryLocation!.latitude.toStringAsFixed(4)}, ${deliveryLocation!.longitude.toStringAsFixed(4)})"
                            : "Select Delivery Location",
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _createPackage,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: const Text(
                          "Create Package",
                          style: TextStyle(fontSize: 16),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}

// --------------------------
// Simple Map Picker Screen
// --------------------------
class MapPickerScreen extends StatefulWidget {
  final LatLng initialLocation;
  const MapPickerScreen({super.key, required this.initialLocation});

  @override
  State<MapPickerScreen> createState() => _MapPickerScreenState();
}

class _MapPickerScreenState extends State<MapPickerScreen> {
  late LatLng selectedLocation;

  @override
  void initState() {
    super.initState();
    selectedLocation = widget.initialLocation;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Pick Location")),
      body: Stack(
        children: [
          Positioned.fill(
            child: GoogleMap(
              initialCameraPosition: CameraPosition(
                target: selectedLocation,
                zoom: 15,
              ),
              onTap: (latLng) {
                setState(() {
                  selectedLocation = latLng;
                });
              },
              markers: {
                Marker(
                  markerId: const MarkerId("selected"),
                  position: selectedLocation,
                ),
              },
            ),
          ), // ✅ THIS COMMA + BRACKET WAS MISSING

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
