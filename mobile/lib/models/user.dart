class UserProfile {
  final String id;
  final String phone;
  final String? name;
  final String? email;
  final String? avatarInitial;

  UserProfile({required this.id, required this.phone, this.name, this.email, this.avatarInitial});

  factory UserProfile.fromJson(Map<String, dynamic> j) => UserProfile(
    id: j['id'] as String,
    phone: j['phone'] as String,
    name: j['name'] as String?,
    email: j['email'] as String?,
    avatarInitial: j['avatar_initial'] as String? ?? j['avatarInitial'] as String?,
  );
}
