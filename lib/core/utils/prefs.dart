import 'package:shared_preferences/shared_preferences.dart';

class Prefs {
  static const String keyToken = "auth_token";
  static const String keyIsAdmin = "is_admin";
  static const String keyUserEmail = "user_email";

  static Future<void> saveSession({required String token, required bool isAdmin, required String email}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(keyToken, token);
    await prefs.setBool(keyIsAdmin, isAdmin);
    await prefs.setString(keyUserEmail, email);
  }

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(keyToken);
  }

  static Future<bool> isAdmin() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(keyIsAdmin) ?? false;
  }

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
}
