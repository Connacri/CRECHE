import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

/// 🔐 Service d'authentification utilisant Firebase Auth
class AuthService {
  final firebase_auth.FirebaseAuth _firebaseAuth = firebase_auth.FirebaseAuth.instance;
  final supabase.SupabaseClient _supabase = supabase.Supabase.instance.client;

  // Instance de GoogleSignIn
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  firebase_auth.User? get currentUser => _firebaseAuth.currentUser;

  bool isEmailConfirmed() {
    return _firebaseAuth.currentUser?.emailVerified ?? false;
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

      await credential.user!.sendEmailVerification();
      return AuthResult.success(
        firebaseUser: credential.user,
        needsEmailConfirmation: true,
        message: 'Un email de confirmation a été envoyé à $email',
      );
    } on firebase_auth.FirebaseAuthException catch (e) {
      return AuthResult.error(_parseFirebaseAuthException(e));
    } catch (e) {
      return AuthResult.error('Erreur lors de l\'inscription: $e');
    }
  }

  Future<AuthResult> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return AuthResult.error('Connexion annulée');

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final firebase_auth.AuthCredential credential = firebase_auth.GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await _firebaseAuth.signInWithCredential(credential);
      final user = userCredential.user;

      if (user == null) return AuthResult.error('Échec de la connexion Google');

      final userData = await getUserData(user.uid);

      return AuthResult.success(
        firebaseUser: user,
        needsProfileCompletion: userData == null,
      );
    } catch (e) {
      return AuthResult.error('Erreur Google Sign-In: $e');
    }
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

      if (!user.emailVerified) {
        return AuthResult.success(
          firebaseUser: user,
          needsEmailConfirmation: true,
        );
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
      final payload = {
        'id': userId,
        'email': email,
        'role': role,
        ...profileData,
        'is_active': true,
        'profile_completed': true,
        'updated_at': DateTime.now().toIso8601String(),
        'created_at': DateTime.now().toIso8601String(),
      };

      await _supabase.from('users').upsert(payload);
      return AuthResult.success(message: 'Profil créé avec succès');
    } catch (e) {
      return AuthResult.error('Erreur lors de la sauvegarde du profil: $e');
    }
  }

  Future<Map<String, dynamic>?> getUserData(String userId) async {
    try {
      final response = await _supabase.from('users').select().eq('id', userId).maybeSingle();
      return response;
    } catch (e) {
      return null;
    }
  }

  Future<void> signOut() async {
    await _firebaseAuth.signOut();
    await _googleSignIn.signOut();
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
