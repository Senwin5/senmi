// ignore_for_file: deprecated_member_use

import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:senmi/senmi_shared_account/pending_rider_review/ride_driver_pending_screen.dart';
import 'package:senmi/services/package_api_service.dart';

import 'package:shared_preferences/shared_preferences.dart';

class RideDriverCompleteProfile extends StatefulWidget {
  const RideDriverCompleteProfile({super.key});

  @override
  State<RideDriverCompleteProfile> createState() =>
      _RideDriverCompleteProfileState();
}

class _RideDriverCompleteProfileState extends State<RideDriverCompleteProfile> {
  static const String _baseUrl = "https://www.senmi.com.ng/api";

  final ImagePicker _picker = ImagePicker();

  final _personalFormKey = GlobalKey<FormState>();
  final _vehicleFormKey = GlobalKey<FormState>();
  final _emergencyFormKey = GlobalKey<FormState>();

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

  File? profilePhoto;
  File? driverLicensePhoto;
  File? vehiclePhoto;

  bool loading = true;
  bool saving = false;
  bool hasSavedProgress = false;

  int currentStep = 0;

  // ============================================================
  // LOCAL STORAGE KEYS
  // ============================================================

  static const String _stepKey = "ride_driver_profile_step";

  static const String _fullNameKey = "ride_driver_profile_full_name";
  static const String _phoneKey = "ride_driver_profile_phone";

  static const String _vehicleBrandKey = "ride_driver_profile_vehicle_brand";
  static const String _vehicleModelKey = "ride_driver_profile_vehicle_model";
  static const String _vehicleColorKey = "ride_driver_profile_vehicle_color";
  static const String _vehicleYearKey = "ride_driver_profile_vehicle_year";
  static const String _plateNumberKey = "ride_driver_profile_plate_number";

  static const String _emergencyNameKey = "ride_driver_profile_emergency_name";
  static const String _emergencyPhoneKey =
      "ride_driver_profile_emergency_phone";
  static const String _emergencyAddressKey =
      "ride_driver_profile_emergency_address";
  static const String _emergencyRelationshipKey =
      "ride_driver_profile_emergency_relationship";

  static const String _profilePhotoKey = "ride_driver_profile_photo";
  static const String _licensePhotoKey = "ride_driver_profile_license_photo";
  static const String _vehiclePhotoKey = "ride_driver_profile_vehicle_photo";

  @override
  void initState() {
    super.initState();

    _loadSavedProgress();
  }

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

  // ============================================================
  // LOAD SAVED PROGRESS
  // ============================================================

  Future<void> _loadSavedProgress() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      fullNameController.text = prefs.getString(_fullNameKey) ?? "";

      phoneController.text = prefs.getString(_phoneKey) ?? "";

      vehicleBrandController.text = prefs.getString(_vehicleBrandKey) ?? "";

      vehicleModelController.text = prefs.getString(_vehicleModelKey) ?? "";

      vehicleColorController.text = prefs.getString(_vehicleColorKey) ?? "";

      vehicleYearController.text = prefs.getString(_vehicleYearKey) ?? "";

      plateNumberController.text = prefs.getString(_plateNumberKey) ?? "";

      emergencyNameController.text = prefs.getString(_emergencyNameKey) ?? "";

      emergencyPhoneController.text = prefs.getString(_emergencyPhoneKey) ?? "";

      emergencyAddressController.text =
          prefs.getString(_emergencyAddressKey) ?? "";

      emergencyRelationshipController.text =
          prefs.getString(_emergencyRelationshipKey) ?? "";

      final savedStep = prefs.getInt(_stepKey) ?? 0;

      final savedProfilePhoto = prefs.getString(_profilePhotoKey);

      final savedLicensePhoto = prefs.getString(_licensePhotoKey);

      final savedVehiclePhoto = prefs.getString(_vehiclePhotoKey);

      if (savedProfilePhoto != null && File(savedProfilePhoto).existsSync()) {
        profilePhoto = File(savedProfilePhoto);
      }

      if (savedLicensePhoto != null && File(savedLicensePhoto).existsSync()) {
        driverLicensePhoto = File(savedLicensePhoto);
      }

      if (savedVehiclePhoto != null && File(savedVehiclePhoto).existsSync()) {
        vehiclePhoto = File(savedVehiclePhoto);
      }

      final hasAnyData =
          fullNameController.text.isNotEmpty ||
          phoneController.text.isNotEmpty ||
          vehicleBrandController.text.isNotEmpty ||
          vehicleModelController.text.isNotEmpty ||
          vehicleColorController.text.isNotEmpty ||
          vehicleYearController.text.isNotEmpty ||
          plateNumberController.text.isNotEmpty ||
          emergencyNameController.text.isNotEmpty ||
          emergencyPhoneController.text.isNotEmpty ||
          emergencyAddressController.text.isNotEmpty ||
          emergencyRelationshipController.text.isNotEmpty ||
          profilePhoto != null ||
          driverLicensePhoto != null ||
          vehiclePhoto != null;

      if (!mounted) return;

      setState(() {
        currentStep = savedStep.clamp(0, 2);
        hasSavedProgress = hasAnyData;
        loading = false;
      });

      if (hasAnyData) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Row(
                children: [
                  Icon(Icons.restore_rounded, color: Colors.white),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text("Your saved progress has been restored."),
                  ),
                ],
              ),
              backgroundColor: Colors.deepPurple,
              behavior: SnackBarBehavior.floating,
            ),
          );
        });
      }
    } catch (e) {
      debugPrint("LOAD DRIVER PROFILE PROGRESS ERROR: $e");

      if (!mounted) return;

      setState(() {
        loading = false;
      });
    }
  }

  // ============================================================
  // SAVE TEXT PROGRESS
  // ============================================================

  Future<void> _saveTextProgress() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      await prefs.setString(_fullNameKey, fullNameController.text);

      await prefs.setString(_phoneKey, phoneController.text);

      await prefs.setString(_vehicleBrandKey, vehicleBrandController.text);

      await prefs.setString(_vehicleModelKey, vehicleModelController.text);

      await prefs.setString(_vehicleColorKey, vehicleColorController.text);

      await prefs.setString(_vehicleYearKey, vehicleYearController.text);

      await prefs.setString(_plateNumberKey, plateNumberController.text);

      await prefs.setString(_emergencyNameKey, emergencyNameController.text);

      await prefs.setString(_emergencyPhoneKey, emergencyPhoneController.text);

      await prefs.setString(
        _emergencyAddressKey,
        emergencyAddressController.text,
      );

      await prefs.setString(
        _emergencyRelationshipKey,
        emergencyRelationshipController.text,
      );
    } catch (e) {
      debugPrint("SAVE DRIVER PROFILE PROGRESS ERROR: $e");
    }
  }

  // ============================================================
  // SAVE CURRENT STEP
  // ============================================================

  Future<void> _saveCurrentStep() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      await prefs.setInt(_stepKey, currentStep);

      await _saveTextProgress();
    } catch (e) {
      debugPrint("SAVE DRIVER STEP ERROR: $e");
    }
  }

  // ============================================================
  // SAVE IMAGE PERMANENTLY
  // ============================================================

  Future<File> _saveImagePermanently(File source, String fileName) async {
    final directory = await getApplicationDocumentsDirectory();

    final driverDirectory = Directory("${directory.path}/ride_driver_profile");

    if (!await driverDirectory.exists()) {
      await driverDirectory.create(recursive: true);
    }

    final target = File("${driverDirectory.path}/$fileName");

    return source.copy(target.path);
  }

  // ============================================================
  // PICK IMAGE
  // ============================================================

  Future<void> _pickImage({required String type}) async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 42,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  "Select image source",
                  style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 18),
                ListTile(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.deepPurple.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.camera_alt_rounded,
                      color: Colors.deepPurple,
                    ),
                  ),
                  title: const Text(
                    "Take a photo",
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: const Text("Use your camera"),
                  onTap: () {
                    Navigator.pop(context, ImageSource.camera);
                  },
                ),
                const SizedBox(height: 8),
                ListTile(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.deepPurple.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.photo_library_rounded,
                      color: Colors.deepPurple,
                    ),
                  ),
                  title: const Text(
                    "Choose from gallery",
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: const Text("Select an existing photo"),
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

    try {
      setState(() {
        saving = true;
      });

      final temporaryFile = File(pickedFile.path);

      String fileName;

      if (type == "profile") {
        fileName = "profile_photo.jpg";
      } else if (type == "license") {
        fileName = "driver_license_photo.jpg";
      } else {
        fileName = "vehicle_photo.jpg";
      }

      final savedFile = await _saveImagePermanently(temporaryFile, fileName);

      final prefs = await SharedPreferences.getInstance();

      if (type == "profile") {
        profilePhoto = savedFile;

        await prefs.setString(_profilePhotoKey, savedFile.path);
      } else if (type == "license") {
        driverLicensePhoto = savedFile;

        await prefs.setString(_licensePhotoKey, savedFile.path);
      } else {
        vehiclePhoto = savedFile;

        await prefs.setString(_vehiclePhotoKey, savedFile.path);
      }

      if (!mounted) return;

      setState(() {
        saving = false;
      });
    } catch (e) {
      debugPrint("SAVE DRIVER IMAGE ERROR: $e");

      if (!mounted) return;

      setState(() {
        saving = false;
      });

      _showMessage("Unable to save this photo. Please try again.");
    }
  }

  // ============================================================
  // VALIDATION
  // ============================================================

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

  // ============================================================
  // NEXT STEP
  // ============================================================

  Future<void> _nextStep() async {
    if (currentStep == 0) {
      if (!_personalFormKey.currentState!.validate()) {
        return;
      }
    }

    if (currentStep == 1) {
      if (!_vehicleFormKey.currentState!.validate()) {
        return;
      }

      if (!_validateImages()) {
        return;
      }
    }

    await _saveCurrentStep();

    if (!mounted) return;

    setState(() {
      currentStep++;
    });

    await _saveCurrentStep();
  }

  // ============================================================
  // PREVIOUS STEP
  // ============================================================

  Future<void> _previousStep() async {
    if (currentStep == 0) {
      return;
    }

    await _saveCurrentStep();

    if (!mounted) return;

    setState(() {
      currentStep--;
    });

    await _saveCurrentStep();
  }

  // ============================================================
  // SUBMIT PROFILE
  // ============================================================

  Future<void> _submitProfile() async {
    if (!_emergencyFormKey.currentState!.validate()) {
      return;
    }

    if (!_validateImages()) {
      return;
    }

    await _saveTextProgress();

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
        await _clearSavedProgress();

        if (!mounted) return;

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
      debugPrint("SUBMIT DRIVER PROFILE ERROR: $e");

      if (!mounted) return;

      setState(() {
        loading = false;
      });

      _showMessage(
        "Unable to submit your profile. Please check your internet connection and try again.",
      );
    }
  }

  // ============================================================
  // CLEAR SAVED PROGRESS AFTER SUCCESSFUL SUBMISSION
  // ============================================================

  Future<void> _clearSavedProgress() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      await prefs.remove(_stepKey);

      await prefs.remove(_fullNameKey);
      await prefs.remove(_phoneKey);

      await prefs.remove(_vehicleBrandKey);
      await prefs.remove(_vehicleModelKey);
      await prefs.remove(_vehicleColorKey);
      await prefs.remove(_vehicleYearKey);
      await prefs.remove(_plateNumberKey);

      await prefs.remove(_emergencyNameKey);
      await prefs.remove(_emergencyPhoneKey);
      await prefs.remove(_emergencyAddressKey);
      await prefs.remove(_emergencyRelationshipKey);

      await prefs.remove(_profilePhotoKey);
      await prefs.remove(_licensePhotoKey);
      await prefs.remove(_vehiclePhotoKey);

      try {
        if (profilePhoto != null && await profilePhoto!.exists()) {
          await profilePhoto!.delete();
        }

        if (driverLicensePhoto != null && await driverLicensePhoto!.exists()) {
          await driverLicensePhoto!.delete();
        }

        if (vehiclePhoto != null && await vehiclePhoto!.exists()) {
          await vehiclePhoto!.delete();
        }
      } catch (_) {}
    } catch (e) {
      debugPrint("CLEAR DRIVER PROFILE PROGRESS ERROR: $e");
    }
  }

  // ============================================================
  // MESSAGE
  // ============================================================

  void _showMessage(String message, {bool error = true}) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: error ? Colors.red : Colors.deepPurple,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }

  // ============================================================
  // INPUT DECORATION
  // ============================================================

  InputDecoration _inputDecoration({
    required String label,
    required IconData icon,
    String? hint,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: Icon(icon),
      filled: true,
      fillColor: Theme.of(context).brightness == Brightness.dark
          ? const Color(0xFF1E1E1E)
          : Colors.white,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Colors.deepPurple, width: 2),
      ),
    );
  }

  // ============================================================
  // IMAGE CARD
  // ============================================================

  Widget _imageCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required File? image,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: image != null ? Colors.deepPurple : Colors.grey.shade400,
          width: 1.4,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: loading || saving ? null : onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 72,
                height: 72,
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
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      image != null ? "Photo selected" : subtitle,
                      style: TextStyle(
                        color: image != null
                            ? Colors.green
                            : isDark
                            ? Colors.white60
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

  // ============================================================
  // SECTION TITLE
  // ============================================================

  Widget _sectionTitle(String title, String subtitle) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 21,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            subtitle,
            style: TextStyle(
              color: isDark ? Colors.white60 : Colors.grey.shade600,
              fontSize: 13,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // STEP INDICATOR
  // ============================================================

  Widget _stepIndicator() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    const titles = ["Personal", "Vehicle", "Emergency"];

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
      child: Row(
        children: List.generate(3, (index) {
          final active = currentStep >= index;

          return Expanded(
            child: Row(
              children: [
                Column(
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: active
                            ? Colors.deepPurple
                            : isDark
                            ? Colors.white12
                            : Colors.grey.shade200,
                      ),
                      child: Center(
                        child: currentStep > index
                            ? const Icon(
                                Icons.check,
                                color: Colors.white,
                                size: 20,
                              )
                            : Text(
                                "${index + 1}",
                                style: TextStyle(
                                  color: active
                                      ? Colors.white
                                      : isDark
                                      ? Colors.white54
                                      : Colors.grey,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      titles[index],
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: active
                            ? FontWeight.bold
                            : FontWeight.normal,
                        color: active
                            ? Colors.deepPurple
                            : isDark
                            ? Colors.white54
                            : Colors.grey,
                      ),
                    ),
                  ],
                ),
                if (index < 2)
                  Expanded(
                    child: Container(
                      height: 2,
                      margin: const EdgeInsets.only(
                        bottom: 20,
                        left: 6,
                        right: 6,
                      ),
                      color: currentStep > index
                          ? Colors.deepPurple
                          : isDark
                          ? Colors.white12
                          : Colors.grey.shade300,
                    ),
                  ),
              ],
            ),
          );
        }),
      ),
    );
  }

  // ============================================================
  // STEP 1
  // ============================================================

  Widget _personalStep() {
    return Form(
      key: _personalFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle(
            "Personal Information",
            "Tell us about yourself as a Ride Driver.",
          ),
          TextFormField(
            controller: fullNameController,
            textInputAction: TextInputAction.next,
            onChanged: (_) {
              _saveTextProgress();
            },
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
            onChanged: (_) {
              _saveTextProgress();
            },
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
        ],
      ),
    );
  }

  // ============================================================
  // STEP 2
  // ============================================================

  Widget _vehicleStep() {
    return Form(
      key: _vehicleFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle(
            "Vehicle & Documents",
            "Provide the vehicle information and verification photos.",
          ),

          TextFormField(
            controller: vehicleBrandController,
            textInputAction: TextInputAction.next,
            onChanged: (_) {
              _saveTextProgress();
            },
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
            onChanged: (_) {
              _saveTextProgress();
            },
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
            onChanged: (_) {
              _saveTextProgress();
            },
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
            onChanged: (_) {
              _saveTextProgress();
            },
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
            onChanged: (_) {
              _saveTextProgress();
            },
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

          const SizedBox(height: 24),

          Text(
            "Verification Photos",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.white
                  : Colors.black87,
            ),
          ),

          const SizedBox(height: 5),

          Text(
            "Upload clear photos. These will be reviewed by Senmi.",
            style: TextStyle(
              fontSize: 13,
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.white60
                  : Colors.grey.shade600,
            ),
          ),

          const SizedBox(height: 14),

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
        ],
      ),
    );
  }

  // ============================================================
  // STEP 3
  // ============================================================

  Widget _emergencyStep() {
    return Form(
      key: _emergencyFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle(
            "Emergency Contact",
            "Add someone Senmi can contact if there is an emergency.",
          ),

          TextFormField(
            controller: emergencyNameController,
            textInputAction: TextInputAction.next,
            onChanged: (_) {
              _saveTextProgress();
            },
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
            onChanged: (_) {
              _saveTextProgress();
            },
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
            onChanged: (_) {
              _saveTextProgress();
            },
            decoration: _inputDecoration(
              label: "Relationship",
              icon: Icons.family_restroom_outlined,
              hint: "e.g. Brother, Sister, Spouse",
            ),
          ),

          const SizedBox(height: 16),

          TextFormField(
            controller: emergencyAddressController,
            maxLines: 3,
            onChanged: (_) {
              _saveTextProgress();
            },
            decoration: _inputDecoration(
              label: "Emergency Contact Address",
              icon: Icons.home_outlined,
              hint: "Enter their address",
            ),
          ),

          const SizedBox(height: 20),

          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.deepPurple.withOpacity(0.08),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.verified_user_outlined, color: Colors.deepPurple),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    "Review your information before submitting. Once submitted, your driver profile will be sent to Senmi for admin approval.",
                    style: TextStyle(fontSize: 13, height: 1.5),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // CURRENT STEP
  // ============================================================

  Widget _currentStepWidget() {
    switch (currentStep) {
      case 0:
        return _personalStep();

      case 1:
        return _vehicleStep();

      case 2:
        return _emergencyStep();

      default:
        return _personalStep();
    }
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (loading) {
      return Scaffold(
        backgroundColor: isDark
            ? const Color(0xFF121212)
            : const Color(0xFFF7F5FB),
        body: const Center(
          child: CircularProgressIndicator(color: Colors.deepPurple),
        ),
      );
    }

    return WillPopScope(
      onWillPop: () async {
        if (loading || saving) {
          return false;
        }

        if (currentStep > 0) {
          await _previousStep();
          return false;
        }

        await _saveCurrentStep();
        return true;
      },
      child: Scaffold(
        backgroundColor: isDark
            ? const Color(0xFF121212)
            : const Color(0xFFF7F5FB),
        appBar: AppBar(
          title: const Text("Complete Driver Profile"),
          backgroundColor: Colors.deepPurple,
          foregroundColor: Colors.white,
          elevation: 0,
          automaticallyImplyLeading: !loading && !saving,
        ),
        body: Column(
          children: [
            _stepIndicator(),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 650),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (hasSavedProgress)
                        Container(
                          width: double.infinity,
                          margin: const EdgeInsets.only(bottom: 18),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.deepPurple.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: Colors.deepPurple.withOpacity(0.12),
                            ),
                          ),
                          child: const Row(
                            children: [
                              Icon(
                                Icons.save_outlined,
                                color: Colors.deepPurple,
                                size: 21,
                              ),
                              SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  "Your progress is saved automatically. You can safely continue later.",
                                  style: TextStyle(fontSize: 13, height: 1.4),
                                ),
                              ),
                            ],
                          ),
                        ),

                      _currentStepWidget(),

                      const SizedBox(height: 30),

                      // ------------------------------------------------
                      // NAVIGATION BUTTONS
                      // ------------------------------------------------
                      Row(
                        children: [
                          if (currentStep > 0)
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: loading || saving
                                    ? null
                                    : _previousStep,
                                icon: const Icon(Icons.arrow_back_rounded),
                                label: const Text("Back"),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.deepPurple,
                                  side: BorderSide(
                                    color: Colors.deepPurple.withOpacity(0.45),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 16,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                ),
                              ),
                            ),

                          if (currentStep > 0) const SizedBox(width: 12),

                          Expanded(
                            flex: currentStep == 0 ? 1 : 2,
                            child: ElevatedButton.icon(
                              onPressed: loading || saving
                                  ? null
                                  : currentStep == 2
                                  ? _submitProfile
                                  : _nextStep,
                              icon: saving
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : Icon(
                                      currentStep == 2
                                          ? Icons.send_rounded
                                          : Icons.arrow_forward_rounded,
                                    ),
                              label: Text(
                                currentStep == 2
                                    ? "Submit Driver Profile"
                                    : "Next",
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.deepPurple,
                                foregroundColor: Colors.white,
                                disabledBackgroundColor: Colors.deepPurple
                                    .withOpacity(0.4),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                elevation: 2,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 14),

                      Center(
                        child: Text(
                          "Step ${currentStep + 1} of 3",
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark
                                ? Colors.white54
                                : Colors.grey.shade600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),

        // ------------------------------------------------------------
        // SUBMISSION OVERLAY
        // ------------------------------------------------------------
        bottomNavigationBar: loading
            ? Container(
                height: 72,
                color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: Colors.deepPurple,
                      ),
                    ),
                    SizedBox(width: 12),
                    Text(
                      "Submitting profile...",
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              )
            : null,
      ),
    );
  }
}
