import 'package:shared_preferences/shared_preferences.dart';

class Prefs {
  static const String keyToken = "auth_token";
  static const String keyIsAdmin = "is_admin";
  static const String keyUserEmail = "user_email";
  static const String keyRole = "user_role";
  static const String keySubAdminType = "sub_admin_type";

  static Future<void> saveSession({
    required String token,
    required bool isAdmin,
    required String email,
    String role = 'USER',
    String? subAdminType,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(keyToken, token);
    await prefs.setBool(keyIsAdmin, isAdmin);
    await prefs.setString(keyUserEmail, email);
    await prefs.setString(keyRole, role.toUpperCase());
    if (subAdminType != null) {
      await prefs.setString(keySubAdminType, subAdminType.toUpperCase());
    } else {
      await prefs.remove(keySubAdminType);
    }
  }

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(keyToken);
  }

  static Future<bool> isAdmin() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(keyIsAdmin) ?? false;
  }

  static Future<String> getRole() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(keyRole) ?? 'USER';
  }

  static Future<bool> isSubAdmin() async {
    final role = await getRole();
    return role == 'SUBADMIN';
  }

  static Future<String?> getSubAdminType() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(keySubAdminType);
  }

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
}
