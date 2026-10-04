// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:senmi/services/driver_api_service.dart';

const Color senmiRidePurple = Color(0xFF6C3EF4);

class RateDriverScreen extends StatefulWidget {
  final String rideId;
  final Map<String, dynamic> driver;

  const RateDriverScreen({
    super.key,
    required this.rideId,
    required this.driver,
  });

  @override
  State<RateDriverScreen> createState() => _RateDriverScreenState();
}

class _RateDriverScreenState extends State<RateDriverScreen> {
  int selectedRating = 0;
  bool submitting = false;

  final TextEditingController commentController = TextEditingController();

  String _stringValue(dynamic value, {String fallback = ""}) {
    if (value == null) return fallback;

    final text = value.toString().trim();

    return text.isEmpty ? fallback : text;
  }

  @override
  void dispose() {
    commentController.dispose();
    super.dispose();
  }

  Future<void> _submitRating() async {
    if (selectedRating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please select a rating."),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (submitting) return;

    setState(() {
      submitting = true;
    });

    try {
      await RideService.rateDriver(
        rideId: widget.rideId,
        rating: selectedRating,
        comment: commentController.text.trim(),
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Thank you for rating your driver!"),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;

      setState(() {
        submitting = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst("Exception: ", "")),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final driverName = _stringValue(
      widget.driver["full_name"],
      fallback: "Your Driver",
    );

    final driverPhone = _stringValue(widget.driver["phone_number"]);

    final driverImage = _stringValue(widget.driver["profile_photo"]);

    final vehicleBrand = _stringValue(widget.driver["vehicle_brand"]);

    final vehicleModel = _stringValue(widget.driver["vehicle_model"]);

    final vehicleColor = _stringValue(widget.driver["vehicle_color"]);

    final plateNumber = _stringValue(
      widget.driver["plate_number"],
      fallback: "Vehicle",
    );

    final vehicleName = [
      vehicleBrand,
      vehicleModel,
    ].where((value) => value.isNotEmpty).join(" ");

    final vehicleDetails = [
      vehicleName,
      vehicleColor,
    ].where((value) => value.isNotEmpty).join(" • ");

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF101014)
          : const Color(0xFFF7F7F9),
      appBar: AppBar(
        title: const Text(
          "Rate Driver",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        ),
        centerTitle: false,
        backgroundColor: isDark ? const Color(0xFF101014) : Colors.white,
        foregroundColor: isDark ? Colors.white : Colors.black87,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 30),
          child: Column(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E1E22) : Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(isDark ? 0.15 : 0.05),
                      blurRadius: 18,
                      offset: const Offset(0, 7),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Container(
                      width: 88,
                      height: 88,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: senmiRidePurple.withOpacity(0.10),
                      ),
                      child: ClipOval(
                        child: driverImage.isNotEmpty
                            ? Image.network(
                                driverImage,
                                width: 88,
                                height: 88,
                                fit: BoxFit.cover,
                                errorBuilder: (_, _, _) {
                                  return const Icon(
                                    Icons.person,
                                    size: 45,
                                    color: senmiRidePurple,
                                  );
                                },
                              )
                            : const Icon(
                                Icons.person,
                                size: 45,
                                color: senmiRidePurple,
                              ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    Text(
                      driverName,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),

                    if (driverPhone.isNotEmpty) ...[
                      const SizedBox(height: 5),
                      Text(
                        driverPhone,
                        style: TextStyle(
                          fontSize: 13,
                          color: isDark ? Colors.white54 : Colors.black54,
                        ),
                      ),
                    ],

                    if (vehicleDetails.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Text(
                        vehicleDetails,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white70 : Colors.black54,
                        ),
                      ),
                    ],

                    const SizedBox(height: 5),

                    Text(
                      plateNumber,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        color: senmiRidePurple,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              Text(
                "How was your ride?",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),

              const SizedBox(height: 8),

              Text(
                "Tap a star to rate your experience",
                style: TextStyle(
                  fontSize: 14,
                  color: isDark ? Colors.white54 : Colors.black54,
                ),
              ),

              const SizedBox(height: 18),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) {
                  final starNumber = index + 1;
                  final selected = starNumber <= selectedRating;

                  return GestureDetector(
                    onTap: submitting
                        ? null
                        : () {
                            setState(() {
                              selectedRating = starNumber;
                            });
                          },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 5),
                      child: Icon(
                        selected
                            ? Icons.star_rounded
                            : Icons.star_border_rounded,
                        size: 48,
                        color: selected
                            ? Colors.amber
                            : isDark
                            ? Colors.white30
                            : Colors.black26,
                      ),
                    ),
                  );
                }),
              ),

              const SizedBox(height: 12),

              if (selectedRating > 0)
                Text(
                  _ratingText(selectedRating),
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: senmiRidePurple,
                  ),
                ),

              const SizedBox(height: 28),

              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "Add a comment",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
              ),

              const SizedBox(height: 10),

              TextField(
                controller: commentController,
                enabled: !submitting,
                maxLines: 5,
                maxLength: 500,
                textInputAction: TextInputAction.newline,
                decoration: InputDecoration(
                  hintText: "Tell us about your experience (optional)",
                  hintStyle: TextStyle(
                    color: isDark ? Colors.white38 : Colors.black38,
                  ),
                  filled: true,
                  fillColor: isDark ? const Color(0xFF1E1E22) : Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(
                      color: isDark ? Colors.white10 : Colors.black12,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(
                      color: isDark ? Colors.white10 : Colors.black12,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(
                      color: senmiRidePurple,
                      width: 1.5,
                    ),
                  ),
                  contentPadding: const EdgeInsets.all(16),
                ),
              ),

              const SizedBox(height: 18),

              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: submitting ? null : _submitRating,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: senmiRidePurple,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: senmiRidePurple.withOpacity(0.5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child: submitting
                      ? const SizedBox(
                          width: 23,
                          height: 23,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          "Submit Rating",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                ),
              ),

              const SizedBox(height: 12),

              Text(
                "Your feedback helps us improve Senmi.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? Colors.white38 : Colors.black38,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _ratingText(int rating) {
    switch (rating) {
      case 1:
        return "Very poor";
      case 2:
        return "Poor";
      case 3:
        return "Good";
      case 4:
        return "Very good";
      case 5:
        return "Excellent!";
      default:
        return "";
    }
  }
}
