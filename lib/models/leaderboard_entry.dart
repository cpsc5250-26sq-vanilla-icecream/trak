class LeaderboardEntry {
  final String userId;
  final String username;
  final String? displayName;
  final String? avatarUrl;
  final int totalPoints;
  final int rank;

  const LeaderboardEntry({
    required this.userId,
    required this.username,
    this.displayName,
    this.avatarUrl,
    required this.totalPoints,
    required this.rank,
  });

  factory LeaderboardEntry.fromMap(Map<String, dynamic> map) {
    return LeaderboardEntry(
      userId: map['user_id'],
      username: map['username'],
      displayName: map['display_name'],
      avatarUrl: map['avatar_url'],
      totalPoints: map['points'],
      rank: map['rank'],
    );
  }

  factory LeaderboardEntry.fromCloud(Map<String, dynamic> map) {
    return LeaderboardEntry(
      userId: map['userId'],
      username: map['username'],
      displayName: map['displayName'] as String?,
      avatarUrl: map['avatarUrl'] as String?,
      totalPoints: map['points'] as int,
      rank: map['rank'] as int,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'user_id': userId,
      'username': username,
      'display_name': displayName,
      'avatar_url': avatarUrl,
      'points': totalPoints,
      'rank': rank,
      'cached_at': DateTime.now().millisecondsSinceEpoch,
    };
  }
}
