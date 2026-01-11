import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _storage = const FlutterSecureStorage();
  final _formKey = GlobalKey<FormState>();
  final _serverController = TextEditingController();
  final _portController = TextEditingController();
  final _userController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    _serverController.text = await _storage.read(key: 'mqtt_server') ?? '';
    _portController.text = await _storage.read(key: 'mqtt_port') ?? '';
    _userController.text = await _storage.read(key: 'mqtt_user') ?? '';
    _passwordController.text = await _storage.read(key: 'mqtt_password') ?? '';
  }

  Future<void> _saveSettings() async {
    if (_formKey.currentState!.validate()) {
      await _storage.write(key: 'mqtt_server', value: _serverController.text);
      await _storage.write(key: 'mqtt_port', value: _portController.text);
      await _storage.write(key: 'mqtt_user', value: _userController.text);
      await _storage.write(key: 'mqtt_password', value: _passwordController.text);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Configurações salvas com sucesso!')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Configurações do Broker MQTT')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _serverController,
                decoration: const InputDecoration(labelText: 'Servidor MQTT'),
                validator: (value) => value!.isEmpty ? 'Por favor, insira o servidor' : null,
              ),
              TextFormField(
                controller: _portController,
                decoration: const InputDecoration(labelText: 'Porta MQTT'),
                keyboardType: TextInputType.number,
                validator: (value) => value!.isEmpty ? 'Por favor, insira a porta' : null,
              ),
              TextFormField(
                controller: _userController,
                decoration: const InputDecoration(labelText: 'Usuário MQTT (Opcional)'),
              ),
              TextFormField(
                controller: _passwordController,
                decoration: const InputDecoration(labelText: 'Senha MQTT (Opcional)'),
                obscureText: true,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _saveSettings,
                child: const Text('Salvar Configurações'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
