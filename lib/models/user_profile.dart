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
}
