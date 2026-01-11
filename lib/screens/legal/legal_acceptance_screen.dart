import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Importa o FirebaseAuth
import 'package:go_router/go_router.dart';

class LegalAcceptanceScreen extends StatefulWidget {
  const LegalAcceptanceScreen({super.key});

  @override
  State<LegalAcceptanceScreen> createState() => _LegalAcceptanceScreenState();
}

class _LegalAcceptanceScreenState extends State<LegalAcceptanceScreen> {
  bool _isLoading = true;
  String _privacyPolicy = '';
  String _termsAndConditions = '';
  Timestamp? _privacyTimestamp;
  Timestamp? _termsTimestamp;

  bool _acceptedPrivacy = false;
  bool _acceptedTerms = false;

  @override
  void initState() {
    super.initState();
    _loadLegalDocuments();
  }

  Future<void> _loadLegalDocuments() async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    try {
      final privacyDoc = await FirebaseFirestore.instance.collection('legal').doc('privacy_policy').get();
      final termsDoc = await FirebaseFirestore.instance.collection('legal').doc('terms_and_conditions').get();

      if (!mounted) return;

      setState(() {
        if (privacyDoc.exists) {
          _privacyPolicy = privacyDoc.data()!['content'] ?? 'Não disponível.';
          _privacyTimestamp = privacyDoc.data()!['lastUpdated'];
        }
        if (termsDoc.exists) {
          _termsAndConditions = termsDoc.data()!['content'] ?? 'Não disponível.';
          _termsTimestamp = termsDoc.data()!['lastUpdated'];
        }
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
      scaffoldMessenger.showSnackBar(const SnackBar(
        content: Text('Erro ao carregar os documentos legais.'),
        backgroundColor: Colors.red,
      ));
    }
  }

  Future<void> _submitAcceptance() async {
    if (!_acceptedPrivacy || !_acceptedTerms) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() => _isLoading = true);

    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final navigator = GoRouter.of(context);

    try {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'legal_acceptance': {
          'privacy_policy_version': _privacyTimestamp,
          'terms_and_conditions_version': _termsTimestamp,
          'accepted_at': FieldValue.serverTimestamp(),
        }
      }, SetOptions(merge: true));

      if (!mounted) return;
      navigator.go('/');

    } catch (e) {
      if (!mounted) return;
      scaffoldMessenger.showSnackBar(const SnackBar(
        content: Text('Ocorreu um erro ao guardar a sua aceitação.'),
        backgroundColor: Colors.red,
      ));
    } finally {
      if(mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool canSubmit = _acceptedPrivacy && _acceptedTerms;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Termos e Privacidade'),
        automaticallyImplyLeading: false, // Remove o botão de voltar
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 0),
              child: Column(
                children: [
                  Expanded(
                    child: DefaultTabController(
                      length: 2,
                      child: Column(
                        children: [
                          const TabBar(
                            tabs: [
                              Tab(text: 'Termos de Uso'),
                              Tab(text: 'Política de Privacidade'),
                            ],
                          ),
                          Expanded(
                            child: TabBarView(
                              children: [
                                _buildDocumentViewer(_termsAndConditions),
                                _buildDocumentViewer(_privacyPolicy),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
       bottomNavigationBar: _isLoading ? null : _buildBottomBar(canSubmit),
    );
  }

   Widget _buildBottomBar(bool canSubmit) {
     return BottomAppBar(
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
             _buildAcceptanceCheckbox(
              title: 'Li e aceito os Termos e Condições',
              value: _acceptedTerms,
              onChanged: (value) => setState(() => _acceptedTerms = value!),
            ),
            _buildAcceptanceCheckbox(
              title: 'Li e aceito a Política de Privacidade',
              value: _acceptedPrivacy,
              onChanged: (value) => setState(() => _acceptedPrivacy = value!),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: canSubmit ? _submitAcceptance : null,
              child: const Text('ACEITAR E CONTINUAR'),
            ),
          ],
        ),
      ),
    );
   }

  Widget _buildDocumentViewer(String text) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Text(text, style: Theme.of(context).textTheme.bodyMedium),
    );
  }

  Widget _buildAcceptanceCheckbox(
      {required String title, required bool value, required ValueChanged<bool?> onChanged}) {
    return CheckboxListTile(
      title: Text(title, style: Theme.of(context).textTheme.bodySmall),
      value: value,
      onChanged: onChanged,
      controlAffinity: ListTileControlAffinity.leading,
      dense: true,
      contentPadding: EdgeInsets.zero,
    );
  }

}
