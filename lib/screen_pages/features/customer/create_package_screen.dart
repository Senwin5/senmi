// ignore_for_file: use_build_context_synchronously

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:senmi/map/map_picker_screen.dart';
import 'package:senmi/screen_pages/features/customer/create_package_details.dart';
import 'package:senmi/services/api_service.dart';
import 'package:http/http.dart' as http;

class CreatePackageScreen extends StatefulWidget {
  const CreatePackageScreen({super.key});

  @override
  State<CreatePackageScreen> createState() => _CreatePackageScreenState();
}

class _CreatePackageScreenState extends State<CreatePackageScreen> {
  double? estimatedPrice;
  double? distanceKm;
  bool calculatingPrice = false;

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

  final String apiKey = "YOUR_GOOGLE_MAPS_API_KEY";

  // 🔥 NEW: convert coordinates → real Lagos street address
  Future<String> _getAddressFromLatLng(LatLng pos) async {
    final url =
        "https://maps.googleapis.com/maps/api/geocode/json?latlng=${pos.latitude},${pos.longitude}&key=$apiKey";

    final res = await http.get(Uri.parse(url));
    final data = jsonDecode(res.body);

    if (data["status"] == "OK" && data["results"].isNotEmpty) {
      return data["results"][0]["formatted_address"];
    }

    return "Unknown location";
  }

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

    if (pickupAddress.isEmpty && pickupLocation != null) {
      pickupAddress =
          "Lat: ${pickupLocation!.latitude}, Lng: ${pickupLocation!.longitude}";
    }

    if (deliveryAddress.isEmpty && deliveryLocation != null) {
      deliveryAddress =
          "Lat: ${deliveryLocation!.latitude}, Lng: ${deliveryLocation!.longitude}";
    }

    setState(() => loading = true);

    try {
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
        'price': estimatedPrice,
      };

      final packageId = await ApiService.createPackage(payload);

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
          const SnackBar(content: Text("❌ Package creation failed")),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> _calculatePrice() async {
    if (pickupLocation == null || deliveryLocation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Select locations first")),
      );
      return;
    }

    setState(() => calculatingPrice = true);

    final payload = {
      'pickup_lat': pickupLocation!.latitude,
      'pickup_lng': pickupLocation!.longitude,
      'delivery_lat': deliveryLocation!.latitude,
      'delivery_lng': deliveryLocation!.longitude,
    };

    final res = await ApiService.getPrice(payload);

    if (res != null) {
      setState(() {
        estimatedPrice = (res['price'] as num?)?.toDouble();
        distanceKm = (res['distance_km'] as num?)?.toDouble();
      });
    }

    setState(() => calculatingPrice = false);
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

          _getAddressFromLatLng(selected).then((value) {
            setState(() {
              pickupAddress = value;
            });
          });
        } else {
          deliveryLocation = selected;

          _getAddressFromLatLng(selected).then((value) {
            setState(() {
              deliveryAddress = value;
            });
          });
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
                    _buildTextField("Receiver Name",
                        onSaved: (v) => receiverName = v ?? ''),
                    _buildTextField("Receiver Phone",
                        type: TextInputType.phone,
                        onSaved: (v) => receiverPhone = v ?? ''),
                    _buildTextField("Description",
                        onSaved: (v) => description = v ?? ''),

                    GestureDetector(
                      onTap: () => _pickLocation(isPickup: true),
                      child: AbsorbPointer(
                        child: _buildTextField(
                          "Pickup Address (tap to pick on map)",
                          onSaved: (v) => pickupAddress = v ?? '',
                        ),
                      ),
                    ),

                    GestureDetector(
                      onTap: () => _pickLocation(isPickup: false),
                      child: AbsorbPointer(
                        child: _buildTextField(
                          "Delivery Address (tap to pick on map)",
                          onSaved: (v) => deliveryAddress = v ?? '',
                        ),
                      ),
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
                      onPressed: calculatingPrice ? null : _calculatePrice,
                      child: calculatingPrice
                          ? const CircularProgressIndicator()
                          : const Text("Calculate Price"),
                    ),

                    if (estimatedPrice != null) ...[
                      const SizedBox(height: 20),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Column(
                          children: [
                            Text("Distance: ${distanceKm?.toStringAsFixed(2)} km"),
                            const SizedBox(height: 5),
                            Text(
                              "Estimated Price: ₦${estimatedPrice!.toStringAsFixed(0)}",
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

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