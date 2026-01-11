import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class InitialScreen extends StatefulWidget {
  const InitialScreen({super.key});

  @override
  State<InitialScreen> createState() => _InitialScreenState();
}

class _InitialScreenState extends State<InitialScreen> {
  final _storage = const FlutterSecureStorage();

  @override
  void initState() {
    super.initState();
    _checkFirstLaunch();
  }

  Future<void> _checkFirstLaunch() async {
    // Verifique se esta é a primeira vez que o aplicativo é iniciado
    final isFirstLaunch = await _storage.read(key: 'isFirstLaunch') ?? 'true';

    if (isFirstLaunch == 'true') {
      // É a primeira vez, então mostre alguma tela de integração ou configuração
      // Por enquanto, vamos direto para a tela principal
      await _storage.write(key: 'isFirstLaunch', value: 'false');
      if (mounted) {
        context.go('/');
      }
    } else {
      // Não é a primeira vez, então vá direto para a tela principal
      if (mounted) {
        context.go('/');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Mostra um indicador de carregamento enquanto verificamos o primeiro lançamento
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}
