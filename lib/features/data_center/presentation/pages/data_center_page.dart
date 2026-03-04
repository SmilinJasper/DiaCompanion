import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/data_center_provider.dart';
import '../widgets/upload_tab.dart';
import '../widgets/dashboard_tab.dart';

/// Data Center — upload files and view glucose trend charts.
class DataCenterPage extends StatelessWidget {
  const DataCenterPage({super.key, this.initialTab = 0});

  /// Which tab to show initially (0 = Upload, 1 = Dashboard).
  final int initialTab;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DefaultTabController(
      length: 2,
      initialIndex: initialTab,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Data Center'),
          bottom: TabBar(
            indicatorColor: Colors.white,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            indicatorWeight: 3,
            labelStyle: theme.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w600,
            ),
            tabs: const [
              Tab(icon: Icon(Icons.upload_file_rounded), text: 'Upload'),
              Tab(icon: Icon(Icons.dashboard_rounded), text: 'Dashboard'),
            ],
          ),
        ),
        body: Consumer<DataCenterProvider>(
          builder: (context, provider, _) {
            return const TabBarView(
              children: [
                UploadTab(),
                DashboardTab(),
              ],
            );
          },
        ),
      ),
    );
  }
}
