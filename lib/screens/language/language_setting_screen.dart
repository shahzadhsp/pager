import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:myapp/models/language_model.dart';
import 'package:myapp/screens/onboarding/onboarding_screen.dart';
import 'package:country_flags/country_flags.dart';

class LanguageSettingsScreen extends StatefulWidget {
  const LanguageSettingsScreen({super.key});

  @override
  State<LanguageSettingsScreen> createState() => _LanguageSettingsScreenState();
}

class _LanguageSettingsScreenState extends State<LanguageSettingsScreen> {
  /// stores selected language locally
  Locale? _selectedLocale;
  final Map<String, String> languageFlags = {
    'en': 'US', // 🇺🇸 United States
    'ur': 'PK', // 🇵🇰 Pakistan
    'ar': 'SA', // 🇸🇦 Saudi Arabia
    'pt': 'PT', // 🇵🇹 Portugal
    'zh': 'CN', // 🇨🇳 China
    'ru': 'RU', // 🇷🇺 Russia
    'es': 'ES', // 🇪🇸 Spain
    'fr': 'FR', // 🇫🇷 France
    'de': 'DE', // 🇩🇪 Germany
    'hi': 'IN', // 🇮🇳 India
    'th': 'TH', // 🇹🇭 Thailand
    'vi': 'VN', // 🇻🇳 Vietnam
    'bn': 'BD', // 🇧🇩 Bangladesh
    'fa': 'IR', // 🇮🇷 Iran
    'pl': 'PL', // 🇵🇱 Poland
    'id': 'ID', // 🇮🇩 Indonesia
    'it': 'IT', // 🇮🇹 Italy
    'ko': 'KR', // 🇰🇷 South Korea
    'tr': 'TR', // 🇹🇷 Turkey
  };
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
    AppLanguage('Hindi', const Locale('hi')),
    AppLanguage('Thai', const Locale('th')),
    AppLanguage('Vietnamese', const Locale('vi')),
    AppLanguage('Bengali', const Locale('bn')),
    AppLanguage('Persian', const Locale('fa')),
    AppLanguage('Polish', const Locale('pl')),
    AppLanguage('Indonesian', const Locale('id')),
    AppLanguage('Italian', const Locale('it')),
    AppLanguage('Korean', const Locale('ko')),
    AppLanguage('Turkish', const Locale('tr')),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        surfaceTintColor: Colors.transparent,
        backgroundColor: Colors.transparent,
        title: Text('language'.tr()),
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            // Disabled until a language is selected
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const OnboardingScreen(),
                ),
              );
            },
          ),
        ],
      ),

      body: ListView.builder(
        itemCount: languages.length,
        itemBuilder: (context, index) {
          final lang = languages[index];

          final isSelected =
              _selectedLocale == lang.locale || context.locale == lang.locale;

          return ListTile(
            leading: CountryFlag.fromCountryCode(
              languageFlags[lang.locale.languageCode] ?? 'US',
            ),

            title: Text(lang.title),

            trailing: isSelected
                ? const Icon(Icons.check, color: Colors.green)
                : null,

            onTap: () async {
              // change language only
              await context.setLocale(lang.locale);

              // update UI selection
              setState(() {
                _selectedLocale = lang.locale;
              });
            },
          );
        },
      ),
    );
  }
}
