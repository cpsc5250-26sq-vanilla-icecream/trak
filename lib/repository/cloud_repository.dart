import 'dart:convert';
import 'package:amplify_auth_cognito/amplify_auth_cognito.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:http/http.dart' as http;
import '../auth/jwt_utils.dart';
import '../models/friend.dart';
import '../models/leaderboard_entry.dart';

class CloudRepository {
  static const _base =
      'https://v1mm0rec3f.execute-api.us-east-1.amazonaws.com/prod';

  Future<String> _getToken() async {
    final session = await Amplify.Auth.fetchAuthSession() as CognitoAuthSession;
    return session.userPoolTokensResult.value.idToken.raw;
  }

  Future<Map<String, String>> _headers() async => {
    'Authorization': 'Bearer ${await _getToken()}',
    'Content-Type': 'application/json',
  };

  void _check(http.Response response, String call) {
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('$call failed ${response.statusCode}: ${response.body}');
    }
  }

  Future<void> upsertUser() async {
    final headers = await _headers();
    final claims = JwtUtils.decodeClaims(
      headers['Authorization']!.substring('Bearer '.length),
    );

    final response = await http.post(
      Uri.parse('$_base/users'),
      headers: headers,
      body: jsonEncode({
        if (claims['name'] != null) 'displayName': claims['name'],
        if (claims['picture'] != null) 'avatarUrl': claims['picture'],
      }),
    );
    _check(response, 'upsertUser');
  }

  Future<void> submitSteps(int stepCount) async {
    final response = await http.post(
      Uri.parse('$_base/steps'),
      headers: await _headers(),
      body: jsonEncode({'stepCount': stepCount}),
    );
    _check(response, 'submitSteps');
  }

  Future<List<LeaderboardEntry>> fetchLeaderboard() async {
    final response = await http.get(
      Uri.parse('$_base/leaderboard'),
      headers: await _headers(),
    );
    _check(response, 'fetchLeaderboard');
    final list = jsonDecode(response.body) as List<dynamic>;
    return list
        .map((e) => LeaderboardEntry.fromCloud(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<Friend>> fetchFriends() async {
    final response = await http.get(
      Uri.parse('$_base/friends'),
      headers: await _headers(),
    );
    _check(response, 'fetchFriends');
    final data = jsonDecode(response.body) as List<dynamic>;
    return data
        .map((e) => Friend.fromCloud(e as Map<String, dynamic>))
        .toList();
  }
}
