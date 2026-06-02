import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// 🎧 Listener automatique de confirmation email pour Firebase
class EmailConfirmationListener {
  static final EmailConfirmationListener _instance =
      EmailConfirmationListener._internal();
  factory EmailConfirmationListener() => _instance;
  EmailConfirmationListener._internal();

  Timer? _pollingTimer;
  bool _isListening = false;
  VoidCallback? _onConfirmed;
  VoidCallback? _onError;

  final Duration _pollingInterval = const Duration(seconds: 3);
  final int _maxAttempts = 100;
  int _attemptCount = 0;

  void startListening({
    required VoidCallback onConfirmed,
    VoidCallback? onError,
  }) {
    if (_isListening) return;

    _isListening = true;
    _onConfirmed = onConfirmed;
    _onError = onError;
    _attemptCount = 0;

    _checkEmailConfirmation();

    _pollingTimer = Timer.periodic(_pollingInterval, (_) {
      _checkEmailConfirmation();
    });
  }

  Future<void> _checkEmailConfirmation() async {
    if (!_isListening) return;

    _attemptCount++;

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      await user.reload();
      final updatedUser = FirebaseAuth.instance.currentUser;
      final isConfirmed = updatedUser?.emailVerified ?? false;

      if (isConfirmed) {
        stopListening();
        _onConfirmed?.call();
        return;
      }

      if (_attemptCount >= _maxAttempts) {
        stopListening();
        _onError?.call();
      }
    } catch (e) {
      if (_attemptCount >= _maxAttempts) {
        stopListening();
        _onError?.call();
      }
    }
  }

  void stopListening() {
    if (!_isListening) return;
    _isListening = false;
    _pollingTimer?.cancel();
    _pollingTimer = null;
    _attemptCount = 0;
  }

  Future<bool> checkNow() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return false;

      await user.reload();
      final updatedUser = FirebaseAuth.instance.currentUser;
      final isConfirmed = updatedUser?.emailVerified ?? false;

      if (isConfirmed) {
        stopListening();
        _onConfirmed?.call();
      }
      return isConfirmed;
    } catch (e) {
      return false;
    }
  }

  void dispose() {
    stopListening();
  }

  bool get isListening => _isListening;
}

class WindowFocusListener extends WidgetsBindingObserver {
  final VoidCallback onWindowFocused;
  WindowFocusListener({required this.onWindowFocused});

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      onWindowFocused();
    }
  }
}
