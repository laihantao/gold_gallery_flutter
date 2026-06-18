import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  static const _prefBioEnabled = 'bio_lock_enabled';

  static final LocalAuthentication _auth = LocalAuthentication();

  static Future<bool> isBiometricEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_prefBioEnabled) ?? false;
  }

  static Future<void> setBiometricEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefBioEnabled, value);
  }

  static Future<bool> isDeviceSupported() => _auth.isDeviceSupported();

  static Future<bool> canCheckBiometrics() => _auth.canCheckBiometrics;

  /// Returns true when the user authenticates successfully.
  static Future<bool> authenticate() async {
    try {
      return await _auth.authenticate(
        localizedReason: 'Authenticate to access Gold Gallery',
        biometricOnly: false,
      );
    } catch (_) {
      return false;
    }
  }
}
