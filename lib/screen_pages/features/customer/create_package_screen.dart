// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'package:senmi/map/map_picker_screen.dart';
import 'package:senmi/screen_pages/features/customer/create_package_details.dart';
import 'package:senmi/services/api_service.dart';

class CreatePackageScreen extends StatefulWidget {
  const CreatePackageScreen({super.key});

  @override
  State<CreatePackageScreen> createState() => _CreatePackageScreenState();
}

class _CreatePackageScreenState extends State<CreatePackageScreen> {
  double? estimatedPrice;
  double? distanceKm;
  bool calculatingPrice = false;
  bool loading = false;

  final _formKey = GlobalKey<FormState>();

  // ✅ controllers (REAL FIX)
  final pickupController = TextEditingController();
  final deliveryController = TextEditingController();

  @override
  void dispose() {
    pickupController.dispose();
    deliveryController.dispose();
    super.dispose();
  }

  String senderName = '';
  String senderPhone = '';
  String receiverName = '';
  String receiverPhone = '';
  String description = '';
  String pickupAddress = '';
  String deliveryAddress = '';

  LatLng? pickupLocation;
  LatLng? deliveryLocation;

  final String apiKey = "AIzaSyAZQIQTDqT15t8CfFrzHh99uDJmsFs7VtA";

  Future<String> _getAddressFromLatLng(LatLng pos) async {
    try {
      final placemarks = await placemarkFromCoordinates(
        pos.latitude,
        pos.longitude,
      );

      if (placemarks.isEmpty) return "Unknown location";

      final p = placemarks.first;

      return "${p.name ?? ''}, ${p.street ?? ''}, ${p.locality ?? ''}, ${p.country ?? ''}";
    } catch (e) {
      print("PLACEMARK ERROR: $e");
      return "Unknown location";
    }
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

    if (selected == null) return;

    if (isPickup) {
      pickupLocation = selected;

      final addr = await _getAddressFromLatLng(selected);

      setState(() {
        pickupAddress = addr;
        //pickupController.text = addr;
        setState(() {
          pickupAddress = addr;
          pickupController.value = TextEditingValue(
            text: addr,
            selection: TextSelection.collapsed(offset: addr.length),
          );
        });
      });
    } else {
      deliveryLocation = selected;

      final addr = await _getAddressFromLatLng(selected);

      setState(() {
        deliveryAddress = addr;
        //deliveryController.text = addr; // ✅ FIX UI
        setState(() {
          deliveryAddress = addr;
          deliveryController.value = TextEditingValue(
            text: addr,
            selection: TextSelection.collapsed(offset: addr.length),
          );
        });
      });
    }
  }

  Future<void> _calculatePrice() async {
    if (pickupLocation == null || deliveryLocation == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Select locations first")));
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

  Future<void> _createPackage() async {
    if (estimatedPrice == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please calculate price first")),
      );
      return;
    }

    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    if (pickupLocation == null || deliveryLocation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("⚠️ Please select pickup and delivery locations"),
        ),
      );
      return;
    }

    setState(() => loading = true);

    try {
      final payload = {
        'description': description.trim(),
        'pickup_address': pickupAddress,
        'delivery_address': deliveryAddress,
        'receiver_name': receiverName.trim(),
        'receiver_phone': receiverPhone.trim(),
        'pickup_lat': pickupLocation!.latitude,
        'pickup_lng': pickupLocation!.longitude,
        'delivery_lat': deliveryLocation!.latitude,
        'delivery_lng': deliveryLocation!.longitude,
        'price': estimatedPrice?.toStringAsFixed(2),
      };

      //final packageId = await ApiService.createPackage(payload);
      final res = await ApiService.createPackage(payload);

      if (!mounted) return;

      if (res['success'] == true && res['package_id'] != null) {
        final packageId = res['package_id'].toString();

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => PackageDetailsScreen(packageId: packageId),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("❌ ${res['error'] ?? 'Package creation failed'}"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Widget _buildTextField(
    String label, {
    TextInputType type = TextInputType.text,
    Function(String?)? onSaved,
    TextEditingController? controller,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextFormField(
        controller: controller,
        keyboardType: type,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
        onSaved: onSaved,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Create Package",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        elevation: 0,
      ),
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
                      "Receiver Details",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    _buildTextField(
                      "Receiver Name",
                      onSaved: (v) => receiverName = v ?? '',
                    ),
                    _buildTextField(
                      "Receiver Phone",
                      type: TextInputType.phone,
                      onSaved: (v) => receiverPhone = v ?? '',
                    ),

                    const SizedBox(height: 10),

                    const Text(
                      "Package Info",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    _buildTextField(
                      "Description",
                      onSaved: (v) => description = v ?? '',
                    ),

                    const SizedBox(height: 10),

                    const Text(
                      "Locations",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    // PICKUP
                    GestureDetector(
                      onTap: () => _pickLocation(isPickup: true),
                      child: AbsorbPointer(
                        child: _buildTextField(
                          "Pickup Address",
                          controller: pickupController,
                          onSaved: (v) => pickupAddress = v ?? '',
                        ),
                      ),
                    ),

                    // DELIVERY
                    GestureDetector(
                      onTap: () => _pickLocation(isPickup: false),
                      child: AbsorbPointer(
                        child: _buildTextField(
                          "Delivery Address",
                          controller: deliveryController,
                          onSaved: (v) => deliveryAddress = v ?? '',
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // LOCATION BUTTONS
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => _pickLocation(isPickup: true),
                            icon: const Icon(Icons.my_location),
                            label: const Text("Pickup"),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => _pickLocation(isPickup: false),
                            icon: const Icon(Icons.location_on),
                            label: const Text("Delivery"),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // CALCULATE BUTTON
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: calculatingPrice ? null : _calculatePrice,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: calculatingPrice
                            ? const CircularProgressIndicator(
                                color: Colors.white,
                              )
                            : const Text(
                                "Calculate Price",
                                style: TextStyle(fontSize: 16),
                              ),
                      ),
                    ),

                    if (estimatedPrice != null) ...[
                      const SizedBox(height: 20),

                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.green.shade400,
                              Colors.green.shade600,
                            ],
                          ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              // ignore: deprecated_member_use
                              color: Colors.green.withOpacity(0.3),
                              blurRadius: 10,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            Text(
                              "Distance: ${distanceKm?.toStringAsFixed(2)} km",
                              style: const TextStyle(color: Colors.white),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              "₦${estimatedPrice!.toStringAsFixed(0)}",
                              style: const TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: 30),

                    // CREATE BUTTON
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _createPackage,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: const Text(
                          "Create Package",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
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
