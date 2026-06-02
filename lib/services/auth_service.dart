import 'dart:io' show Platform;
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;
import '../core/config/supabase_config.dart';

/// 🔐 Service d'authentification utilisant Firebase Auth et Supabase
class AuthService {
  final firebase_auth.FirebaseAuth _firebaseAuth = firebase_auth.FirebaseAuth.instance;
  final supabase.SupabaseClient _supabase = supabase.Supabase.instance.client;
  
  /// 🛡️ Client Admin (Service Role) pour contourner le RLS
  late final supabase.SupabaseClient _adminClient;

  bool _initialized = false;
  bool _googleSignInAvailable = true;

  // ✅ ID Client Web (IMPÉRATIF pour Windows/Desktop)
  static const String _webClientId = '1074625929550-e7d40mt384j3cduc6202hujmbn22b7t6.apps.googleusercontent.com';

  /// ✅ Instance de GoogleSignIn (Singleton v7.x)
  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;

  AuthService() {
    _adminClient = supabase.SupabaseClient(
      SupabaseConfig.url,
      SupabaseConfig.serviceRoleKey,
    );
  }

  /// ✅ Initialisation obligatoire pour google_sign_in v7.x
  Future<void> init({
    String? clientId,
    String? serverClientId,
  }) async {
    if (_initialized) return;
    
    // Le package officiel ne supporte pas Windows. 
    // On garde la logique de config au cas où une implémentation custom desktop est présente,
    // mais on prévient les crashs potentiels.
    if (!kIsWeb && (Platform.isWindows || Platform.isLinux)) {
      debugPrint('[AuthService] Google Sign-In non supporté nativement sur cette plateforme.');
      _googleSignInAvailable = false;
      _initialized = true;
      return;
    }

    try {
      debugPrint('[AuthService] Initialisation Google Sign-In...');

      // Dans v7.2.0, initialize ne prend plus de paramètre 'scopes' direct
      await _googleSignIn.initialize(
        clientId: (clientId ?? (Platform.isWindows ? _webClientId : null)),
        serverClientId: (serverClientId ?? (Platform.isWindows ? _webClientId : null)),
      );
      _initialized = true;
      debugPrint('[AuthService] Google Sign-In initialisé.');
    } catch (e) {
      debugPrint('[AuthService] Error initializing GoogleSignIn: $e');
      _googleSignInAvailable = false;
    }
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
      
      // ✅ Création via ADMIN
      await ensureUserRowAdmin(user.uid, email, role: role);

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
    try {
      await _adminClient.from('users').upsert({
        'id': uid,
        'email': email,
        'role': role,
        'is_active': true,
        'profile_completed': false,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      debugPrint('[AuthService] ensureUserRowAdmin error: $e');
    }
  }

  Future<AuthResult> signInWithGoogle() async {
    if (!_googleSignInAvailable) {
      return AuthResult.error('Google Sign-In indisponible sur cette plateforme');
    }
    
    if (!_initialized) {
      await init();
    }

    try {
      debugPrint('[AuthService] Début Google Sign-In (authenticate)...');
      
      // Dans v7.2.0, on utilise authenticate() à la place de signIn()
      final GoogleSignInAccount? googleUser = await _googleSignIn.authenticate();
      
      if (googleUser == null) {
        return AuthResult.error('Connexion annulée par l\'utilisateur');
      }

      debugPrint('[AuthService] Récupération tokens...');
      // googleUser.authentication est un Future dans v7.x
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      
      final String? idToken = googleAuth.idToken;
      
      // L'accessToken est désormais récupéré via authorizationClient dans v7.x
      String? accessToken;
      try {
        final tokenData = await googleUser.authorizationClient.authorizeScopes(['email', 'openid', 'profile']);
        accessToken = tokenData.accessToken;
      } catch (e) {
        debugPrint('[AuthService] Note: Erreur lors de la récupération de l\'accessToken: $e');
      }

      if (idToken == null) {
        debugPrint('[AuthService] Erreur: idToken est null');
        return AuthResult.error('Échec de récupération du jeton d\'identité Google');
      }

      debugPrint('[AuthService] Connexion Firebase avec ID Token...');
      final firebase_auth.AuthCredential credential = firebase_auth.GoogleAuthProvider.credential(
        idToken: idToken,
        accessToken: accessToken,
      );

      final userCredential = await _firebaseAuth.signInWithCredential(credential);
      final user = userCredential.user;

      if (user == null) return AuthResult.error('Échec de l\'authentification Firebase');

      debugPrint('[AuthService] Utilisateur connecté: ${user.uid}');

      // Synchronisation avec Supabase
      final userData = await getUserData(user.uid);
      if (userData == null) {
         debugPrint('[AuthService] Création du profil utilisateur dans Supabase...');
         await ensureUserRowAdmin(user.uid, user.email ?? '', role: 'parent');
      }

      // Configuration du header RLS
      _setAuthHeader(user.uid);

      return AuthResult.success(
        firebaseUser: user,
        needsProfileCompletion: userData == null || !(userData['profile_completed'] ?? false),
      );
    } catch (e) {
      debugPrint('[AuthService] Google Error: $e');
      return AuthResult.error('Erreur lors de la connexion Google: $e');
    }
  }

  /// 🔄 Tente une connexion silencieuse (au démarrage de l'app)
  Future<firebase_auth.User?> signInSilently() async {
    if (!_googleSignInAvailable) return _firebaseAuth.currentUser;
    
    if (!_initialized) {
      await init();
    }

    try {
      debugPrint('[AuthService] Tentative de connexion silencieuse...');
      // Dans v7.2.0, on utilise attemptLightweightAuthentication()
      final GoogleSignInAccount? googleUser = await _googleSignIn.attemptLightweightAuthentication();
      
      if (googleUser != null) {
        final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
        
        String? accessToken;
        try {
          final tokenData = await googleUser.authorizationClient.authorizeScopes(['email', 'openid', 'profile']);
          accessToken = tokenData.accessToken;
        } catch (_) {}

        final firebase_auth.AuthCredential credential = firebase_auth.GoogleAuthProvider.credential(
          idToken: googleAuth.idToken,
          accessToken: accessToken,
        );
        final userCredential = await _firebaseAuth.signInWithCredential(credential);
        final user = userCredential.user;
        
        if (user != null) {
          debugPrint('[AuthService] Connexion silencieuse réussie.');
          _setAuthHeader(user.uid);
          return user;
        }
      }
    } catch (e) {
      debugPrint('[AuthService] Silent Sign-In Error: $e');
    }
    
    final user = _firebaseAuth.currentUser;
    if (user != null) _setAuthHeader(user.uid);
    return user;
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

  Future<void> updateUserProfileAdmin(String userId, Map<String, dynamic> data) async {
    try {
      await _adminClient.from('users').update({
        ...data,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', userId);
    } catch (e) {
      debugPrint('[AuthService] updateUserProfileAdmin error: $e');
    }
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
      debugPrint('[AuthService] getUserData error: $e');
      return null;
    }
  }

  Future<void> signOut() async {
    await _firebaseAuth.signOut();
    try {
      await _googleSignIn.signOut();
    } catch (_) {}
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
