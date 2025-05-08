import 'package:get_storage/get_storage.dart';

class LocalStorageService {
  static final _storage = GetStorage();

  static const _keyName = 'name';
  static const _keyEmail = 'email';
  static const _keyPhone = 'phone';
  static const _keyPassword = 'password';
  static const _keyIsLoggedIn = 'is_logged_in';

  static Future<void> saveUserData({
    required String name,
    required String email,
    required String phone,
    required String password,
  }) async {
    await _storage.write(_keyName, name);
    await _storage.write(_keyEmail, email);
    await _storage.write(_keyPhone, phone);
    await _storage.write(_keyPassword, password);
    await _storage.write(_keyIsLoggedIn, true);
  }

  static Map<String, dynamic>? getUserData() {
    if (_storage.read(_keyIsLoggedIn) != true) return null;

    return {
      'name': _storage.read(_keyName),
      'email': _storage.read(_keyEmail),
      'phone': _storage.read(_keyPhone),
      'password': _storage.read(_keyPassword),
    };
  }

  static Future<void> logout() async {
    await _storage.remove(_keyName);
    await _storage.remove(_keyEmail);
    await _storage.remove(_keyPhone);
    await _storage.remove(_keyPassword);
    await _storage.write(_keyIsLoggedIn, false);
  }

  static bool isLoggedIn() => _storage.read(_keyIsLoggedIn) == true;
}
