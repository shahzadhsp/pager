import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:myapp/models/admin_device_model.dart';
import 'package:myapp/models/admin_uplink.dart';
import 'package:myapp/models/admin_users_model.dart';
import 'package:provider/provider.dart';
import '../../services/admin_service.dart';
import '../../services/firebase_service.dart';

class AdminDeviceDetailScreen extends StatefulWidget {
  final String deviceId;

  const AdminDeviceDetailScreen({super.key, required this.deviceId});

  @override
  State<AdminDeviceDetailScreen> createState() =>
      _AdminDeviceDetailScreenState();
}

class _AdminDeviceDetailScreenState extends State<AdminDeviceDetailScreen> {
  bool _isSendingCommand = false;

  Future<void> _sendCommand(
    BuildContext context,
    String macAddress,
    String command,
  ) async {
    setState(() => _isSendingCommand = true);

    final firebaseService = context.read<FirebaseService>();
    final success = await firebaseService.sendDownlinkCommand(
      macAddress,
      command,
    );

    if (mounted) {
      setState(() => _isSendingCommand = false);
      _showActionSnackbar(
        context,
        success
            ? 'sendCommand'.tr(args: [command])
            : 'errorSendingCommand'.tr(),
        success: success,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final adminService = Provider.of<AdminService>(context);

    try {
      final device = adminService.devices.firstWhere(
        (d) => d.id == widget.deviceId,
      );
      final owner = adminService.users.firstWhere(
        (u) => u.id == device.ownerId,
      );
      final uplinks = adminService.uplinks
          .where((u) => u.deviceId == widget.deviceId)
          .toList();

      return Scaffold(
        appBar: AppBar(title: Text(device.id)),
        body: AbsorbPointer(
          absorbing: _isSendingCommand, // Block the UI while sending
          child: Stack(
            children: [
              ListView(
                padding: const EdgeInsets.all(12.0),
                children: [
                  _buildStatusCard(context, device),
                  const SizedBox(height: 16),
                  _buildOwnerCard(context, owner),
                  const SizedBox(height: 16),
                  _buildActionsCard(context, device),
                  const SizedBox(height: 16),
                  _buildHistoryCard(context, uplinks),
                ],
              ),
              if (_isSendingCommand)
                const Center(child: CircularProgressIndicator()),
            ],
          ),
        ),
      );
    } catch (e) {
      return Scaffold(
        appBar: AppBar(title: Text('error'.tr())),
        body: Center(
          child: Text(
            '${'deviceWithId'.tr()} \'${widget.deviceId}\' ${'wasNotFound'.tr()}',
          ),
        ),
      );
    }
  }

  Widget _buildStatusCard(BuildContext context, AdminDevice device) {
    final gateway = Provider.of<AdminService>(
      context,
      listen: false,
    ).gateways.firstWhere((g) => g.id == device.lastHeardByGatewayId);
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm:ss');

    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'statusAndInformation'.tr(),
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const Divider(height: 20),
            _buildInfoRow(Icons.memory, 'diviceID'.tr(), device.id),
            _buildInfoRow(
              Icons.developer_board,
              'macAddress'.tr(),
              device.macAddress,
            ),
            _buildInfoRow(Icons.person_outline, 'owner'.tr(), device.ownerName),
            _buildInfoRow(
              device.isOnline ? Icons.signal_wifi_4_bar : Icons.signal_wifi_off,
              'status'.tr(),
              device.isOnline ? 'online'.tr() : 'offline'.tr(),
              color: device.isOnline ? Colors.green : Colors.red,
            ),
            _buildInfoRow(
              Icons.history,
              'lastUplink'.tr(),
              dateFormat.format(device.lastUplink),
            ),
            _buildInfoRow(Icons.router, 'gateway'.tr(), gateway.name),
            _buildInfoRow(
              Icons.location_on_outlined,
              'location'.tr(),
              '${device.location.latitude.toStringAsFixed(4)}, ${device.location.longitude.toStringAsFixed(4)}',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOwnerCard(BuildContext context, AdminUser owner) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'ownerDetaials'.tr(),
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const Divider(height: 20),
            _buildInfoRow(Icons.badge_outlined, 'name'.tr(), owner.name),
            _buildInfoRow(Icons.email_outlined, 'email'.tr(), owner.email),
            _buildInfoRow(
              Icons.app_registration,
              'memberSince'.tr(),
              DateFormat('dd/MM/yyyy').format(owner.registrationDate),
            ),
            _buildInfoRow(
              owner.isActive ? Icons.check_circle_outline : Icons.highlight_off,
              'account'.tr(),
              owner.isActive ? 'active'.tr() : 'inactive'.tr(),
              color: owner.isActive ? Colors.green : Colors.red,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionsCard(BuildContext context, AdminDevice device) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'remoteActions'.tr(),
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const Divider(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                ElevatedButton.icon(
                  icon: const Icon(Icons.refresh),
                  label: Text('restart'.tr()),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange.shade700,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () =>
                      _sendCommand(context, device.macAddress, 'restart'.tr()),
                ),
                ElevatedButton.icon(
                  icon: const Icon(Icons.download_for_offline_outlined),
                  label: Text('requestStatus'.tr()),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade700,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () => _sendCommand(
                    context,
                    device.macAddress,
                    'statusRequested'.tr(),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryCard(BuildContext context, List<AdminUplink> uplinks) {
    final dateFormat = DateFormat('dd/MM HH:mm:ss');
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'uplinkHistory'.tr(),
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const Divider(height: 20),
            if (uplinks.isEmpty)
              Center(child: Text('noUplinksRegistered'.tr())),
            if (uplinks.isNotEmpty)
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 250),
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: uplinks.length,
                  itemBuilder: (context, index) {
                    final uplink = uplinks[index];
                    return ListTile(
                      dense: true,
                      leading: const Icon(Icons.arrow_upward, size: 20),
                      title: Text('RSSI: ${uplink.rssi} dBm'),
                      subtitle: Text(
                        '${'payload'.tr()}: ${uplink.payload.toString()} | Via: ${uplink.gatewayId}',
                      ),

                      trailing: Text(dateFormat.format(uplink.timestamp)),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(
    IconData icon,
    String label,
    String value, {
    Color? color,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        children: [
          Icon(icon, color: Colors.grey.shade600, size: 20),
          const SizedBox(width: 16),
          Text('$label: ', style: const TextStyle(fontWeight: FontWeight.bold)),
          Expanded(
            child: Text(
              value,
              style: TextStyle(color: color, fontSize: 14),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }

  void _showActionSnackbar(
    BuildContext context,
    String message, {
    required bool success,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: success ? Colors.green.shade600 : Colors.red.shade600,
        duration: const Duration(seconds: 3),
      ),
    );
  }
}
