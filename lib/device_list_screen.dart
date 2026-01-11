import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:go_router/go_router.dart';

class DeviceListScreen extends StatefulWidget {
  const DeviceListScreen({super.key});

  @override
  State<DeviceListScreen> createState() => _DeviceListScreenState();
}

class _DeviceListScreenState extends State<DeviceListScreen> {
  final _storage = const FlutterSecureStorage();
  List<String> _deviceIds = [];

  @override
  void initState() {
    super.initState();
    _loadDeviceIds();
  }

  Future<void> _loadDeviceIds() async {
    // Para garantir que a lista seja atualizada ao voltar para esta tela,
    // vamos recarregá-la toda vez que ela for construída.
    final all = await _storage.readAll();
    final devEUIs = all.keys
        .where((key) => key.startsWith('devEUI_'))
        .map((key) => key.substring(7))
        .toList();

    if (mounted) {
      setState(() {
        _deviceIds = devEUIs;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dispositivos Salvos'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => context.go('/settings'),
            tooltip: 'Configurações',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadDeviceIds,
        child: _deviceIds.isEmpty
            ? Center(
                child: Text(
                  'Nenhum dispositivo salvo encontrado.\nArraste para baixo para atualizar.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              )
            : ListView.builder(
                itemCount: _deviceIds.length,
                itemBuilder: (context, index) {
                  final deviceId = _deviceIds[index];
                  return Card(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    elevation: 4,
                    child: ListTile(
                      leading: const Icon(Icons.developer_board, size: 40),
                      title: Text(deviceId, style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: const Text('Status: Ativo'), // Status de espaço reservado
                      trailing: const Icon(Icons.arrow_forward_ios),
                      onTap: () => context.go('/device/$deviceId'),
                    ),
                  );
                },
              ),
      ),
    );
  }
}
