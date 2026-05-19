class Friend {
  final String userId;
  final String friendId;
  final String createdAt;
  Friend({
    required this.userId,
    required this.friendId,
    required this.createdAt,
  });

  factory Friend.fromCloud(Map<String, dynamic> map) {
    return Friend(
      userId: map['userId'] as String,
      friendId: map['friendId'] as String,
      createdAt: map['createdAt'] as String,
    );
  }

  Map<String, dynamic> toMap() {
    return {'userId': userId, 'friendId': friendId, 'createdAt': createdAt};
  }
}
