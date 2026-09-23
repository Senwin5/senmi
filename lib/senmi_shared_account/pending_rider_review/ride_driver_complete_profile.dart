// ignore_for_file: deprecated_member_use

import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:senmi/senmi_shared_account/pending_rider_review/ride_driver_pending_screen.dart';
import 'package:senmi/services/package_api_service.dart';

class RideDriverCompleteProfile extends StatefulWidget {
  const RideDriverCompleteProfile({super.key});

  @override
  State<RideDriverCompleteProfile> createState() =>
      _RideDriverCompleteProfileState();
}

class _RideDriverCompleteProfileState extends State<RideDriverCompleteProfile> {
  static const String _baseUrl = "https://www.senmi.com.ng/api";

  final _formKey = GlobalKey<FormState>();

  final fullNameController = TextEditingController();
  final phoneController = TextEditingController();

  final vehicleBrandController = TextEditingController();
  final vehicleModelController = TextEditingController();
  final vehicleColorController = TextEditingController();
  final vehicleYearController = TextEditingController();
  final plateNumberController = TextEditingController();

  final emergencyNameController = TextEditingController();
  final emergencyPhoneController = TextEditingController();
  final emergencyAddressController = TextEditingController();
  final emergencyRelationshipController = TextEditingController();

  final ImagePicker _picker = ImagePicker();

  File? profilePhoto;
  File? driverLicensePhoto;
  File? vehiclePhoto;

  bool loading = false;

  @override
  void dispose() {
    fullNameController.dispose();
    phoneController.dispose();

    vehicleBrandController.dispose();
    vehicleModelController.dispose();
    vehicleColorController.dispose();
    vehicleYearController.dispose();
    plateNumberController.dispose();

    emergencyNameController.dispose();
    emergencyPhoneController.dispose();
    emergencyAddressController.dispose();
    emergencyRelationshipController.dispose();

    super.dispose();
  }

  Future<void> _pickImage({required String type}) async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  "Select image source",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                ListTile(
                  leading: const Icon(Icons.camera_alt),
                  title: const Text("Take a photo"),
                  onTap: () {
                    Navigator.pop(context, ImageSource.camera);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.photo_library),
                  title: const Text("Choose from gallery"),
                  onTap: () {
                    Navigator.pop(context, ImageSource.gallery);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );

    if (source == null) return;

    final pickedFile = await _picker.pickImage(
      source: source,
      imageQuality: 70,
      maxWidth: 1200,
      maxHeight: 1200,
    );

    if (pickedFile == null) return;

    setState(() {
      final file = File(pickedFile.path);

      if (type == "profile") {
        profilePhoto = file;
      } else if (type == "license") {
        driverLicensePhoto = file;
      } else if (type == "vehicle") {
        vehiclePhoto = file;
      }
    });
  }

  bool _validateImages() {
    if (profilePhoto == null) {
      _showMessage("Please upload your profile photo.");
      return false;
    }

    if (driverLicensePhoto == null) {
      _showMessage("Please upload your driver's licence photo.");
      return false;
    }

    if (vehiclePhoto == null) {
      _showMessage("Please upload your vehicle photo.");
      return false;
    }

    return true;
  }

  void _showMessage(String message, {bool error = true}) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: error ? Colors.red : Colors.deepPurple,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _submitProfile() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (!_validateImages()) {
      return;
    }

    setState(() {
      loading = true;
    });

    try {
      await ApiService.loadToken();

      if (ApiService.token == null || ApiService.token!.isEmpty) {
        _showMessage("Your session has expired. Please login again.");

        if (mounted) {
          setState(() {
            loading = false;
          });
        }

        return;
      }

      // Check whether this driver already has a profile.
      bool isRejected = false;

      final profileCheck = await http.get(
        Uri.parse("$_baseUrl/ride/driver/profile/"),
        headers: {"Authorization": "Bearer ${ApiService.token}"},
      );

      if (profileCheck.statusCode == 200) {
        final profileData = jsonDecode(profileCheck.body);

        if (profileData is Map<String, dynamic>) {
          isRejected = profileData["status"] == "rejected";
        }
      } else if (profileCheck.statusCode != 404) {
        throw Exception("Unable to check driver profile.");
      }

      final request = http.MultipartRequest(
        isRejected ? "PUT" : "POST",
        Uri.parse("$_baseUrl/ride/driver/profile/"),
      );

      request.headers["Authorization"] = "Bearer ${ApiService.token}";

      request.fields["full_name"] = fullNameController.text.trim();

      request.fields["phone_number"] = phoneController.text.trim();

      request.fields["vehicle_brand"] = vehicleBrandController.text.trim();

      request.fields["vehicle_model"] = vehicleModelController.text.trim();

      request.fields["vehicle_color"] = vehicleColorController.text.trim();

      request.fields["vehicle_year"] = vehicleYearController.text.trim();

      request.fields["plate_number"] = plateNumberController.text.trim();

      request.fields["emergency_contact_name"] = emergencyNameController.text
          .trim();

      request.fields["emergency_contact_phone"] = emergencyPhoneController.text
          .trim();

      request.fields["emergency_contact_address"] = emergencyAddressController
          .text
          .trim();

      request.fields["emergency_contact_relationship"] =
          emergencyRelationshipController.text.trim();

      request.files.add(
        await http.MultipartFile.fromPath("profile_photo", profilePhoto!.path),
      );

      request.files.add(
        await http.MultipartFile.fromPath(
          "driver_license_photo",
          driverLicensePhoto!.path,
        ),
      );

      request.files.add(
        await http.MultipartFile.fromPath("vehicle_photo", vehiclePhoto!.path),
      );

      final response = await request.send();

      final responseBody = await response.stream.bytesToString();

      dynamic decodedBody;

      try {
        decodedBody = jsonDecode(responseBody);
      } catch (_) {
        decodedBody = {};
      }

      if (!mounted) return;

      if (response.statusCode == 201 || response.statusCode == 200) {
        setState(() {
          loading = false;
        });

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const RideDriverPendingScreen()),
        );

        return;
      }

      String message = "Profile submission failed. Please try again.";

      if (decodedBody is Map<String, dynamic>) {
        if (decodedBody["detail"] != null) {
          message = decodedBody["detail"].toString();
        } else {
          final errors = <String>[];

          decodedBody.forEach((key, value) {
            if (value is List && value.isNotEmpty) {
              errors.add("$key: ${value.first}");
            } else if (value != null) {
              errors.add("$key: $value");
            }
          });

          if (errors.isNotEmpty) {
            message = errors.join("\n");
          }
        }
      }

      setState(() {
        loading = false;
      });

      _showMessage(message);
    } catch (e) {
      if (!mounted) return;

      setState(() {
        loading = false;
      });

      _showMessage(
        "Unable to submit your profile. Please check your internet connection and try again.",
      );
    }
  }

  InputDecoration _inputDecoration({
    required String label,
    required IconData icon,
    String? hint,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: Icon(icon),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Colors.deepPurple, width: 2),
      ),
    );
  }

  Widget _imageCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required File? image,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: image != null ? Colors.deepPurple : Colors.grey.shade400,
          width: 1.5,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: loading ? null : onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  color: Colors.deepPurple.withOpacity(0.08),
                ),
                child: image != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: Image.file(image, fit: BoxFit.cover),
                      )
                    : Icon(icon, color: Colors.deepPurple, size: 32),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      image != null ? "Photo selected" : subtitle,
                      style: TextStyle(
                        color: image != null
                            ? Colors.green
                            : Colors.grey.shade600,
                        fontSize: 12.5,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                image != null ? Icons.check_circle : Icons.camera_alt_outlined,
                color: image != null ? Colors.green : Colors.deepPurple,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionTitle(String title, String subtitle) {
    return Padding(
      padding: const EdgeInsets.only(top: 10, bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Complete Driver Profile"),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        automaticallyImplyLeading: !loading,
      ),
      body: Stack(
        children: [
          Form(
            key: _formKey,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: Colors.deepPurple.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.info_outline, color: Colors.deepPurple),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            "Complete your driver profile and submit your documents. Your application will be reviewed by Senmi before you can go online.",
                            style: TextStyle(fontSize: 13, height: 1.45),
                          ),
                        ),
                      ],
                    ),
                  ),

                  _sectionTitle(
                    "Personal Information",
                    "Enter your driver details.",
                  ),

                  TextFormField(
                    controller: fullNameController,
                    textInputAction: TextInputAction.next,
                    decoration: _inputDecoration(
                      label: "Full Name",
                      icon: Icons.person_outline,
                      hint: "Enter your full name",
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return "Full name is required";
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 16),

                  TextFormField(
                    controller: phoneController,
                    keyboardType: TextInputType.phone,
                    decoration: _inputDecoration(
                      label: "Phone Number",
                      icon: Icons.phone_outlined,
                      hint: "Enter your phone number",
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return "Phone number is required";
                      }
                      return null;
                    },
                  ),

                  _sectionTitle(
                    "Vehicle Information",
                    "Enter the vehicle you will use for ride services.",
                  ),

                  TextFormField(
                    controller: vehicleBrandController,
                    textInputAction: TextInputAction.next,
                    decoration: _inputDecoration(
                      label: "Vehicle Brand",
                      icon: Icons.directions_car_outlined,
                      hint: "e.g. Toyota",
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return "Vehicle brand is required";
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 16),

                  TextFormField(
                    controller: vehicleModelController,
                    textInputAction: TextInputAction.next,
                    decoration: _inputDecoration(
                      label: "Vehicle Model",
                      icon: Icons.car_rental_outlined,
                      hint: "e.g. Corolla",
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return "Vehicle model is required";
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 16),

                  TextFormField(
                    controller: vehicleColorController,
                    decoration: _inputDecoration(
                      label: "Vehicle Color",
                      icon: Icons.color_lens_outlined,
                      hint: "e.g. Black",
                    ),
                  ),

                  const SizedBox(height: 16),

                  TextFormField(
                    controller: vehicleYearController,
                    keyboardType: TextInputType.number,
                    decoration: _inputDecoration(
                      label: "Vehicle Year",
                      icon: Icons.calendar_today_outlined,
                      hint: "e.g. 2018",
                    ),
                  ),

                  const SizedBox(height: 16),

                  TextFormField(
                    controller: plateNumberController,
                    textCapitalization: TextCapitalization.characters,
                    decoration: _inputDecoration(
                      label: "Plate Number",
                      icon: Icons.pin_outlined,
                      hint: "e.g. ABC123XY",
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return "Plate number is required";
                      }
                      return null;
                    },
                  ),

                  _sectionTitle(
                    "Driver Documents",
                    "Upload clear photos for verification.",
                  ),

                  _imageCard(
                    title: "Profile Photo",
                    subtitle: "Clear photo of your face",
                    icon: Icons.person,
                    image: profilePhoto,
                    onTap: () {
                      _pickImage(type: "profile");
                    },
                  ),

                  _imageCard(
                    title: "Driver Licence",
                    subtitle: "Clear photo of your driver's licence",
                    icon: Icons.badge_outlined,
                    image: driverLicensePhoto,
                    onTap: () {
                      _pickImage(type: "license");
                    },
                  ),

                  _imageCard(
                    title: "Vehicle Photo",
                    subtitle: "Clear photo of your vehicle",
                    icon: Icons.directions_car,
                    image: vehiclePhoto,
                    onTap: () {
                      _pickImage(type: "vehicle");
                    },
                  ),

                  _sectionTitle(
                    "Emergency Contact",
                    "Add someone Senmi can contact in an emergency.",
                  ),

                  TextFormField(
                    controller: emergencyNameController,
                    textInputAction: TextInputAction.next,
                    decoration: _inputDecoration(
                      label: "Emergency Contact Name",
                      icon: Icons.person_add_alt_1_outlined,
                      hint: "Full name",
                    ),
                  ),

                  const SizedBox(height: 16),

                  TextFormField(
                    controller: emergencyPhoneController,
                    keyboardType: TextInputType.phone,
                    textInputAction: TextInputAction.next,
                    decoration: _inputDecoration(
                      label: "Emergency Contact Phone",
                      icon: Icons.phone_in_talk_outlined,
                      hint: "Phone number",
                    ),
                  ),

                  const SizedBox(height: 16),

                  TextFormField(
                    controller: emergencyRelationshipController,
                    textInputAction: TextInputAction.next,
                    decoration: _inputDecoration(
                      label: "Relationship",
                      icon: Icons.family_restroom_outlined,
                      hint: "e.g. Brother, Sister, Spouse",
                    ),
                  ),

                  const SizedBox(height: 16),

                  TextFormField(
                    controller: emergencyAddressController,
                    maxLines: 2,
                    decoration: _inputDecoration(
                      label: "Emergency Contact Address",
                      icon: Icons.home_outlined,
                      hint: "Enter their address",
                    ),
                  ),

                  const SizedBox(height: 28),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: loading ? null : _submitProfile,
                      icon: const Icon(Icons.send_rounded),
                      label: const Text("Submit Driver Profile"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepPurple,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 17),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),

          if (loading)
            Container(
              color: Colors.black.withOpacity(0.45),
              child: const Center(
                child: Card(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(color: Colors.deepPurple),
                        SizedBox(height: 16),
                        Text(
                          "Submitting profile...",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
