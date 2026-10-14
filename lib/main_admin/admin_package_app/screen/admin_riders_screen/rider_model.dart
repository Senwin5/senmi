import 'package:flutter/foundation.dart';

class RiderModel {
  // ============================================================
  // BASIC USER INFORMATION
  // ============================================================

  final int id;
  final String riderId;
  final String username;
  final String email;
  final String fullName;
  final String status;

  // ============================================================
  // ACCOUNT STATUS
  // ============================================================

  final bool isActive;

  // ============================================================
  // CONTACT INFORMATION
  // ============================================================

  final String? phone;

  // ============================================================
  // IDENTITY INFORMATION
  // ============================================================

  final String? ninNumber;
  final String? dateOfBirth;

  // ============================================================
  // ADDRESS INFORMATION
  // ============================================================

  final String? address;
  final String? city;

  // ============================================================
  // VEHICLE INFORMATION
  // ============================================================

  final String? vehicleNumber;

  // ============================================================
  // EMERGENCY CONTACT
  // ============================================================

  final String? emergencyContactName;
  final String? emergencyContactPhone;
  final String? emergencyContactAddress;
  final String? emergencyContactRelationship;

  // ============================================================
  // RIDER IMAGES
  // ============================================================

  final String? profileImage;
  final String? ninImage;
  final String? vehicleImage;

  // ============================================================
  // CONSTRUCTOR
  // ============================================================

  RiderModel({
    required this.id,
    required this.riderId,
    required this.username,
    required this.email,
    required this.fullName,
    required this.status,
    required this.isActive,

    this.phone,

    this.ninNumber,
    this.dateOfBirth,

    this.address,
    this.city,

    this.vehicleNumber,

    this.emergencyContactName,
    this.emergencyContactPhone,
    this.emergencyContactAddress,
    this.emergencyContactRelationship,

    this.profileImage,
    this.ninImage,
    this.vehicleImage,
  });

  // ============================================================
  // FROM JSON
  // ============================================================

  factory RiderModel.fromJson(Map<String, dynamic> json) {
    // ==========================================================
    // ACCOUNT STATUS
    //
    // Handles:
    // true
    // false
    // 1
    // 0
    // "true"
    // "false"
    // "1"
    // "0"
    // ==========================================================

    final activeValue = json['is_active'];

    final bool parsedIsActive =
        activeValue == true ||
        activeValue == 1 ||
        activeValue?.toString().trim().toLowerCase() == 'true' ||
        activeValue?.toString().trim() == '1';

    if (kDebugMode) {
      print('========================================');
      print('RIDER JSON');
      print(json);
      print('========================================');

      print('ID => ${json['id']}');
      print('RIDER ID => ${json['rider_id']}');
      print('USERNAME => ${json['username']}');
      print('EMAIL => ${json['email']}');
      print('FULL NAME => ${json['full_name']}');
      print('STATUS => ${json['status']}');

      // IMPORTANT DEBUG
      print('RAW IS ACTIVE => $activeValue');
      print('PARSED IS ACTIVE => $parsedIsActive');

      print(
        'PHONE => '
        '${json['phone_number'] ?? json['phone']}',
      );

      print('ADDRESS => ${json['address']}');
      print('CITY => ${json['city']}');

      print('NIN NUMBER => ${json['nin_number']}');
      print('DATE OF BIRTH => ${json['date_of_birth']}');

      print('VEHICLE NUMBER => ${json['vehicle_number']}');

      print(
        'EMERGENCY CONTACT NAME => '
        '${json['emergency_contact_name']}',
      );

      print(
        'EMERGENCY CONTACT PHONE => '
        '${json['emergency_contact_phone']}',
      );

      print(
        'EMERGENCY CONTACT ADDRESS => '
        '${json['emergency_contact_address']}',
      );

      print(
        'EMERGENCY CONTACT RELATIONSHIP => '
        '${json['emergency_contact_relationship']}',
      );

      print(
        'PROFILE PICTURE => '
        '${json['profile_picture']}',
      );

      print(
        'NIN IMAGE => '
        '${json['nin_image']}',
      );

      print(
        'RIDER IMAGE WITH VEHICLE => '
        '${json['rider_image_with_vehicle']}',
      );
    }

    return RiderModel(
      // ========================================================
      // BASIC INFORMATION
      // ========================================================

      id: int.tryParse(
            json['id']?.toString() ?? '',
          ) ??
          0,

      riderId: json['rider_id']?.toString() ?? '',

      username: json['username']?.toString() ?? '',

      email: json['email']?.toString() ?? '',

      fullName: json['full_name']?.toString() ?? '',

      status: json['status']?.toString() ?? 'pending',

      // ========================================================
      // ACCOUNT STATUS
      // ========================================================

      isActive: parsedIsActive,

      // ========================================================
      // CONTACT
      // ========================================================

      phone:
          json['phone_number']?.toString() ??
          json['phone']?.toString(),

      // ========================================================
      // IDENTITY
      // ========================================================

      ninNumber: json['nin_number']?.toString(),

      dateOfBirth: json['date_of_birth']?.toString(),

      // ========================================================
      // ADDRESS
      // ========================================================

      address: json['address']?.toString(),

      city: json['city']?.toString(),

      // ========================================================
      // VEHICLE
      // ========================================================

      vehicleNumber: json['vehicle_number']?.toString(),

      // ========================================================
      // EMERGENCY CONTACT
      // ========================================================

      emergencyContactName:
          json['emergency_contact_name']?.toString(),

      emergencyContactPhone:
          json['emergency_contact_phone']?.toString(),

      emergencyContactAddress:
          json['emergency_contact_address']?.toString(),

      emergencyContactRelationship:
          json['emergency_contact_relationship']?.toString(),

      // ========================================================
      // IMAGES
      // ========================================================

      profileImage:
          json['profile_picture']?.toString(),

      ninImage:
          json['nin_image']?.toString(),

      vehicleImage:
          json['rider_image_with_vehicle']?.toString(),
    );
  }

  // ============================================================
  // TO JSON
  // ============================================================

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'rider_id': riderId,

      'username': username,
      'email': email,

      'full_name': fullName,
      'status': status,

      // ========================================================
      // ACCOUNT STATUS
      // ========================================================

      'is_active': isActive,

      // Django field
      'phone_number': phone,

      'nin_number': ninNumber,
      'date_of_birth': dateOfBirth,

      'address': address,
      'city': city,

      'vehicle_number': vehicleNumber,

      'emergency_contact_name':
          emergencyContactName,

      'emergency_contact_phone':
          emergencyContactPhone,

      'emergency_contact_address':
          emergencyContactAddress,

      'emergency_contact_relationship':
          emergencyContactRelationship,

      // Django image fields
      'profile_picture': profileImage,
      'nin_image': ninImage,
      'rider_image_with_vehicle':
          vehicleImage,
    };
  }
}