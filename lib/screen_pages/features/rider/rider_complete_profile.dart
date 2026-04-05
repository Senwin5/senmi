import 'dart:io';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:image_picker/image_picker.dart';
import 'package:senmi/screen_pages/features/rider/rider_pending_screen.dart';
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
    showModalBottomSheet(
      context: context,
      builder: (_) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text("Take Photo"),
                onTap: () async {
                  Navigator.pop(context);

                  var status = await Permission.camera.request();
                  if (status.isGranted) {
                    final image = await _picker.pickImage(
                      source: ImageSource.camera,
                    );

                    if (image != null) {
                      setState(() {
                        if (type == 'profile') {
                          profilePicture = File(image.path);
                        }
                        if (type == 'rider1') riderImage1 = File(image.path);
                        if (type == 'withVehicle') {
                          riderImageWithVehicle = File(image.path);
                        }
                      });
                    }
                  } else {
                    // ignore: use_build_context_synchronously
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Camera permission denied")),
                    );
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo),
                title: const Text("Choose from Gallery"),
                onTap: () async {
                  Navigator.pop(context);

                  final image = await _picker.pickImage(
                    source: ImageSource.gallery,
                  );

                  if (image != null) {
                    setState(() {
                      if (type == 'profile') profilePicture = File(image.path);
                      if (type == 'rider1') riderImage1 = File(image.path);
                      if (type == 'withVehicle') {
                        riderImageWithVehicle = File(image.path);
                      }
                    });
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void submitProfile() async {
    if (!_formKey.currentState!.validate()) return;

    if (profilePicture == null ||
        riderImage1 == null ||
        riderImageWithVehicle == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("All images are required.")));
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

    if (res.containsKey('error')) {
      ScaffoldMessenger.of(
        // ignore: use_build_context_synchronously
        context,
      ).showSnackBar(SnackBar(content: Text(res['error'])));
      return;
    }

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
                Navigator.pop(context);
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const RiderPendingScreen()),
                );
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      "Profile submitted! Waiting for admin approval.",
                    ),
                  ),
                );
              },
              child: const Text("OK"),
            ),
          ],
        ),
      );
    } else {
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to submit profile: ${res.toString()}")),
      );
    }
  }

  Widget imagePickerTile(String label, File? file, String type) {
    return GestureDetector(
      onTap: () => pickImage(type),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        height: 120,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey),
          borderRadius: BorderRadius.circular(12),
        ),
        child: file != null
            ? ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.file(
                  file,
                  fit: BoxFit.cover,
                  width: double.infinity,
                ),
              )
            : Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.add_a_photo, size: 40, color: Colors.grey),
                    const SizedBox(height: 8),
                    Text(label, style: const TextStyle(color: Colors.grey)),
                  ],
                ),
              ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Complete Rider Profile"),
        automaticallyImplyLeading: false,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: Stack(
        children: [
          FutureBuilder<dynamic>(
            future: ApiService.getRiderProfile(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError || snapshot.data == null) {
                return const Center(child: Text("Error loading profile"));
              }

              // Safely cast to Map
              final profile = snapshot.data is Map<String, dynamic>
                  ? snapshot.data as Map<String, dynamic>
                  : {};

              // Prefill controllers only if they are empty
              if (fullNameController.text.isEmpty) {
                fullNameController.text = profile['full_name'] ?? '';
              }
              if (phoneController.text.isEmpty) {
                phoneController.text = profile['phone'] ?? '';
              }
              if (vehicleController.text.isEmpty) {
                vehicleController.text = profile['vehicle_number'] ?? '';
              }
              if (addressController.text.isEmpty) {
                addressController.text = profile['address'] ?? '';
              }
              if (cityController.text.isEmpty) {
                cityController.text = profile['city'] ?? '';
              }

              return SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      TextFormField(
                        controller: fullNameController,
                        decoration: const InputDecoration(
                          labelText: "Full Name",
                          prefixIcon: Icon(Icons.person),
                          border: OutlineInputBorder(),
                        ),
                        validator: (val) => val!.isEmpty ? "Required" : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: phoneController,
                        decoration: const InputDecoration(
                          labelText: "Phone Number",
                          prefixIcon: Icon(Icons.phone),
                          border: OutlineInputBorder(),
                        ),
                        validator: (val) => val!.isEmpty ? "Required" : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: vehicleController,
                        decoration: const InputDecoration(
                          labelText: "Vehicle Number",
                          prefixIcon: Icon(Icons.directions_car),
                          border: OutlineInputBorder(),
                        ),
                        validator: (val) => val!.isEmpty ? "Required" : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: addressController,
                        decoration: const InputDecoration(
                          labelText: "Address",
                          prefixIcon: Icon(Icons.home),
                          border: OutlineInputBorder(),
                        ),
                        validator: (val) => val!.isEmpty ? "Required" : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: cityController,
                        decoration: const InputDecoration(
                          labelText: "City",
                          prefixIcon: Icon(Icons.location_city),
                          border: OutlineInputBorder(),
                        ),
                        validator: (val) => val!.isEmpty ? "Required" : null,
                      ),
                      const SizedBox(height: 16),
                      imagePickerTile("Profile Picture", profilePicture, 'profile'),
                      imagePickerTile("Rider Image 1", riderImage1, 'rider1'),
                      imagePickerTile("Rider Image with Vehicle", riderImageWithVehicle, 'withVehicle'),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: submitProfile,
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text("Submit Profile"),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          if (loading)
            Container(
              color: Colors.black45,
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }
}