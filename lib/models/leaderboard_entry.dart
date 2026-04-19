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
}
