import 'dart:async';
import 'package:flutter/material.dart';

class AppStateService {
  static const int _autoLockTimeout = 5 * 60; // 5 minutes in seconds
  Timer? _lockTimer;
  final VoidCallback _onLockRequired;
  bool _isLocked = false;

  AppStateService(this._onLockRequired);

  void initialize() {
    WidgetsBinding.instance.addObserver(_AppLifecycleObserver(this));
  }

  void onResume() {
    if (_isLocked) {
      _onLockRequired();
    }
  }

  void onPause() {
    _startLockTimer();
  }

  void onUserInteraction() {
    _resetLockTimer();
  }

  void _startLockTimer() {
    _lockTimer?.cancel();
    _lockTimer = Timer(const Duration(seconds: _autoLockTimeout), () {
      _isLocked = true;
      _onLockRequired();
    });
  }

  void _resetLockTimer() {
    _lockTimer?.cancel();
    _startLockTimer();
  }

  void dispose() {
    _lockTimer?.cancel();
  }
}

class _AppLifecycleObserver extends WidgetsBindingObserver {
  final AppStateService _service;

  _AppLifecycleObserver(this._service);

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        _service.onResume();
        break;
      case AppLifecycleState.paused:
        _service.onPause();
        break;
      default:
        break;
    }
  }
} 