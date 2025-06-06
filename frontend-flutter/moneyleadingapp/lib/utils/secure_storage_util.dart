// This file is optional, as FlutterSecureStorage can be used directly.
// It could be useful for more complex token management (e.g., refresh tokens).

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:mylendingapp_flutter/utils/constants.dart';

class SecureStorageUtil {
  static const _storage = FlutterSecureStorage();

  static Future<void> saveToken(String token) async {
    await _storage.write(key: AUTH_TOKEN_KEY, value: token);
  }

  static Future<String?> readToken() async {
    return await _storage.read(key: AUTH_TOKEN_KEY);
  }

  static Future<void> deleteToken() async {
    await _storage.delete(key: AUTH_TOKEN_KEY);
  }

  // Add methods for refresh tokens if your backend supports them
}