
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class EditLegalDocsScreen extends StatefulWidget {
  const EditLegalDocsScreen({super.key});

  @override
  State<EditLegalDocsScreen> createState() => _EditLegalDocsScreenState();
}

class _EditLegalDocsScreenState extends State<EditLegalDocsScreen> {
  final _privacyPolicyController = TextEditingController();
  final _termsAndConditionsController = TextEditingController();
  bool _isLoading = true;

  final DocumentReference _privacyRef = FirebaseFirestore.instance.collection('legal').doc('privacy_policy');
  final DocumentReference _termsRef = FirebaseFirestore.instance.collection('legal').doc('terms_and_conditions');

  @override
  void initState() {
    super.initState();
    _loadDocuments();
  }

  Future<void> _loadDocuments() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final privacyDoc = await _privacyRef.get();
      final termsDoc = await _termsRef.get();

      if (privacyDoc.exists) {
        _privacyPolicyController.text = (privacyDoc.data() as Map<String, dynamic>)['content'] ?? '';
      }
      if (termsDoc.exists) {
        _termsAndConditionsController.text = (termsDoc.data() as Map<String, dynamic>)['content'] ?? '';
      }
    } catch (e) {
      _setFeedback('Erro ao carregar os documentos.', isError: true);
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _setFeedback(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
      ),
    );
  }

  Future<void> _saveDocuments() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final batch = FirebaseFirestore.instance.batch();
      final timestamp = FieldValue.serverTimestamp();

      batch.set(_privacyRef, {
        'content': _privacyPolicyController.text,
        'lastUpdated': timestamp,
      }, SetOptions(merge: true));

      batch.set(_termsRef, {
        'content': _termsAndConditionsController.text,
        'lastUpdated': timestamp,
      }, SetOptions(merge: true));

      await batch.commit();
      _setFeedback('Documentos guardados com sucesso!');
    } catch (e) {
      _setFeedback('Erro ao guardar os documentos.', isError: true);
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Editar Documentos Legais'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildEditor('Política de Privacidade', _privacyPolicyController),
                  const SizedBox(height: 24),
                  _buildEditor('Termos e Condições', _termsAndConditionsController),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: _saveDocuments,
                    icon: const Icon(Icons.save_alt),
                    label: const Text('GUARDAR ALTERAÇÕES'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildEditor(String title, TextEditingController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          maxLines: 15,
          decoration: InputDecoration(
            border: const OutlineInputBorder(),
            hintText: 'Escreva o conteúdo aqui...',
            filled: true,
            fillColor: Theme.of(context).colorScheme.surface.withAlpha(50),
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _privacyPolicyController.dispose();
    _termsAndConditionsController.dispose();
    super.dispose();
  }
}
