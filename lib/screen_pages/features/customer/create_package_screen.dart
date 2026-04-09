// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
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

  bool loading = false;

  Future<void> _createPackage() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

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
      });

      if (packageId != null) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => PackageDetailsScreen(packageId: packageId),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to create package: $e")),
      );
    } finally {
      setState(() => loading = false);
    }
  }

  Widget _buildTextField(String label,
      {TextInputType type = TextInputType.text,
      Function(String?)? onSaved,
      String? Function(String?)? validator}) {
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
                    const Text("Sender Information",
                        style:
                            TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                    _buildTextField("Sender Name",
                        onSaved: (v) => senderName = v ?? '',
                        validator: (v) => (v == null || v.isEmpty) ? "Required" : null),
                    _buildTextField("Sender Phone",
                        type: TextInputType.phone,
                        onSaved: (v) => senderPhone = v ?? '',
                        validator: (v) => (v == null || v.isEmpty) ? "Required" : null),
                    const SizedBox(height: 16),
                    const Text("Receiver Information",
                        style:
                            TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                    _buildTextField("Receiver Name",
                        onSaved: (v) => receiverName = v ?? '',
                        validator: (v) => (v == null || v.isEmpty) ? "Required" : null),
                    _buildTextField("Receiver Phone",
                        type: TextInputType.phone,
                        onSaved: (v) => receiverPhone = v ?? '',
                        validator: (v) => (v == null || v.isEmpty) ? "Required" : null),
                    const SizedBox(height: 16),
                    const Text("Package Information",
                        style:
                            TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                    _buildTextField("Description", onSaved: (v) => description = v ?? ''),
                    _buildTextField("Pickup Address", onSaved: (v) => pickupAddress = v ?? ''),
                    _buildTextField("Delivery Address", onSaved: (v) => deliveryAddress = v ?? ''),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _createPackage,
                        style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16)),
                        child: const Text("Create Package",
                            style: TextStyle(fontSize: 16)),
                      ),
                    )
                  ],
                ),
              ),
            ),
    );
  }
}