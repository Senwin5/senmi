import 'dart:io';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:image_picker/image_picker.dart';
import 'package:senmi/screen_pages/features/rider/pending_rider_review/rider_pending_screen.dart';
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

                  // ✅ REQUEST CAMERA PERMISSION
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
      // 🔹 show API error
      // ignore: use_build_context_synchronously
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
      // 🔹 catch any unexpected API response
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
          border: Border.all(
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.white
                : Colors.black,
          ),
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
                    Icon(
                      Icons.add_a_photo,
                      size: 40,
                      color: Theme.of(context).iconTheme.color,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      label,
                      style: TextStyle(
                        color: Theme.of(context).textTheme.bodyMedium?.color,
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF581C87),
      appBar: AppBar(
        backgroundColor: const Color(0xFF581C87),
        title: const Text(
          "Complete Rider Profile",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        automaticallyImplyLeading: false,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.green,
                    blurRadius: 12,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    TextFormField(
                      controller: fullNameController,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: "Full Nmae",
                        labelStyle: TextStyle(
                          color: Theme.of(context).iconTheme.color,
                        ),

                        prefixIcon: Icon(
                          Icons.person,
                          color: Theme.of(context).iconTheme.color,
                        ),

                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.black),
                        ),

                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(
                            color: Color(0xFF581C87),
                            width: 2,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    TextFormField(
                      controller: phoneController,
                      style: TextStyle(
                        color: Theme.of(context).textTheme.bodyLarge?.color,
                      ),
                      decoration: InputDecoration(
                        labelText: "Phone Number",
                        labelStyle: TextStyle(
                          color: Theme.of(context).iconTheme.color,
                        ),
                        prefixIcon: Icon(
                          Icons.phone,
                          color: Theme.of(context).iconTheme.color,
                        ),

                        enabledBorder: const OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.black),
                        ),

                        focusedBorder: const OutlineInputBorder(
                          borderSide: BorderSide(
                            color: Color(0xFF581C87),
                            width: 2,
                          ),
                        ),
                      ),
                      validator: (val) => val!.isEmpty ? "Required" : null,
                    ),

                    const SizedBox(height: 12),

                    TextFormField(
                      controller: vehicleController,
                      style: TextStyle(
                        color: Theme.of(context).textTheme.bodyLarge?.color,
                      ),
                      decoration: InputDecoration(
                        labelText: "Vehicle Number",
                        labelStyle: TextStyle(
                          color: Theme.of(context).iconTheme.color,
                        ),
                        prefixIcon: Icon(
                          Icons.directions_car,
                          color: Theme.of(context).iconTheme.color,
                        ),

                        enabledBorder: const OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.black),
                        ),

                        focusedBorder: const OutlineInputBorder(
                          borderSide: BorderSide(
                            color: Color(0xFF581C87),
                            width: 2,
                          ),
                        ),
                      ),
                      validator: (val) => val!.isEmpty ? "Required" : null,
                    ),

                    const SizedBox(height: 12),
                    TextFormField(
                      controller: addressController,
                      style: TextStyle(
                        color: Theme.of(context).textTheme.bodyLarge?.color,
                      ),
                      decoration: InputDecoration(
                        labelText: "Home Address",
                        labelStyle: TextStyle(
                          color: Theme.of(context).iconTheme.color,
                        ),
                        prefixIcon: Icon(
                          Icons.home,
                          color: Theme.of(context).iconTheme.color,
                        ),

                        enabledBorder: const OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.black),
                        ),

                        focusedBorder: const OutlineInputBorder(
                          borderSide: BorderSide(
                            color: Color(0xFF581C87),
                            width: 2,
                          ),
                        ),
                      ),
                      validator: (val) => val!.isEmpty ? "Required" : null,
                    ),

                    const SizedBox(height: 12),

                    TextFormField(
                      controller: cityController,
                      style: TextStyle(
                        color: Theme.of(context).textTheme.bodyLarge?.color,
                      ),
                      decoration: InputDecoration(
                        labelText: "State",
                        labelStyle: TextStyle(
                          color: Theme.of(context).iconTheme.color,
                        ),
                        prefixIcon: Icon(
                          Icons.location_city,
                          color: Theme.of(context).iconTheme.color,
                        ),

                        enabledBorder: const OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.black),
                        ),

                        focusedBorder: const OutlineInputBorder(
                          borderSide: BorderSide(
                            color: Color(0xFF581C87),
                            width: 2,
                          ),
                        ),
                      ),
                      validator: (val) => val!.isEmpty ? "Required" : null,
                    ),

                    const SizedBox(height: 16),

                    imagePickerTile(
                      "Profile Picture",
                      profilePicture,
                      'profile',
                    ),
                    imagePickerTile("Rider Image 1", riderImage1, 'rider1'),
                    imagePickerTile(
                      "Rider Image with Vehicle",
                      riderImageWithVehicle,
                      'withVehicle',
                    ),

                    const SizedBox(height: 24),

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: submitProfile,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF581C87),
                          foregroundColor: Colors.white,
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
            ),
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
