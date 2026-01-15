import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return Scaffold(body: Center(child: Text('userNotLoggedIn'.tr())));
    }

    final DatabaseReference userRef = FirebaseDatabase.instance.ref(
      'users/${user.uid}',
    );

    return Scaffold(
      appBar: AppBar(title: Text('profile'.tr())),
      body: StreamBuilder<DatabaseEvent>(
        stream: userRef.onValue,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final data = snapshot.data?.snapshot.value;

          if (data == null) {
            return Center(child: Text('profileData'.tr()));
          }

          final userData = Map<String, dynamic>.from(data as Map);

          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Center(child: Icon(Icons.person, size: 80)),
                const SizedBox(height: 30),

                _item('email'.tr(), userData['email']),
                _item('role'.tr(), userData['role']),
                _item('Created At', _formatDate(userData['createdAt'])),
                _item('lastLogin'.tr(), _formatDate(userData['lastLogin'])),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _item(String title, dynamic value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 12)),
          const SizedBox(height: 4),
          Text(
            value?.toString() ?? '',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  String _formatDate(dynamic millis) {
    if (millis == null) return '';
    return DateTime.fromMillisecondsSinceEpoch(millis).toString();
  }
}
