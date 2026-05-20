class Friend {
  final String userId;
  final String friendId;
  final String? username;
  final String? displayName;
  final String createdAt;

  Friend({
    required this.userId,
    required this.friendId,
    this.username,
    this.displayName,
    required this.createdAt,
  });

  factory Friend.fromCloud(Map<String, dynamic> map) {
    return Friend(
      userId: map['userId'] as String,
      friendId: map['friendId'] as String,
      username: map['username'] as String?,
      displayName: map['displayName'] as String?,
      createdAt: map['createdAt'] as String,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'friendId': friendId,
      'username': username,
      'displayName': displayName,
      'createdAt': createdAt,
    };
  }
}
