class RiderModel {
  final int id;
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
    return RiderModel(
      id: json['id'] ?? 0,
      username: json['username'] ?? '',
      email: json['email'] ?? '',
      status: json['status'] ?? 'pending',

      phone: json['phone_number'],
      city: json['city'],
      address: json['address'],

      profileImage: json['profile_picture'],
      riderImage: json['rider_image_1'],
      vehicleImage: json['rider_image_with_vehicle'],
    );
  }
}