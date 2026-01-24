import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../services/admin_service.dart';

enum DeviceFilterStatus { all, online, offline }

class AdminDeviceManagementScreen extends StatefulWidget {
  const AdminDeviceManagementScreen({super.key});

  @override
  State<AdminDeviceManagementScreen> createState() =>
      _AdminDeviceManagementScreenState();
}

class _AdminDeviceManagementScreenState
    extends State<AdminDeviceManagementScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  DeviceFilterStatus _selectedStatus = DeviceFilterStatus.all;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final adminService = Provider.of<AdminService>(context);
    final dateFormat = DateFormat('dd/MM/yy HH:mm');

    final filteredDevices = adminService.devices.where((device) {
      final matchesStatus =
          _selectedStatus == DeviceFilterStatus.all ||
          (_selectedStatus == DeviceFilterStatus.online && device.isOnline) ||
          (_selectedStatus == DeviceFilterStatus.offline && !device.isOnline);

      final matchesQuery =
          _searchQuery.isEmpty ||
          device.id.toLowerCase().contains(_searchQuery) ||
          device.ownerName.toLowerCase().contains(_searchQuery);

      return matchesStatus && matchesQuery;
    }).toList();

    return Scaffold(
      appBar: AppBar(title: Text('deviceManagement'.tr())),
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(12.0.r),
            child: Column(
              children: [
                TextFormField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    labelText: 'searchByIDOrName'.tr(),
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                            },
                          )
                        : null,
                  ),
                ),
                SizedBox(height: 12.h),
                Wrap(
                  spacing: 8.0,
                  children: [
                    ChoiceChip(
                      label: Text('todos'.tr()),
                      selected: _selectedStatus == DeviceFilterStatus.all,
                      onSelected: (selected) {
                        if (selected) {
                          setState(
                            () => _selectedStatus = DeviceFilterStatus.all,
                          );
                        }
                      },
                    ),
                    ChoiceChip(
                      label: Text('online'.tr()),
                      avatar: const Icon(Icons.power, color: Colors.green),
                      selected: _selectedStatus == DeviceFilterStatus.online,
                      onSelected: (selected) {
                        if (selected) {
                          setState(
                            () => _selectedStatus = DeviceFilterStatus.online,
                          );
                        }
                      },
                    ),
                    ChoiceChip(
                      label: Text('offline'.tr()),
                      avatar: const Icon(Icons.power_off, color: Colors.red),
                      selected: _selectedStatus == DeviceFilterStatus.offline,
                      onSelected: (selected) {
                        if (selected) {
                          setState(
                            () => _selectedStatus = DeviceFilterStatus.offline,
                          );
                        }
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: filteredDevices.length,
              itemBuilder: (context, index) {
                final device = filteredDevices[index];
                return Card(
                  margin: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                  child: ListTile(
                    leading: Icon(
                      device.isOnline ? Icons.sensors : Icons.sensors_off,
                      color: device.isOnline ? Colors.green : Colors.grey,
                      size: 30.sp,
                    ),
                    title: Text(
                      device.id,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      '${'owner'.tr()}: ${device.ownerName}\n${'lastContact'.tr()}: ${dateFormat.format(device.lastUplink)}',
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    isThreeLine: true,
                    onTap: () {
                      // Ação para navegar para a tela de detalhes do dispositivo
                      context.push('/admin/devices/${device.id}');
                    },
                  ),
                );
              },
            ),
          ),
          if (filteredDevices.isEmpty)
            Padding(
              padding: EdgeInsets.all(20.0.r),
              child: Center(child: Text('noDeviceMatches'.tr())),
            ),
        ],
      ),
    );
  }
}
