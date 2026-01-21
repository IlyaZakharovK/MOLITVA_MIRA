import 'profile_role.dart';

class ProfileModel {
  final ProfileRole role;

  // layman
  final String fullName;
  final String email;
  final String phone;

  // temple/clergy
  final String templeName;
  final String eparchy;
  final String address;
  final String rectorName;
  final String rectorPhone;

  const ProfileModel({
    required this.role,
    this.fullName = '',
    this.email = '',
    this.phone = '',
    this.templeName = '',
    this.eparchy = '',
    this.address = '',
    this.rectorName = '',
    this.rectorPhone = '',
  });

  ProfileModel copyWith({
    ProfileRole? role,
    String? fullName,
    String? email,
    String? phone,
    String? templeName,
    String? eparchy,
    String? address,
    String? rectorName,
    String? rectorPhone,
  }) {
    return ProfileModel(
      role: role ?? this.role,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      templeName: templeName ?? this.templeName,
      eparchy: eparchy ?? this.eparchy,
      address: address ?? this.address,
      rectorName: rectorName ?? this.rectorName,
      rectorPhone: rectorPhone ?? this.rectorPhone,
    );
  }
}
