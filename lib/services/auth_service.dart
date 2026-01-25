import 'dart:developer';
import 'dart:io';
import 'dart:developer' as developer;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:myapp/screens/home_screen.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

class AuthService {
  final FirebaseAuth _firebaseAuth;
  // final GoogleSignIn _googleSignIn;
  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;
  AuthService({FirebaseAuth? firebaseAuth})
    : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance;
  Future<void> initGoogle() async {
    await _googleSignIn.initialize(
      serverClientId:
          '703705111388-0p54em755npdpaehnueepardv1cr594v.apps.googleusercontent.com',
    );
  }

  Stream<User?> get authStateChanges => _firebaseAuth.authStateChanges();

  User? get currentUser => _firebaseAuth.currentUser;

  Future<User?> signInWithEmailAndPassword(
    String email,
    String password,
  ) async {
    try {
      final userCredential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return userCredential.user;
    } on FirebaseAuthException catch (e, s) {
      developer.log(
        'Login com Email falhou',
        name: 'app.auth',
        error: e,
        stackTrace: s,
      );
      return null;
    }
  }

  // Future<User?> createUserWithEmailAndPassword(
  //   String email,
  //   String password,
  //   String fullName,
  // ) async {
  //   try {
  //     final userCredential = await _firebaseAuth.createUserWithEmailAndPassword(
  //       email: email,
  //       password: password,
  //     );
  //     return userCredential.user;
  //   } on FirebaseAuthException catch (e, s) {
  //     developer.log(
  //       'Registo com Email falhou',
  //       name: 'app.auth',
  //       error: e,
  //       stackTrace: s,
  //     );
  //     return null;
  //   }
  // }
  Future<User?> createUserWithEmailAndPassword(
    String email,
    String password,
    String fullName,
  ) async {
    try {
      final userCredential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = userCredential.user;

      if (user != null) {
        // ✅ Update display name in Firebase Auth
        await user.updateDisplayName(fullName);
        await user.reload();
        return _firebaseAuth.currentUser;
      }

      return null;
    } on FirebaseAuthException catch (e, s) {
      developer.log(
        'Registo com Email falhou',
        name: 'app.auth',
        error: e,
        stackTrace: s,
      );
      return null;
    }
  }

  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _firebaseAuth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e, s) {
      developer.log(
        'Envio de email de reset falhou',
        name: 'app.auth',
        error: e,
        stackTrace: s,
      );
    }
  }

  Future<User?> signInWithGoogle(BuildContext context) async {
    try {
      // 🌐 Internet check
      await InternetAddress.lookup('google.com');
      final GoogleSignIn googleSignIn = GoogleSignIn.instance;
      // ✅ Initialize with ONLY serverClientId (Web Client ID)
      await googleSignIn.initialize(
        serverClientId:
            '703705111388-0p54em755npdpaehnueepardv1cr594v.apps.googleusercontent.com',
      );
      // 🔐 Start Google Sign-In
      final GoogleSignInAccount? googleUser = await googleSignIn.authenticate();
      if (googleUser == null) {
        log('❌ Google Sign-In cancelled by user');
        return null;
      }

      // 🔑 Get auth tokens
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      // 🔐 Firebase credential
      final OAuthCredential credential = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
      );

      // 🔥 Firebase sign-in
      final UserCredential userCredential = await FirebaseAuth.instance
          .signInWithCredential(credential);
      await saveUserToDatabase(userCredential.user!);
      log('✅ Google Sign-In successful');
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => HomeScreen(isAdmin: false)),
      );

      return userCredential.user;
    } catch (e, s) {
      log('❌ Google Sign-In Failed', error: e, stackTrace: s);
      return null;
    }
  }

  Future<User?> signInWithApple() async {
    if (!Platform.isIOS) {
      developer.log('Login com Apple apenas para iOS.', name: 'app.auth');
      throw UnsupportedError(
        'Sign in with Apple is only supported on iOS devices.',
      );
    }

    try {
      final appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );

      final oAuthProvider = OAuthProvider("apple.com");
      final credential = oAuthProvider.credential(
        idToken: appleCredential.identityToken,
        accessToken: appleCredential.authorizationCode,
      );

      final userCredential = await _firebaseAuth.signInWithCredential(
        credential,
      );
      return userCredential.user;
    } on FirebaseAuthException catch (e, s) {
      developer.log(
        'Firebase Auth falhou com Apple',
        name: 'app.auth',
        error: e,
        stackTrace: s,
      );
      return null;
    } catch (e, s) {
      developer.log(
        'Erro inesperado no Login com Apple',
        name: 'app.auth',
        error: e,
        stackTrace: s,
      );
      return null;
    }
  }

  Future<void> signOut() async {
    try {
      await Future.wait([_firebaseAuth.signOut(), _googleSignIn.signOut()]);
    } catch (e, s) {
      developer.log(
        'Erro ao fazer signOut',
        name: 'app.auth',
        error: e,
        stackTrace: s,
      );
    }
  }

  // save to user in the database
  Future<void> saveUserToDatabase(User user) async {
    final ref = FirebaseDatabase.instance.ref('users/${user.uid}');

    final snapshot = await ref.get();

    if (!snapshot.exists) {
      await ref.set({
        'email': user.email,
        'name': user.displayName ?? 'Unnamed User',
        'role': 'user',
        'createdAt': DateTime.now().millisecondsSinceEpoch,
        'lastLogin': DateTime.now().millisecondsSinceEpoch,
      });
    } else {
      // Update last login
      await ref.update({'lastLogin': DateTime.now().millisecondsSinceEpoch});
    }
  }
}
