import 'package:flutter/foundation.dart';
import 'package:local_auth/local_auth.dart';

class BiometricAuthService {
  static LocalAuthentication? _localAuth;
  static bool testMode = false;
  static bool testAuthResult = true;

  static LocalAuthentication get _auth => _localAuth ??= LocalAuthentication();

  /// Check whether this physical device has a biometric sensor (fingerprint, face, etc.)
  static Future<bool> canAuthenticate() async {
    if (testMode) return true;
    if (kIsWeb) return false;
    try {
      final isSupported = await _auth.isDeviceSupported();
      final canCheck = await _auth.canCheckBiometrics;
      return isSupported || canCheck;
    } catch (_) {
      return false;
    }
  }

  /// Trigger the native phone OS biometric prompt (Android BiometricPrompt / iOS LocalAuthentication)
  static Future<bool> authenticate({
    String reason = 'Scan your fingerprint or verify biometrics to log in to TrackMyLibrary',
  }) async {
    if (testMode) return testAuthResult;
    if (kIsWeb) return false;
    try {
      final canCheck = await canAuthenticate();
      if (!canCheck) return false;

      return await _auth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(
          biometricOnly: false,
          stickyAuth: true,
          useErrorDialogs: true,
        ),
      );
    } catch (_) {
      return false;
    }
  }
}
