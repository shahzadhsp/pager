import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:go_router/go_router.dart';
import '../../services/admin_service.dart';

class AdminReportsScreen extends StatefulWidget {
  const AdminReportsScreen({super.key});

  @override
  State<AdminReportsScreen> createState() => _AdminReportsScreenState();
}

class _AdminReportsScreenState extends State<AdminReportsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('reportsAndAnalysis').tr(),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: [
            Tab(icon: Icon(Icons.dashboard_outlined), text: 'overview'.tr()),
            Tab(icon: Icon(Icons.people_alt_outlined), text: 'users'.tr()),
            Tab(icon: Icon(Icons.devices_other_outlined), text: 'devices'.tr()),
            Tab(icon: Icon(Icons.lan_outlined), text: 'network'.tr()),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          _GeneralOverviewTab(),
          _UsersReportTab(),
          _DevicesReportTab(),
          _NetworkReportTab(),
        ],
      ),
    );
  }
}

// --- WIDGETS DE CADA SEPARADOR ---

class _GeneralOverviewTab extends StatelessWidget {
  const _GeneralOverviewTab();

  @override
  Widget build(BuildContext context) {
    final adminService = context.watch<AdminService>();
    final growthData = adminService.getNetworkGrowthLast30Days();
    final mostActive = adminService.getMostActiveDevice();

    final device = mostActive.$1;
    final uplinks = mostActive.$2;

    // 👇 CONDITION HERE (VERY IMPORTANT)
    final bool hasMostActiveData = device != null && uplinks != null;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildSectionTitle(context, 'networkGrowth'.tr()),
        SizedBox(height: 16.h),
        _buildGrowthChart(context, growthData),
        SizedBox(height: 24.h),
        _buildSectionTitle(context, 'activityMetrics'.tr()),
        SizedBox(height: 16.h),
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                context,
                'uplinks'.tr(),
                adminService.getUplinksLastWeek().toString(),
                Icons.bar_chart_outlined,
              ),
            ),
            SizedBox(width: 16.h),
            // Expanded(
            //   child: _buildMetricCard(
            //     context,
            //     'mostActiveDevices'.tr(),
            //     device?.id ?? 'N/A',
            //     Icons.devices_other_outlined,
            //     subtext: 'Uplinks: ${uplinks ?? 'N/A'}',
            //   ),
            // ),
            Expanded(
              child: hasMostActiveData
                  ? _buildMetricCard(
                      context,
                      'mostActiveDevices'.tr(),
                      device!.id,
                      Icons.devices_other_outlined,
                      subtext: 'Uplinks: $uplinks',
                    )
                  : _buildMetricCard(
                      context,
                      'mostActiveDevices'.tr(),
                      'No data',
                      Icons.devices_other_outlined,
                      subtext: 'No uplinks yet',
                    ),
            ),
          ],
        ),
      ],
    );
  }
}

class _UsersReportTab extends StatelessWidget {
  const _UsersReportTab();

  @override
  Widget build(BuildContext context) {
    final adminService = context.watch<AdminService>();
    final recentUsers = adminService.getRecentlyRegisteredUsers();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildSectionTitle(context, 'newUsers'.tr()),
        SizedBox(height: 16.h),
        _buildNewUsersChart(context, adminService.getNewUsersByWeek()),
        SizedBox(height: 24.h),
        _buildSectionTitle(context, 'recentlyRegisteredUsers'.tr()),
        SizedBox(height: 8.h),
        Card(
          child: Column(
            children: recentUsers
                .map(
                  (user) => ListTile(
                    leading: const Icon(Icons.person_add_alt_1_outlined),
                    title: Text(user.name),
                    subtitle: Text(user.email),
                    trailing: Text(
                      DateFormat('dd/MM/yy').format(user.registrationDate),
                    ),
                  ),
                )
                .toList(),
          ),
        ),
      ],
    );
  }
}

class _DevicesReportTab extends StatelessWidget {
  const _DevicesReportTab();

  @override
  Widget build(BuildContext context) {
    final adminService = context.watch<AdminService>();
    final inactiveDevices = adminService.getInactiveDevices();
    final deviceDistribution = adminService.getDeviceDistributionPerUser();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildSectionTitle(context, 'inactiveDevices'.tr()),
        SizedBox(height: 8.h),
        Card(
          color: Theme.of(context).colorScheme.errorContainer,
          child: Column(
            children: inactiveDevices.isEmpty
                ? [ListTile(title: Text('noInactiveDevices'.tr()))]
                : inactiveDevices
                      .map(
                        (device) => ListTile(
                          leading: const Icon(Icons.warning_amber_rounded),
                          title: Text(
                            device.id,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                            'Proprietário: ${device.ownerName}\nÚltimo Uplink: ${DateFormat('dd/MM/yy HH:mm').format(device.lastUplink)}',
                          ),
                          trailing: const Icon(Icons.arrow_forward_ios),
                          onTap: () =>
                              context.go('/admin/devices/${device.id}'),
                        ),
                      )
                      .toList(),
          ),
        ),
        SizedBox(height: 24.h),
        _buildSectionTitle(context, 'deviceDistribution'.tr()),
        SizedBox(height: 16.h),
        _buildDeviceDistributionChart(context, deviceDistribution),
      ],
    );
  }
}

class _NetworkReportTab extends StatelessWidget {
  const _NetworkReportTab();

  @override
  Widget build(BuildContext context) {
    final adminService = context.watch<AdminService>();
    final uplinksByGateway = adminService.getUplinksByGateway();
    final avgRssi = adminService.getAverageRssiPerGateway();

    return ListView(
      padding: EdgeInsets.all(16.r),
      children: [
        _buildSectionTitle(context, 'uplinkDistributionByGateway'.tr()),
        SizedBox(height: 16.h),
        _buildGatewayPieChart(context, uplinksByGateway),
        SizedBox(height: 24.h),
        _buildSectionTitle(context, 'averageSingleQuality'.tr()),
        SizedBox(height: 8.h),
        Card(
          child: Column(
            children: avgRssi.entries
                .map(
                  (entry) => ListTile(
                    leading: const Icon(Icons.signal_cellular_alt),
                    title: Text(entry.key),
                    trailing: Text(
                      '${entry.value.toStringAsFixed(1)} dBm',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                )
                .toList(),
          ),
        ),
      ],
    );
  }
}

// --- Chart Widgets and Components ---

Widget _buildSectionTitle(BuildContext context, String title) {
  return Text(title, style: Theme.of(context).textTheme.titleLarge);
}

Widget _buildMetricCard(
  BuildContext context,
  String title,
  String value,
  IconData icon, {
  String? subtext,
}) {
  return Card(
    child: Padding(
      padding: EdgeInsets.all(16.r),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 28.sp, color: Theme.of(context).colorScheme.primary),
          SizedBox(height: 8.h),
          Text(title, style: Theme.of(context).textTheme.bodyMedium),
          SizedBox(height: 4.h),
          Text(
            value,
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          if (subtext != null) ...[
            const SizedBox(height: 4),
            Text(subtext, style: Theme.of(context).textTheme.bodySmall),
          ],
        ],
      ),
    ),
  );
}

Widget _buildGrowthChart(BuildContext context, GrowthData data) {
  return SizedBox(
    height: 200.h,
    child: LineChart(
      LineChartData(
        gridData: const FlGridData(show: false),
        titlesData: const FlTitlesData(show: false),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: List.generate(
              data.userCounts.length,
              (i) => FlSpot(i.toDouble(), data.userCounts[i].toDouble()),
            ),
            isCurved: true,
            color: Colors.blue,
            barWidth: 3.w,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: false),
          ),
          LineChartBarData(
            spots: List.generate(
              data.deviceCounts.length,
              (i) => FlSpot(i.toDouble(), data.deviceCounts[i].toDouble()),
            ),
            isCurved: true,
            color: Colors.green,
            barWidth: 3.w,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: false),
          ),
        ],
      ),
    ),
  );
}

Widget _buildNewUsersChart(BuildContext context, Map<int, int> data) {
  return SizedBox(
    height: 200.h,
    child: BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        gridData: const FlGridData(show: false),
        titlesData: FlTitlesData(
          leftTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) => Text('S${value.toInt()}'),
              reservedSize: 20,
            ),
          ),
        ),
        barGroups: data.entries
            .map(
              (e) => BarChartGroupData(
                x: e.key,
                barRods: [
                  BarChartRodData(
                    toY: e.value.toDouble(),
                    color: Colors.blueAccent,
                    width: 15.w,
                  ),
                ],
              ),
            )
            .toList(),
      ),
    ),
  );
}

Widget _buildDeviceDistributionChart(
  BuildContext context,
  Map<String, int> data,
) {
  final sortedEntries = data.entries.toList()
    ..sort((a, b) => b.value.compareTo(a.value));
  final topEntries = sortedEntries.take(5).toList();

  return SizedBox(
    height: 200.h,
    child: BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        gridData: const FlGridData(show: false),
        titlesData: FlTitlesData(
          leftTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) => Text(
                topEntries[value.toInt()].key,
                style: TextStyle(fontSize: 10.sp),
              ),
              reservedSize: 30,
            ),
          ),
        ),
        barGroups: List.generate(
          topEntries.length,
          (i) => BarChartGroupData(
            x: i,
            barRods: [
              BarChartRodData(
                toY: topEntries[i].value.toDouble(),
                color: Colors.green,
                width: 15.w,
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

Widget _buildGatewayPieChart(BuildContext context, Map<String, int> data) {
  final colors = [
    Colors.red,
    Colors.orange,
    Colors.yellow,
    Colors.cyan,
    Colors.pink,
  ];
  int colorIndex = 0;

  return SizedBox(
    height: 200.h,
    child: PieChart(
      PieChartData(
        sections: data.entries.map((entry) {
          final color = colors[colorIndex++ % colors.length];
          return PieChartSectionData(
            value: entry.value.toDouble(),
            title: '${entry.value}',
            color: color,
            radius: 80.r,
            titleStyle: TextStyle(fontWeight: FontWeight.bold),
          );
        }).toList(),
        sectionsSpace: 4,
        centerSpaceRadius: 40.r,
      ),
    ),
  );
}
