class Profile {
  final String id; // User ID (from Supabase Auth)
  final String email; // User email
  final String name; // User name
  final String? avatarUrl; // Optional avatar image URL
  final String? dob; // Optional date of birth
  final String? country; // Optional country

  Profile({
    required this.id,
    required this.email,
    required this.name,
    this.avatarUrl,
    this.dob,
    this.country,
  });

  /// Convert from Supabase row (Map) to Profile object
  factory Profile.fromMap(Map<String, dynamic> map) {
    return Profile(
      id: map['id'] ?? '',
      email: map['email'] ?? '',
      name: map['name'] ?? '',
      avatarUrl: map['avatar_url'],
      dob: map['dob'],
      country: map['country'],
    );
  }

  /// Convert Profile object to Map for insert/update
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'email': email,
      'name': name,
      if (avatarUrl != null) 'avatar_url': avatarUrl,
      if (dob != null) 'dob': dob,
      if (country != null) 'country': country,
    };
  }
}
