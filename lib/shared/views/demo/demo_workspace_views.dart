import 'package:flutter/material.dart';
import 'package:quickboom_app/core/theme/app_colors.dart';
import 'package:quickboom_app/core/widgets/responsive/responsive.dart';
import 'package:remixicon/remixicon.dart';

enum DemoEmployeeWorkspace { bpo, visitor }

extension DemoEmployeeWorkspaceLabel on DemoEmployeeWorkspace {
  String get title => switch (this) {
    DemoEmployeeWorkspace.bpo => 'BPO Employee',
    DemoEmployeeWorkspace.visitor => 'Visitor Employee',
  };

  String get description => switch (this) {
    DemoEmployeeWorkspace.bpo => 'Leads, follow-ups and customer calls',
    DemoEmployeeWorkspace.visitor => 'Scheduled visits and field updates',
  };

  IconData get icon => switch (this) {
    DemoEmployeeWorkspace.bpo => Remix.headphone_line,
    DemoEmployeeWorkspace.visitor => Remix.map_pin_2_line,
  };
}

/// Employee demo home: BPO and Visitor workspaces are tabs, opened directly
/// after app start — no demo login or workspace chooser screens.
class DemoHomeView extends StatefulWidget {
  const DemoHomeView({super.key});

  @override
  State<DemoHomeView> createState() => _DemoHomeViewState();
}

class _DemoHomeViewState extends State<DemoHomeView> {
  int _index = 0;

  static const _pages = [
    DemoEmployeeWorkspaceView(workspace: DemoEmployeeWorkspace.bpo),
    DemoEmployeeWorkspaceView(workspace: DemoEmployeeWorkspace.visitor),
  ];

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(DemoEmployeeWorkspace.values[_index].title),
      actions: const [
        Padding(
          padding: EdgeInsets.only(right: 12),
          child: Chip(label: Text('DEMO')),
        ),
      ],
    ),
    body: SafeArea(
      child: IndexedStack(index: _index, children: _pages),
    ),
    bottomNavigationBar: ResponsiveBottomNavigation(
      index: _index,
      onSelected: (index) => setState(() => _index = index),
      destinations: [
        for (final workspace in DemoEmployeeWorkspace.values)
          NavigationDestination(
            icon: Icon(workspace.icon),
            label: workspace.title,
          ),
      ],
    ),
  );
}

class DemoEmployeeWorkspaceView extends StatelessWidget {
  const DemoEmployeeWorkspaceView({super.key, required this.workspace});

  final DemoEmployeeWorkspace workspace;

  bool get _isBpo => workspace == DemoEmployeeWorkspace.bpo;

  @override
  Widget build(BuildContext context) {
    final metrics = _isBpo
        ? const [
            ('New leads', '12'),
            ('Follow-ups', '8'),
            ('Calls today', '24'),
          ]
        : const [
            ('Scheduled visits', '4'),
            ('Completed today', '2'),
            ('Updates needed', '1'),
          ];
    final records = _isBpo
        ? const [
            ('New enquiry', 'Sample customer · Follow up today'),
            ('Callback', 'Sample customer · Due at 2:30 PM'),
            ('Lead update', 'Sample customer · Recently assigned'),
          ]
        : const [
            ('Scheduled visit', 'Sample location · 10:30 AM'),
            ('In progress', 'Sample location · Update required'),
            ('Completed visit', 'Sample location · Today'),
          ];

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Image.asset(
                      'assets/images/app_logo_brand.png',
                      width: 150,
                      fit: BoxFit.contain,
                      semanticLabel: 'QB Suite logo',
                    ),
                    const Spacer(),
                    const Chip(label: Text('DEMO')),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Today at a glance',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            LayoutBuilder(
              builder: (context, constraints) {
                final columns = constraints.maxWidth >= 600 ? 3 : 1;
                final cardWidth =
                    (constraints.maxWidth - (columns - 1) * 12) / columns;
                return Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    for (final metric in metrics)
                      SizedBox(
                        width: cardWidth,
                        child: Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(metric.$1),
                                const SizedBox(height: 8),
                                Text(
                                  metric.$2,
                                  style: Theme.of(
                                    context,
                                  ).textTheme.headlineMedium,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
            const SizedBox(height: 24),
            Text(
              _isBpo ? 'Recent lead activity' : 'Today’s visits',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            for (final record in records)
              Card(
                child: ListTile(
                  leading: Icon(
                    _isBpo ? Remix.user_search_line : Remix.map_pin_line,
                    color: AppColors.primary,
                  ),
                  title: Text(record.$1),
                  subtitle: Text(record.$2),
                ),
              ),
            const SizedBox(height: 12),
            const Text(
              'This workspace uses local sample data. API calls are disabled.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}
