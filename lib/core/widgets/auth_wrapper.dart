import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class AuthWrapper extends StatefulWidget {
  final Widget child;

  const AuthWrapper({
    Key? key,
    required this.child,
  }) : super(key: key);

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  final AuthService _authService = AuthService();
  bool _isAuthenticated = false;
  bool _isSettingPin = false;
  final TextEditingController _pinController = TextEditingController();
  final TextEditingController _confirmPinController = TextEditingController();
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _checkAuthentication();
  }

  Future<void> _checkAuthentication() async {
    final canAuth = await _authService.canAuthenticate();
    if (canAuth) {
      final isAuthenticated = await _authService.authenticate();
      if (mounted) {
        final hasPin = await _authService.hasPin();
        setState(() {
          _isSettingPin = !hasPin;
          _isAuthenticated = isAuthenticated;
        });
      }
    } else {
      final hasPin = await _authService.hasPin();
      if (mounted) {
        setState(() {
          _isSettingPin = !hasPin;
          _isAuthenticated = hasPin;
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
      setState(() {
        _isSettingPin = false;
        _isAuthenticated = true;
        _errorMessage = null;
      });
    }
  }

  Future<void> _verifyPin() async {
    final isValid = await _authService.verifyPin(_pinController.text);
    if (mounted) {
      setState(() {
        _isAuthenticated = isValid;
        if (!isValid) {
          _errorMessage = 'Invalid PIN';
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isAuthenticated) {
      if (_isSettingPin) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Set PIN'),
            backgroundColor: Theme.of(context).primaryColor,
            foregroundColor: Colors.white,
          ),
          body: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextField(
                  controller: _pinController,
                  decoration: const InputDecoration(
                    labelText: 'Enter 6-digit PIN',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  obscureText: true,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _confirmPinController,
                  decoration: const InputDecoration(
                    labelText: 'Confirm PIN',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  obscureText: true,
                ),
                if (_errorMessage != null) ...[
                  const SizedBox(height: 16),
                  Text(
                    _errorMessage!,
                    style: const TextStyle(color: Colors.red),
                  ),
                ],
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _setupPin,
                  child: const Text('Set PIN'),
                ),
              ],
            ),
          ),
        );
      } else {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Enter PIN'),
            backgroundColor: Theme.of(context).primaryColor,
            foregroundColor: Colors.white,
          ),
          body: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextField(
                  controller: _pinController,
                  decoration: const InputDecoration(
                    labelText: 'Enter PIN',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  obscureText: true,
                ),
                if (_errorMessage != null) ...[
                  const SizedBox(height: 16),
                  Text(
                    _errorMessage!,
                    style: const TextStyle(color: Colors.red),
                  ),
                ],
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _verifyPin,
                  child: const Text('Verify PIN'),
                ),
              ],
            ),
          ),
        );
      }
    }

    return widget.child;
  }

  @override
  void dispose() {
    _pinController.dispose();
    _confirmPinController.dispose();
    super.dispose();
  }
} 