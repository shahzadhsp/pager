import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:rxdart/rxdart.dart';

import '../models/device_status_model.dart'; // Já estava a importar o ficheiro certo

enum DeviceFilter { all, active, inactive }

class AdminDeviceListScreen extends StatefulWidget {
  const AdminDeviceListScreen({super.key});

  @override
  State<AdminDeviceListScreen> createState() => _AdminDeviceListScreenState();
}

class _AdminDeviceListScreenState extends State<AdminDeviceListScreen> {
  final TextEditingController _searchController = TextEditingController();
  final _searchSubject = BehaviorSubject<String>();
  DeviceFilter _currentFilter = DeviceFilter.all;

  final List<DeviceStatusModel> _devices = []; // Corrigido aqui
  bool _isLoading = false;
  bool _hasMore = true;
  String? _lastKey;
  final int _pageSize = 15; // Aumentado para melhor preenchimento

  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    
    _searchSubject
        .debounceTime(const Duration(milliseconds: 500))
        .listen((_) => _resetAndFetch());

    _scrollController.addListener(() {
      if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent * 0.9 && _hasMore && !_isLoading) {
        _fetchDevices();
      }
    });

    _fetchDevices();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchSubject.close();
    _scrollController.dispose();
    super.dispose();
  }

  void _resetAndFetch() {
    setState(() {
      _devices.clear();
      _lastKey = null;
      _hasMore = true;
    });
    _fetchDevices();
  }

  Future<void> _fetchDevices() async {
    if (_isLoading || !_hasMore) return;
    if (mounted) setState(() { _isLoading = true; });

    try {
      Query query = FirebaseDatabase.instance.ref('device_status').orderByKey();
      if (_lastKey != null) {
        query = query.startAfter(_lastKey);
      }
      
      final DataSnapshot snapshot = await query.limitToFirst(_pageSize + 1).get(); // Pede +1 para saber se há mais

      if (snapshot.exists && snapshot.value != null) {
        final Map<dynamic, dynamic> data = snapshot.value as Map<dynamic, dynamic>;
        final List<DeviceStatusModel> newDevices = []; // Corrigido aqui

        final String searchText = _searchController.text.trim().toLowerCase();

        data.forEach((key, value) {
          if (newDevices.length >= _pageSize) return;
          
          final device = DeviceStatusModel.fromFirebase(key, value as Map<dynamic, dynamic>); // Corrigido aqui

          bool passesFilter = (_currentFilter == DeviceFilter.all) ||
                              (_currentFilter == DeviceFilter.active && device.isActive) ||
                              (_currentFilter == DeviceFilter.inactive && !device.isActive);

          bool passesSearch = searchText.isEmpty || 
                              device.id.toLowerCase().contains(searchText) || 
                              (device.nickname?.toLowerCase().contains(searchText) ?? false);

          if (passesFilter && passesSearch) {
            newDevices.add(device);
          }
        });

        if (mounted) {
          setState(() {
            _devices.addAll(newDevices);
            if (data.length <= _pageSize) {
              _hasMore = false;
            }
            _lastKey = data.keys.last;
          });
        }

      } else {
        if (mounted) setState(() { _hasMore = false; });
      }

    } catch (e) {
      if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erro ao buscar dispositivos: $e')),
          );
      }
    } finally {
      if (mounted) setState(() { _isLoading = false; });
    }
  }

  Future<void> _sendCommand(String deviceId, String command) async {
    final ref = FirebaseDatabase.instance.ref('downlink_commands').push();
    try {
      await ref.set({
        'to_mac': deviceId,
        'command': command,
        'timestamp': ServerValue.timestamp,
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Comando \'$command\' enviado para $deviceId')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao enviar comando: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          _buildFilterBar(),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async => _resetAndFetch(),
              child: ListView.builder(
                controller: _scrollController,
                itemCount: _devices.length + (_hasMore ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index == _devices.length) {
                    return _isLoading ? const Center(child: Padding(padding: EdgeInsets.all(16.0), child: CircularProgressIndicator())) : const SizedBox.shrink();
                  }
                  final device = _devices[index];
                  return ListTile(
                    leading: Icon(
                      Icons.circle,
                      color: device.isActive ? Colors.green : Colors.grey[400],
                      size: 16,
                    ),
                    title: Text(device.nickname ?? device.id),
                    subtitle: Text('Última vez visto: ${device.formattedLastSeen}'), // Corrigido aqui
                    trailing: IconButton(
                      icon: const Icon(Icons.vibration_outlined),
                      tooltip: 'Fazer Vibrar',
                      onPressed: () => _showConfirmationDialog(device),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showConfirmationDialog(DeviceStatusModel device) { // Corrigido aqui
     showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Confirmar Ação'),
          content: Text('Tem a certeza que deseja enviar o comando para fazer vibrar o dispositivo ${device.nickname ?? device.id}?'),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancelar'),
              onPressed: () => Navigator.of(dialogContext).pop(),
            ),
            ElevatedButton(
              child: const Text('Enviar'),
              onPressed: () {
                Navigator.of(dialogContext).pop();
                _sendCommand(device.id, 'vibrate');
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildFilterBar() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        children: [
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              labelText: 'Pesquisar por ID ou Apelido',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onChanged: (value) => _searchSubject.add(value),
          ),
          const SizedBox(height: 8),
          SegmentedButton<DeviceFilter>(
            segments: const [
              ButtonSegment(value: DeviceFilter.all, label: Text('Todos')),
              ButtonSegment(value: DeviceFilter.active, label: Text('Ativos'), icon: Icon(Icons.check_circle_outline)),
              ButtonSegment(value: DeviceFilter.inactive, label: Text('Inativos'), icon: Icon(Icons.cancel_outlined)),
            ],
            selected: {_currentFilter},
            onSelectionChanged: (Set<DeviceFilter> newSelection) {
              if (newSelection.isNotEmpty) {
                setState(() {
                  _currentFilter = newSelection.first;
                  _resetAndFetch();
                });
              }
            },
          ),
        ],
      ),
    );
  }
}
