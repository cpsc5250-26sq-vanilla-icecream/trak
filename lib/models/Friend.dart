class Friend {
  final userId;
  final friendId;
  final createdAt;
  Friend({this.userId, this.friendId, this.createdAt});

  factory Friend.fromCloud(Map<String,dynamic> map){
    return Friend(
      userId: map['userId'] as String,
      friendId: map['friendId'] as String,
      createdAt: map['createdAt'] as String
    );
  }

  Map<String, dynamic> toMap(){
    return {
      'userId': userId,
      'friendId': friendId,
      'createdAt': createdAt,
    };
  }
}