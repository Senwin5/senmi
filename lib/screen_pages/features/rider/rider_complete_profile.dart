// rider_complete_profile.dart
import 'dart:io';
import 'package:flutter/material.dart';
// ignore: depend_on_referenced_packages
import 'package:image_picker/image_picker.dart';
import 'package:senmi/services/api_service.dart';

class RiderCompleteProfile extends StatefulWidget {
  const RiderCompleteProfile({super.key});

  @override
  State<RiderCompleteProfile> createState() => _RiderCompleteProfileState();
}

class _RiderCompleteProfileState extends State<RiderCompleteProfile> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController fullNameController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController vehicleController = TextEditingController();
  final TextEditingController addressController = TextEditingController();
  final TextEditingController cityController = TextEditingController();

  File? profilePicture;
  File? riderImage1;
  File? riderImageWithVehicle;

  bool loading = false;

  final ImagePicker _picker = ImagePicker();

  Future<void> pickImage(String type) async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        if (type == 'profile') profilePicture = File(image.path);
        if (type == 'rider1') riderImage1 = File(image.path);
        if (type == 'withVehicle') riderImageWithVehicle = File(image.path);
      });
    }
  }

  void submitProfile() async {
    if (!_formKey.currentState!.validate()) return;

    if (profilePicture == null || riderImage1 == null || riderImageWithVehicle == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("All images are required.")),
      );
      return;
    }

    setState(() => loading = true);

    final res = await ApiService.updateRiderProfile(
      fullNameController.text,
      phoneController.text,
      vehicleController.text,
      addressController.text,
      cityController.text,
      profilePicture!,
      riderImage1!,
      riderImageWithVehicle!,
    );

    setState(() => loading = false);

    if (res.containsKey('message')) {
      showDialog(
        // ignore: use_build_context_synchronously
        context: context,
        builder: (_) => AlertDialog(
          title: const Text("Success"),
          content: Text(res['message']),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context); // close dialog first
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Profile submitted! Waiting for admin approval."),
                  ),
                );
              },
              child: const Text("OK"),
            )
          ],
        ),
      );
    } else {

      String errorText = "";
      if (res.containsKey('missing_fields')) {
        errorText += "Please fill all required fields.\n";
      }
      if (res.containsKey('missing_images')) {
        errorText += "Please upload all required images.\n";
      }
      if (res.containsKey('detail')) {
        errorText += res['detail'];
      }
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorText.isEmpty ? "Failed to submit profile" : errorText)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Complete Rider Profile")),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    TextFormField(
                      controller: fullNameController,
                      decoration: const InputDecoration(labelText: "Full Name"),
                      validator: (val) => val!.isEmpty ? "Required" : null,
                    ),
                    TextFormField(
                      controller: phoneController,
                      decoration: const InputDecoration(labelText: "Phone Number"),
                      validator: (val) => val!.isEmpty ? "Required" : null,
                    ),
                    TextFormField(
                      controller: vehicleController,
                      decoration: const InputDecoration(labelText: "Vehicle Number"),
                      validator: (val) => val!.isEmpty ? "Required" : null,
                    ),
                    TextFormField(
                      controller: addressController,
                      decoration: const InputDecoration(labelText: "Address"),
                      validator: (val) => val!.isEmpty ? "Required" : null,
                    ),
                    TextFormField(
                      controller: cityController,
                      decoration: const InputDecoration(labelText: "City"),
                      validator: (val) => val!.isEmpty ? "Required" : null,
                    ),
                    const SizedBox(height: 16),
                    imagePickerTile("Profile Picture", profilePicture, 'profile'),
                    imagePickerTile("Rider Image 1", riderImage1, 'rider1'),
                    imagePickerTile("Rider Image with Vehicle", riderImageWithVehicle, 'withVehicle'),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: submitProfile,
                      child: const Text("Submit Profile"),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget imagePickerTile(String label, File? file, String type) {
    return ListTile(
      title: Text(label),
      trailing: file != null
          ? Image.file(file, width: 50, height: 50, fit: BoxFit.cover)
          : const Icon(Icons.image),
      onTap: () => pickImage(type),
    );
  }
}