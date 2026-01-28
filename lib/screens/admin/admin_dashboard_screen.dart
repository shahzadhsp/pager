import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:myapp/providers/chat_provider.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:go_router/go_router.dart';
import '../../services/admin_service.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  @override
  Widget build(BuildContext context) {
    final adminService = Provider.of<AdminService>(context);
    final theme = Theme.of(context);
    final groups = context.watch<AdminService>().groupsRTDB;

    return Scaffold(
      appBar: AppBar(
        title: Text('administratorDashboard'.tr()),
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 1,
      ),
      body: ListView(
        padding: EdgeInsets.all(16.0.r),
        children: [
          _buildMetricsGrid(adminService, context),
          const SizedBox(height: 24),
          _buildActivityChart(adminService, context),
          const SizedBox(height: 24),
          _buildNavigationMenu(context),
        ],
      ),
    );
  }

  Widget _buildMetricsGrid(AdminService service, BuildContext context) {
    // sirf group conversations
    final metrics = [
      {
        'title': 'totalUers'.tr(),
        'value': service.users1.length.toString(),
        'icon': Icons.people_outline,
        'color': Colors.blue,
        'route': '/admin/users',
      },
      {
        'title': 'totalDevices'.tr(),
        'value': service.totalDevices.toString(),
        'icon': Icons.devices_other_outlined,
        'color': Colors.green,
        'route': '/admin/devices',
      },
      {
        'title': 'totalGateways'.tr(),
        'value': service.totalGateways.toString(),
        'icon': Icons.router_outlined,
        'color': Colors.red,
        'route': '/admin/gateways',
      },
      {
        'title': 'totalGroups'.tr(),
        'value': service.groupsRTDB.length.toString(),
        'icon': Icons.group_work_outlined,
        'color': Colors.orange,
        'route': '/admin/groups',
      },
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 1.2,
      ),
      itemCount: metrics.length,
      itemBuilder: (context, index) {
        final metric = metrics[index];
        return Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: InkWell(
            onTap: () => context.go(metric['route'] as String),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Icon(
                    metric['icon'] as IconData,
                    size: 32.sp,
                    color: metric['color'] as Color,
                  ),
                  Text(
                    metric['title'] as String,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  Text(
                    metric['value'] as String,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildActivityChart(AdminService service, BuildContext context) {
    final hourlyData = service.getHourlyUplinkVolume(hours: 24);
    final theme = Theme.of(context);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('uplinkVolume'.tr(), style: theme.textTheme.titleLarge),
            const SizedBox(height: 24),
            SizedBox(
              height: 200.h,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY:
                      (hourlyData.values.isEmpty
                          ? 0
                          : hourlyData.values.reduce((a, b) => a > b ? a : b)) *
                      1.2,
                  barTouchData: BarTouchData(enabled: true),
                  titlesData: FlTitlesData(
                    show: true,
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (double value, TitleMeta meta) {
                          final hour = value.toInt();
                          return SideTitleWidget(
                            meta: meta,
                            child: Text(hour % 6 == 0 ? '$hour:00' : ''),
                          );
                        },
                        reservedSize: 30,
                      ),
                    ),
                  ),
                  gridData: const FlGridData(show: false),
                  borderData: FlBorderData(show: false),
                  barGroups: hourlyData.entries.map((entry) {
                    return BarChartGroupData(
                      x: entry.key,
                      barRods: [
                        BarChartRodData(
                          toY: entry.value.toDouble(),
                          color: theme.colorScheme.primary,
                          width: 12,
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(4),
                            topRight: Radius.circular(4),
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavigationMenu(BuildContext context) {
    final items = [
      {
        'title': 'userManagement'.tr(),
        'icon': Icons.manage_accounts_outlined,
        'route': '/admin/users',
      },
      {
        'title': 'deviceManagement'.tr(),
        'icon': Icons.dvr_outlined,
        'route': '/admin/devices',
      },
      {
        'title': 'gatewayManagement'.tr(),
        'icon': Icons.router_outlined,
        'route': '/admin/gateways',
      },
      {
        'title': 'groupManagement'.tr(),
        'icon': Icons.group_work_outlined,
        'route': '/admin/groups',
      },
      {
        'title': 'reportsAndAnalytics'.tr(),
        'icon': Icons.analytics_outlined,
        'route': '/admin/reports',
      },
      {
        'title': 'uplinkFeed'.tr(),
        'icon': Icons.stream_outlined,
        'route': '/admin/uplink-feed',
      },
      {
        'title': 'deviceMap'.tr(),
        'icon': Icons.map_outlined,
        'route': '/admin/map',
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 8.0),
          child: Text(
            'managementTools'.tr(),
            style: Theme.of(context).textTheme.titleLarge,
          ),
        ),
        ...items.map((item) {
          return Card(
            margin: const EdgeInsets.symmetric(vertical: 6.0),
            child: ListTile(
              leading: Icon(
                item['icon'] as IconData,
                color: Theme.of(context).colorScheme.secondary,
              ),
              title: Text(item['title'] as String),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.go(item['route'] as String),
            ),
          );
        }),
      ],
    );
  }
}
