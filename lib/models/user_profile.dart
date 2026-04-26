class UserProfile {
  final String userId;
  final String username;
  final String displayName;
  final String? avatarUrl;

  const UserProfile({
    required this.userId,
    required this.username,
    required this.displayName,
    this.avatarUrl,
  });

  factory UserProfile.fromMap(Map<String, dynamic> map) {
    return UserProfile(
      userId: map['userId'],
      username: map['username'],
      displayName: map['displayName'],
      avatarUrl: map['avatarUrl'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'username': username,
      'displayName': displayName,
      'avatarUrl': avatarUrl,
    };
  }
}
