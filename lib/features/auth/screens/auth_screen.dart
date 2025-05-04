import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
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

class _AuthScreenState extends State<AuthScreen> with SingleTickerProviderStateMixin {
  final AuthService _authService = AuthService();
  final TextEditingController _pinController = TextEditingController();
  final TextEditingController _confirmPinController = TextEditingController();
  final LocalAuthentication _localAuth = LocalAuthentication();
  
  bool _isBiometricAvailable = false;
  bool _showPinInput = false;
  bool _isSettingPin = false;
  bool _isLoading = true;
  String? _errorMessage;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );
    _animationController.forward();
    _checkAuthentication();
  }

  Future<void> _checkAuthentication() async {
    try {
      final canAuth = await _localAuth.canCheckBiometrics;
      final isDeviceSupported = await _localAuth.isDeviceSupported();
      final shouldSetupPin = await _authService.shouldSetupPin();
      final hasPin = await _authService.hasPin();

      if (mounted) {
        setState(() {
          _isBiometricAvailable = canAuth && isDeviceSupported;
          _isSettingPin = shouldSetupPin;
          _showPinInput = !_isBiometricAvailable && hasPin;
          _isLoading = false;
        });
      }

      if (_isBiometricAvailable && !shouldSetupPin) {
        _authenticateWithBiometrics();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Error checking authentication methods';
        });
      }
    }
  }

  Future<void> _authenticateWithBiometrics() async {
    try {
      final isAuthenticated = await _localAuth.authenticate(
        localizedReason: 'Authenticate to access your credentials',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: true,
        ),
      );

      if (isAuthenticated) {
        widget.onAuthenticated();
      } else {
        if (mounted) {
          setState(() {
            _showPinInput = true;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Biometric authentication failed';
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

  Widget _buildLogo() {
    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withOpacity(0.1),
        shape: BoxShape.circle,
      ),
      child: const Icon(
        Icons.lock_outline,
        size: 64,
        color: AppTheme.primaryColor,
      ),
    );
  }

  Widget _buildPinInput() {
    return Column(
      children: [
        TextField(
          controller: _pinController,
          keyboardType: TextInputType.number,
          obscureText: true,
          maxLength: 6,
          style: const TextStyle(fontSize: 24, letterSpacing: 8),
          textAlign: TextAlign.center,
          decoration: InputDecoration(
            labelText: _isSettingPin ? 'Enter 6-digit PIN' : 'Enter PIN',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            filled: true,
            fillColor: Theme.of(context).cardColor,
          ),
        ),
        if (_isSettingPin) ...[
          const SizedBox(height: 16),
          TextField(
            controller: _confirmPinController,
            keyboardType: TextInputType.number,
            obscureText: true,
            maxLength: 6,
            style: const TextStyle(fontSize: 24, letterSpacing: 8),
            textAlign: TextAlign.center,
            decoration: InputDecoration(
              labelText: 'Confirm PIN',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: Theme.of(context).cardColor,
            ),
          ),
        ],
        if (_errorMessage != null) ...[
          const SizedBox(height: 16),
          Text(
            _errorMessage!,
            style: TextStyle(
              color: Theme.of(context).colorScheme.error,
              fontSize: 14,
            ),
          ),
        ],
        const SizedBox(height: 24),
        ElevatedButton(
          onPressed: _isSettingPin ? _setupPin : _authenticateWithPin,
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: Text(
            _isSettingPin ? 'Set PIN' : 'Authenticate',
            style: const TextStyle(fontSize: 16),
          ),
        ),
      ],
    );
  }

  Widget _buildBiometricButton() {
    return Column(
      children: [
        ElevatedButton.icon(
          onPressed: _authenticateWithBiometrics,
          icon: const Icon(Icons.fingerprint, size: 24),
          label: const Text('Use Biometrics'),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        const SizedBox(height: 16),
        TextButton(
          onPressed: () {
            setState(() {
              _showPinInput = true;
            });
          },
          child: const Text('Use PIN instead'),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Theme.of(context).colorScheme.primary.withOpacity(0.1),
              Theme.of(context).scaffoldBackgroundColor,
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildLogo(),
                      const SizedBox(height: 32),
                      const Text(
                        'Secure Credentials',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Please authenticate to continue',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 32),
                      if (_isLoading)
                        const CircularProgressIndicator()
                      else if (_isSettingPin || _showPinInput)
                        _buildPinInput()
                      else if (_isBiometricAvailable)
                        _buildBiometricButton(),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    _pinController.dispose();
    _confirmPinController.dispose();
    super.dispose();
  }
} 