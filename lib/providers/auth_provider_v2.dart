import 'dart:async';
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

import '../services/auth_service.dart';
import '../services/image_storage_service.dart';
import '../services/fcm_service.dart';
import '../models/user_model.dart';

class AuthProviderV2 with ChangeNotifier {
  UserModel? get user => _userData != null ? UserModel.fromSupabase(_userData!) : null;
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

  Future<void> _init() async {
    await _authService.init();

    _authSubscription =
        firebase_auth.FirebaseAuth.instance.authStateChanges().listen(
      (user) {
        // ─────────────────────────────────────────────────────────────────
        // 🛡️ Windows Threading Fix: Use microtask to ensure we're not 
        // blocking or being called from a sensitive native context.
        // ─────────────────────────────────────────────────────────────────
        Future.microtask(() async {
          _currentUser = user;

          if (user != null) {
            _setAuthHeader(user.uid);

            if (user.emailVerified) {
              _needsEmailConfirmation = false;
              await _checkUserStatus();
              _updateFCMToken();
            } else {
              _needsEmailConfirmation = true;
              _setState(AppAuthState.needsEmailConfirmation);
            }
          } else {
            _setAuthHeader(null);
            _userData = null;
            _setState(AppAuthState.unauthenticated);
          }

          notifyListeners();
        });
      },
      onError: (e) => debugPrint('❌ [AuthProviderV2] authStateChanges Error: $e'),
    );
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
      } else {
        await _checkUserStatus();
      }
    } else {
      _errorMessage = result.message;
      _setState(AppAuthState.error);
    }

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
    try {
      await _authService.signOut();
    } catch (e) {
      debugPrint('Error during logout: $e');
    } finally {
      _currentUser = null;
      _userData = null;
      _needsEmailConfirmation = false;
      _needsProfileCompletion = false;
      _setState(AppAuthState.unauthenticated);
    }
  }

  Future<AuthResult> resendConfirmationEmail(String email) async {
    if (_currentUser != null) {
      try {
        await _currentUser!.sendEmailVerification();
        return AuthResult.success(
            firebaseUser: _currentUser, message: 'Email envoyé');
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
    _setState(AppAuthState.loading);
    _errorMessage = null;
    final result = await _authService.sendPasswordResetEmail(email);
    if (!result.success) {
      _errorMessage = result.message;
      _setState(AppAuthState.error);
    } else {
      _setState(AppAuthState.unauthenticated);
    }
    notifyListeners();
    return result;
  }

  Future<bool> checkEmailConfirmationStatus(
      {bool forceBypass = false}) async {
    if (_currentUser != null) {
      debugPrint(
          '[AuthProviderV2] checkEmailConfirmationStatus: reloading user ${_currentUser!.email}');

      try {
        await _currentUser!.reload();
        await _currentUser!.getIdToken(true);
        _currentUser = firebase_auth.FirebaseAuth.instance.currentUser;

        final isVerified = _currentUser?.emailVerified ?? false;
        debugPrint(
            '[AuthProviderV2] emailVerified (Firebase): $isVerified');

        if (isVerified || forceBypass) {
          if (forceBypass) {
            debugPrint('[AuthProviderV2] Bypassing Firebase verification...');
          }
          _needsEmailConfirmation = false;
          await _checkUserStatus();
          notifyListeners();
          return true;
        }
      } catch (e) {
        debugPrint(
            '[AuthProviderV2] Error during confirmation check: $e');
      }
    }
    return false;
  }

  bool _checkingUserStatus = false;

  Future<void> _checkUserStatus() async {
    if (_currentUser == null || _checkingUserStatus) return;
    _checkingUserStatus = true;

    debugPrint(
        '[AuthProviderV2] _checkUserStatus for uid=${_currentUser!.uid}');
    try {
      final data = await _authService.getUserData(_currentUser!.uid);
      debugPrint(
          '[AuthProviderV2] getUserData returned: ${data != null ? "OK" : "null"}');

      if (data == null) {
        debugPrint(
            '[AuthProviderV2] User data null → checking for existing data by email...');
        
        // Tentative de récupération par email pour préserver le rôle avant migration
        final existingByEmail = await _authService.adminClient
            .from('users')
            .select('role')
            .eq('email', _currentUser!.email!)
            .maybeSingle();
        
        String? roleToPreserve;
        if (existingByEmail != null) {
          roleToPreserve = existingByEmail['role'];
          debugPrint('[AuthProviderV2] Role found for preservation: $roleToPreserve');
        }

        await _ensureUserRow(role: roleToPreserve);
        
        final retryData =
            await _authService.getUserData(_currentUser!.uid);
        if (retryData != null) {
          _userData = retryData;
          _needsProfileCompletion =
              !(retryData['profile_completed'] ?? false);
          _setState(_needsProfileCompletion
              ? AppAuthState.needsProfileCompletion
              : AppAuthState.authenticated);
        } else {
          debugPrint(
              '[AuthProviderV2] Toujours null après ensureUserRow. Vérifier RLS admin.');
          _needsProfileCompletion = true;
          _setState(AppAuthState.needsProfileCompletion);
        }
      } else {
        _userData = data;
        _needsProfileCompletion = !(data['profile_completed'] ?? false);
        _setState(_needsProfileCompletion
            ? AppAuthState.needsProfileCompletion
            : AppAuthState.authenticated);
      }
    } catch (e) {
      debugPrint('[AuthProviderV2] _checkUserStatus CRITICAL ERROR: $e');
      _errorMessage = e.toString();
      _setState(AppAuthState.error);
    } finally {
      _checkingUserStatus = false;
    }
  }

  /// Positionne les headers Supabase pour le RLS
  void _setAuthHeader(String? uid) {
    final client = supabase.Supabase.instance.client;
    if (uid != null) {
      client.rest.headers['x-firebase-id'] = uid;
      client.storage.headers['x-firebase-id'] = uid;
    } else {
      client.rest.headers.remove('x-firebase-id');
      client.storage.headers.remove('x-firebase-id');
    }
  }

  Future<void> _ensureUserRow({String? role}) async {
    if (_currentUser == null) return;
    debugPrint(
        '[AuthProviderV2] _ensureUserRow: id=${_currentUser!.uid} (preferred role: $role)');
    try {
      await _authService.ensureUserRowAdmin(
          _currentUser!.uid, _currentUser!.email!, role: role ?? 'parent');
      debugPrint('[AuthProviderV2] _ensureUserRow: Réussi via Admin');
    } catch (e) {
      debugPrint('[AuthProviderV2] _ensureUserRow: Échec: $e');
    }
  }

  Future<AuthResult> createUserProfile(
      Map<String, dynamic> profileData) async {
    if (_currentUser == null) {
      return AuthResult.error('Utilisateur non connecté');
    }
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

  Future<AuthResult> updateUserProfile(
      Map<String, dynamic> profileData) async {
    debugPrint('[AuthProviderV2] updateUserProfile: $profileData');
    final result = await updateUserProfileSilent(profileData);
    if (result.success && profileData['profile_completed'] == true) {
      await _checkUserStatus();
    }
    return result;
  }

  Future<AuthResult> updateUserProfileSilent(
      Map<String, dynamic> profileData) async {
    if (_currentUser == null) {
      return AuthResult.error('Utilisateur non connecté');
    }
    try {
      await _authService.updateUserProfileAdmin(
          _currentUser!.uid, profileData);

      _userData ??= {};
      profileData.forEach((key, value) {
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
      debugPrint('[AuthProviderV2] updateUserProfileSilent failed: $e');
      return AuthResult.error(e.toString());
    }
  }

  Future<AuthResult> updateProfileImage(File imageFile) async {
    if (_currentUser == null) {
      return AuthResult.error('Utilisateur non connecté');
    }
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
      final result =
          await updateUserProfileSilent({'profile_images': profileImages});
      _setState(AppAuthState.authenticated);
      return result;
    } catch (e) {
      _errorMessage = e.toString();
      _setState(AppAuthState.error);
      return AuthResult.error(e.toString());
    }
  }

  String? get userRole => _userData?['role'];

  Future<Map<String, dynamic>?> getUserData(String userId) => _authService.getUserData(userId);

  void _setState(AppAuthState newState) {
    _state = newState;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  Future<AuthResult> deleteAccount() async {
    if (_currentUser == null) {
      return AuthResult.error('Utilisateur non connecté');
    }

    _setState(AppAuthState.loading);
    try {
      final userId = _currentUser!.uid;
      final result = await _authService.deleteUserAccount(userId);

      if (result.success) {
        _currentUser = null;
        _userData = null;
        _needsEmailConfirmation = false;
        _needsProfileCompletion = false;
        _setState(AppAuthState.unauthenticated);
      } else {
        _errorMessage = result.message;
        _setState(AppAuthState.authenticated); // Back to authenticated if failed
      }
      return result;
    } catch (e) {
      _errorMessage = e.toString();
      _setState(AppAuthState.authenticated);
      return AuthResult.error(e.toString());
    }
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