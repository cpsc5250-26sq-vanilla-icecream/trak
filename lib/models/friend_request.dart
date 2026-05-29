class FriendRequest {
  final String fromUserId;
  final String fromUsername;
  final String? fromDisplayName;
  final String? fromAvatarUrl;
  final String createdAt;

  FriendRequest({
    required this.fromUserId,
    required this.fromUsername,
    this.fromDisplayName,
    this.fromAvatarUrl,
    required this.createdAt,
  });

  factory FriendRequest.fromCloud(Map<String, dynamic> map) {
    return FriendRequest(
      fromUserId: map['fromUserId'] as String,
      fromUsername: map['fromUsername'] as String,
      fromDisplayName: map['fromDisplayName'] as String?,
      fromAvatarUrl: map['fromAvatarUrl'] as String?,
      createdAt: map['createdAt'] as String,
    );
  }
}
