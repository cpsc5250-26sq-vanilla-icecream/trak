import 'dart:convert';
import 'package:amplify_auth_cognito/amplify_auth_cognito.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:http/http.dart' as http;
import '../auth/jwt_utils.dart';
import '../models/inventory_item.dart';
import '../models/leaderboard_entry.dart';
import '../models/use_item_result.dart';
import '../models/user_profile.dart';

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

  Future<UserProfile> getCurrentUser() async {
    final response = await http.get(
      Uri.parse('$_base/users/me'),
      headers: await _headers(),
    );
    _check(response, 'getCurrentUser');
    final map = jsonDecode(response.body) as Map<String, dynamic>;
    return UserProfile(
      userId: map['userId'],
      username: map['username'] ?? '',
      displayName: map['displayName'] ?? '',
      avatarUrl: map['avatarUrl'],
    );
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

  Future<List<InventoryItem>> fetchInventory() async {
    final response = await http.get(
      Uri.parse('$_base/inventory'),
      headers: await _headers(),
    );
    _check(response, 'fetchInventory');
    final list = jsonDecode(response.body) as List<dynamic>;
    return list
        .map((e) => InventoryItem.fromCloud(e as Map<String, dynamic>))
        .toList();
  }

  Future<UseItemResult> useItem(String itemId, String targetUserId) async {
    final response = await http.post(
      Uri.parse('$_base/inventory/use'),
      headers: await _headers(),
      body: jsonEncode({'itemId': itemId, 'targetUserId': targetUserId}),
    );
    if (response.statusCode == 404) {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      return UseItemResult.failure(body['message'] as String);
    }
    _check(response, 'useItem');
    return const UseItemResult.success();
  }

  Future<void> addFriend(String username) async {
    final response = await http.post(
      Uri.parse('$_base/friends'),
      headers: await _headers(),
      body: jsonEncode({'username': username}),
    );
    _check(response, 'addFriend');
  }

  Future<void> removeFriend(String friendId) async {
    final response = await http.delete(
      Uri.parse('$_base/friends/$friendId'),
      headers: await _headers(),
    );
    _check(response, 'removeFriend');
  }
}
