class UserProfile {
  final String name;
  final int age;

  UserProfile({
    required this.name,
    required this.age,
  });

  UserProfile copyWith({
    String? name,
    int? age,
  }) {
    return UserProfile(
      name: name ?? this.name,
      age: age ?? this.age,
    );
  }
}
