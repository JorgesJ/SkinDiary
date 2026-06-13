import 'package:shared_preferences/shared_preferences.dart';

/// Gestiona si el usuario ha aceptado el aviso de uso informativo.
class ConsentService {
  const ConsentService._();

  static const String _key = 'consent_accepted_v1';

  static Future<bool> isAccepted() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_key) ?? false;
  }

  static Future<void> setAccepted(bool value) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_key, value);
  }
}
