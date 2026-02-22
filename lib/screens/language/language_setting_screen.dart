import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:myapp/models/language_model.dart';
import 'package:myapp/screens/home_screen.dart';
import 'package:myapp/screens/onboarding/onboarding_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LanguageSettingsScreen extends StatelessWidget {
  const LanguageSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final List<AppLanguage> languages = [
      AppLanguage('English', const Locale('en')),
      AppLanguage('اردو', const Locale('ur')),
      AppLanguage('العربية', const Locale('ar')),
      AppLanguage('Português', const Locale('pt')),
      AppLanguage('Chinese', const Locale('zh')),
      AppLanguage('Russia', const Locale('ru')),
      AppLanguage('Spanish', const Locale('es')),
      AppLanguage('French', const Locale('fr')),
      AppLanguage('Deutsch', const Locale('de')),
      // new languages
      AppLanguage('Hindi', const Locale('hi')),
      AppLanguage('Thai', const Locale('th')),
      AppLanguage('Vietnamese', const Locale('vi')),
      AppLanguage('Bengali', const Locale('bn')),
      AppLanguage('Persian', const Locale('fa')),
      AppLanguage('Polish', const Locale('pl')),
      AppLanguage('Persian', const Locale('fa')),
      AppLanguage('Indonesian', const Locale('id')),
      AppLanguage('Italian', const Locale('it')),
      AppLanguage('Korean', const Locale('ko')),
      AppLanguage('Turkish', const Locale('tr')),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text('language'.tr()),
        // actions: [
        //   IconButton(
        //     onPressed: () {
        //       Navigator.push(
        //         context,
        //         MaterialPageRoute(builder: (context) => const LoginScreen()),
        //       );
        //     },
        //     icon: Icon(Icons.check),
        //   ),
        // ],
      ),
      body: ListView.builder(
        itemCount: languages.length,
        itemBuilder: (context, index) {
          final lang = languages[index];
          final isSelected = context.locale == lang.locale;

          return ListTile(
            title: Text(lang.title),
            trailing: isSelected
                ? const Icon(Icons.check, color: Colors.green)
                : null,

            // onTap: () async {
            //   await context.setLocale(lang.locale);

            //   final prefs = await SharedPreferences.getInstance();
            //   await prefs.setBool('hasSelectedLanguage', true);

            //   if (context.mounted) {
            //     // context.go('/onboarding');
            //     Navigator.push(
            //       context,
            //       MaterialPageRoute(
            //         builder: (context) => const OnboardingScreen(),
            //       ),
            //     );
            //   }
            // },
            onTap: () async {
              // 1️⃣ Set selected language
              await context.setLocale(lang.locale);
              final prefs = await SharedPreferences.getInstance();
              await prefs.setBool('hasSelectedLanguage', true);
              if (!context.mounted) return;
              // 2️⃣ Check if user is already logged in
              final isLoggedIn = FirebaseAuth.instance.currentUser != null;

              if (isLoggedIn) {
                // Already logged in → go to HomeScreen
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const HomeScreen(isAdmin: false),
                  ),
                );
              } else {
                // Not logged in → go to Onboarding/Login
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const OnboardingScreen(),
                  ),
                );
              }
            },
          );
        },
      ),
    );
  }
}
