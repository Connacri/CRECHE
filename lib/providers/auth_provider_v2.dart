import 'dart:io';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../services/auth_service.dart';
import '../services/image_storage_service.dart';

/// 🎯 Provider d'authentification avec gestion cas edge
class AuthProviderV2 extends ChangeNotifier {
  final AuthService _authService = AuthService();
  final ImageStorageService _imageService = ImageStorageService();

  // ============================================================================
  // ÉTAT
  // ============================================================================

  AppAuthState _state = AppAuthState.initial;
  User? _currentUser;
  Map<String, dynamic>? _userData;
  String? _errorMessage;
  bool _needsEmailConfirmation = false;
  bool _needsProfileCompletion = false;

  // Getters
  AppAuthState get state => _state;

  User? get currentUser => _currentUser;

  Map<String, dynamic>? get userData => _userData;

  String? get errorMessage => _errorMessage;

  bool get needsEmailConfirmation => _needsEmailConfirmation;

  bool get needsProfileCompletion => _needsProfileCompletion;

  bool get isAuthenticated => _currentUser != null;

  bool get isLoading => _state == AppAuthState.loading;

  // ============================================================================
  // INITIALISATION
  // ============================================================================

  AuthProviderV2() {
    _initialize();
  }

  Future<void> _initialize() async {
    _setState(AppAuthState.loading);

    try {
      Supabase.instance.client.auth.onAuthStateChange.listen((data) {
        _handleAuthStateChange(data);
      });

      final session = Supabase.instance.client.auth.currentSession;
      if (session != null) {
        _currentUser = session.user;
        await _checkUserStatus();
      } else {
        _setState(AppAuthState.unauthenticated);
      }
    } catch (e) {
      print('[AuthProviderV2] Erreur initialisation: $e');
      _setState(AppAuthState.error);
      _errorMessage = 'Erreur d\'initialisation';
    }
  }

  void _handleAuthStateChange(AuthState authState) async {
    print('[AuthProviderV2] Auth event: ${authState.event}');

    switch (authState.event) {
      case AuthChangeEvent.signedIn:
        _currentUser = authState.session?.user;
        await _checkUserStatus();
        break;

      case AuthChangeEvent.signedOut:
        _currentUser = null;
        _userData = null;
        _needsEmailConfirmation = false;
        _needsProfileCompletion = false;
        _setState(AppAuthState.unauthenticated);
        break;

      case AuthChangeEvent.userUpdated:
        _currentUser = authState.session?.user;
        if (_currentUser != null && _needsEmailConfirmation) {
          final isNowConfirmed = _currentUser!.emailConfirmedAt != null;
          if (isNowConfirmed) {
            print(
                '[AuthProviderV2] 🎉 Email confirmé détecté via userUpdated!');
            _needsEmailConfirmation = false;
          }
        }
        await _checkUserStatus();
        break;

      case AuthChangeEvent.tokenRefreshed:
        print('[AuthProviderV2] 🔄 Token rafraîchi, vérification statut...');
        _currentUser = authState.session?.user;
        await _checkUserStatus();
        break;

      default:
        break;
    }
  }

  Future<void> _checkUserStatus() async {
    if (_currentUser == null) return;

    try {
      final emailConfirmed = _authService.isEmailConfirmed();
      print('[AuthProviderV2] Email confirmé: $emailConfirmed');

      if (!emailConfirmed) {
        _needsEmailConfirmation = true;
        _needsProfileCompletion = false;
        _setState(AppAuthState.needsEmailConfirmation);
        return;
      }

      _userData = await _authService.getUserData(_currentUser!.id);

      if (_userData == null) {
        print(
            '[AuthProviderV2] ⚠️ Email confirmé mais profil manquant → Création auto');
        await _createMinimalProfile();
        _userData = await _authService.getUserData(_currentUser!.id);

        if (_userData == null) {
          print(
              '[AuthProviderV2] ❌ Échec création auto → Forcer ProfileCompletion');
          _needsEmailConfirmation = false;
          _needsProfileCompletion = true;
          _setState(AppAuthState.needsProfileCompletion);
          return;
        }
      }

      final profileCompleted = _userData!['profile_completed'] ?? false;

      if (!profileCompleted) {
        _needsEmailConfirmation = false;
        _needsProfileCompletion = true;
        _setState(AppAuthState.needsProfileCompletion);
      } else {
        _needsEmailConfirmation = false;
        _needsProfileCompletion = false;
        _setState(AppAuthState.authenticated);
      }
    } catch (e) {
      print('[AuthProviderV2] Erreur _checkUserStatus: $e');
      _setState(AppAuthState.error);
      _errorMessage = 'Erreur de vérification du statut';
    }
  }

  Future<void> _createMinimalProfile() async {
    if (_currentUser == null) return;

    try {
      final role = _authService.getUserRole() ?? 'parent';

      final minimalData = {
        'id': _currentUser!.id,
        'email': _currentUser!.email!,
        'role': role,
        'name': 'À compléter',
        'is_active': true,
        'profile_completed': false,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      };

      await Supabase.instance.client.from('users').insert(minimalData);
      print('[AuthProviderV2] ✅ Profil minimal créé pour ${_currentUser!.id}');
    } catch (e) {
      print('[AuthProviderV2] ❌ Erreur _createMinimalProfile: $e');
    }
  }

  // ============================================================================
  // ACTIONS D'AUTHENTIFICATION
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
      _currentUser = result.user;
      _needsEmailConfirmation = result.needsEmailConfirmation;
      _needsProfileCompletion = false;

      if (_needsEmailConfirmation) {
        _setState(AppAuthState.needsEmailConfirmation);
      } else {
        // Si pas de confirmation requise, on vérifie le statut (profil etc.)
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
      _currentUser = result.user;
      _needsEmailConfirmation = result.needsEmailConfirmation;
      _needsProfileCompletion = result.needsProfileCompletion;

      if (_needsEmailConfirmation) {
        _setState(AppAuthState.needsEmailConfirmation);
      } else if (_needsProfileCompletion) {
        _setState(AppAuthState.needsProfileCompletion);
      } else {
        await _checkUserStatus();
      }
    } else {
      _errorMessage = result.message;
      _setState(AppAuthState.error);
    }

    return result;
  }

  Future<AuthResult> resendConfirmationEmail(String email) async {
    return await _authService.resendConfirmationEmail(email);
  }

  Future<AuthResult> deleteUnconfirmedAccount() async {
    _setState(AppAuthState.loading);

    final result = await _authService.deleteUnconfirmedAccount();

    if (result.success) {
      _currentUser = null;
      _userData = null;
      _needsEmailConfirmation = false;
      _needsProfileCompletion = false;
      _setState(AppAuthState.unauthenticated);
    } else {
      _setState(AppAuthState.error);
      _errorMessage = result.message;
    }

    notifyListeners();
    return result;
  }

  Future<AuthResult> createUserProfile(Map<String, dynamic> profileData) async {
    if (_currentUser == null) {
      return AuthResult.error('Utilisateur non connecté');
    }

    _setState(AppAuthState.loading);
    _errorMessage = null;

    final role = _authService.getUserRole() ?? 'parent';

    final result = await _authService.createUserProfile(
      userId: _currentUser!.id,
      email: _currentUser!.email!,
      role: role,
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

  /// ✅ OPTIMISÉ: Deep merge des données pour refresh instantané
  Future<AuthResult> updateUserProfileSilent(
      Map<String, dynamic> profileData) async {
    if (_currentUser == null) {
      return AuthResult.error('Utilisateur non connecté');
    }

    _errorMessage = null;

    try {
      print('[AuthProviderV2] 🔄 Début updateUserProfileSilent');
      print('[AuthProviderV2] Données à mettre à jour: $profileData');

      final now = DateTime.now().toIso8601String();
      final updates = {
        ...profileData,
        'updated_at': now,
      };

      // 1. Mettre à jour Supabase
      await Supabase.instance.client.from('users').update(updates).eq('id', _currentUser!.id);

      print('[AuthProviderV2] ✅ Supabase mis à jour');

      // 2. ✅ Deep merge des données dans le cache local
      if (_userData == null) {
        _userData = {};
      }

      // Merger chaque clé de updates (qui contient déjà profileData + updated_at)
      updates.forEach((key, value) {
        if (value is Map && _userData![key] is Map) {
          // Pour les maps imbriquées comme profile_images, faire un deep merge
          _userData![key] = {
            ...(_userData![key] as Map<String, dynamic>),
            ...(value as Map<String, dynamic>),
          };
        } else {
          // Pour les valeurs simples, remplacer directement
          _userData![key] = value;
        }
      });

      print('[AuthProviderV2] ✅ Cache local mis à jour: $_userData');

      // 3. ✅ CRUCIAL: Notifier les listeners pour rebuild instantané
      notifyListeners();

      print(
          '[AuthProviderV2] ✅ notifyListeners() appelé - UI devrait se rafraîchir');

      return AuthResult.success(
        message: 'Profil mis à jour',
        user: _currentUser,
        needsProfileCompletion: false,
      );
    } catch (e) {
      final msg = e.toString();
      print('[AuthProviderV2] ❌ updateUserProfileSilent ERROR: $msg');
      _errorMessage = msg;
      return AuthResult.error(msg);
    }
  }

  Future<AuthResult> updateUserProfile(Map<String, dynamic> profileData) async {
    if (_currentUser == null) {
      return AuthResult.error('Utilisateur non connecté');
    }

    _setState(AppAuthState.loading);
    _errorMessage = null;

    try {
      await Supabase.instance.client.from('users').update({
        ...profileData,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', _currentUser!.id);

      _userData = {
        ...(_userData ?? {}),
        ...profileData,
      };

      _needsProfileCompletion = false;
      await _checkUserStatus();

      return AuthResult.success(
        message: 'Profil mis à jour',
        user: _currentUser,
        needsProfileCompletion: false,
      );
    } catch (e) {
      final msg = e.toString();
      print('[AuthProviderV2] updateUserProfile ERROR: $msg');
      _errorMessage = msg;
      _setState(AppAuthState.error);
      return AuthResult.error(msg);
    }
  }

  /// 📸 Met à jour la photo de profil avec upload vers Supabase Storage
  Future<AuthResult> updateProfileImage(File imageFile) async {
    if (_currentUser == null) {
      return AuthResult.error('Utilisateur non connecté');
    }

    _setState(AppAuthState.loading);
    _errorMessage = null;

    try {
      print('[AuthProviderV2] 📤 Début updateProfileImage');

      // 1. Upload de l'image
      final imageUrl = await _imageService.uploadUserProfileImage(
        imageFile: imageFile,
        userId: _currentUser!.id,
        isProfileImage: true,
      );

      if (imageUrl == null) {
        throw Exception('Échec de l\'upload de l\'image');
      }

      print('[AuthProviderV2] ✅ Image uploadée: $imageUrl');

      // 2. Mettre à jour le profil dans la base de données
      // On prépare l'objet profile_images tel qu'attendu par le modèle
      final profileImages = {
        'profileImageSupabase': imageUrl,
        'lastUpdated': DateTime.now().toIso8601String(),
      };

      final result = await updateUserProfileSilent({
        'profile_images': profileImages,
      });

      print('[AuthProviderV2] ✅ Profil mis à jour avec la nouvelle image');
      _setState(AppAuthState.authenticated); // Sortir du mode loading
      return result;
    } catch (e) {
      final msg = e.toString();
      print('[AuthProviderV2] ❌ updateProfileImage ERROR: $msg');
      _errorMessage = msg;
      _setState(AppAuthState.error);
      return AuthResult.error(msg);
    }
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

  Future<void> logout() async {
    print('[AuthProviderV2] 🔄 Début de la déconnexion optimiste...');

    // 1. Mise à jour IMMÉDIATE de l'état local pour débloquer l'UI
    _currentUser = null;
    _userData = null;
    _needsEmailConfirmation = false;
    _needsProfileCompletion = false;
    _errorMessage = null;
    
    // On passe directement à unauthenticated au lieu de loading
    _setState(AppAuthState.unauthenticated);
    
    print('[AuthProviderV2] 🏠 État local réinitialisé, UI devrait basculer');

    // 2. Déconnexion serveur en arrière-plan
    try {
      // On ne 'await' pas obligatoirement ici pour ne pas bloquer l'UI
      // mais on le fait pour s'assurer que la session est bien fermée côté Supabase
      await _authService.signOut().timeout(
        const Duration(seconds: 2),
        onTimeout: () => print('[AuthProviderV2] ⚠️ Timeout signOut serveur (2s)'),
      );
      print('[AuthProviderV2] ✅ Déconnexion serveur réussie');
    } catch (e) {
      print('[AuthProviderV2] ❌ Erreur déconnexion serveur (non bloquant): $e');
    }
  }

  // ============================================================================
  // VÉRIFICATION MANUELLE DE LA CONFIRMATION EMAIL
  // ============================================================================

  Future<bool> checkEmailConfirmationStatus() async {
    try {
      print('[AuthProviderV2] 🔄 Vérification manuelle confirmation email...');

      final refreshResponse =
          await Supabase.instance.client.auth.refreshSession();

      if (refreshResponse.session == null) {
        print('[AuthProviderV2] ❌ Pas de session après refresh');
        return false;
      }

      _currentUser = refreshResponse.session!.user;

      final isConfirmed = _currentUser!.emailConfirmedAt != null;
      print('[AuthProviderV2] Email confirmé: $isConfirmed');

      if (isConfirmed) {
        _needsEmailConfirmation = false;
        await _checkUserStatus();
        return true;
      }

      return false;
    } catch (e, stackTrace) {
      print('[AuthProviderV2] ❌ Erreur checkEmailConfirmationStatus: $e');
      print(stackTrace);
      return false;
    }
  }

  // ============================================================================
  // GESTION D'ÉTAT
  // ============================================================================

  void _setState(AppAuthState newState) {
    _state = newState;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}

// ============================================================================
// ÉNUMÉRATIONS
// ============================================================================

enum AppAuthState {
  initial,
  loading,
  authenticated,
  unauthenticated,
  needsEmailConfirmation,
  needsProfileCompletion,
  error,
}
