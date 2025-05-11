import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

class _AuthScreenState extends State<AuthScreen>
    with SingleTickerProviderStateMixin {
  final AuthService _authService = AuthService();
  final TextEditingController _pinController = TextEditingController();
  final TextEditingController _confirmPinController = TextEditingController();
  final LocalAuthentication _localAuth = LocalAuthentication();

  bool _isBiometricAvailable = false;
  bool _showPinInput = false;
  bool _isSettingPin = true;
  bool _isLoading = true;
  String? _errorMessage;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  int _currentQuoteIndex = 0;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));
    _animationController.forward();
    _checkAuthentication();
    _startQuoteAnimation();
  }

  void _startQuoteAnimation() {
    Future.delayed(const Duration(seconds: 3), () {
        setState(() {
          _currentQuoteIndex = (_currentQuoteIndex + 1) % 5;
        });
        _startQuoteAnimation();
    });
  }

  Future<void> _checkAuthentication() async {
    try {
      final canAuth = await _localAuth.canCheckBiometrics;
      final isDeviceSupported = await _localAuth.isDeviceSupported();
      final hasPin = await _authService.hasPin();
      final availableBiometrics = await _localAuth.getAvailableBiometrics();

      setState(() {
        _isBiometricAvailable =
            canAuth && isDeviceSupported && availableBiometrics.isNotEmpty;
        _isSettingPin = !hasPin;
        _showPinInput = !_isBiometricAvailable || _isSettingPin;
        _isLoading = false;
      });

      if (_isBiometricAvailable && !_isSettingPin) {
        _authenticateWithBiometrics();
      }
    } catch (e) {
      debugPrint('Error checking authentication: $e');
        setState(() {
          _isLoading = false;
          _errorMessage = 'Error checking authentication methods';
          _showPinInput = true;
        });
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

          setState(() {
            _showPinInput = true;
            _errorMessage =
                'Biometric authentication failed. Please use PIN instead.';
          });
      }
    } catch (e) {
      debugPrint('Error during biometric authentication: $e');
        setState(() {
          _errorMessage =
              'Biometric authentication failed. Please use PIN instead.';
          _showPinInput = true;
        });
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

    try {
      await _authService.setPin(_pinController.text);
        widget.onAuthenticated();
    } catch (e) {
      debugPrint('Error setting PIN: $e');
        setState(() {
          _errorMessage = 'Failed to set PIN. Please try again.';
        });
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

    try {
      final isValid = await _authService.verifyPin(pin);
      if (isValid) {
        widget.onAuthenticated();
      } else {
        setState(() {
          _errorMessage = 'Invalid PIN';
        });
      }
    } catch (e) {
      debugPrint('Error verifying PIN: $e');
        setState(() {
          _errorMessage = 'Failed to verify PIN. Please try again.';
        });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AnimatedQuote(currentQuoteIndex: _currentQuoteIndex),
                  const SizedBox(height: 40),
                  const AppLogo(),
                  const SizedBox(height: 40),
                  AuthHeader(
                    isSettingPin: _isSettingPin,
                  ),
                  const SizedBox(height: 16),
                  AuthSubtitle(
                    isSettingPin: _isSettingPin,
                  ),
                  const SizedBox(height: 32),
                  if (_errorMessage != null) ...[
                    ErrorBanner(
                      errorMessage: _errorMessage!,
                      onDismiss: () {
                        setState(() {
                          _errorMessage = null;
                        });
                      },
                    ),
                    const SizedBox(height: 24),
                  ],
                  if (_isSettingPin)
                    PinSetupForm(
                      pinController: _pinController,
                      confirmPinController: _confirmPinController,
                      onSetup: _setupPin,
                      isLoading: _isLoading,
                    )
                  else
                    PinAuthForm(
                      pinController: _pinController,
                      showPinInput: _showPinInput,
                      onToggleVisibility: () {
                        setState(() {
                          _showPinInput = !_showPinInput;
                        });
                      },
                      onAuthenticate: _authenticateWithPin,
                      isLoading: _isLoading,
                    ),
                  if (!_isSettingPin && _isBiometricAvailable) ...[
                    const SizedBox(height: 32),
                    BiometricButton(
                      onAuthenticate: _authenticateWithBiometrics,
                    ),
                  ],
                ],
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

class AppLogo extends StatelessWidget {
  const AppLogo({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withOpacity(0.18),
            blurRadius: 32,
            spreadRadius: 8,
          ),
        ],
      ),
      child: const Icon(
        Icons.lock_outline,
        size: 64,
        color: AppTheme.primaryColor,
      ),
    );
  }
}

class AnimatedQuote extends StatelessWidget {
  final int currentQuoteIndex;

  const AnimatedQuote({
    Key? key,
    required this.currentQuoteIndex,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final quotes = [
      {
        'text': "Your secrets are safe with us",
        'author': "Secure Vault",
        'icon': Icons.shield_outlined,
      },
      {
        'text': "Security is not a feature, it's a promise",
        'author': "Secure Vault",
        'icon': Icons.security_outlined,
      },
      {
        'text': "Protecting what matters most",
        'author': "Secure Vault",
        'icon': Icons.lock_outline,
      },
      {
        'text': "Your digital fortress",
        'author': "Secure Vault",
        'icon': Icons.castle_outlined,
      },
      {
        'text': "Security you can trust",
        'author': "Secure Vault",
        'icon': Icons.verified_user_outlined,
      },
    ];

    final currentQuote = quotes[currentQuoteIndex];

    return SizedBox(
      height: 180, // Fixed height for the quote container
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 1000),
        transitionBuilder: (Widget child, Animation<double> animation) {
          return FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0.0, 0.1),
                end: Offset.zero,
              ).animate(animation),
              child: child,
            ),
          );
        },
        child: Container(
          key: ValueKey<int>(currentQuoteIndex),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppTheme.primaryColor.withOpacity(0.1),
                AppTheme.primaryColor.withOpacity(0.05),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppTheme.primaryColor.withOpacity(0.1),
              width: 1,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                currentQuote['icon'] as IconData,
                size: 32,
                color: AppTheme.primaryColor.withOpacity(0.7),
              ),
              const SizedBox(height: 16),
              Text(
                currentQuote['text'] as String,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey[800],
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                currentQuote['author'] as String,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class AuthHeader extends StatelessWidget {
  final bool isSettingPin;

  const AuthHeader({
    Key? key,
    required this.isSettingPin,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Text(
      isSettingPin ? 'Set Up Your PIN' : 'Welcome to Secure Vault',
      textAlign: TextAlign.center,
      style: const TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        color: AppTheme.primaryColor,
      ),
    );
  }
}

class AuthSubtitle extends StatelessWidget {
  final bool isSettingPin;

  const AuthSubtitle({
    Key? key,
    required this.isSettingPin,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Text(
      isSettingPin
          ? 'Create a 6-digit PIN to secure your vault'
          : 'Please enter your master password to continue',
      textAlign: TextAlign.center,
      style: TextStyle(
        fontSize: 16,
        color: Colors.grey[600],
      ),
    );
  }
}

class ErrorBanner extends StatelessWidget {
  final String errorMessage;
  final VoidCallback onDismiss;

  const ErrorBanner({
    Key? key,
    required this.errorMessage,
    required this.onDismiss,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    IconData errorIcon;
    String errorTitle;

    if (errorMessage.toLowerCase().contains('biometric')) {
      errorIcon = Icons.fingerprint;
      errorTitle = 'Biometric Authentication Failed';
    } else if (errorMessage.toLowerCase().contains('pin')) {
      errorIcon = Icons.lock;
      errorTitle = 'PIN Error';
    } else {
      errorIcon = Icons.error_outline;
      errorTitle = 'Authentication Error';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 24.0),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.red[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.red[100]!.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.red[100],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(errorIcon, color: Colors.red[700], size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  errorTitle,
                  style: TextStyle(
                    color: Colors.red[700],
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  errorMessage,
                  style: TextStyle(
                    color: Colors.red[600],
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(Icons.close, color: Colors.red[400], size: 20),
            onPressed: onDismiss,
          ),
        ],
      ),
    );
  }
}

class PinSetupForm extends StatefulWidget {
  final TextEditingController pinController;
  final TextEditingController confirmPinController;
  final VoidCallback onSetup;
  final bool isLoading;

  const PinSetupForm({
    Key? key,
    required this.pinController,
    required this.confirmPinController,
    required this.onSetup,
    required this.isLoading,
  }) : super(key: key);

  @override
  State<PinSetupForm> createState() => _PinSetupFormState();
}

class _PinSetupFormState extends State<PinSetupForm> {
  bool _obscurePin = true;
  bool _obscureConfirmPin = true;

  void _togglePinVisibility() {
    setState(() {
      _obscurePin = !_obscurePin;
    });
  }

  void _toggleConfirmPinVisibility() {
    setState(() {
      _obscureConfirmPin = !_obscureConfirmPin;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextField(
          controller: widget.pinController,
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(6),
          ],
          obscureText: _obscurePin,
          style: const TextStyle(
            color: Colors.black87,
            fontSize: 24,
            letterSpacing: 8,
          ),
          textAlign: TextAlign.center,
          decoration: InputDecoration(
            hintText: 'Enter 6-digit PIN',
            hintStyle: TextStyle(
              color: Colors.grey[500],
              fontSize: 16,
              letterSpacing: 0,
            ),
            prefixIcon: Icon(
              Icons.lock_outline,
              color: Colors.grey[500],
            ),
            suffixIcon: IconButton(
              icon: Icon(
                _obscurePin ? Icons.visibility_off : Icons.visibility,
                color: Colors.grey[500],
              ),
              onPressed: _togglePinVisibility,
            ),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: AppTheme.primaryColor,
                width: 2,
              ),
            ),
          ),
        ),
        const SizedBox(height: 20),
        TextField(
          controller: widget.confirmPinController,
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(6),
          ],
          obscureText: _obscureConfirmPin,
          style: const TextStyle(
            color: Colors.black87,
            fontSize: 24,
            letterSpacing: 8,
          ),
          textAlign: TextAlign.center,
          decoration: InputDecoration(
            hintText: 'Confirm 6-digit PIN',
            hintStyle: TextStyle(
              color: Colors.grey[500],
              fontSize: 16,
              letterSpacing: 0,
            ),
            prefixIcon: Icon(
              Icons.lock_outline,
              color: Colors.grey[500],
            ),
            suffixIcon: IconButton(
              icon: Icon(
                _obscureConfirmPin ? Icons.visibility_off : Icons.visibility,
                color: Colors.grey[500],
              ),
              onPressed: _toggleConfirmPinVisibility,
            ),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: AppTheme.primaryColor,
                width: 2,
              ),
            ),
          ),
        ),
        const SizedBox(height: 32),
        ElevatedButton(
          onPressed: widget.isLoading ? null : widget.onSetup,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primaryColor,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 2,
          ),
          child: widget.isLoading
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : const Text(
                  'Set PIN',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
        ),
      ],
    );
  }
}

class PinAuthForm extends StatefulWidget {
  final TextEditingController pinController;
  final bool showPinInput;
  final VoidCallback onToggleVisibility;
  final VoidCallback onAuthenticate;
  final bool isLoading;

  const PinAuthForm({
    Key? key,
    required this.pinController,
    required this.showPinInput,
    required this.onToggleVisibility,
    required this.onAuthenticate,
    required this.isLoading,
  }) : super(key: key);

  @override
  State<PinAuthForm> createState() => _PinAuthFormState();
}

class _PinAuthFormState extends State<PinAuthForm> {
  bool _obscureText = true;

  void _toggleVisibility() {
    setState(() {
      _obscureText = !_obscureText;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextField(
          controller: widget.pinController,
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(6),
          ],
          obscureText: _obscureText,
          style: const TextStyle(
            color: Colors.black87,
            fontSize: 24,
            letterSpacing: 8,
          ),
          textAlign: TextAlign.center,
          decoration: InputDecoration(
            hintText: 'Enter 6-digit PIN',
            hintStyle: TextStyle(
              color: Colors.grey[500],
              fontSize: 16,
              letterSpacing: 0,
            ),
            prefixIcon: Icon(
              Icons.lock_outline,
              color: Colors.grey[500],
            ),
            suffixIcon: IconButton(
              icon: Icon(
                _obscureText ? Icons.visibility_off : Icons.visibility,
                color: Colors.grey[500],
              ),
              onPressed: _toggleVisibility,
            ),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: AppTheme.primaryColor,
                width: 2,
              ),
            ),
          ),
        ),
        const SizedBox(height: 32),
        ElevatedButton(
          onPressed: widget.isLoading ? null : widget.onAuthenticate,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primaryColor,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 2,
          ),
          child: widget.isLoading
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : const Text(
                  'Unlock',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
        ),
      ],
    );
  }
}

class BiometricButton extends StatelessWidget {
  final VoidCallback onAuthenticate;

  const BiometricButton({
    Key? key,
    required this.onAuthenticate,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      child: Column(
        children: [
          const Divider(
            color: Colors.grey,
            thickness: 0.5,
          ),
          const SizedBox(height: 20),
          Text(
            'Or use biometric authentication',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: onAuthenticate,
            icon: const Icon(Icons.fingerprint, size: 24),
            label: const Text('Use Biometrics'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 2,
            ),
          ),
        ],
      ),
    );
  }
}
