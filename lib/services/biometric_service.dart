import 'package:local_auth/local_auth.dart';

class BiometricService {
  static final LocalAuthentication auth = LocalAuthentication();

  static Future<bool> isAvailable() async {
    return await auth.isDeviceSupported();
  }

  static Future<bool> authenticate() async {
    try {
      return await auth.authenticate(
        localizedReason: "Authenticate to access Senmi",
        biometricOnly: true,
      );
    } catch (_) {
      return false;
    }
  }
}