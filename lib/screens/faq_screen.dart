import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class FaqScreen extends StatelessWidget {
  const FaqScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('faqHelp'.tr())),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          FaqItem(question: 'whatIsApp'.tr(), answer: 'appDescription'.tr()),
          FaqItem(
            question: 'howToAddDevice'.tr(),
            answer: 'howToAddDeviceAnswer'.tr(),
          ),
          FaqItem(
            question: 'deviceAppear'.tr(),
            answer: 'deviceAppearAnswer'.tr(),
          ),
          FaqItem(
            question: 'chnageTheme'.tr(),
            answer: 'changeThemeAnswer'.tr(),
          ),
          FaqItem(
            question: 'viewSensorsData'.tr(),
            answer: 'viewSensorsDataAnswer'.tr(),
          ),
          FaqItem(
            question: 'groupsManagement'.tr(),
            answer: 'groupsManagementAnswer'.tr(),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {
              _launchURL(context);
            },
            child: Text('viewManual'.tr()),
          ),
        ],
      ),
    );
  }

  void _launchURL(BuildContext context) async {
    final Uri url = Uri.parse('manual.html');
    if (!await launchUrl(url)) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('openManualError'.tr())));
    }
  }
}

class FaqItem extends StatelessWidget {
  final String question;
  final String answer;

  const FaqItem({super.key, required this.question, required this.answer});

  @override
  Widget build(BuildContext context) {
    return ExpansionTile(
      title: Text(question, style: Theme.of(context).textTheme.titleMedium),
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Text(answer),
        ),
      ],
    );
  }
}
