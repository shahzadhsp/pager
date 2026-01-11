import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:developer' as developer;
import '../models/user_model.dart';

class UserProvider with ChangeNotifier {
  UserModel? _userModel;
  UserModel? get userModel => _userModel;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  UserProvider() {
    _auth.authStateChanges().listen((user) {
      if (user != null) {
        fetchUserData(user.uid);
      } else {
        _userModel = null;
        notifyListeners();
      }
    });
  }

  Future<void> fetchUserData(String uid) async {
    try {
      _setLoading(true);
      final doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        _userModel = UserModel.fromFirestore(doc);
      } else {
        final currentUser = _auth.currentUser;
        if (currentUser != null) {
          _userModel = UserModel(
            uid: currentUser.uid,
            email: currentUser.email ?? 'Sem email',
          );
          await _firestore
              .collection('users')
              .doc(uid)
              .set(_userModel!.toFirestore());
        }
      }
    } catch (e, s) {
      developer.log(
        'Erro ao buscar dados do utilizador: $e',
        name: 'user.provider',
        error: e,
        stackTrace: s,
      );
    } finally {
      _setLoading(false);
    }
  }

  Future<void> updateDisplayName(String newName) async {
    if (_userModel == null || newName.trim().isEmpty) return;

    try {
      _setLoading(true);
      await _firestore.collection('users').doc(_userModel!.uid).update({
        'displayName': newName,
      });
      _userModel = _userModel!.copyWith(displayName: newName);
    } catch (e, s) {
      developer.log(
        'Erro ao atualizar o nome: $e',
        name: 'user.provider',
        error: e,
        stackTrace: s,
      );
    } finally {
      _setLoading(false);
    }
  }

  Future<void> uploadProfilePicture() async {
    if (_userModel == null) return;

    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 50,
        maxWidth: 800,
      );

      if (pickedFile == null) return;

      _setLoading(true);
      File imageFile = File(pickedFile.path);

      Reference storageRef = _storage
          .ref()
          .child('profile_pictures')
          .child('${_userModel!.uid}.jpg');

      UploadTask uploadTask = storageRef.putFile(imageFile);
      TaskSnapshot taskSnapshot = await uploadTask;

      String downloadUrl = await taskSnapshot.ref.getDownloadURL();

      await _firestore.collection('users').doc(_userModel!.uid).update({
        'photoUrl': downloadUrl,
      });
      _userModel = _userModel!.copyWith(photoUrl: downloadUrl);
    } catch (e, s) {
      developer.log(
        'Erro ao carregar a imagem de perfil: $e',
        name: 'user.provider',
        error: e,
        stackTrace: s,
      );
    } finally {
      _setLoading(false);
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
