import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthResult {
  final bool success;
  final String? error;

  AuthResult({required this.success, this.error});
}

class AuthPageServices {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Save or update user record in Firestore
  Future<void> _createOrUpdateUser(User user, {String? displayName}) async {
    final docRef = _db.collection("users").doc(user.uid);
    final docSnapshot = await docRef.get();

    final userData = {
      "uid": user.uid,
      "email": user.email ?? "",
      "displayName": displayName ?? user.displayName ?? "",
      "photoUrl": user.photoURL ?? "",
      "role": "user", // default role
      "lastOnline": FieldValue.serverTimestamp(),
    };

    if (docSnapshot.exists) {
      // Merge profile update
      await docRef.set(userData, SetOptions(merge: true));
    } else {
      // First signup → also set createdAt
      await docRef.set({
        ...userData,
        "createdAt": FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }
  }

  /// Sign in with Email/Password
  Future<AuthResult> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      final userCred = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      await _createOrUpdateUser(userCred.user!);
      return AuthResult(success: true);
    } on FirebaseAuthException catch (e) {
      return AuthResult(success: false, error: e.message);
    }
  }

  /// Register with Email/Password
  Future<AuthResult> registerWithEmailAndPassword({
    required String email,
    required String password,
    required String displayName,
  }) async {
    try {
      final userCred = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      await userCred.user?.updateDisplayName(displayName);
      await _createOrUpdateUser(userCred.user!, displayName: displayName);
      return AuthResult(success: true);
    } on FirebaseAuthException catch (e) {
      return AuthResult(success: false, error: e.message);
    }
  }

  /// Google Sign-In (Web)
  Future<AuthResult> signInWithGoogle() async {
    try {
      final googleProvider = GoogleAuthProvider();
      googleProvider.addScope('email');

      final userCred = await _auth.signInWithPopup(googleProvider);
      await _createOrUpdateUser(userCred.user!);
      return AuthResult(success: true);
    } on FirebaseAuthException catch (e) {
      return AuthResult(success: false, error: e.message);
    } catch (e) {
      return AuthResult(success: false, error: "Something went wrong: $e");
    }
  }

  /// Sign out
  Future<void> signOut() async {
    await _auth.signOut();
  }

  /// Current signed-in user
  User? get currentUser => _auth.currentUser;
}
