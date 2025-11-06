import 'dart:convert';

class UserProfile {
  const UserProfile({
    required this.fullName,
    required this.handle,
    required this.bio,
    required this.profession,
    this.avatarImageBase64,
    this.headerImageBase64,
  });

  final String fullName;
  final String handle;
  final String bio;
  final String profession;
  final String? avatarImageBase64;
  final String? headerImageBase64;

  bool get hasAvatarImage =>
      avatarImageBase64 != null && avatarImageBase64!.isNotEmpty;
  bool get hasHeaderImage =>
      headerImageBase64 != null && headerImageBase64!.isNotEmpty;

  UserProfile copyWith({
    String? fullName,
    String? handle,
    String? bio,
    String? profession,
    String? avatarImageBase64,
    String? headerImageBase64,
  }) {
    return UserProfile(
      fullName: fullName ?? this.fullName,
      handle: handle ?? this.handle,
      bio: bio ?? this.bio,
      profession: profession ?? this.profession,
      avatarImageBase64: avatarImageBase64 ?? this.avatarImageBase64,
      headerImageBase64: headerImageBase64 ?? this.headerImageBase64,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'fullName': fullName,
        'handle': handle,
        'bio': bio,
        'profession': profession,
        'avatarImageBase64': avatarImageBase64,
        'headerImageBase64': headerImageBase64,
      };

  factory UserProfile.fromJson(Map<String, dynamic> json) => UserProfile(
        fullName: json['fullName'] as String? ?? 'Alex Rivera',
        handle: json['handle'] as String? ?? '@productlead',
        bio: json['bio'] as String? ??
            'Guiding nursing and midwifery teams through safe practice, exam preparation, and compassionate leadership across our teaching hospital.',
        profession: json['profession'] as String? ?? 'Clinical Educator',
        avatarImageBase64: json['avatarImageBase64'] as String?,
        headerImageBase64: json['headerImageBase64'] as String?,
      );

  String encode() => jsonEncode(toJson());

  static UserProfile decode(String source) =>
      UserProfile.fromJson(jsonDecode(source) as Map<String, dynamic>);

  static String? encodeBytes(List<int>? bytes) =>
      bytes == null || bytes.isEmpty ? null : base64Encode(bytes);

  List<int>? decodeBytes() {
    if (!hasAvatarImage) return null;
    try {
      return base64Decode(avatarImageBase64!);
    } catch (_) {
      return null;
    }
  }

  List<int>? decodeHeaderBytes() {
    if (!hasHeaderImage) return null;
    try {
      return base64Decode(headerImageBase64!);
    } catch (_) {
      return null;
    }
  }
}
