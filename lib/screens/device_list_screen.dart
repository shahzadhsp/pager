import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:myapp/services/lora_service.dart';

class DeviceListScreen extends StatefulWidget {
  const DeviceListScreen({super.key});

  @override
  State<DeviceListScreen> createState() => _DeviceListScreenState();
}

class _DeviceListScreenState extends State<DeviceListScreen> {
  // Instancia o nosso novo serviço para interagir com o Firebase
  final LoraService _loraService = LoraService();

  // Função auxiliar para recriar o MAC address original a partir do ID limpo
  // Ex: 'AABBCC112233' -> 'AA:BB:CC:11:22:33'
  String _formatMac(String deviceId) {
    if (deviceId.length != 12)
      return deviceId; // Retorna o original se não for um MAC
    var mac = '';
    for (var i = 0; i < deviceId.length; i += 2) {
      mac += deviceId.substring(i, i + 2);
      if (i < 10) mac += ':';
    }
    return mac.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('connected'.tr()),
        // Ações como adicionar dispositivo podem ser reativadas depois
      ),
      // Usamos um StreamBuilder para ouvir a lista de dispositivos em tempo real
      body: StreamBuilder<List<String>>(
        stream: _loraService.getDeviceListStream(),
        builder: (context, snapshot) {
          // Estado 1: A aguardar dados
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          // Estado 2: Ocorreu um erro
          if (snapshot.hasError) {
            return Center(
              child: Text('Erro ao carregar dispositivos: ${snapshot.error}'),
            );
          }

          // Estado 3: Recebemos dados, mas estão vazios
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Text(
                'Nenhum dispositivo encontrado.\nVerifique se o gateway está online e se os dispositivos enviaram dados.',
                textAlign: TextAlign.center,
              ),
            );
          }

          // Estado 4: Temos dados! Construímos a lista.
          final deviceIds = snapshot.data!;

          return ListView.builder(
            itemCount: deviceIds.length,
            itemBuilder: (context, index) {
              final deviceId = deviceIds[index];
              final originalMac = _formatMac(deviceId);

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: ListTile(
                  leading: const Icon(
                    Icons.developer_board,
                    color: Colors.deepPurple,
                  ),
                  title: Text('loraDevices'.tr()),
                  subtitle: Text('ID: $originalMac'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    // Navega para a tela de detalhes, passando o ID limpo e o MAC original
                    // Assumimos que a rota '/device-details' está configurada no GoRouter
                    context.go(
                      '/device-details',
                      extra: {'deviceId': deviceId, 'originalMac': originalMac},
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
