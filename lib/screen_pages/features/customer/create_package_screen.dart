// lib/screen_pages/features/customer/create_package_screen.dart
import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:senmi/map/map_picker_screen.dart';
import 'package:senmi/screen_pages/features/customer/create_package_details.dart';
import 'package:senmi/widgets/custom_buttom.dart';
import '../../../services/api_service.dart';

class CreatePackageScreen extends StatefulWidget {
  const CreatePackageScreen({super.key});

  @override
  State<CreatePackageScreen> createState() => _CreatePackageScreenState();
}

class _CreatePackageScreenState extends State<CreatePackageScreen> {
  // Controllers
  final description = TextEditingController();

  // Pickup
  final pickupAddress = TextEditingController();
  final senderName = TextEditingController();
  final senderPhone = TextEditingController();

  // Dropoff
  final deliveryAddress = TextEditingController();
  final receiverName = TextEditingController();
  final receiverPhone = TextEditingController();

  final price = TextEditingController();

  // Coordinates
  double? pickupLat;
  double? pickupLng;
  double? deliveryLat;
  double? deliveryLng;

  final _formKey = GlobalKey<FormState>();
  bool loading = false;

  // Payment option
  String paymentOption = "sender";

  // DISTANCE CALCULATION
  double calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const R = 6371; // Earth radius in km
    double dLat = (lat2 - lat1) * pi / 180;
    double dLon = (lon2 - lon1) * pi / 180;

    double a = sin(dLat / 2) * sin(dLat / 2) +
        cos(lat1 * pi / 180) *
            cos(lat2 * pi / 180) *
            sin(dLon / 2) *
            sin(dLon / 2);

    double c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return R * c;
  }

  void calculatePrice() {
    if (pickupLat != null && deliveryLat != null) {
      double distance =
          calculateDistance(pickupLat!, pickupLng!, deliveryLat!, deliveryLng!);
      double calculatedPrice = distance * 500; // Price formula
      price.text = calculatedPrice.toStringAsFixed(0);
    }
  }

  Future<void> create() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => loading = true);

    final res = await ApiService.createPackage({
      "description": description.text,
      "pickup_address": pickupAddress.text,
      "delivery_address": deliveryAddress.text,
      "price": double.tryParse(price.text) ?? 0,
      "pickup_lat": pickupLat,
      "pickup_lng": pickupLng,
      "delivery_lat": deliveryLat,
      "delivery_lng": deliveryLng,
      "sender_name": senderName.text,
      "sender_phone": senderPhone.text,
      "receiver_name": receiverName.text,
      "receiver_phone": receiverPhone.text,
      "payer": paymentOption,
    });

    setState(() => loading = false);

    if (res['id'] != null) {
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("Package created!")));

      Navigator.push(
        // ignore: use_build_context_synchronously
        context,
        MaterialPageRoute(
          builder: (_) => PackageDetailsScreen(packageId: res['id']),
        ),
      );
    } else {
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("Failed to create package.")));
    }
  }

  Future<void> openMap(bool isPickup) async {
    final result = await Navigator.of(context).push(_slideFadeRoute(const MapScreen()));

    if (result != null) {
      setState(() {
        if (isPickup) {
          pickupAddress.text = result['address'];
          pickupLat = result['lat'];
          pickupLng = result['lng'];
        } else {
          deliveryAddress.text = result['address'];
          deliveryLat = result['lat'];
          deliveryLng = result['lng'];
        }

        calculatePrice();
      });
    }
  }

  Route _slideFadeRoute(Widget page) {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final slide = Tween<Offset>(begin: const Offset(1, 0), end: Offset.zero)
            .animate(animation);
        final fade = Tween<double>(begin: 0, end: 1).animate(animation);
        return SlideTransition(
          position: slide,
          child: FadeTransition(opacity: fade, child: child),
        );
      },
      transitionDuration: const Duration(milliseconds: 400),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      appBar: AppBar(
        title: const Text("New Delivery"),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  // Locations
                  _card(
                    child: Column(
                      children: [
                        _locationTile(
                          "Pickup location",
                          pickupAddress,
                          () => openMap(true),
                        ),
                        const Divider(),
                        _locationTile(
                          "Drop-off location",
                          deliveryAddress,
                          () => openMap(false),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Sender
                  _card(
                    title: "Sender",
                    child: Column(
                      children: [
                        _input(senderName, "Enter full name"),
                        const SizedBox(height: 12),
                        _input(senderPhone, "Enter phone number", isNumber: true),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Receiver
                  _card(
                    title: "Receiver",
                    child: Column(
                      children: [
                        _input(receiverName, "Enter full name"),
                        const SizedBox(height: 12),
                        _input(receiverPhone, "Enter phone number", isNumber: true),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Package details
                  _card(
                    title: "Package",
                    child: Column(
                      children: [
                        _input(description, "Describe your package"),
                        const SizedBox(height: 12),
                        _input(price, "Price will be calculated",
                            isNumber: true, readOnly: true),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Payment
                  _card(
                    title: "Payment",
                    child: Column(
                      children: [
                        RadioListTile<String>(
                          title: const Text("Sender Pays"),
                          value: "sender",
                          // ignore: deprecated_member_use
                          groupValue: paymentOption,
                          fillColor: WidgetStateProperty.all(Colors.blue),
                          // ignore: deprecated_member_use
                          onChanged: (val) =>
                              setState(() => paymentOption = val!),
                        ),
                        RadioListTile<String>(
                          title: const Text("Receiver Pays"),
                          value: "receiver",
                          // ignore: deprecated_member_use
                          groupValue: paymentOption,
                          fillColor: WidgetStateProperty.all(Colors.blue),
                          // ignore: deprecated_member_use
                          onChanged: (val) =>
                              setState(() => paymentOption = val!),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Submit button
                  CustomButton(
                    text: "Request Rider",
                    onPressed: create,
                    fullWidth: true,
                    padding: const EdgeInsets.all(16),
                    color: Colors.blue, // ✅ give a valid color
                  ),
                ],
              ),
            ),
          ),
          if (loading)
            Container(
              color: Colors.black26,
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }

  // Helper Widgets
  Widget _card({String? title, required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 3))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null)
            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
                color: Colors.black,
              ),
            ),
          if (title != null) const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  Widget _locationTile(String title, TextEditingController controller, VoidCallback onTap) {
    return ListTile(
      onTap: onTap,
      contentPadding: EdgeInsets.zero,
      leading: const Icon(Icons.location_on, color: Colors.blue),
      title: Text(title, style: const TextStyle(color: Colors.black)),
      subtitle: Text(
        controller.text.isEmpty ? "Select location" : controller.text,
        style: const TextStyle(color: Colors.black54),
      ),
    );
  }

  Widget _input(TextEditingController controller, String hint,
      {bool isNumber = false, bool readOnly = false}) {
    return TextFormField(
      controller: controller,
      readOnly: readOnly,
      keyboardType: isNumber ? TextInputType.phone : TextInputType.text,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.black45),
        filled: true,
        fillColor: const Color(0xFFF1F2F6),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      style: const TextStyle(color: Colors.black87),
      validator: (val) => val!.isEmpty ? "Required" : null,
    );
  }
}