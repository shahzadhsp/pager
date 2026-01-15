import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:myapp/providers/theme_provider.dart';
import 'package:myapp/screens/faq_screen.dart';
import 'package:myapp/screens/language/language_setting_screen.dart';
import 'package:myapp/screens/profile/profile_screen.dart';
import 'package:myapp/services/auth_service.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../providers/settings_provider.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  void _shareApp(BuildContext context) {
    // Personalize esta mensagem como desejar
    const String appLink =
        'https://play.google.com/store/apps/details?id=com.example.app'; // Link genérico
    const String message =
        'Experimente esta aplicação incrível para os seus dispositivos LoRa!\n\n$appLink';
    Share.share(message);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('settings'.tr())),
      body: Consumer<SettingsProvider>(
        builder: (context, settingsProvider, child) {
          if (settingsProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          return ListView(
            children: [
              _buildPrivacySection(context, settingsProvider),
              const Divider(),
              _buildAboutSection(context),
              const Divider(),
              // Other settings sections can be added here.
            ],
          );
        },
      ),
    );
  }

  Widget _buildPrivacySection(
    BuildContext context,
    SettingsProvider settingsProvider,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 8.0),
          child: Text(
            'privacy'.tr(),
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
        ),
        SwitchListTile(
          title: Text('readReceits'.tr()),
          subtitle: Text('disable'.tr()),
          value: settingsProvider.readReceiptsEnabled,
          onChanged: (bool value) {
            settingsProvider.toggleReadReceipts(value);
          },
          secondary: const Icon(Icons.privacy_tip_outlined),
        ),
      ],
    );
  }

  Widget _buildAboutSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 8.0),
          child: Text(
            'about'.tr(),
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
        ),
        ListTile(
          leading: const Icon(Icons.share_outlined),
          title: Text('shareApp'.tr()),
          subtitle: Text('shareWithFriends'.tr()),
          onTap: () => _shareApp(context),
        ),
        ListTile(
          leading: const Icon(Icons.language),
          title: Text('language'.tr()),
          subtitle: Text('changeLanguage'.tr()),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const LanguageSettingsScreen()),
            );
          },
        ),
        ListTile(
          leading: Icon(Icons.help_outline),
          title: Text('faq'.tr()),
          subtitle: Text('faqSubtitle'.tr()),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const FaqScreen()),
            );
          },
        ),
        ListTile(
          leading: Icon(Icons.privacy_tip_outlined),
          title: Text('privacyPolicy'.tr()),
          subtitle: Text('privacyPolicySubtitle'.tr()),
          onTap: () {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text('Add This later')));
          },
        ),
        ListTile(
          leading: Icon(Icons.person_outline),
          title: Text('profile'.tr()),
          subtitle: Text('profileSubtitle'.tr()),
          onTap: () {
            // Profile screen ya future action
            // ScaffoldMessenger.of(context).showSnackBar(
            //   SnackBar(content: Text('Profile screen coming soon')),
            // );
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ProfileScreen()),
            );
          },
        ),

        ListTile(
          leading: const Icon(Icons.dark_mode),
          title: const Text('Dark Mode'),
          trailing: Switch(
            value: context.watch<ThemeProvider>().isDark,
            onChanged: (value) {
              context.read<ThemeProvider>().setTheme(
                value ? ThemeMode.dark : ThemeMode.light,
              );
            },
          ),
        ),
        ListTile(
          leading: const Icon(Icons.logout, color: Colors.red),
          title: const Text('Logout', style: TextStyle(color: Colors.red)),
          onTap: () {
            showDialog(
              context: context,
              builder: (dialogCtx) => AlertDialog(
                title: const Text('Logout'),
                content: const Text('Are you sure you want to logout?'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(dialogCtx),
                    child: Text('cancel'.tr()),
                  ),
                  TextButton(
                    onPressed: () async {
                      // 1️⃣ Close dialog safely
                      Navigator.pop(dialogCtx);

                      // 2️⃣ Logout
                      await context.read<AuthService>().signOut();
                    },
                    child: const Text(
                      'Logout',
                      style: TextStyle(color: Colors.red),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
        ListTile(
          leading: const Icon(Icons.info_outline),
          title: Text('appVersion'.tr()),
          subtitle: const Text('1.0.0'),
          onTap: () {},
        ),
      ],
    );
  }
}
