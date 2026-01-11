// import 'package:flutter/foundation.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:myapp/models/user_model.dart';
// import 'dart:developer' as developer;

// class UserService with ChangeNotifier {
//   final FirebaseFirestore _firestore = FirebaseFirestore.instance;
//   final FirebaseAuth _auth = FirebaseAuth.instance;

//   UserModel? _user;
//   UserModel? get user => _user;

//   UserService() {
//     _auth.authStateChanges().listen(_onAuthStateChanged);
//   }

//   Future<void> _onAuthStateChanged(User? firebaseUser) async {
//     if (firebaseUser == null) {
//       _user = null;
//     } else {
//       await fetchUser(firebaseUser.uid);
//     }
//     notifyListeners();
//   }

//   Future<void> fetchUser(String userId) async {
//     try {
//       DocumentSnapshot doc = await _firestore.collection('users').doc(userId).get();
//       if (doc.exists) {
//         _user = UserModel.fromFirestore(doc);
//       }
//     } catch (e, s) {
//       developer.log('Error fetching user: $e', name: 'user.service', error: e, stackTrace: s);
//       _user = null;
//     }
//     notifyListeners();
//   }

//   Future<void> updateUser(UserModel user) async {
//     try {
//       await _firestore.collection('users').doc(user.uid).update(user.toFirestore());
//       _user = user;
//       notifyListeners();
//     } catch (e, s) {
//       developer.log('Error updating user: $e', name: 'user.service', error: e, stackTrace: s);
//     }
//   }
// }

import 'package:firebase_database/firebase_database.dart';
import 'package:myapp/models/app_user.dart';

class UserService {
  final DatabaseReference _usersRef = FirebaseDatabase.instance.ref('users');

  Stream<List<AppUser>> usersStream() {
    return _usersRef.onValue.map((event) {
      final data = event.snapshot.value;

      if (data == null) return [];

      final map = Map<String, dynamic>.from(data as Map);
      return map.entries.map((e) {
        return AppUser.fromMap(e.key, Map<String, dynamic>.from(e.value));
      }).toList();
    });
  }
}
