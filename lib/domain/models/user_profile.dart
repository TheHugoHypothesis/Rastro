class UserProfile {
  final String name;
  final int age;
  final String? photoPath;

  UserProfile({
    required this.name,
    required this.age,
    this.photoPath,
  });

  UserProfile copyWith({
    String? name,
    int? age,
    String? photoPath,
    bool removePhoto = false,
  }) {
    return UserProfile(
      name: name ?? this.name,
      age: age ?? this.age,
      photoPath: removePhoto ? null : (photoPath ?? this.photoPath),
    );
  }
}
