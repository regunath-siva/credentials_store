import 'package:flutter/material.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/theme/app_theme.dart';

class AuthScreen extends StatefulWidget {
  final VoidCallback onAuthenticated;

  const AuthScreen({
    Key? key,
    required this.onAuthenticated,
  }) : super(key: key);

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final AuthService _authService = AuthService();
  final TextEditingController _pinController = TextEditingController();
  final TextEditingController _confirmPinController = TextEditingController();
  bool _isBiometricAvailable = false;
  bool _showPinInput = false;
  bool _isSettingPin = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _checkAuthentication();
  }

  Future<void> _checkAuthentication() async {
    final shouldSetupPin = await _authService.shouldSetupPin();
    final canAuth = await _authService.canAuthenticate();
    final hasPin = await _authService.hasPin();

    if (mounted) {
      setState(() {
        _isBiometricAvailable = canAuth;
        _isSettingPin = shouldSetupPin;
        _showPinInput = !canAuth && hasPin;
      });
    }

    if (canAuth) {
      _authenticateWithBiometrics();
    }
  }

  Future<void> _authenticateWithBiometrics() async {
    final isAuthenticated = await _authService.authenticate();
    if (isAuthenticated) {
      widget.onAuthenticated();
    } else {
      if (mounted) {
        setState(() {
          _showPinInput = true;
        });
      }
    }
  }

  Future<void> _setupPin() async {
    if (_pinController.text.length != 6) {
      setState(() {
        _errorMessage = 'PIN must be 6 digits';
      });
      return;
    }

    if (_pinController.text != _confirmPinController.text) {
      setState(() {
        _errorMessage = 'PINs do not match';
      });
      return;
    }

    await _authService.setPin(_pinController.text);
    if (mounted) {
      widget.onAuthenticated();
    }
  }

  Future<void> _authenticateWithPin() async {
    final pin = _pinController.text;
    if (pin.length != 6) {
      setState(() {
        _errorMessage = 'PIN must be 6 digits';
      });
      return;
    }

    final isValid = await _authService.verifyPin(pin);
    if (isValid) {
      widget.onAuthenticated();
    } else {
      setState(() {
        _errorMessage = 'Invalid PIN';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.lock_outline,
                size: 64,
                color: AppTheme.primaryColor,
              ),
              const SizedBox(height: 24),
              const Text(
                'Secure Credentials',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textColor,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Please authenticate to continue',
                style: TextStyle(
                  fontSize: 16,
                  color: AppTheme.textColor,
                ),
              ),
              const SizedBox(height: 32),
              if (_isSettingPin) ...[
                TextField(
                  controller: _pinController,
                  keyboardType: TextInputType.number,
                  obscureText: true,
                  maxLength: 6,
                  decoration: const InputDecoration(
                    labelText: 'Enter 6-digit PIN',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _confirmPinController,
                  keyboardType: TextInputType.number,
                  obscureText: true,
                  maxLength: 6,
                  decoration: const InputDecoration(
                    labelText: 'Confirm PIN',
                    border: OutlineInputBorder(),
                  ),
                ),
                if (_errorMessage != null) ...[
                  const SizedBox(height: 16),
                  Text(
                    _errorMessage!,
                    style: const TextStyle(color: Colors.red),
                  ),
                ],
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _setupPin,
                  child: const Text('Set PIN'),
                ),
              ] else if (_showPinInput) ...[
                TextField(
                  controller: _pinController,
                  keyboardType: TextInputType.number,
                  obscureText: true,
                  maxLength: 6,
                  decoration: const InputDecoration(
                    labelText: 'Enter PIN',
                    border: OutlineInputBorder(),
                  ),
                ),
                if (_errorMessage != null) ...[
                  const SizedBox(height: 16),
                  Text(
                    _errorMessage!,
                    style: const TextStyle(color: Colors.red),
                  ),
                ],
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _authenticateWithPin,
                  child: const Text('Authenticate'),
                ),
              ] else if (_isBiometricAvailable) ...[
                ElevatedButton.icon(
                  onPressed: _authenticateWithBiometrics,
                  icon: const Icon(Icons.fingerprint),
                  label: const Text('Use Biometrics'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _pinController.dispose();
    _confirmPinController.dispose();
    super.dispose();
  }
} 