import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../providers/device_provider.dart';
import '../providers/search_provider.dart';
import '../models/device_status_model.dart';
import 'chat/conversation_list_screen.dart';
import 'groups/group_list_screen.dart';

class HomeScreen extends StatefulWidget {
  final bool isAdmin;
  const HomeScreen({super.key, required this.isAdmin});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;
  int _currentTabIndex = 0;
  static const String _adminPassword = 'admin';
  late DatabaseReference userRef;
  bool _isAdmin = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        setState(() => _currentTabIndex = _tabController.index);
      }
    });
    _searchController.addListener(() {
      context.read<SearchProvider>().query = _searchController.text;
    });
    final uid = FirebaseAuth.instance.currentUser!.uid;
    userRef = FirebaseDatabase.instance.ref('users/$uid');

    userRef.onValue.listen((event) {
      final role =
          event.snapshot.child('role').value?.toString().toLowerCase() ??
          'user';
      setState(() {
        _isAdmin = role == 'admin';
      });
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _passwordController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _toggleSearch() {
    setState(() {
      _isSearching = !_isSearching;
      if (!_isSearching) {
        _searchController.clear();
      }
    });
  }

  void _showAdminPasswordDialog() {
    _passwordController.clear();
    showDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text('adminAceess'.tr()),
          content: TextField(
            controller: _passwordController,
            obscureText: true,
            autofocus: true,
            onSubmitted: (_) => _validatePasswordAndNavigate(dialogContext),
            decoration: InputDecoration(labelText: 'password'.tr()),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('cancel'.tr()),
              onPressed: () => Navigator.of(dialogContext).pop(),
            ),
            ElevatedButton(
              child: Text('enter').tr(),
              onPressed: () => _validatePasswordAndNavigate(dialogContext),
            ),
          ],
        );
      },
    );
  }

  void _validatePasswordAndNavigate(BuildContext dialogContext) {
    final enteredPassword = _passwordController.text;
    Navigator.of(dialogContext).pop(); //
    if (enteredPassword == _adminPassword) {
      // Navegar para o novo dashboard de admin
      context.push('/admin');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('incorrectPassword'.tr()),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  PreferredSizeWidget _buildAppBar() {
    if (_isSearching) {
      return AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: _toggleSearch,
        ),
        title: TextField(
          controller: _searchController,
          autofocus: true,
          decoration: InputDecoration(
            hintText: 'search'.tr(),
            border: InputBorder.none,
            hintStyle: TextStyle(
              color: Theme.of(
                context,
              ).appBarTheme.foregroundColor?.withOpacity(0.7),
            ),
          ),
          style: TextStyle(
            color: Theme.of(context).appBarTheme.foregroundColor,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => _searchController.clear(),
          ),
        ],
      );
    } else {
      return AppBar(
        title: Text('myapp'.tr()),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            tooltip: 'Search',
            onPressed: _toggleSearch,
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'Settings',
            onPressed: () => context.push('/settings'),
          ),
          _isAdmin
              ? IconButton(
                  icon: const Icon(Icons.admin_panel_settings_outlined),
                  tooltip: 'Admin Panel',
                  onPressed: _showAdminPasswordDialog,
                )
              : SizedBox.shrink(),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: 'conversation'.tr()),
            Tab(text: 'groups'.tr()),
            Tab(text: 'devices'.tr()),
          ],
        ),
      );
    }
  }

  Widget? _buildFab() {
    if (_isSearching) return null;

    final fabRoutes = ['/scan', '/groups/create', '/scan'];

    final fabIcons = [Icons.message, Icons.group_add, Icons.qr_code_scanner];

    return FloatingActionButton(
      onPressed: () => context.push(fabRoutes[_currentTabIndex]),
      child: Icon(fabIcons[_currentTabIndex]),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: TabBarView(
        controller: _tabController,
        children: [
          const ConversationListScreen(
            useFab: false,
          ), // FAB is now handled by HomeScreen
          const GroupListScreen(), // FAB is now handled by HomeScreen
          Consumer<DeviceProvider>(
            builder: (context, deviceProvider, child) {
              return AnimatedSwitcher(
                duration: const Duration(milliseconds: 500),
                child: _buildContent(context, deviceProvider),
              );
            },
          ),
        ],
      ),
      floatingActionButton: _buildFab(),
    );
  }

  Widget _buildContent(BuildContext context, DeviceProvider deviceProvider) {
    final searchQuery = context.watch<SearchProvider>().query.toLowerCase();
    if (deviceProvider.isLoading) {
      return const Center(
        key: Key('loading'),
        child: CircularProgressIndicator(),
      );
    }
    if (deviceProvider.error != null) {
      return Center(
        key: Key('error'),
        child: Text('Erro: ${deviceProvider.error}'),
      );
    }
    if (!deviceProvider.hasDevices) {
      return const EmptyState(key: Key('empty'));
    }
    return DeviceListView(searchQuery: searchQuery);
  }
}

class EmptyState extends StatelessWidget {
  const EmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.devices_other, size: 80, color: Colors.grey),
            const SizedBox(height: 20),
            Text(
              'welcome'.tr(),
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18, color: Colors.black87),
            ),
            const SizedBox(height: 30),
            ElevatedButton.icon(
              icon: const Icon(Icons.qr_code_scanner, size: 28),
              label: Text('firstDevice'.tr()),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
                textStyle: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              onPressed: () => context.push('/scan'),
            ),
          ],
        ),
      ),
    );
  }
}

class DeviceListView extends StatelessWidget {
  final String searchQuery;
  const DeviceListView({super.key, this.searchQuery = ''});

  @override
  Widget build(BuildContext context) {
    final deviceProvider = Provider.of<DeviceProvider>(context);
    final deviceIds = deviceProvider.deviceIds.where((id) {
      final status = deviceProvider.deviceStatusMap[id];
      final nickname = status?.nickname?.toLowerCase() ?? '';
      final deviceId = id.toLowerCase();
      return nickname.contains(searchQuery) || deviceId.contains(searchQuery);
    }).toList();

    if (deviceIds.isEmpty) {
      return Center(
        child: Text(
          '${tr('noDeviceFoundFor')} "$searchQuery"',

          style: const TextStyle(fontSize: 16, color: Colors.grey),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12.0),
      itemCount: deviceIds.length,
      itemBuilder: (context, index) {
        final deviceId = deviceIds[index];
        final status = deviceProvider.deviceStatusMap[deviceId];
        return DeviceControlCard(deviceId: deviceId, status: status);
      },
    );
  }
}

class DeviceControlCard extends StatelessWidget {
  final String deviceId;
  final DeviceStatusModel? status;

  const DeviceControlCard({super.key, required this.deviceId, this.status});

  Future<void> _showEditNicknameDialog(
    BuildContext context,
    DeviceProvider provider,
  ) async {
    final controller = TextEditingController(text: status?.nickname ?? '');
    return showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text('editNickname'.tr()),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: InputDecoration(labelText: 'deviceName'.tr()),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text('cancel'.tr()),
            ),
            ElevatedButton(
              onPressed: () async {
                await provider.setDeviceNickname(deviceId, controller.text);
                if (context.mounted) Navigator.pop(dialogContext);
              },
              child: const Text('save').tr(),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final deviceProvider = Provider.of<DeviceProvider>(context, listen: false);
    final bool isActive = status?.isActive ?? false;
    final String lastSeen = status?.formattedLastSeen ?? 'Unknown';
    final String nickname = status?.nickname ?? deviceId;

    return Card(
      elevation: 5.0,
      margin: const EdgeInsets.symmetric(vertical: 10.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            colors: [Colors.deepPurple.shade50, Colors.white],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Text(
                      nickname,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.edit_outlined,
                      color: Colors.grey,
                      size: 20,
                    ),
                    onPressed: () =>
                        _showEditNicknameDialog(context, deviceProvider),
                    tooltip: 'Edit Nickname',
                  ),
                ],
              ),
              if (nickname != deviceId)
                Text(
                  'ID: $deviceId',
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: isActive
                      ? Colors.green.withOpacity(0.1)
                      : Colors.grey.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isActive
                        ? Colors.green.shade200
                        : Colors.grey.shade300,
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.circle,
                      color: isActive ? Colors.green : Colors.grey,
                      size: 12,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${isActive ? "Ativo" : "Inativo"} - Visto: $lastSeen',
                      style: TextStyle(
                        fontSize: 12,
                        color: isActive
                            ? Colors.green.shade800
                            : Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 30),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _ControlButton(
                    label: 'turnOnLed'.tr(),
                    icon: Icons.lightbulb,
                    color: Colors.green,
                    onPressed: () async {
                      final result = await deviceProvider.sendCommand(
                        deviceId,
                        'led_on',
                      );
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(result),
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      }
                    },
                  ),
                  _ControlButton(
                    label: 'turnOffLed'.tr(),
                    icon: Icons.lightbulb_outline,
                    color: Colors.red,
                    onPressed: () async {
                      final result = await deviceProvider.sendCommand(
                        deviceId,
                        'led_off',
                      );
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(result),
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      }
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ControlButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onPressed;

  const _ControlButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      icon: Icon(icon, color: Colors.white),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        elevation: 3,
        shadowColor: color.withOpacity(0.5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      ),
      onPressed: onPressed,
    );
  }
}
