import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';

class BiometricSession {
  BiometricSession({required this.token});

  final String token;
}

class BiometricAuthService {
  BiometricAuthService._();

  static const _storage = FlutterSecureStorage();
  static final _auth = LocalAuthentication();

  static const _tokenKey = 'meca_oficina_bio_token';
  static const _enabledKey = 'meca_oficina_bio_enabled';

  static Future<bool> canUseBiometrics() async {
    try {
      final supported = await _auth.isDeviceSupported();
      final canCheck = await _auth.canCheckBiometrics;
      return supported && canCheck;
    } on PlatformException {
      return false;
    }
  }

  static Future<bool> hasEnabledBiometrics() async {
    final enabled = await _storage.read(key: _enabledKey);
    final token = await _storage.read(key: _tokenKey);
    return enabled == 'true' && token != null && token.isNotEmpty;
  }

  static Future<void> saveSession(String token) async {
    await _storage.write(key: _tokenKey, value: token);
    await _storage.write(key: _enabledKey, value: 'true');
  }

  static Future<void> disable() async {
    await _storage.delete(key: _tokenKey);
    await _storage.delete(key: _enabledKey);
  }

  static Future<BiometricSession?> authenticate() async {
    final available = await canUseBiometrics();
    if (!available) return null;

    try {
      final didAuthenticate = await _auth.authenticate(
        localizedReason: 'Use sua biometria para entrar no app',
        options: const AuthenticationOptions(
          biometricOnly: false,
          stickyAuth: true,
          useErrorDialogs: true,
        ),
      );

      if (!didAuthenticate) {
        return null;
      }

      final token = await _storage.read(key: _tokenKey);
      if (token == null || token.isEmpty) {
        return null;
      }

      return BiometricSession(token: token);
    } on PlatformException {
      return null;
    }
  }
}





