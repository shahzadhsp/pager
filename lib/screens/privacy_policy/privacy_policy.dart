import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PrivacyPolicyScreen extends StatefulWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  State<PrivacyPolicyScreen> createState() => _PrivacyPolicyScreenState();
}

class _PrivacyPolicyScreenState extends State<PrivacyPolicyScreen> {
  bool isAccepted = false;
  @override
  void initState() {
    super.initState();
    _loadPrivacyStatus();
  }

  Future<void> _loadPrivacyStatus() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      isAccepted = prefs.getBool('privacyAccepted') ?? false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("privacyPolicy".tr())),
      body: Column(
        children: [
          // 📜 Privacy Policy Text
          //           Expanded(
          //             child: Padding(
          //               padding: const EdgeInsets.all(16),
          //               child: SingleChildScrollView(
          //                 child: const Text('''
          // Your Privacy Policy text here...
          // 1. We collect basic account information.
          // 2. We do not sell user data.
          // 3. Messages are stored securely.
          // 4. Users can request account deletion anytime.

          // By using this app, you agree to this Privacy Policy.
          //                   ''', style: TextStyle(fontSize: 14)),
          //               ),
          //             ),
          //           ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('privacy_policy.line1'.tr()),
              SizedBox(height: 10),

              Text('privacy_policy.point1'.tr()),
              Text('privacy_policy.point2'.tr()),
              Text('privacy_policy.point3'.tr()),
              Text('privacy_policy.point4'.tr()),

              SizedBox(height: 12),
              Text('privacy_policy.footer'.tr()),
            ],
          ),
          Divider(height: 1),
          // ✅ Checkbox + Agree Button
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                Row(
                  children: [
                    Checkbox(
                      value: isAccepted,
                      onChanged: (value) {
                        setState(() {
                          isAccepted = value ?? false;
                        });
                      },
                    ),
                    Expanded(child: Text("agreePrivacyPolicy".tr())),
                  ],
                ),

                const SizedBox(height: 10),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: isAccepted
                        ? () {
                            Navigator.pop(context, true);
                          }
                        : null,
                    child: Text("iAgree".tr()),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
