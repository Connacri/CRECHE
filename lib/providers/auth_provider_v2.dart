import 'dart:async';
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

import '../services/auth_service.dart';
import '../services/image_storage_service.dart';
import '../services/fcm_service.dart';

class AuthProviderV2 with ChangeNotifier {
  final AuthService _authService = AuthService();
  final ImageStorageService _imageService = ImageStorageService();
  final FCMService _fcmService = FCMService();

  firebase_auth.User? _currentUser;
  Map<String, dynamic>? _userData;
  AppAuthState _state = AppAuthState.initial;
  String? _errorMessage;

  bool _needsEmailConfirmation = false;
  bool _needsProfileCompletion = false;

  StreamSubscription<firebase_auth.User?>? _authSubscription;

  AuthProviderV2() {
    _init();
  }

  void _init() {
    _authSubscription = firebase_auth.FirebaseAuth.instance.authStateChanges().listen((user) async {
      _currentUser = user;
      if (user != null) {
        if (user.emailVerified) {
          _needsEmailConfirmation = false;
          await _checkUserStatus();
          _updateFCMToken();
        } else {
          _needsEmailConfirmation = true;
          _setState(AppAuthState.needsEmailConfirmation);
        }
      } else {
        _userData = null;
        _setState(AppAuthState.unauthenticated);
      }
      notifyListeners();
    });
  }

  Future<void> _updateFCMToken() async {
    if (_currentUser != null) {
      final token = await _fcmService.getToken();
      if (token != null) {
        await _fcmService.updateUserToken(_currentUser!.uid, token);
      }
    }
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }

  // Getters
  firebase_auth.User? get currentUser => _currentUser;
  Map<String, dynamic>? get userData => _userData;
  AppAuthState get state => _state;
  String? get errorMessage => _errorMessage;
  bool get needsEmailConfirmation => _needsEmailConfirmation;
  bool get needsProfileCompletion => _needsProfileCompletion;
  bool get isLoading => _state == AppAuthState.loading;

  // ============================================================================
  // MÉTHODES D'AUTHENTIFICATION
  // ============================================================================

  Future<AuthResult> signup({
    required String email,
    required String password,
    required String role,
  }) async {
    _setState(AppAuthState.loading);
    _errorMessage = null;

    final result = await _authService.signup(
      email: email,
      password: password,
      role: role,
    );

    if (result.success) {
      _currentUser = result.firebaseUser;
      _needsEmailConfirmation = result.needsEmailConfirmation;
      if (_needsEmailConfirmation) {
        _setState(AppAuthState.needsEmailConfirmation);
      }
    } else {
      _errorMessage = result.message;
      _setState(AppAuthState.error);
    }

    notifyListeners();
    return result;
  }

  Future<AuthResult> login({
    required String email,
    required String password,
  }) async {
    _setState(AppAuthState.loading);
    _errorMessage = null;

    final result = await _authService.login(
      email: email,
      password: password,
    );

    if (result.success) {
      _currentUser = result.firebaseUser;
      _needsEmailConfirmation = result.needsEmailConfirmation;
      _needsProfileCompletion = result.needsProfileCompletion;

      if (_needsEmailConfirmation) {
        _setState(AppAuthState.needsEmailConfirmation);
      } else if (_needsProfileCompletion) {
        _setState(AppAuthState.needsProfileCompletion);
      } else {
        await _checkUserStatus();
        await _updateFCMToken();
      }
    } else {
      _errorMessage = result.message;
      _setState(AppAuthState.error);
    }

    notifyListeners();
    return result;
  }

  Future<AuthResult> signInWithGoogle() async {
    _setState(AppAuthState.loading);
    _errorMessage = null;

    final result = await _authService.signInWithGoogle();

    if (result.success) {
      _currentUser = result.firebaseUser;
      _needsProfileCompletion = result.needsProfileCompletion;

      if (_needsProfileCompletion) {
        _setState(AppAuthState.needsProfileCompletion);
      } else {
        await _checkUserStatus();
        await _updateFCMToken();
      }
    } else {
      _errorMessage = result.message;
      _setState(AppAuthState.error);
    }

    notifyListeners();
    return result;
  }

  Future<void> logout() async {
    _setState(AppAuthState.loading);
    await _authService.signOut();
    _currentUser = null;
    _userData = null;
    _needsEmailConfirmation = false;
    _needsProfileCompletion = false;
    _setState(AppAuthState.unauthenticated);
    notifyListeners();
  }

  Future<AuthResult> resendConfirmationEmail(String email) async {
    if (_currentUser != null) {
      try {
        await _currentUser!.sendEmailVerification();
        return AuthResult.success(firebaseUser: _currentUser, message: 'Email envoyé');
      } catch (e) {
        return AuthResult.error(e.toString());
      }
    }
    return AuthResult.error('Utilisateur non connecté');
  }

  Future<AuthResult> deleteUnconfirmedAccount() async {
    if (_currentUser != null) {
      try {
        await _currentUser!.delete();
        await logout();
        return AuthResult.success(message: 'Compte supprimé');
      } catch (e) {
        return AuthResult.error(e.toString());
      }
    }
    return AuthResult.error('Utilisateur non connecté');
  }

  Future<AuthResult> sendPasswordReset(String email) async {
    return await _authService.sendPasswordResetEmail(email);
  }

  Future<bool> checkEmailConfirmationStatus() async {
    if (_currentUser != null) {
      await _currentUser!.reload();
      _currentUser = firebase_auth.FirebaseAuth.instance.currentUser;
      if (_currentUser?.emailVerified ?? false) {
        _needsEmailConfirmation = false;
        await _checkUserStatus();
        return true;
      }
    }
    return false;
  }

  // ============================================================================
  // GESTION DU PROFIL (SUPABASE)
  // ============================================================================

  Future<void> _checkUserStatus() async {
    if (_currentUser == null) return;
    try {
      final data = await _authService.getUserData(_currentUser!.uid);
      if (data == null) {
        _needsProfileCompletion = true;
        _setState(AppAuthState.needsProfileCompletion);
      } else {
        _userData = data;
        _needsProfileCompletion = !(data['profile_completed'] ?? false);
        if (_needsProfileCompletion) {
          _setState(AppAuthState.needsProfileCompletion);
        } else {
          _setState(AppAuthState.authenticated);
        }
      }
    } catch (e) {
      _errorMessage = e.toString();
      _setState(AppAuthState.error);
    }
  }

  Future<AuthResult> createUserProfile(Map<String, dynamic> profileData) async {
    if (_currentUser == null) return AuthResult.error('Utilisateur non connecté');
    _setState(AppAuthState.loading);
    final result = await _authService.createUserProfile(
      userId: _currentUser!.uid,
      email: _currentUser!.email!,
      role: profileData['role'] ?? 'parent',
      profileData: profileData,
    );
    if (result.success) {
      _needsProfileCompletion = false;
      await _checkUserStatus();
    } else {
      _errorMessage = result.message;
      _setState(AppAuthState.error);
    }
    notifyListeners();
    return result;
  }

  Future<AuthResult> updateUserProfile(Map<String, dynamic> profileData) async {
    return await updateUserProfileSilent(profileData);
  }

  Future<AuthResult> updateUserProfileSilent(Map<String, dynamic> profileData) async {
    if (_currentUser == null) return AuthResult.error('Utilisateur non connecté');
    try {
      final updates = {
        ...profileData,
        'updated_at': DateTime.now().toIso8601String(),
      };
      await supabase.Supabase.instance.client.from('users').update(updates).eq('id', _currentUser!.uid);
      if (_userData == null) _userData = {};
      updates.forEach((key, value) {
        if (value is Map && _userData![key] is Map) {
          _userData![key] = {
            ...(_userData![key] as Map<String, dynamic>),
            ...(value as Map<String, dynamic>),
          };
        } else {
          _userData![key] = value;
        }
      });
      notifyListeners();
      return AuthResult.success(firebaseUser: _currentUser);
    } catch (e) {
      return AuthResult.error(e.toString());
    }
  }

  Future<AuthResult> updateProfileImage(File imageFile) async {
    if (_currentUser == null) return AuthResult.error('Utilisateur non connecté');
    _setState(AppAuthState.loading);
    try {
      final imageUrl = await _imageService.uploadUserProfileImage(
        imageFile: imageFile,
        userId: _currentUser!.uid,
        isProfileImage: true,
      );
      if (imageUrl == null) throw Exception('Upload failed');
      final profileImages = {
        'profileImageSupabase': imageUrl,
        'lastUpdated': DateTime.now().toIso8601String(),
      };
      final result = await updateUserProfileSilent({'profile_images': profileImages});
      _setState(AppAuthState.authenticated);
      return result;
    } catch (e) {
      _errorMessage = e.toString();
      _setState(AppAuthState.error);
      return AuthResult.error(e.toString());
    }
  }

  String? get userRole => _userData?['role'];

  void _setState(AppAuthState newState) {
    _state = newState;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}

enum AppAuthState {
  initial,
  loading,
  authenticated,
  unauthenticated,
  needsEmailConfirmation,
  needsProfileCompletion,
  error,
}
