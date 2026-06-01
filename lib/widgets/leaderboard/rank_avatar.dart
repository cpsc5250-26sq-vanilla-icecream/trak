import 'package:flutter/material.dart';

class RankAvatar extends StatelessWidget {
  final int rank;
  final Color color;
  const RankAvatar({super.key, required this.rank, required this.color});

  @override
  Widget build(BuildContext context) {
    final isTopThree = rank <= 3;
    return CircleAvatar(
      radius: 18,
      backgroundColor: color,
      child: Text(
        '$rank',
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.bold,
          color: isTopThree ? Colors.black87 : Colors.black54,
        ),
      ),
    );
  }
}
