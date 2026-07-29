// ignore_for_file: deprecated_member_use

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:image_picker/image_picker.dart';
import 'package:senmi/screen_package_pages/features/rider/pending_rider_review/rider_pending_screen.dart';
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

  static const Color _primaryColor = Color(0xFF581C87);
  static const Color _secondaryColor = Color(0xFF7E22CE);
  static const Color _softPurple = Color(0xFFF5EDFF);
  static const Color _darkBackground = Color(0xFF16091F);

  @override
  void dispose() {
    fullNameController.dispose();
    phoneController.dispose();
    vehicleController.dispose();
    addressController.dispose();
    cityController.dispose();
    super.dispose();
  }

  Future<void> pickImage(String type) async {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final sheetColor = isDark ? const Color(0xFF211129) : Colors.white;

        return SafeArea(
          child: Container(
            margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
            decoration: BoxDecoration(
              color: sheetColor,
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.20),
                  blurRadius: 30,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 44,
                  height: 5,
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withOpacity(0.20)
                        : Colors.black.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Add a photo',
                  style: TextStyle(
                    color: Theme.of(context).textTheme.titleLarge?.color,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Choose how you want to upload this image',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.color?.withOpacity(0.65),
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 22),

                _bottomSheetOption(
                  icon: Icons.camera_alt_rounded,
                  title: 'Take a photo',
                  subtitle: 'Use your phone camera',
                  onTap: () async {
                    Navigator.pop(context);

                    var status = await Permission.camera.request();

                    if (status.isGranted) {
                      final image = await _picker.pickImage(
                        source: ImageSource.camera,
                      );

                      if (image != null && mounted) {
                        setState(() {
                          if (type == 'profile') {
                            profilePicture = File(image.path);
                          }
                          if (type == 'rider1') {
                            riderImage1 = File(image.path);
                          }
                          if (type == 'withVehicle') {
                            riderImageWithVehicle = File(image.path);
                          }
                        });
                      }
                    } else {
                      if (!mounted) return;

                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Camera permission denied'),
                        ),
                      );
                    }
                  },
                ),

                const SizedBox(height: 12),

                _bottomSheetOption(
                  icon: Icons.photo_library_rounded,
                  title: 'Choose from gallery',
                  subtitle: 'Select an existing photo',
                  onTap: () async {
                    Navigator.pop(context);

                    final image = await _picker.pickImage(
                      source: ImageSource.gallery,
                    );

                    if (image != null && mounted) {
                      setState(() {
                        if (type == 'profile') {
                          profilePicture = File(image.path);
                        }
                        if (type == 'rider1') {
                          riderImage1 = File(image.path);
                        }
                        if (type == 'withVehicle') {
                          riderImageWithVehicle = File(image.path);
                        }
                      });
                    }
                  },
                ),
              ],
            ),
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
      ).showSnackBar(const SnackBar(content: Text('All images are required.')));
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

    if (!mounted) return;

    setState(() => loading = false);

    if (res.containsKey('error')) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(res['error']),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (res.containsKey('message')) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          contentPadding: const EdgeInsets.fromLTRB(24, 26, 24, 12),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: const BoxDecoration(
                  color: Color(0xFFEDE9FE),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle_rounded,
                  color: _primaryColor,
                  size: 42,
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                'Profile submitted',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 21, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 10),
              Text(
                res['message'],
                textAlign: TextAlign.center,
                style: TextStyle(
                  height: 1.5,
                  color: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.color?.withOpacity(0.70),
                ),
              ),
            ],
          ),
          actionsPadding: const EdgeInsets.fromLTRB(24, 8, 24, 22),
          actions: [
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const RiderPendingScreen(),
                    ),
                  );

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Profile submitted! Waiting for admin approval.',
                      ),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primaryColor,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text(
                  'Continue',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to submit profile: ${res.toString()}'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Widget _bottomSheetOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: isDark ? Colors.white.withOpacity(0.06) : const Color(0xFFF8F5FB),
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.all(15),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: const BoxDecoration(
                  color: Color(0xFFEDE9FE),
                  borderRadius: BorderRadius.all(Radius.circular(14)),
                ),
                child: Icon(icon, color: _primaryColor),
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
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 13,
                        color: Theme.of(
                          context,
                        ).textTheme.bodySmall?.color?.withOpacity(0.65),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: Theme.of(context).iconTheme.color?.withOpacity(0.40),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionTitle({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Padding(
      padding: const EdgeInsets.only(top: 4, bottom: 15),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: const BoxDecoration(
              color: Color(0xFFEDE9FE),
              borderRadius: BorderRadius.all(Radius.circular(13)),
            ),
            child: Icon(icon, color: _primaryColor, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.35,
                    color: Theme.of(
                      context,
                    ).textTheme.bodySmall?.color?.withOpacity(0.65),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    required String? Function(String?) validator,
    TextInputType? keyboardType,
    int maxLines = 1,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: TextFormField(
        controller: controller,
        validator: validator,
        keyboardType: keyboardType,
        maxLines: maxLines,
        textInputAction: maxLines > 1
            ? TextInputAction.newline
            : TextInputAction.next,
        style: TextStyle(
          color: Theme.of(context).textTheme.bodyLarge?.color,
          fontSize: 15,
          fontWeight: FontWeight.w500,
        ),
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          alignLabelWithHint: maxLines > 1,
          filled: true,
          fillColor: isDark
              ? Colors.white.withOpacity(0.055)
              : const Color(0xFFFAF8FC),
          prefixIcon: Padding(
            padding: EdgeInsets.only(bottom: maxLines > 1 ? 56 : 0),
            child: Icon(icon, color: _primaryColor),
          ),
          labelStyle: TextStyle(
            color: Theme.of(
              context,
            ).textTheme.bodyMedium?.color?.withOpacity(0.72),
            fontWeight: FontWeight.w500,
          ),
          hintStyle: TextStyle(
            color: Theme.of(
              context,
            ).textTheme.bodyMedium?.color?.withOpacity(0.35),
            fontSize: 14,
          ),
          contentPadding: EdgeInsets.symmetric(
            horizontal: 18,
            vertical: maxLines > 1 ? 17 : 18,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(
              color: isDark
                  ? Colors.white.withOpacity(0.10)
                  : const Color(0xFFE6DFE9),
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(
              color: isDark
                  ? Colors.white.withOpacity(0.10)
                  : const Color(0xFFE6DFE9),
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: _primaryColor, width: 1.8),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Colors.redAccent),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Colors.redAccent, width: 1.6),
          ),
        ),
      ),
    );
  }

  Widget imagePickerTile({
    required String label,
    required String subtitle,
    required File? file,
    required String type,
    required IconData icon,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hasImage = file != null;

    return Padding(
      padding: const EdgeInsets.only(bottom: 13),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(19),
        child: InkWell(
          onTap: () => pickImage(type),
          borderRadius: BorderRadius.circular(19),
          child: Ink(
            height: 138,
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withOpacity(0.045)
                  : const Color(0xFFFAF8FC),
              borderRadius: BorderRadius.circular(19),
              border: Border.all(
                color: hasImage
                    ? _secondaryColor
                    : isDark
                    ? Colors.white.withOpacity(0.13)
                    : const Color(0xFFE3DBE7),
                width: hasImage ? 1.5 : 1,
              ),
            ),
            child: hasImage
                ? Stack(
                    fit: StackFit.expand,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(18),
                        child: Image.file(file, fit: BoxFit.cover),
                      ),
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(18),
                          gradient: LinearGradient(
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                            colors: [
                              Colors.black.withOpacity(0.68),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                      Positioned(
                        left: 15,
                        right: 15,
                        bottom: 13,
                        child: Row(
                          children: [
                            const Icon(
                              Icons.check_circle_rounded,
                              color: Colors.white,
                              size: 21,
                            ),
                            const SizedBox(width: 7),
                            Expanded(
                              child: Text(
                                '$label added',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 11,
                                vertical: 7,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.20),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Text(
                                'Change',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  )
                : Row(
                    children: [
                      const SizedBox(width: 16),
                      Container(
                        width: 54,
                        height: 54,
                        decoration: const BoxDecoration(
                          color: Color(0xFFEDE9FE),
                          borderRadius: BorderRadius.all(Radius.circular(17)),
                        ),
                        child: Icon(icon, color: _primaryColor, size: 27),
                      ),
                      const SizedBox(width: 15),
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              label,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              subtitle,
                              style: TextStyle(
                                fontSize: 12.5,
                                height: 1.35,
                                color: Theme.of(
                                  context,
                                ).textTheme.bodySmall?.color?.withOpacity(0.62),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Padding(
                        padding: EdgeInsets.only(right: 16),
                        child: Icon(
                          Icons.add_circle_outline_rounded,
                          color: _primaryColor,
                          size: 26,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final pageBackground = isDark ? _darkBackground : const Color(0xFFF7F3F9);

    final cardColor = isDark ? const Color(0xFF211129) : Colors.white;

    return Scaffold(
      backgroundColor: pageBackground,
      body: Stack(
        children: [
          CustomScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            slivers: [
              SliverAppBar(
                expandedHeight: 245,
                pinned: true,
                elevation: 0,
                backgroundColor: _primaryColor,
                automaticallyImplyLeading: false,
                leading: Padding(
                  padding: const EdgeInsets.only(left: 10, top: 6, bottom: 6),
                  child: IconButton(
                    icon: const Icon(Icons.close_rounded, color: Colors.white),
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    tooltip: 'Close',
                  ),
                ),
                flexibleSpace: FlexibleSpaceBar(
                  collapseMode: CollapseMode.pin,
                  background: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Color(0xFF3B0A5F),
                          Color(0xFF581C87),
                          Color(0xFF7E22CE),
                        ],
                      ),
                    ),
                    child: Stack(
                      children: [
                        Positioned(
                          top: -65,
                          right: -45,
                          child: Container(
                            width: 190,
                            height: 190,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white.withOpacity(0.07),
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: -55,
                          left: -35,
                          child: Container(
                            width: 155,
                            height: 155,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white.withOpacity(0.06),
                            ),
                          ),
                        ),
                        SafeArea(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(28, 72, 28, 28),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 11,
                                    vertical: 7,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.13),
                                    borderRadius: BorderRadius.circular(30),
                                    border: Border.all(
                                      color: Colors.white.withOpacity(0.16),
                                    ),
                                  ),
                                  child: const Text(
                                    'RIDER VERIFICATION',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 1.2,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 15),
                                const Text(
                                  'Complete your profile',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 29,
                                    height: 1.1,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: -0.5,
                                  ),
                                ),
                                const SizedBox(height: 9),
                                Text(
                                  'Provide your details and verification photos to get approved.',
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.78),
                                    fontSize: 14,
                                    height: 1.45,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(isDark ? 0.22 : 0.08),
                          blurRadius: 24,
                          offset: const Offset(0, 8),
                        ),
                      ],
                      border: Border.all(
                        color: isDark
                            ? Colors.white.withOpacity(0.06)
                            : Colors.white,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: const BoxDecoration(
                            color: Color(0xFFEDE9FE),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.verified_user_rounded,
                            color: _primaryColor,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 14),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Verification information',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'All fields and photos are required.',
                                style: TextStyle(
                                  fontSize: 12.5,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 40),
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 720),
                    margin: const EdgeInsets.symmetric(horizontal: 0),
                    padding: const EdgeInsets.fromLTRB(18, 22, 18, 20),
                    decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius: BorderRadius.circular(25),
                      border: Border.all(
                        color: isDark
                            ? Colors.white.withOpacity(0.06)
                            : const Color(0xFFEDE6F0),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(
                            isDark ? 0.16 : 0.045,
                          ),
                          blurRadius: 28,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _sectionTitle(
                            icon: Icons.person_outline_rounded,
                            title: 'Personal information',
                            subtitle:
                                'Enter the details associated with your rider account.',
                          ),

                          _buildTextField(
                            controller: fullNameController,
                            label: 'Full name',
                            hint: 'Enter your full name',
                            icon: Icons.person_outline_rounded,
                            validator: (val) =>
                                val == null || val.trim().isEmpty
                                ? 'Full name is required'
                                : null,
                            keyboardType: TextInputType.name,
                          ),

                          _buildTextField(
                            controller: phoneController,
                            label: 'Phone number',
                            hint: 'Enter your active phone number',
                            icon: Icons.phone_outlined,
                            validator: (val) =>
                                val == null || val.trim().isEmpty
                                ? 'Phone number is required'
                                : null,
                            keyboardType: TextInputType.phone,
                          ),

                          const SizedBox(height: 6),

                          Divider(
                            color: isDark
                                ? Colors.white.withOpacity(0.08)
                                : const Color(0xFFECE6EF),
                          ),

                          const SizedBox(height: 20),

                          _sectionTitle(
                            icon: Icons.two_wheeler_rounded,
                            title: 'Vehicle information',
                            subtitle:
                                'Provide the vehicle number used for deliveries.',
                          ),

                          _buildTextField(
                            controller: vehicleController,
                            label: 'Vehicle number',
                            hint: 'Enter your vehicle registration number',
                            icon: Icons.directions_car_outlined,
                            validator: (val) =>
                                val == null || val.trim().isEmpty
                                ? 'Vehicle number is required'
                                : null,
                            keyboardType: TextInputType.text,
                          ),

                          const SizedBox(height: 6),

                          Divider(
                            color: isDark
                                ? Colors.white.withOpacity(0.08)
                                : const Color(0xFFECE6EF),
                          ),

                          const SizedBox(height: 20),

                          _sectionTitle(
                            icon: Icons.location_on_outlined,
                            title: 'Address information',
                            subtitle: 'Tell us where you are currently based.',
                          ),

                          _buildTextField(
                            controller: addressController,
                            label: 'Home address',
                            hint: 'Enter your full home address',
                            icon: Icons.home_outlined,
                            validator: (val) =>
                                val == null || val.trim().isEmpty
                                ? 'Home address is required'
                                : null,
                            keyboardType: TextInputType.streetAddress,
                            maxLines: 2,
                          ),

                          _buildTextField(
                            controller: cityController,
                            label: 'State',
                            hint: 'Enter your state',
                            icon: Icons.location_city_outlined,
                            validator: (val) =>
                                val == null || val.trim().isEmpty
                                ? 'State is required'
                                : null,
                            keyboardType: TextInputType.text,
                          ),

                          const SizedBox(height: 7),

                          Divider(
                            color: isDark
                                ? Colors.white.withOpacity(0.08)
                                : const Color(0xFFECE6EF),
                          ),

                          const SizedBox(height: 20),

                          _sectionTitle(
                            icon: Icons.photo_camera_outlined,
                            title: 'Verification photos',
                            subtitle:
                                'Upload clear and recent photos. Make sure your face and vehicle are visible.',
                          ),

                          imagePickerTile(
                            label: 'Profile picture',
                            subtitle: 'Upload a clear photo of your face',
                            file: profilePicture,
                            type: 'profile',
                            icon: Icons.account_circle_outlined,
                          ),

                          imagePickerTile(
                            label: 'Rider photo',
                            subtitle: 'Upload a clear full photo of yourself',
                            file: riderImage1,
                            type: 'rider1',
                            icon: Icons.person_pin_outlined,
                          ),

                          imagePickerTile(
                            label: 'Photo with your vehicle',
                            subtitle:
                                'Make sure you and your vehicle are clearly visible',
                            file: riderImageWithVehicle,
                            type: 'withVehicle',
                            icon: Icons.two_wheeler_rounded,
                          ),

                          const SizedBox(height: 12),

                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? _primaryColor.withOpacity(0.18)
                                  : _softPurple,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(
                                  Icons.info_outline_rounded,
                                  color: _primaryColor,
                                  size: 21,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    'Your profile will be reviewed by our team before your rider account is approved.',
                                    style: TextStyle(
                                      fontSize: 12.5,
                                      height: 1.45,
                                      color: Theme.of(context)
                                          .textTheme
                                          .bodyMedium
                                          ?.color
                                          ?.withOpacity(0.76),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 23),

                          SizedBox(
                            width: double.infinity,
                            height: 55,
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [_primaryColor, _secondaryColor],
                                ),
                                borderRadius: BorderRadius.circular(17),
                                boxShadow: [
                                  BoxShadow(
                                    color: _secondaryColor.withOpacity(0.28),
                                    blurRadius: 18,
                                    offset: const Offset(0, 8),
                                  ),
                                ],
                              ),
                              child: ElevatedButton(
                                onPressed: loading ? null : submitProfile,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.transparent,
                                  foregroundColor: Colors.white,
                                  disabledBackgroundColor: Colors.transparent,
                                  shadowColor: Colors.transparent,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(17),
                                  ),
                                ),
                                child: const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      'Submit for review',
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                    SizedBox(width: 9),
                                    Icon(Icons.arrow_forward_rounded, size: 20),
                                  ],
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 13),

                          Center(
                            child: Text(
                              'Your information is securely submitted for verification.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 11.5,
                                color: Theme.of(
                                  context,
                                ).textTheme.bodySmall?.color?.withOpacity(0.52),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),

          if (loading)
            Positioned.fill(
              child: ColoredBox(
                color: Colors.black.withOpacity(0.58),
                child: Center(
                  child: Container(
                    width: 210,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 25,
                    ),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF281431) : Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.22),
                          blurRadius: 30,
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(
                          width: 40,
                          height: 40,
                          child: CircularProgressIndicator(
                            strokeWidth: 3.5,
                            color: _primaryColor,
                          ),
                        ),
                        const SizedBox(height: 18),
                        const Text(
                          'Submitting profile',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Please wait while we securely upload your information.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 12.5,
                            height: 1.45,
                            color: Theme.of(
                              context,
                            ).textTheme.bodySmall?.color?.withOpacity(0.62),
                          ),
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
