import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import '../../providers/user_provider.dart';
import '../../models/user_model.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final UserModel? user = userProvider.userModel;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Meu Perfil'), centerTitle: true),
      body: Stack(
        children: [
          if (user != null)
            _buildProfileContent(context, userProvider, user, theme)
          else
            const Center(child: Text('Utilizador não encontrado.')),
          if (userProvider.isLoading)
            Container(
              color: Colors.black.withOpacity(0.5),
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }

  Widget _buildProfileContent(
    BuildContext context,
    UserProvider userProvider,
    UserModel user,
    ThemeData theme,
  ) {
    return ListView(
      padding: const EdgeInsets.all(24.0),
      children: <Widget>[
        Center(
          child: Column(
            children: [
              _buildAvatar(context, userProvider, user, theme),
              const SizedBox(height: 24.0),
              Text(
                user.displayName.isNotEmpty
                    ? user.displayName
                    : "Adicionar nome",
                style: theme.textTheme.headlineSmall,
              ),
              const SizedBox(height: 8.0),
              Text(
                user.email,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: theme.textTheme.bodySmall?.color?.withOpacity(0.7),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 32.0),
        const Divider(),
        _buildListTile(
          context,
          Icons.edit,
          'Alterar Nome de Exibição',
          () => _showEditNameDialog(context, userProvider, user.displayName),
        ),
        _buildListTile(
          context,
          Icons.info_outline,
          'UID do Utilizador',
          () => _showInfoDialog(context, "UID do Utilizador", user.uid),
        ),
        const Divider(),
        const SizedBox(height: 16.0),
        ElevatedButton.icon(
          icon: const Icon(Icons.logout, color: Colors.white),
          label: const Text('Terminar Sessão'),
          style: ElevatedButton.styleFrom(
            backgroundColor: theme.colorScheme.error,
            foregroundColor: theme.colorScheme.onError,
            padding: const EdgeInsets.symmetric(vertical: 12),
          ),
          onPressed: () async {
            if (!mounted) return;
            await FirebaseAuth.instance.signOut();
            if (context.mounted) {
              context.go('/');
            }
          },
        ),
      ],
    );
  }

  Widget _buildAvatar(
    BuildContext context,
    UserProvider userProvider,
    UserModel user,
    ThemeData theme,
  ) {
    return Stack(
      alignment: Alignment.bottomRight,
      children: [
        CircleAvatar(
          radius: 60,
          backgroundColor: theme.colorScheme.surfaceVariant,
          backgroundImage: user.photoUrl.isNotEmpty
              ? NetworkImage(user.photoUrl)
              : null,
          child: user.photoUrl.isEmpty
              ? Icon(
                  Icons.person,
                  size: 70,
                  color: theme.colorScheme.onSurfaceVariant,
                )
              : null,
        ),
        Positioned(
          bottom: 0,
          right: 0,
          child: IconButton.filled(
            style: IconButton.styleFrom(
              backgroundColor: theme.colorScheme.primary,
            ),
            icon: const Icon(Icons.camera_alt, size: 20),
            onPressed: () async {
              if (!mounted) return;
              await userProvider.uploadProfilePicture();
            },
          ),
        ),
      ],
    );
  }

  ListTile _buildListTile(
    BuildContext context,
    IconData icon,
    String title,
    VoidCallback onTap,
  ) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      trailing: const Icon(Icons.chevron_right, size: 20),
      onTap: onTap,
    );
  }

  void _showEditNameDialog(
    BuildContext context,
    UserProvider userProvider,
    String currentName,
  ) {
    final TextEditingController nameController = TextEditingController(
      text: currentName,
    );
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Alterar Nome'),
          content: TextField(
            controller: nameController,
            autofocus: true,
            decoration: const InputDecoration(
              hintText: 'Digite o seu novo nome',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              child: const Text('Guardar'),
              onPressed: () async {
                if (nameController.text.trim().isNotEmpty) {
                  await userProvider.updateDisplayName(
                    nameController.text.trim(),
                  );
                  if (mounted) Navigator.pop(dialogContext);
                }
              },
            ),
          ],
        );
      },
    );
  }

  void _showInfoDialog(BuildContext context, String title, String content) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(title),
          content: SelectableText(content),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Fechar'),
            ),
          ],
        );
      },
    );
  }
}
