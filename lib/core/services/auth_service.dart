import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AuthService {
  final LocalAuthentication _localAuth = LocalAuthentication();
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  static const String _pinKey = 'auth_pin';

  Future<bool> canAuthenticate() async {
    try {
      return await _localAuth.canCheckBiometrics ||
          await _localAuth.isDeviceSupported();
    } on PlatformException {
      return false;
    }
  }

  Future<bool> authenticate() async {
    try {
        return await _localAuth.authenticate(
          localizedReason: 'Please authenticate to access your credentials',
          options: const AuthenticationOptions(
            stickyAuth: true,
            biometricOnly: false,
          ),
        );
    } on PlatformException {
      return false;
    }
  }

  Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      return await _localAuth.getAvailableBiometrics();
    } on PlatformException {
      return [];
    }
  }

  Future<bool> isDeviceSecure() async {
    try {
      return await _localAuth.isDeviceSupported();
    } on PlatformException {
      return false;
    }
  }

  Future<void> setPin(String pin) async {
    await _secureStorage.write(key: _pinKey, value: pin);
  }

  Future<bool> verifyPin(String pin) async {
    final storedPin = await _secureStorage.read(key: _pinKey);
    return pin == storedPin;
  }

  Future<bool> hasPin() async {
    bool pinSet =  await _secureStorage.containsKey(key: _pinKey);
    if(pinSet) {
      final storedPin = await _secureStorage.read(key: _pinKey);
      pinSet = storedPin != null;
    }
    return pinSet;
  }

  Future<bool> shouldSetupPin() async {
    final canAuth = await canAuthenticate();
    final hasPinSet = await hasPin();
    return !canAuth && !hasPinSet;
  }
} 