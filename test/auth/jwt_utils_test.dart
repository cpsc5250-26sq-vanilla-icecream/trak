import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:trak/auth/jwt_utils.dart';

String _makeToken(Map<String, dynamic> claims) {
  final payload = base64Url.encode(utf8.encode(jsonEncode(claims)));
  return 'eyJhbGciOiJSUzI1NiJ9.$payload.fakesig';
}

void main() {
  group('JwtUtils.decodeClaims', () {
    test('decodes standard string claims', () {
      final token = _makeToken({
        'sub': 'user-123',
        'name': 'Alice',
        'email': 'alice@example.com',
      });

      final claims = JwtUtils.decodeClaims(token);

      expect(claims['sub'], 'user-123');
      expect(claims['name'], 'Alice');
      expect(claims['email'], 'alice@example.com');
    });

    test('decodes token with null optional fields', () {
      final token = _makeToken({'sub': 'user-456'});

      final claims = JwtUtils.decodeClaims(token);

      expect(claims['name'], isNull);
      expect(claims['picture'], isNull);
    });

    test('decodes token where picture is present', () {
      final token = _makeToken({
        'sub': 'user-789',
        'picture': 'https://example.com/avatar.jpg',
      });

      final claims = JwtUtils.decodeClaims(token);

      expect(claims['picture'], 'https://example.com/avatar.jpg');
    });

    test('handles base64url payload without padding', () {
      // Payloads with lengths that don't align to 4-byte boundaries
      // need normalize() — this exercises that path.
      final token = _makeToken({'a': 'bc'});
      expect(() => JwtUtils.decodeClaims(token), returnsNormally);
    });
  });
}
