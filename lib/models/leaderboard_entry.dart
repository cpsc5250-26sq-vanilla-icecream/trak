class LeaderboardEntry {
  final String userId;
  final String username;
  final String? avatarUrl;
  final int totalPoints;
  final int rank;

  const LeaderboardEntry({
    required this.userId,
    required this.username,
    this.avatarUrl,
    required this.totalPoints,
    required this.rank,
  });
  factory LeaderboardEntry.fromMap(Map<String, dynamic> map) {
    return LeaderboardEntry(
      userId: map['user_id'],
      username: map['username'],
      avatarUrl: map['avatar_url'],
      totalPoints: map['points'],
      rank: map['rank'],
    );
  }

  factory LeaderboardEntry.fromCloud(Map<String, dynamic> map) {
    return LeaderboardEntry(
      userId: map['userId'],
      username: map['username'],
      avatarUrl: map['avatarUrl'],
      totalPoints: map['points'],
      rank: map['rank'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'user_id': userId,
      'username': username,
      'avatar_url': avatarUrl,
      'points': totalPoints,
      'rank': rank,
      'cached_at': DateTime.now().millisecondsSinceEpoch,
    };
  }
}
