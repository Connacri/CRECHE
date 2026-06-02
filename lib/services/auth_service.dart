import 'dart:io' show Platform;
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:flutter/cupertino.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;
import '../core/config/supabase_config.dart';

/// 🔐 Service d'authentification utilisant Firebase Auth
class AuthService {
  final firebase_auth.FirebaseAuth _firebaseAuth = firebase_auth.FirebaseAuth.instance;
  final supabase.SupabaseClient _supabase = supabase.Supabase.instance.client;
  
  /// 🛡️ Client Admin (Service Role) pour contourner le RLS
  late final supabase.SupabaseClient _adminClient;

  bool _initialized = false;
  bool _googleSignInAvailable = true;

  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;

  AuthService() {
    _adminClient = supabase.SupabaseClient(
      SupabaseConfig.url,
      SupabaseConfig.serviceRoleKey,
    );
  }

  firebase_auth.User? get currentUser => _firebaseAuth.currentUser;

  bool isEmailConfirmed() {
    return _firebaseAuth.currentUser?.emailVerified ?? false;
  }

  /// Sets the custom header for Supabase RLS based on Firebase UID
  void _setAuthHeader(String? uid) {
    if (uid != null) {
      debugPrint('[AuthService] Setting x-firebase-id header: $uid');
      _supabase.rest.headers['x-firebase-id'] = uid;
      _supabase.storage.headers['x-firebase-id'] = uid;
    } else {
      debugPrint('[AuthService] Removing x-firebase-id header');
      _supabase.rest.headers.remove('x-firebase-id');
      _supabase.storage.headers.remove('x-firebase-id');
    }
  }

  Future<AuthResult> signup({
    required String email,
    required String password,
    required String role,
  }) async {
    try {
      final credential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (credential.user == null) {
        return AuthResult.error('Échec de création du compte');
      }

      final user = credential.user!;
      await user.sendEmailVerification();
      
      // ✅ Création via ADMIN (RLS Bypass)
      await ensureUserRowAdmin(user.uid, email, role: role);

      // On prépare quand même le header pour les futurs appels standard
      _setAuthHeader(user.uid);

      return AuthResult.success(
        firebaseUser: user,
        needsEmailConfirmation: true,
        message: 'Un email de confirmation a été envoyé à $email',
      );
    } on firebase_auth.FirebaseAuthException catch (e) {
      return AuthResult.error(_parseFirebaseAuthException(e));
    } catch (e) {
      return AuthResult.error('Erreur lors de l\'inscription: $e');
    }
  }

  /// 🛡️ Force la création/vérification de la ligne utilisateur via Service Role
  Future<void> ensureUserRowAdmin(String uid, String email, {String role = 'parent'}) async {
    debugPrint('[AuthService] ensureUserRowAdmin: id=$uid email=$email');
    await _adminClient.from('users').upsert({
      'id': uid,
      'email': email,
      'role': role,
      'is_active': true,
      'profile_completed': false,
      'created_at': DateTime.now().toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
    });
  }

  Future<AuthResult> signInWithGoogle() async {
    if (!_googleSignInAvailable) {
      return AuthResult.error('Google Sign-In n\'est pas disponible sur cette plateforme');
    }
    try {
      debugPrint('[AuthService] Starting Google Sign-In...');
      
      // 1. Déclencher le flux d'authentification
      // Note: authenticate() est utilisé pour la compatibilité desktop dans v7.2.0
      final GoogleSignInAccount googleUser = await _googleSignIn.authenticate();
      
      // 2. Récupérer l'authentification
      final GoogleSignInAuthentication googleAuth = googleUser.authentication;
      final String? idToken = googleAuth.idToken;

      if (idToken == null) {
        debugPrint('[AuthService] Error: Google ID Token is null');
        return AuthResult.error('Échec de récupération de l\'ID Token Google');
      }

      // 3. Se connecter à Firebase
      final firebase_auth.AuthCredential credential = firebase_auth.GoogleAuthProvider.credential(
        idToken: idToken,
      );

      final userCredential = await _firebaseAuth.signInWithCredential(credential);
      final user = userCredential.user;

      if (user == null) {
        debugPrint('[AuthService] Error: Firebase user is null after Google sign-in');
        return AuthResult.error('Échec de la connexion Firebase avec Google');
      }

      debugPrint('[AuthService] Firebase Google login success: ${user.email}');

      // 4. ✅ Synchronisation avec Supabase via ADMIN (Comme le signup)
      final userData = await getUserData(user.uid);
      if (userData == null) {
         debugPrint('[AuthService] Google user not found in Supabase, creating via Admin');
         await ensureUserRowAdmin(user.uid, user.email ?? '', role: 'parent');
      }

      _setAuthHeader(user.uid);

      return AuthResult.success(
        firebaseUser: user,
        needsProfileCompletion: userData == null || !(userData['profile_completed'] ?? false),
      );
    } catch (e) {
      debugPrint('[AuthService] CRITICAL Google Sign-In Error: $e');
      if (e.toString().contains('canceled')) {
        return AuthResult.error('Connexion annulée');
      }
      return AuthResult.error('Erreur Google: $e');
    }
  }

  Future<void> init({
    String? clientId,
    String? serverClientId,
  }) async {
    if (_initialized) return;
    try {
      // ✅ Configuration par défaut pour Windows si non fournie
      final effectiveClientId = clientId ?? (Platform.isWindows 
          ? '1074625929550-c00lqf0h458frddg0b504bqgdhao1j4k.apps.googleusercontent.com' 
          : null);

      await _googleSignIn.initialize(
        clientId: effectiveClientId,
        serverClientId: serverClientId,
      );
      
      debugPrint('[AuthService] Google Sign-In initialized');

      if (_firebaseAuth.currentUser != null) {
        _setAuthHeader(_firebaseAuth.currentUser!.uid);
      }
    } catch (e) {
      debugPrint('[AuthService] Google Sign-In initialization failed: $e');
      _googleSignInAvailable = false;
    }
    _initialized = true;
  }

  Future<AuthResult> login({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = credential.user;
      if (user == null) return AuthResult.error('Email ou mot de passe incorrect');

      _setAuthHeader(user.uid);

      if (!user.emailVerified) {
        return AuthResult.success(firebaseUser: user, needsEmailConfirmation: true);
      }

      final userData = await getUserData(user.uid);

      return AuthResult.success(
        firebaseUser: user,
        needsProfileCompletion: userData == null || !(userData['profile_completed'] ?? false),
      );
    } on firebase_auth.FirebaseAuthException catch (e) {
      return AuthResult.error(_parseFirebaseAuthException(e));
    } catch (e) {
      return AuthResult.error('Erreur de connexion: $e');
    }
  }

  Future<AuthResult> createUserProfile({
    required String userId,
    required String email,
    required String role,
    required Map<String, dynamic> profileData,
  }) async {
    try {
      // ✅ Mise à jour via ADMIN
      await _adminClient.from('users').upsert({
        'id': userId,
        'email': email,
        'role': role,
        ...profileData,
        'is_active': true,
        'profile_completed': true,
        'updated_at': DateTime.now().toIso8601String(),
      });
      return AuthResult.success(message: 'Profil créé avec succès');
    } catch (e) {
      return AuthResult.error('Erreur profil: $e');
    }
  }

  /// 🛡️ Met à jour le profil silencieusement via Admin
  Future<void> updateUserProfileAdmin(String userId, Map<String, dynamic> data) async {
    await _adminClient.from('users').update({
      ...data,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', userId);
  }

  Future<Map<String, dynamic>?> getUserData(String userId) async {
    try {
      final response = await _adminClient
          .from('users')
          .select()
          .eq('id', userId)
          .maybeSingle();
      return response;
    } catch (e) {
      debugPrint('[AuthService] getUserData CRITICAL error: $e');
      return null;
    }
  }

  Future<void> signOut() async {
    await _firebaseAuth.signOut();
    if (_googleSignInAvailable) await _googleSignIn.signOut();
  }

  Future<AuthResult> sendPasswordResetEmail(String email) async {
    try {
      await _firebaseAuth.sendPasswordResetEmail(email: email);
      return AuthResult.success(message: 'Email de réinitialisation envoyé');
    } catch (e) {
      return AuthResult.error('Erreur: $e');
    }
  }

  String _parseFirebaseAuthException(firebase_auth.FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return 'Email ou mot de passe incorrect';
      case 'email-already-in-use':
        return 'Cet email est déjà utilisé';
      case 'weak-password':
        return 'Le mot de passe est trop faible';
      default:
        return e.message ?? 'Une erreur est survenue';
    }
  }
}

class AuthResult {
  final bool success;
  final String? message;
  final firebase_auth.User? firebaseUser;
  final bool needsEmailConfirmation;
  final bool needsProfileCompletion;

  AuthResult._({
    required this.success,
    this.message,
    this.firebaseUser,
    this.needsEmailConfirmation = false,
    this.needsProfileCompletion = false,
  });

  factory AuthResult.success({
    String? message,
    firebase_auth.User? firebaseUser,
    bool needsEmailConfirmation = false,
    bool needsProfileCompletion = false,
  }) {
    return AuthResult._(
      success: true,
      message: message,
      firebaseUser: firebaseUser,
      needsEmailConfirmation: needsEmailConfirmation,
      needsProfileCompletion: needsProfileCompletion,
    );
  }

  factory AuthResult.error(String message) {
    return AuthResult._(success: false, message: message);
  }
}
