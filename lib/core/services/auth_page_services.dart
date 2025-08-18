import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthResult {
  final bool success;
  final User? user;
  final String? error;
  final bool isNewUser;

  AuthResult({
    required this.success,
    this.user,
    this.error,
    this.isNewUser = false,
  });

  factory AuthResult.success(User user, {bool isNewUser = false}) =>
      AuthResult(success: true, user: user, isNewUser: isNewUser);

  factory AuthResult.failure(String error) =>
      AuthResult(success: false, error: error);
}

class AuthPageServices {
  static final AuthPageServices _instance = AuthPageServices._internal();
  factory AuthPageServices() => _instance;
  AuthPageServices._internal();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  User? get currentUser => _auth.currentUser;
  Stream<User?> get authStateChanges => _auth.authStateChanges();
  bool get isSignedIn => currentUser != null;

  // ==================== GOOGLE SIGN IN ====================
  Future<AuthResult> signInWithGoogle() async {
    try {
      if (!kIsWeb) {
        return AuthResult.failure(
          'Google Sign-In currently implemented only for Web.',
        );
      }

      final provider = GoogleAuthProvider();
      provider.setCustomParameters({'prompt': 'select_account'});

      final userCredential = await _auth.signInWithPopup(provider);

      final user = userCredential.user;
      if (user == null) return AuthResult.failure('Google sign in failed');

      final bool isNewUser =
          userCredential.additionalUserInfo?.isNewUser ?? false;
      await _createOrUpdateUserDocument(user, isNewUser);

      return AuthResult.success(user, isNewUser: isNewUser);
    } on FirebaseAuthException catch (e) {
      debugPrint('FirebaseAuthException: ${e.code} - ${e.message}');
      return AuthResult.failure(_firebaseErrorMessage(e.code));
    } catch (e, st) {
      debugPrint('Google SignIn error: $e\n$st');
      return AuthResult.failure('Google sign in failed. Please try again.');
    }
  }

  // ==================== EMAIL/PASSWORD ====================
  Future<AuthResult> registerWithEmailAndPassword({
    required String email,
    required String password,
    required String displayName,
  }) async {
    try {
      final result = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      final user = result.user;
      if (user == null) return AuthResult.failure('Registration failed');

      await user.updateDisplayName(displayName.trim());
      await user.reload();
      await _createOrUpdateUserDocument(
        user,
        true,
        displayName: displayName.trim(),
      );
      await user.sendEmailVerification();

      return AuthResult.success(user, isNewUser: true);
    } on FirebaseAuthException catch (e) {
      return AuthResult.failure(_firebaseErrorMessage(e.code));
    }
  }

  Future<AuthResult> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      final result = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      final user = result.user;
      if (user == null) return AuthResult.failure('Login failed');
      await _updateLastLogin(user.uid);
      return AuthResult.success(user);
    } on FirebaseAuthException catch (e) {
      return AuthResult.failure(_firebaseErrorMessage(e.code));
    }
  }

  // ==================== FIRESTORE ====================
  Future<void> _createOrUpdateUserDocument(
    User user,
    bool isNewUser, {
    String? displayName,
  }) async {
    final doc = _firestore.collection('users').doc(user.uid);
    final now = FieldValue.serverTimestamp();

    if (isNewUser) {
      await doc.set({
        'uid': user.uid,
        'email': user.email,
        'displayName': displayName ?? user.displayName ?? '',
        'photoURL': user.photoURL,
        'role': 'user',
        'emailVerified': user.emailVerified,
        'createdAt': now,
        'lastLoginAt': now,
      }, SetOptions(merge: false));
    } else {
      await doc.update({
        'lastLoginAt': now,
        'emailVerified': user.emailVerified,
      });
    }
  }

  Future<void> _updateLastLogin(String uid) async {
    try {
      await _firestore.collection('users').doc(uid).update({
        'lastLoginAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Failed to update last login: $e');
    }
  }

  // ==================== ERROR MESSAGES ====================
  String _firebaseErrorMessage(String code) {
    switch (code) {
      case 'user-not-found':
        return 'No account found with this email';
      case 'wrong-password':
        return 'Incorrect password';
      case 'email-already-in-use':
        return 'Email already registered';
      case 'invalid-email':
        return 'Enter a valid email';
      case 'weak-password':
        return 'Weak password, minimum 8 characters';
      default:
        return 'An error occurred. Please try again.';
    }
  }
}
