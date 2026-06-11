import 'package:flutter/foundation.dart';

class RiderModel {
  final int id;
  final String riderId;
  final String username;
  final String email;
  final String status;

  final String? phone;
  final String? city;
  final String? address;

  final String? profileImage;
  final String? riderImage;
  final String? vehicleImage;

  RiderModel({
    required this.id,
    required this.riderId,
    required this.username,
    required this.email,
    required this.status,
    this.phone,
    this.city,
    this.address,
    this.profileImage,
    this.riderImage,
    this.vehicleImage,
  });

  factory RiderModel.fromJson(Map<String, dynamic> json) {
    if (kDebugMode) {
      print("ADDRESS FIELD => ${json['address']}");
    }
    return RiderModel(
      id: int.tryParse(json['id'].toString()) ?? 0,

      // Unique Rider ID (RIDER-58F38620)
      riderId: json['rider_id']?.toString() ?? '',

      username: json['username']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      status: json['status']?.toString() ?? 'pending',

      phone: json['phone']?.toString(),
      city: json['city']?.toString(),
      address: json['address']?.toString(),

      profileImage: json['profile_picture']?.toString(),
      riderImage: json['rider_image_1']?.toString(),
      vehicleImage: json['rider_image_with_vehicle']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'rider_id': riderId,
      'username': username,
      'email': email,
      'status': status,
      'phone_number': phone,
      'city': city,
      'address': address,
      'profile_picture': profileImage,
      'rider_image_1': riderImage,
      'rider_image_with_vehicle': vehicleImage,
    };
  }
}
