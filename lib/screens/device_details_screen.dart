import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:myapp/services/lora_service.dart';

class DeviceDetailsScreen extends StatefulWidget {
  final String deviceId;
  final String originalMac;

  const DeviceDetailsScreen({
    super.key,
    required this.deviceId,
    required this.originalMac,
  });

  @override
  State<DeviceDetailsScreen> createState() => _DeviceDetailsScreenState();
}

class _DeviceDetailsScreenState extends State<DeviceDetailsScreen> {
  final LoraService _loraService = LoraService();
  final TextEditingController _downlinkController = TextEditingController();
  
  // Variáveis para manter o estado
  final List<UplinkMessage> _messages = [];
  StreamSubscription? _uplinkSubscription;
  late final Stream<bool> _otaReadyStream;

  @override
  void initState() {
    super.initState();
    
    // Configura o stream para o botão OTA
    _otaReadyStream = _loraService.getOtaReadyStream(widget.deviceId);

    // Ouve o stream de mensagens e adiciona-as à nossa lista de estado
    _uplinkSubscription = _loraService.getUplinkStream(widget.deviceId).listen((message) {
      if (mounted) {
        setState(() {
          _messages.insert(0, message); // Insere no início para ter a mais recente primeiro
        });
      }
    });
  }

  Future<void> _sendDownlinkMessage() async {
    if (!mounted || _downlinkController.text.isEmpty) return;

    final text = _downlinkController.text;
    _downlinkController.clear();
    FocusScope.of(context).unfocus();

    try {
      await _loraService.sendTextMessage(widget.deviceId, widget.originalMac, text);
      if (mounted) _showSnackbar('Mensagem de texto enviada com sucesso!');
    } catch (e) {
      if (mounted) _showSnackbar('Erro ao enviar mensagem: $e', isError: true);
    }
  }

  Future<void> _startOtaUpdate() async {
    if (!mounted) return;
    try {
      await _loraService.sendOtaStartCommand(widget.deviceId, widget.originalMac);
      if (mounted) _showSnackbar('Comando para iniciar OTA enviado!');
    } catch (e) {
      if (mounted) _showSnackbar('Erro ao enviar comando OTA: $e', isError: true);
    }
  }

  void _showSnackbar(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.redAccent : Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalhes do Dispositivo'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(20),
          child: Text(widget.originalMac, style: const TextStyle(color: Colors.white70)),
        ),
      ),
      body: Column(
        children: [
          _buildDownlinkSender(),
          const Divider(),
          Expanded(child: _buildUplinkHistory()),
        ],
      ),
      floatingActionButton: StreamBuilder<bool>(
        stream: _otaReadyStream,
        builder: (context, snapshot) {
          if (snapshot.hasData && snapshot.data == true) {
            return FloatingActionButton.extended(
              onPressed: _startOtaUpdate,
              label: const Text('Iniciar Atualização OTA'),
              icon: const Icon(Icons.system_update),
              backgroundColor: Colors.orangeAccent,
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildDownlinkSender() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _downlinkController,
              decoration: const InputDecoration(
                labelText: 'Enviar mensagem via LoRa',
                border: OutlineInputBorder(),
              ),
              onSubmitted: (_) => _sendDownlinkMessage(),
            ),
          ),
          const SizedBox(width: 8),
          IconButton.filled(
            icon: const Icon(Icons.send),
            onPressed: _sendDownlinkMessage,
            tooltip: 'Enviar Comando',
          ),
        ],
      ),
    );
  }

  Widget _buildUplinkHistory() {
    if (_messages.isEmpty) {
      return const Center(child: Text('A aguardar mensagens do dispositivo...'));
    }

    // A lista já está na ordem correta (mais recentes primeiro)
    return ListView.builder(
      itemCount: _messages.length,
      itemBuilder: (context, index) {
        final message = _messages[index];
        return _buildMessageTile(message);
      },
    );
  }

  Widget _buildMessageTile(UplinkMessage message) {
    final isOtaStatus = message.status == 'ota_ready';
    final title = isOtaStatus ? 'Dispositivo Pronto para OTA' : message.text ?? 'Mensagem vazia';
    final icon = isOtaStatus ? Icons.check_circle : Icons.arrow_upward;
    final color = isOtaStatus ? Colors.orangeAccent : Theme.of(context).colorScheme.primary;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: ListTile(
        leading: Icon(icon, color: color),
        title: Text(title, style: TextStyle(fontWeight: isOtaStatus ? FontWeight.bold : FontWeight.normal)),
        subtitle: Text('MAC: ${message.fromMac}'),
        trailing: Text(DateFormat('HH:mm:ss').format(message.timestamp)),
      ),
    );
  }

  @override
  void dispose() {
    _downlinkController.dispose();
    _uplinkSubscription?.cancel(); // Cancela a subscrição para evitar memory leaks
    super.dispose();
  }
}
