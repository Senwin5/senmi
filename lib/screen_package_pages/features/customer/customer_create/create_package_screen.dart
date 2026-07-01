// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:senmi/map/map_picker_screen.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:senmi/screen_package_pages/features/customer/customer_create/create_package_details.dart';
import 'package:senmi/screen_package_pages/features/customer/customer_history/customer_history_screen.dart';
import 'package:senmi/services/api_service.dart';

class CreatePackageScreen extends StatefulWidget {
  final bool fromHome;

  const CreatePackageScreen({super.key, this.fromHome = false});

  @override
  State<CreatePackageScreen> createState() => _CreatePackageScreenState();
}

class _CreatePackageScreenState extends State<CreatePackageScreen> {
  double? estimatedPrice;
  double? distanceKm;
  bool calculatingPrice = false;
  bool loading = false;

  final _formKey = GlobalKey<FormState>();

  final pickupController = TextEditingController();
  final deliveryController = TextEditingController();

  final receiverNameController = TextEditingController();
  final receiverPhoneController = TextEditingController();

  void _resetForm() {
    setState(() {
      pickupController.clear();
      deliveryController.clear();

      receiverName = '';
      receiverPhone = '';
      //description = '';
      pickupAddress = '';
      deliveryAddress = '';

      pickupLocation = null;
      deliveryLocation = null;

      estimatedPrice = null;
      distanceKm = null;
    });

    _formKey.currentState?.reset();
  }

  void _autoCalculatePrice() {
    if (pickupLocation != null && deliveryLocation != null) {
      _calculatePrice();
    }
  }

  Future<void> _refreshPage() async {
    _resetForm();
  }

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
  //String description = '';
  String pickupAddress = '';
  String deliveryAddress = '';

  LatLng? pickupLocation;
  LatLng? deliveryLocation;

  final String apiKey = "AIzaSyANfJatY_6y8gzmUrvV2_n2aR9ms7Xe_ZY";

  Future<String> _getAddressFromLatLng(LatLng pos) async {
    try {
      final placemarks = await placemarkFromCoordinates(
        pos.latitude,
        pos.longitude,
      );

      if (placemarks.isEmpty) return "Unknown location";

      final p = placemarks.first;

      final street = [
        p.subThoroughfare,
        p.thoroughfare,
      ].where((e) => e != null && e.isNotEmpty).join(" ");

      final address =
          [
                if (street.isNotEmpty) street,
                p.locality,
                p.administrativeArea,
                p.country,
              ]
              .where((e) => e != null && e.isNotEmpty)
              .toSet() // removes duplicate Lagos
              .join(", ");

      return address;
    } catch (e) {
      return "Unknown location";
    }
  }

  Future<void> _pickContact() async {
    final status = await FlutterContacts.permissions.request(
      PermissionType.read,
    );

    if (status != PermissionStatus.granted) return;

    final contact = await FlutterContacts.native.showPicker(
      properties: {ContactProperty.phone},
    );

    if (contact == null) return;

    receiverNameController.text = contact.displayName!;

    if (contact.phones.isNotEmpty) {
      receiverPhoneController.text = contact.phones.first.number;
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
      _autoCalculatePrice();

      final addr = await _getAddressFromLatLng(selected);

      setState(() {
        pickupAddress = addr;

        pickupController.value = TextEditingValue(
          text: addr,
          selection: TextSelection.collapsed(offset: addr.length),
        );
      });
    } else {
      deliveryLocation = selected;
      _autoCalculatePrice();

      final addr = await _getAddressFromLatLng(selected);

      setState(() {
        deliveryAddress = addr;

        deliveryController.value = TextEditingValue(
          text: addr,
          selection: TextSelection.collapsed(offset: addr.length),
        );
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
        //'description': description.trim(),
        'pickup_address': pickupController.text,
        'delivery_address': deliveryController.text,
        'receiver_name': receiverName.trim(),
        'receiver_phone': receiverPhone.trim(),
        'pickup_lat': pickupLocation!.latitude,
        'pickup_lng': pickupLocation!.longitude,
        'delivery_lat': deliveryLocation!.latitude,
        'delivery_lng': deliveryLocation!.longitude,
        'price': estimatedPrice?.toStringAsFixed(2),
      };

      final res = await ApiService.createPackage(payload);

      if (!mounted) return;

      if (res['success'] == true && res['package_id'] != null) {
        final packageId = res['package_id'].toString();

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => PackageDetailsScreen(packageId: packageId),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(16),
            backgroundColor: Colors.deepPurple,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            content: Text(
              res['error']?.toString() ?? "Please complete all required fields",
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
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
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: TextFormField(
        controller: controller,
        keyboardType: type,
        cursorColor: const Color(0xFF581C87),
        style: TextStyle(
          color: Theme.of(context).textTheme.bodyLarge?.color,
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: Theme.of(context).cardColor,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 18,
            vertical: 18,
          ),
          labelStyle: TextStyle(
            color: Theme.of(context).textTheme.bodyLarge?.color,
            fontWeight: FontWeight.w600,
            fontSize: 12, // 👈 make it smaller
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: BorderSide(color: Colors.grey.shade200),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: const BorderSide(color: Color(0xFF581C87), width: 2),
          ),
        ),
        onSaved: onSaved,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).brightness == Brightness.dark
          ? const Color(0xFF111111)
          : const Color(0xFFF7F8FC),

      appBar: AppBar(
        elevation: 0,
        centerTitle: true,
        backgroundColor: const Color(0xFF581C87),
        surfaceTintColor: Colors.transparent,

        iconTheme: const IconThemeData(color: Colors.white),

        title: const Text(
          "Create Package",
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),

        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _refreshPage,
          ),
        ],
      ),

      body: loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _refreshPage,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Container(
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? const Color(0xFF1E1E1E)
                        : Colors.white,
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: [
                      BoxShadow(
                        // ignore: deprecated_member_use
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 🔥 ONLY ADDITION (ORDER + HISTORY UI)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            GestureDetector(
                              onTap: () {
                                _resetForm();
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [
                                      Color(0xFF581C87),
                                      Color(0xFF3B0764),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(14),
                                  boxShadow: [
                                    BoxShadow(
                                      // ignore: deprecated_member_use
                                      color: const Color(
                                        0xFF581C87,
                                        // ignore: deprecated_member_use
                                      ).withOpacity(0.25),
                                      blurRadius: 12,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: const Text(
                                  "Reset",
                                  style: TextStyle(color: Colors.white),
                                ),
                              ),
                            ),

                            GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const HistoryScreen(),
                                  ),
                                );
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.grey,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Text(
                                  "History",
                                  style: TextStyle(color: Colors.white),
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 15),
                        const Text(
                          "Pickup & Delivery",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        GestureDetector(
                          onTap: () => _pickLocation(isPickup: true),
                          child: AbsorbPointer(
                            child: _buildTextField(
                              "Pickup location",
                              controller: pickupController,
                            ),
                          ),
                        ),

                        GestureDetector(
                          onTap: () => _pickLocation(isPickup: false),
                          child: AbsorbPointer(
                            child: _buildTextField(
                              "Delivery location",
                              controller: deliveryController,
                            ),
                          ),
                        ),

                        const SizedBox(height: 18),

                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: calculatingPrice
                                ? null
                                : _calculatePrice,
                            child: calculatingPrice
                                ? const CircularProgressIndicator(
                                    color: Colors.white,
                                  )
                                : const Text("Calculate delivery cost"),
                          ),
                        ),

                        if (estimatedPrice != null) ...[
                          const SizedBox(height: 20),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(18),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Colors.green, Colors.greenAccent],
                              ),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Column(
                              children: [
                                const Text(
                                  "Estimated Delivery Cost",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),

                                const SizedBox(height: 8),

                                Text(
                                  "₦${estimatedPrice!.toStringAsFixed(0)}",
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 32,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),

                                const SizedBox(height: 4),

                                Text(
                                  "${distanceKm?.toStringAsFixed(2)} km",
                                  style: const TextStyle(color: Colors.white70),
                                ),
                              ],
                            ),
                          ),
                        ],
                        const SizedBox(height: 18),

                        const Text(
                          "Receiver Details",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        const SizedBox(height: 10),

                        OutlinedButton.icon(
                          onPressed: _pickContact,
                          icon: const Icon(Icons.contacts),
                          label: const Text("Choose from Contacts"),
                        ),

                        _buildTextField(
                          "Receiver Name (Optional)",
                          controller: receiverNameController,
                          onSaved: (v) => receiverName = v ?? '',
                        ),

                        _buildTextField(
                          "Receiver Phone",
                          controller: receiverPhoneController,
                          type: TextInputType.phone,
                          onSaved: (v) => receiverPhone = v ?? '',
                        ),

                        const SizedBox(height: 15),

                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _createPackage,
                            child: const Text("Send Package"),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
    );
  }
}
