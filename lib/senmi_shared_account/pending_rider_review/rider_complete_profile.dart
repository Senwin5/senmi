// ignore_for_file: deprecated_member_use

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:image_picker/image_picker.dart';
import 'package:senmi/senmi_shared_account/pending_rider_review/rider_pending_screen.dart';
import 'package:senmi/services/package_api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class RiderCompleteProfile extends StatefulWidget {
  const RiderCompleteProfile({super.key});

  @override
  State<RiderCompleteProfile> createState() => _RiderCompleteProfileState();
}

class _RiderCompleteProfileState extends State<RiderCompleteProfile> {
  final _formKey = GlobalKey<FormState>();

  // ------------------------------------------------------------
  // STEP CONTROL
  // ------------------------------------------------------------

  int currentStep = 0;

  // ------------------------------------------------------------
  // PERSONAL INFORMATION
  // ------------------------------------------------------------

  final TextEditingController fullNameController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController ninNumberController = TextEditingController();
  final TextEditingController dateOfBirthController = TextEditingController();

  // ------------------------------------------------------------
  // VEHICLE / ADDRESS
  // ------------------------------------------------------------

  final TextEditingController vehicleController = TextEditingController();
  final TextEditingController addressController = TextEditingController();
  final TextEditingController stateController = TextEditingController();

  // ------------------------------------------------------------
  // EMERGENCY CONTACT
  // ------------------------------------------------------------

  final TextEditingController emergencyContactNameController =
      TextEditingController();

  final TextEditingController emergencyContactPhoneController =
      TextEditingController();

  final TextEditingController emergencyContactAddressController =
      TextEditingController();

  final TextEditingController emergencyContactRelationshipController =
      TextEditingController();

  // ------------------------------------------------------------
  // IMAGES
  // ------------------------------------------------------------

  File? profilePicture;
  File? ninImage;
  File? riderImageWithVehicle;

  bool loading = false;
  bool restoringDraft = true;

  final ImagePicker _picker = ImagePicker();

  // ------------------------------------------------------------
  // COLORS
  // ------------------------------------------------------------

  static const Color _primaryColor = Color(0xFF581C87);
  static const Color _secondaryColor = Color(0xFF7E22CE);
  static const Color _softPurple = Color(0xFFF5EDFF);
  static const Color _darkBackground = Color(0xFF16091F);

  // ------------------------------------------------------------
  // LOCAL DRAFT KEYS
  // ------------------------------------------------------------

  static const String _draftPrefix = 'rider_profile_draft_';

  static const String _fullNameKey = '${_draftPrefix}full_name';
  static const String _phoneKey = '${_draftPrefix}phone';
  static const String _ninKey = '${_draftPrefix}nin';
  static const String _dobKey = '${_draftPrefix}dob';

  static const String _vehicleKey = '${_draftPrefix}vehicle';
  static const String _addressKey = '${_draftPrefix}address';
  static const String _stateKey = '${_draftPrefix}state';

  static const String _emergencyNameKey = '${_draftPrefix}emergency_name';
  static const String _emergencyPhoneKey = '${_draftPrefix}emergency_phone';
  static const String _emergencyAddressKey = '${_draftPrefix}emergency_address';
  static const String _emergencyRelationshipKey =
      '${_draftPrefix}emergency_relationship';

  static const String _profileImageKey = '${_draftPrefix}profile_image';
  static const String _ninImageKey = '${_draftPrefix}nin_image';
  static const String _vehicleImageKey = '${_draftPrefix}vehicle_image';

  static const String _stepKey = '${_draftPrefix}step';

  // ------------------------------------------------------------
  // INIT
  // ------------------------------------------------------------

  @override
  void initState() {
    super.initState();

    _restoreDraft();

    _addDraftListeners();
  }

  // ------------------------------------------------------------
  // SAVE DRAFT WHEN USER TYPES
  // ------------------------------------------------------------

  void _addDraftListeners() {
    fullNameController.addListener(_saveDraft);
    phoneController.addListener(_saveDraft);
    ninNumberController.addListener(_saveDraft);
    dateOfBirthController.addListener(_saveDraft);

    vehicleController.addListener(_saveDraft);
    addressController.addListener(_saveDraft);
    stateController.addListener(_saveDraft);

    emergencyContactNameController.addListener(_saveDraft);
    emergencyContactPhoneController.addListener(_saveDraft);
    emergencyContactAddressController.addListener(_saveDraft);
    emergencyContactRelationshipController.addListener(_saveDraft);
  }

  // ------------------------------------------------------------
  // RESTORE SAVED DRAFT
  // ------------------------------------------------------------

  Future<void> _restoreDraft() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      if (!mounted) return;

      setState(() {
        fullNameController.text = prefs.getString(_fullNameKey) ?? '';
        phoneController.text = prefs.getString(_phoneKey) ?? '';
        ninNumberController.text = prefs.getString(_ninKey) ?? '';
        dateOfBirthController.text = prefs.getString(_dobKey) ?? '';

        vehicleController.text = prefs.getString(_vehicleKey) ?? '';
        addressController.text = prefs.getString(_addressKey) ?? '';
        stateController.text = prefs.getString(_stateKey) ?? '';

        emergencyContactNameController.text =
            prefs.getString(_emergencyNameKey) ?? '';

        emergencyContactPhoneController.text =
            prefs.getString(_emergencyPhoneKey) ?? '';

        emergencyContactAddressController.text =
            prefs.getString(_emergencyAddressKey) ?? '';

        emergencyContactRelationshipController.text =
            prefs.getString(_emergencyRelationshipKey) ?? '';

        final profilePath = prefs.getString(_profileImageKey);
        final ninPath = prefs.getString(_ninImageKey);
        final vehiclePath = prefs.getString(_vehicleImageKey);

        if (profilePath != null &&
            profilePath.isNotEmpty &&
            File(profilePath).existsSync()) {
          profilePicture = File(profilePath);
        }

        if (ninPath != null &&
            ninPath.isNotEmpty &&
            File(ninPath).existsSync()) {
          ninImage = File(ninPath);
        }

        if (vehiclePath != null &&
            vehiclePath.isNotEmpty &&
            File(vehiclePath).existsSync()) {
          riderImageWithVehicle = File(vehiclePath);
        }

        final savedStep = prefs.getInt(_stepKey);

        if (savedStep != null && savedStep >= 0 && savedStep <= 2) {
          currentStep = savedStep;
        }

        restoringDraft = false;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        restoringDraft = false;
      });
    }
  }

  // ------------------------------------------------------------
  // SAVE DRAFT
  // ------------------------------------------------------------

  Future<void> _saveDraft() async {
    if (restoringDraft) return;

    try {
      final prefs = await SharedPreferences.getInstance();

      await prefs.setString(_fullNameKey, fullNameController.text);
      await prefs.setString(_phoneKey, phoneController.text);
      await prefs.setString(_ninKey, ninNumberController.text);
      await prefs.setString(_dobKey, dateOfBirthController.text);

      await prefs.setString(_vehicleKey, vehicleController.text);
      await prefs.setString(_addressKey, addressController.text);
      await prefs.setString(_stateKey, stateController.text);

      await prefs.setString(
        _emergencyNameKey,
        emergencyContactNameController.text,
      );

      await prefs.setString(
        _emergencyPhoneKey,
        emergencyContactPhoneController.text,
      );

      await prefs.setString(
        _emergencyAddressKey,
        emergencyContactAddressController.text,
      );

      await prefs.setString(
        _emergencyRelationshipKey,
        emergencyContactRelationshipController.text,
      );

      await prefs.setInt(_stepKey, currentStep);

      if (profilePicture != null) {
        await prefs.setString(_profileImageKey, profilePicture!.path);
      }

      if (ninImage != null) {
        await prefs.setString(_ninImageKey, ninImage!.path);
      }

      if (riderImageWithVehicle != null) {
        await prefs.setString(_vehicleImageKey, riderImageWithVehicle!.path);
      }
    } catch (_) {
      // Draft saving should never interrupt production flow.
    }
  }

  // ------------------------------------------------------------
  // CLEAR DRAFT AFTER SUCCESSFUL SUBMISSION
  // ------------------------------------------------------------

  Future<void> _clearDraft() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      await prefs.remove(_fullNameKey);
      await prefs.remove(_phoneKey);
      await prefs.remove(_ninKey);
      await prefs.remove(_dobKey);

      await prefs.remove(_vehicleKey);
      await prefs.remove(_addressKey);
      await prefs.remove(_stateKey);

      await prefs.remove(_emergencyNameKey);
      await prefs.remove(_emergencyPhoneKey);
      await prefs.remove(_emergencyAddressKey);
      await prefs.remove(_emergencyRelationshipKey);

      await prefs.remove(_profileImageKey);
      await prefs.remove(_ninImageKey);
      await prefs.remove(_vehicleImageKey);

      await prefs.remove(_stepKey);
    } catch (_) {
      // Do not interfere with successful profile submission.
    }
  }

  // ------------------------------------------------------------
  // CHANGE STEP
  // ------------------------------------------------------------

  Future<void> _nextStep() async {
    FocusScope.of(context).unfocus();

    if (currentStep < 2) {
      setState(() {
        currentStep++;
      });

      await _saveDraft();
    }
  }

  Future<void> _previousStep() async {
    FocusScope.of(context).unfocus();

    if (currentStep > 0) {
      setState(() {
        currentStep--;
      });

      await _saveDraft();
    }
  }

  // ------------------------------------------------------------
  // DATE OF BIRTH
  // ------------------------------------------------------------

  Future<void> _selectDateOfBirth() async {
    FocusScope.of(context).unfocus();

    final now = DateTime.now();

    final pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime(now.year - 25),
      firstDate: DateTime(1940),
      lastDate: DateTime(now.year - 18, now.month, now.day),
      helpText: 'Select date of birth',
      cancelText: 'Cancel',
      confirmText: 'Select',
    );

    if (pickedDate == null || !mounted) return;

    final month = pickedDate.month.toString().padLeft(2, '0');
    final day = pickedDate.day.toString().padLeft(2, '0');

    setState(() {
      dateOfBirthController.text = '${pickedDate.year}-$month-$day';
    });

    await _saveDraft();
  }

  // ------------------------------------------------------------
  // IMAGE PICKER
  // ------------------------------------------------------------

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

                    final status = await Permission.camera.request();

                    if (status.isGranted) {
                      final image = await _picker.pickImage(
                        source: ImageSource.camera,
                        imageQuality: 85,
                      );

                      if (image != null && mounted) {
                        setState(() {
                          if (type == 'profile') {
                            profilePicture = File(image.path);
                          } else if (type == 'rider_nin_image') {
                            ninImage = File(image.path);
                          } else if (type == 'withVehicle') {
                            riderImageWithVehicle = File(image.path);
                          }
                        });

                        await _saveDraft();
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
                      imageQuality: 85,
                    );

                    if (image != null && mounted) {
                      setState(() {
                        if (type == 'profile') {
                          profilePicture = File(image.path);
                        } else if (type == 'rider_nin_image') {
                          ninImage = File(image.path);
                        } else if (type == 'withVehicle') {
                          riderImageWithVehicle = File(image.path);
                        }
                      });

                      await _saveDraft();
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

  // ------------------------------------------------------------
  // SUBMIT PROFILE
  // ------------------------------------------------------------

  Future<void> submitProfile() async {
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) return;

    if (profilePicture == null ||
        ninImage == null ||
        riderImageWithVehicle == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('All verification photos are required.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => loading = true);

    try {
      final res = await ApiService.updateRiderProfile(
        fullNameController.text.trim(),
        phoneController.text.trim(),
        ninNumberController.text.trim(),
        dateOfBirthController.text.trim(),
        vehicleController.text.trim(),
        addressController.text.trim(),
        stateController.text.trim(),
        emergencyContactNameController.text.trim(),
        emergencyContactPhoneController.text.trim(),
        emergencyContactAddressController.text.trim(),
        emergencyContactRelationshipController.text.trim(),
        profilePicture!,
        ninImage!,
        riderImageWithVehicle!,
      );

      if (!mounted) return;

      setState(() => loading = false);

      if (res.containsKey('error')) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              res['error']?.toString() ?? 'Failed to submit profile.',
            ),
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }

      if (res.containsKey('message')) {
        // Clear saved draft only after successful submission.
        await _clearDraft();

        await _showSuccessDialog(
          res['message']?.toString() ??
              'Your rider profile has been submitted for review.',
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to submit profile: ${res.toString()}'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;

      setState(() => loading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Something went wrong: $e'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  // ------------------------------------------------------------
  // SUCCESS DIALOG
  // ------------------------------------------------------------

  Future<void> _showSuccessDialog(String message) async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
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
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                height: 1.5,
                color: Theme.of(
                  dialogContext,
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
                Navigator.of(dialogContext).push(
                  MaterialPageRoute(builder: (_) => const RiderPendingScreen()),
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
  }

  // ------------------------------------------------------------
  // BOTTOM SHEET OPTION
  // ------------------------------------------------------------

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

  // ------------------------------------------------------------
  // SECTION TITLE
  // ------------------------------------------------------------

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

  // ------------------------------------------------------------
  // TEXT FIELD
  // ------------------------------------------------------------

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    required String? Function(String?) validator,
    TextInputType? keyboardType,
    int maxLines = 1,
    bool readOnly = false,
    VoidCallback? onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: TextFormField(
        controller: controller,
        validator: validator,
        keyboardType: keyboardType,
        maxLines: maxLines,
        readOnly: readOnly,
        onTap: onTap,
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
          suffixIcon: readOnly
              ? const Icon(Icons.calendar_month_rounded, color: _primaryColor)
              : null,
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

  // ------------------------------------------------------------
  // IMAGE TILE
  // ------------------------------------------------------------

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
          onTap: loading ? null : () => pickImage(type),
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

  // ------------------------------------------------------------
  // DIVIDER
  // ------------------------------------------------------------

  Widget _divider(bool isDark) {
    return Divider(
      color: isDark ? Colors.white.withOpacity(0.08) : const Color(0xFFECE6EF),
    );
  }

  // ------------------------------------------------------------
  // STEP INDICATOR
  // ------------------------------------------------------------

  Widget _stepIndicator(bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 0),
      child: Row(
        children: List.generate(3, (index) {
          final active = index == currentStep;
          final completed = index < currentStep;

          return Expanded(
            child: Row(
              children: [
                Expanded(
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    height: 5,
                    decoration: BoxDecoration(
                      color: active || completed
                          ? _secondaryColor
                          : isDark
                          ? Colors.white.withOpacity(0.10)
                          : const Color(0xFFE4DDE7),
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                ),

                if (index != 2) const SizedBox(width: 6),
              ],
            ),
          );
        }),
      ),
    );
  }

  // ------------------------------------------------------------
  // STEP LABEL
  // ------------------------------------------------------------

  Widget _stepHeader(bool isDark) {
    const titles = [
      'Personal information',
      'Vehicle & address',
      'Emergency & verification',
    ];

    const subtitles = ['Step 1 of 3', 'Step 2 of 3', 'Step 3 of 3'];

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  titles[currentStep],
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Theme.of(context).textTheme.titleLarge?.color,
                  ),
                ),

                const SizedBox(height: 3),

                Text(
                  subtitles[currentStep],
                  style: TextStyle(
                    fontSize: 12.5,
                    color: Theme.of(
                      context,
                    ).textTheme.bodySmall?.color?.withOpacity(0.60),
                  ),
                ),
              ],
            ),
          ),

          if (currentStep > 0)
            Container(
              decoration: BoxDecoration(
                color: isDark ? Colors.white.withOpacity(0.06) : Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: IconButton(
                onPressed: loading ? null : _previousStep,
                icon: const Icon(
                  Icons.arrow_back_rounded,
                  color: _primaryColor,
                ),
                tooltip: 'Previous',
              ),
            ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------
  // STEP 1
  // ------------------------------------------------------------

  Widget _personalStep(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle(
          icon: Icons.person_outline_rounded,
          title: 'Personal information',
          subtitle: 'Enter the details associated with your rider account.',
        ),

        _buildTextField(
          controller: fullNameController,
          label: 'Full name',
          hint: 'Enter your full name',
          icon: Icons.person_outline_rounded,
          validator: (val) {
            if (val == null || val.trim().isEmpty) {
              return 'Full name is required';
            }
            return null;
          },
          keyboardType: TextInputType.name,
        ),

        _buildTextField(
          controller: phoneController,
          label: 'Phone number',
          hint: 'Enter your active phone number',
          icon: Icons.phone_outlined,
          validator: (val) {
            if (val == null || val.trim().isEmpty) {
              return 'Phone number is required';
            }
            return null;
          },
          keyboardType: TextInputType.phone,
        ),

        _buildTextField(
          controller: ninNumberController,
          label: 'NIN number',
          hint: 'Enter your 11-digit NIN number',
          icon: Icons.badge_outlined,
          validator: (val) {
            final value = val?.trim() ?? '';

            if (value.isEmpty) {
              return 'NIN number is required';
            }

            if (!RegExp(r'^\d{11}$').hasMatch(value)) {
              return 'NIN must be exactly 11 digits';
            }

            return null;
          },
          keyboardType: TextInputType.number,
        ),

        _buildTextField(
          controller: dateOfBirthController,
          label: 'Date of birth',
          hint: 'Select your date of birth',
          icon: Icons.cake_outlined,
          validator: (val) {
            if (val == null || val.trim().isEmpty) {
              return 'Date of birth is required';
            }
            return null;
          },
          readOnly: true,
          onTap: _selectDateOfBirth,
        ),

        const SizedBox(height: 8),

        _saveNotice(
          isDark,
          'Your information is saved automatically as you continue.',
        ),
      ],
    );
  }

  // ------------------------------------------------------------
  // STEP 2
  // ------------------------------------------------------------

  Widget _vehicleAddressStep(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle(
          icon: Icons.two_wheeler_rounded,
          title: 'Vehicle information',
          subtitle: 'Provide the vehicle number used for deliveries.',
        ),

        _buildTextField(
          controller: vehicleController,
          label: 'Vehicle number',
          hint: 'Enter your vehicle registration number',
          icon: Icons.two_wheeler,
          validator: (val) {
            if (val == null || val.trim().isEmpty) {
              return 'Vehicle number is required';
            }
            return null;
          },
          keyboardType: TextInputType.text,
        ),

        const SizedBox(height: 8),

        _divider(isDark),

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
          validator: (val) {
            if (val == null || val.trim().isEmpty) {
              return 'Home address is required';
            }
            return null;
          },
          keyboardType: TextInputType.streetAddress,
          maxLines: 2,
        ),

        _buildTextField(
          controller: stateController,
          label: 'State',
          hint: 'Enter your state',
          icon: Icons.location_city_outlined,
          validator: (val) {
            if (val == null || val.trim().isEmpty) {
              return 'State is required';
            }
            return null;
          },
          keyboardType: TextInputType.text,
        ),

        const SizedBox(height: 8),

        _saveNotice(
          isDark,
          'Your progress is saved automatically so you can continue later.',
        ),
      ],
    );
  }

  // ------------------------------------------------------------
  // STEP 3
  // ------------------------------------------------------------

  Widget _emergencyVerificationStep(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle(
          icon: Icons.contact_emergency_outlined,
          title: 'Emergency contact',
          subtitle: 'Provide someone we can contact in case of an emergency.',
        ),

        _buildTextField(
          controller: emergencyContactNameController,
          label: 'Emergency contact name',
          hint: 'Enter emergency contact full name',
          icon: Icons.person_outline_rounded,
          validator: (val) {
            if (val == null || val.trim().isEmpty) {
              return 'Emergency contact name is required';
            }
            return null;
          },
          keyboardType: TextInputType.name,
        ),

        _buildTextField(
          controller: emergencyContactPhoneController,
          label: 'Emergency contact phone',
          hint: 'Enter emergency contact phone number',
          icon: Icons.phone_outlined,
          validator: (val) {
            if (val == null || val.trim().isEmpty) {
              return 'Emergency contact phone is required';
            }
            return null;
          },
          keyboardType: TextInputType.phone,
        ),

        _buildTextField(
          controller: emergencyContactRelationshipController,
          label: 'Relationship',
          hint: 'e.g. Brother, Sister, Parent, Spouse',
          icon: Icons.people_outline_rounded,
          validator: (val) {
            if (val == null || val.trim().isEmpty) {
              return 'Relationship is required';
            }
            return null;
          },
          keyboardType: TextInputType.text,
        ),

        _buildTextField(
          controller: emergencyContactAddressController,
          label: 'Emergency contact address',
          hint: 'Enter their full home address',
          icon: Icons.home_work_outlined,
          validator: (val) {
            if (val == null || val.trim().isEmpty) {
              return 'Emergency contact address is required';
            }
            return null;
          },
          keyboardType: TextInputType.streetAddress,
          maxLines: 2,
        ),

        const SizedBox(height: 7),

        _divider(isDark),

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
          label: 'NIN photo',
          subtitle: 'Upload a clear full photo of your NIN',
          file: ninImage,
          type: 'rider_nin_image',
          icon: Icons.person_pin_outlined,
        ),

        imagePickerTile(
          label: 'Photo with your vehicle',
          subtitle: 'Make sure you and your vehicle are clearly visible',
          file: riderImageWithVehicle,
          type: 'withVehicle',
          icon: Icons.two_wheeler_rounded,
        ),

        const SizedBox(height: 12),

        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isDark ? _primaryColor.withOpacity(0.18) : _softPurple,
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
                    color: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.color?.withOpacity(0.76),
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
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
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
    );
  }

  // ------------------------------------------------------------
  // AUTO-SAVE NOTICE
  // ------------------------------------------------------------

  Widget _saveNotice(bool isDark, String text) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? _primaryColor.withOpacity(0.15) : _softPurple,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        children: [
          const Icon(Icons.cloud_done_outlined, color: _primaryColor, size: 21),

          const SizedBox(width: 10),

          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 12.5,
                height: 1.4,
                color: Theme.of(
                  context,
                ).textTheme.bodyMedium?.color?.withOpacity(0.72),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------
  // BUILD
  // ------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final pageBackground = isDark ? _darkBackground : const Color(0xFFF7F3F9);

    final cardColor = isDark ? const Color(0xFF211129) : Colors.white;

    if (restoringDraft) {
      return Scaffold(
        backgroundColor: pageBackground,
        body: const Center(
          child: CircularProgressIndicator(color: _primaryColor),
        ),
      );
    }

    return PopScope(
      canPop: !loading,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && !loading) {
          _saveDraft();
        }
      },
      child: Scaffold(
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
                      icon: const Icon(
                        Icons.close_rounded,
                        color: Colors.white,
                      ),
                      onPressed: loading
                          ? null
                          : () async {
                              await _saveDraft();

                              if (!context.mounted) return;

                              Navigator.pop(context);
                            },
                      tooltip: 'Save and close',
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
                              padding: const EdgeInsets.fromLTRB(
                                28,
                                72,
                                28,
                                28,
                              ),
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
                                    'Complete these three short steps. Your progress is saved automatically.',
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

                // --------------------------------------------------
                // STEP PROGRESS
                // --------------------------------------------------
                SliverToBoxAdapter(child: _stepIndicator(isDark)),

                SliverToBoxAdapter(child: _stepHeader(isDark)),

                // --------------------------------------------------
                // VERIFICATION INFORMATION
                // --------------------------------------------------
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: cardColor,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(
                              isDark ? 0.22 : 0.08,
                            ),
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
                                  'Your progress is protected',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  'You can close the app and continue later.',
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

                // --------------------------------------------------
                // MAIN FORM
                // --------------------------------------------------
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 40),
                    child: Container(
                      constraints: const BoxConstraints(maxWidth: 720),
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
                            if (currentStep == 0) _personalStep(isDark),

                            if (currentStep == 1) _vehicleAddressStep(isDark),

                            if (currentStep == 2)
                              _emergencyVerificationStep(isDark),

                            // ------------------------------------------------
                            // NEXT BUTTON
                            // ------------------------------------------------
                            if (currentStep < 2) ...[
                              const SizedBox(height: 10),

                              SizedBox(
                                width: double.infinity,
                                height: 54,
                                child: ElevatedButton(
                                  onPressed: loading ? null : _nextStep,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: _primaryColor,
                                    foregroundColor: Colors.white,
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                  ),
                                  child: const Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        'Continue',
                                        style: TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                      SizedBox(width: 8),
                                      Icon(
                                        Icons.arrow_forward_rounded,
                                        size: 20,
                                      ),
                                    ],
                                  ),
                                ),
                              ),

                              const SizedBox(height: 10),

                              Center(
                                child: Text(
                                  'Your progress will be saved automatically.',
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    color: Theme.of(context)
                                        .textTheme
                                        .bodySmall
                                        ?.color
                                        ?.withOpacity(0.52),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),

            // ------------------------------------------------------------
            // LOADING OVERLAY
            // ------------------------------------------------------------
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
      ),
    );
  }

  // ------------------------------------------------------------
  // DISPOSE
  // ------------------------------------------------------------

  @override
  void dispose() {
    fullNameController.dispose();
    phoneController.dispose();
    ninNumberController.dispose();
    dateOfBirthController.dispose();

    vehicleController.dispose();
    addressController.dispose();
    stateController.dispose();

    emergencyContactNameController.dispose();
    emergencyContactPhoneController.dispose();
    emergencyContactAddressController.dispose();
    emergencyContactRelationshipController.dispose();

    super.dispose();
  }
}
