class Friend {
  final String userId;
  final String friendId;
  final String? username;
  final String? displayName;
  final String? avatarUrl;
  final String createdAt;

  Friend({
    required this.userId,
    required this.friendId,
    this.username,
    this.displayName,
    this.avatarUrl,
    required this.createdAt,
  });

  factory Friend.fromCloud(Map<String, dynamic> map) {
    return Friend(
      userId: map['userId'] as String,
      friendId: map['friendId'] as String,
      username: map['username'] as String?,
      displayName: map['displayName'] as String?,
      avatarUrl: map['avatarUrl'] as String?,
      createdAt: map['createdAt'] as String,
    );
  }

  factory Friend.fromMap(Map<String, dynamic> map) {
    return Friend(
      userId: map['user_id'] as String,
      friendId: map['friend_id'] as String,
      username: map['username'] as String?,
      displayName: map['display_name'] as String?,
      avatarUrl: map['avatar_url'] as String?,
      createdAt: map['created_at'] as String,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'friend_id': friendId,
      'user_id': userId,
      'username': username,
      'display_name': displayName,
      'avatar_url': avatarUrl,
      'created_at': createdAt,
      'cached_at': DateTime.now().millisecondsSinceEpoch,
    };
  }
}
