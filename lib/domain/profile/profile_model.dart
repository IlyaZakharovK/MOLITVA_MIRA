import 'profile_role.dart';

class ProfileModel {
  final ProfileRole role;

  final String fullName;
  final String email;
  final String phone;

  final String templeName;
  final String eparchy;
  final String address;
  final String rectorName;
  final String rectorPhone;
  final String avatarUrl;
  final bool canBlass;

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
    this.avatarUrl = '',
    this.canBlass = false,
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
    String? avatarUrl,
    bool? canBlass,
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
      avatarUrl: avatarUrl ?? this.avatarUrl,
      canBlass: canBlass ?? this.canBlass,
    );
  }
}
