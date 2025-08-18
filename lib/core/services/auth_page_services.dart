import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthResult {
  final bool success;
  final String? error;
  final User? user;
  final String? message;

  AuthResult({
    required this.success,
    this.error,
    this.user,
    this.message,
  });

  factory AuthResult.success({User? user, String? message}) {
    return AuthResult(success: true, user: user, message: message);
  }

  factory AuthResult.failure({required String error}) {
    return AuthResult(success: false, error: error);
  }
}

class AuthPageServices {
  static final AuthPageServices _instance = AuthPageServices._internal();
  factory AuthPageServices() => _instance;
  AuthPageServices._internal();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    clientId: '338090358950-ig80c6ikufeitpil9cclbdsrm0u1dpga.apps.googleusercontent.com',
    scopes: ['email', 'profile'],
  );

  static const String usersCollection = 'users';
  static const String adminEmail = 'admin@payadvance.local';

  User? get currentUser => _auth.currentUser;
  bool get isLoggedIn => _auth.currentUser != null;
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<AuthResult> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      print('[AuthPageServices] Starting email/password sign in for: $email');

      final credential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      if (credential.user == null) {
        return AuthResult.failure(error: 'Sign in failed - no user returned');
      }

      print('[AuthPageServices] Email/password sign in successful');

      return AuthResult.success(
        user: credential.user,
        message: 'Sign in successful!',
      );
    } on FirebaseAuthException catch (e) {
      print('[AuthPageServices] FirebaseAuth error: ${e.code} - ${e.message}');
      return AuthResult.failure(error: _getAuthErrorMessage(e));
    } catch (e) {
      print('[AuthPageServices] Unexpected error: $e');
      return AuthResult.failure(error: 'An unexpected error occurred. Please try again.');
    }
  }

  Future<AuthResult> registerWithEmailAndPassword({
    required String email,
    required String password,
    required String displayName,
  }) async {
    try {
      print('[AuthPageServices] Starting registration for: $email');

      final credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      if (credential.user == null) {
        return AuthResult.failure(error: 'Registration failed - no user created');
      }

      await credential.user!.updateDisplayName(displayName.trim());
      await credential.user!.reload();

      await _createUserProfile(credential.user!, displayName.trim());

      print('[AuthPageServices] Registration successful');

      return AuthResult.success(
        user: credential.user,
        message: 'Account created successfully!',
      );
    } on FirebaseAuthException catch (e) {
      print('[AuthPageServices] Registration error: ${e.code} - ${e.message}');
      return AuthResult.failure(error: _getAuthErrorMessage(e));
    } catch (e) {
      print('[AuthPageServices] Registration unexpected error: $e');
      return AuthResult.failure(error: 'Registration failed. Please try again.');
    }
  }

  Future<AuthResult> signInWithGoogle() async {
    try {
      print('[AuthPageServices] === STARTING GOOGLE SIGN IN ===');
      
      await _googleSignIn.signOut();
      
      print('[AuthPageServices] Opening Google sign in popup...');
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      
      if (googleUser == null) {
        print('[AuthPageServices] Google sign in was cancelled');
        return AuthResult.failure(error: 'Google sign in was cancelled');
      }

      print('[AuthPageServices] Google account selected: ${googleUser.email}');

      print('[AuthPageServices] Getting authentication tokens...');
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      
      print('[AuthPageServices] Access token: ${googleAuth.accessToken != null ? "Present" : "Missing"}');
      print('[AuthPageServices] ID token: ${googleAuth.idToken != null ? "Present" : "Missing"}');

      if (googleAuth.accessToken == null || googleAuth.idToken == null) {
        print('[AuthPageServices] Failed to get authentication tokens');
        return AuthResult.failure(error: 'Failed to get Google authentication tokens');
      }

      print('[AuthPageServices] Creating Firebase credential...');
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      print('[AuthPageServices] Signing in to Firebase...');
      final userCredential = await _auth.signInWithCredential(credential);

      if (userCredential.user == null) {
        print('[AuthPageServices] Firebase authentication failed');
        return AuthResult.failure(error: 'Firebase authentication failed');
      }

      final user = userCredential.user!;
      final isNewUser = userCredential.additionalUserInfo?.isNewUser ?? false;

      print('[AuthPageServices] Firebase authentication successful');
      print('[AuthPageServices] User: ${user.email}, New user: $isNewUser');

      if (isNewUser) {
        await _createNewGoogleUserProfile(user);
      } else {
        await _updateExistingUserProfile(user);
      }

      print('[AuthPageServices] === GOOGLE SIGN IN COMPLETED ===');

      return AuthResult.success(
        user: user,
        message: isNewUser 
          ? 'Welcome! Your Google account has been registered successfully!' 
          : 'Welcome back! Signed in successfully.',
      );
      
    } catch (e) {
      print('[AuthPageServices] Google sign in error: $e');
      return AuthResult.failure(error: 'Google sign in failed: ${e.toString()}');
    }
  }

  Future<AuthResult> adminLogin({required String email}) async {
    try {
      if (email.toLowerCase().trim() != adminEmail) {
        return AuthResult.failure(error: 'Invalid admin credentials');
      }
      await Future.delayed(const Duration(milliseconds: 500));
      return AuthResult.success(message: 'Admin login successful');
    } catch (e) {
      return AuthResult.failure(error: 'Admin login failed');
    }
  }

  Future<AuthResult> sendPasswordResetEmail({required String email}) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
      return AuthResult.success(message: 'Password reset email sent! Check your inbox.');
    } on FirebaseAuthException catch (e) {
      return AuthResult.failure(error: _getAuthErrorMessage(e));
    } catch (e) {
      return AuthResult.failure(error: 'Failed to send reset email. Please try again.');
    }
  }

  Future<void> _createUserProfile(User user, String displayName) async {
    try {
      final userProfileData = {
        'uid': user.uid,
        'email': user.email ?? '',
        'displayName': displayName.trim(),
        'photoUrl': user.photoURL,
        'createdAt': DateTime.now().toIso8601String(),
        'lastSignIn': DateTime.now().toIso8601String(),
        'isAdmin': false,
        'signInMethod': 'email',
        'isEmailVerified': user.emailVerified,
        'accountStatus': 'active',
      };

      await _firestore
          .collection(usersCollection)
          .doc(user.uid)
          .set(userProfileData);
    } catch (e) {
      print('[AuthPageServices] Error creating user profile: $e');
    }
  }

  Future<void> _createNewGoogleUserProfile(User user) async {
    try {
      final userProfile = {
        'uid': user.uid,
        'email': user.email ?? '',
        'displayName': user.displayName ?? 'Google User',
        'photoUrl': user.photoURL,
        'createdAt': DateTime.now().toIso8601String(),
        'lastSignIn': DateTime.now().toIso8601String(),
        'signInMethod': 'google',
        'isEmailVerified': user.emailVerified,
        'isAdmin': false,
        'accountStatus': 'active',
      };

      await _firestore
          .collection(usersCollection)
          .doc(user.uid)
          .set(userProfile);
    } catch (e) {
      print('[AuthPageServices] Error creating new Google user profile: $e');
    }
  }

  Future<void> _updateExistingUserProfile(User user) async {
    try {
      await _firestore
          .collection(usersCollection)
          .doc(user.uid)
          .update({
            'lastSignIn': DateTime.now().toIso8601String(),
            'displayName': user.displayName ?? 'Google User',
            'photoUrl': user.photoURL,
            'isEmailVerified': user.emailVerified,
          });
    } catch (e) {
      print('[AuthPageServices] Error updating existing Google user profile: $e');
    }
  }

  Future<Map<String, dynamic>?> getUserProfile(String uid) async {
    try {
      final doc = await _firestore.collection(usersCollection).doc(uid).get();
      if (doc.exists && doc.data() != null) {
        return doc.data()!;
      }
      return null;
    } catch (e) {
      print('[AuthPageServices] Error getting user profile: $e');
      return null;
    }
  }

  Future<bool> userProfileExists(String uid) async {
    try {
      final doc = await _firestore.collection(usersCollection).doc(uid).get();
      return doc.exists;
    } catch (e) {
      print('[AuthPageServices] Error checking if user exists: $e');
      return false;
    }
  }

  Future<AuthResult> signOut() async {
    try {
      await Future.wait([
        _auth.signOut(),
        _googleSignIn.signOut(),
      ]);
      return AuthResult.success(message: 'Signed out successfully');
    } catch (e) {
      return AuthResult.failure(error: 'Failed to sign out completely');
    }
  }

  String _getAuthErrorMessage(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'No account found for this email address.';
      case 'wrong-password':
        return 'Incorrect password. Please try again.';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'too-many-requests':
        return 'Too many failed attempts. Please try again later.';
      case 'email-already-in-use':
        return 'An account with this email already exists.';
      case 'weak-password':
        return 'Password is too weak. Please choose a stronger password.';
      case 'invalid-credential':
        return 'Invalid login credentials. Please check your email and password.';
      case 'network-request-failed':
        return 'Network error. Please check your internet connection.';
      case 'popup-closed-by-user':
        return 'Sign in was cancelled. Please try again.';
      case 'cancelled-popup-request':
        return 'Sign in popup was cancelled.';
      case 'popup-blocked':
        return 'Sign in popup was blocked by browser. Please allow popups and try again.';
      default:
        return e.message ?? 'Authentication failed. Please try again.';
    }
  }
}
