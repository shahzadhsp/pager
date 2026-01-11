
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class AdminScreen extends StatelessWidget {
  const AdminScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Painel de Administração'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: <Widget>[
          Card(
            elevation: 4,
            child: ListTile(
              leading: const Icon(Icons.description_outlined),
              title: const Text('Gerir Documentos Legais'),
              subtitle: const Text('Editar Política de Privacidade e Termos e Condições'),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () {
                // Navega para a tela de edição de documentos legais
                context.go('/admin/edit-legal-docs');
              },
            ),
          ),
          // Outros cartões de administração podem ser adicionados aqui
        ],
      ),
    );
  }
}
