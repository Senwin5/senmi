import 'package:flutter/foundation.dart';
import 'package:local_auth/local_auth.dart';

class BiometricService {
  static final LocalAuthentication auth = LocalAuthentication();

  static Future<bool> isAvailable() async {
    final supported = await auth.isDeviceSupported();
    final canCheck = await auth.canCheckBiometrics;
    final available = await auth.getAvailableBiometrics();

    if (kDebugMode) {
      print("Supported: $supported");
    }
    if (kDebugMode) {
      print("Can check: $canCheck");
    }
    if (kDebugMode) {
      print("Available biometrics: $available");
    }

    return supported && canCheck && available.isNotEmpty;
  }

  static Future<bool> authenticate() async {
    try {
      final result = await auth.authenticate(
        localizedReason: "Authenticate to access Senmi",
        biometricOnly: true,
      );

      if (kDebugMode) {
        print("Authentication result: $result");
      }
      return result;
    } catch (e) {
      if (kDebugMode) {
        print("Authentication error: $e");
      }
      return false;
    }
  }
}
