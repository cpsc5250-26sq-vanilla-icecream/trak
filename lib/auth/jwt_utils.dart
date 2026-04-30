import 'dart:convert';

abstract final class JwtUtils {
  static Map<String, dynamic> decodeClaims(String token) {
    final payload = token.split('.')[1];
    return jsonDecode(
          utf8.decode(base64Url.decode(base64Url.normalize(payload))),
        )
        as Map<String, dynamic>;
  }
}
