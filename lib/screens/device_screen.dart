import 'dart:async';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/lora_service.dart';

class DeviceScreen extends StatefulWidget {
  final String id; // “Device ID (clean MAC)

  const DeviceScreen({super.key, required this.id});

  @override
  State<DeviceScreen> createState() => _DeviceScreenState();
}

class _DeviceScreenState extends State<DeviceScreen> {
  late final LoraService _loraService;
  StreamSubscription? _uplinkSubscription;
  final List<UplinkMessage> _uplinkMessages = [];
  final TextEditingController _textController = TextEditingController();
  bool _isOtaReady = false;

  @override
  void initState() {
    super.initState();
    _loraService = Provider.of<LoraService>(context, listen: false);

    // Ouve por novas mensagens de uplink
    _uplinkSubscription = _loraService.getUplinkStream(widget.id).listen((
      message,
    ) {
      setState(() {
        _uplinkMessages.insert(0, message); // Adiciona no início da lista
      });
    });

    // Ouve pelo status "ota_ready"
    _loraService.getOtaReadyStream(widget.id).listen((isReady) {
      if (mounted && isReady) {
        setState(() {
          _isOtaReady = true;
        });
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('deviceReady'.tr())));
      }
    });
  }

  @override
  void dispose() {
    _uplinkSubscription?.cancel();
    _textController.dispose();
    super.dispose();
  }

  // Função para enviar mensagem de texto
  void _sendText() {
    if (_textController.text.isNotEmpty) {
      // O MAC original (com dois pontos) é necessário para o comando
      // Aqui, estamos a reconstruí-lo a partir do ID.
      // Isto é uma suposição e pode precisar de um campo dedicado no futuro.
      final originalMac = _formatMac(widget.id);
      _loraService.sendTextMessage(
        widget.id,
        originalMac,
        _textController.text,
      );
      _textController.clear();
    }
  }

  // Função para enviar comando OTA
  void _sendOtaCommand() {
    final originalMac = _formatMac(widget.id);
    _loraService.sendOtaStartCommand(widget.id, originalMac);
  }

  // Helper para formatar o MAC address de volta para o formato com ":"
  String _formatMac(String cleanMac) {
    var parts = <String>[];
    for (int i = 0; i < cleanMac.length; i += 2) {
      parts.add(cleanMac.substring(i, i + 2));
    }
    return parts.join(':');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${'device'.tr()} ${widget.id}'),
        actions: [
          if (_isOtaReady)
            Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: ElevatedButton.icon(
                onPressed: _sendOtaCommand,
                icon: const Icon(Icons.system_update, size: 18),
                label: Text('startOTA'.tr()),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          // Campo para enviar mensagens de texto (downlink)
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _textController,
                    decoration: InputDecoration(
                      labelText: 'sendMessage'.tr(),
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: _sendText,
                  style: IconButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Theme.of(context).colorScheme.onPrimary,
                  ),
                ),
              ],
            ),
          ),
          const Divider(),
          // Título da lista de uplinks
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Text(
              'uplinkHistory'.tr(),
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
          // Lista de mensagens de uplink
          Expanded(
            child: _uplinkMessages.isEmpty
                ? Center(child: Text('waitingMessage'.tr()))
                : ListView.builder(
                    itemCount: _uplinkMessages.length,
                    itemBuilder: (context, index) {
                      final message = _uplinkMessages[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        child: ListTile(
                          leading: const Icon(
                            Icons.arrow_upward,
                            color: Colors.green,
                          ),
                          title: Text(
                            message.text ?? 'Status: ${message.status}',
                          ),
                          subtitle: Text(
                            '${'receivedOn'.tr()}: ${message.timestamp.toLocal()}',
                          ),
                          trailing: Text(
                            '#${message.key.substring(message.key.length - 4)}',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
