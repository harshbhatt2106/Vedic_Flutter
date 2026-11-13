import 'package:flutter/material.dart';
import '../../../../../app/theme/app_theme.dart';
import '../../../../../core/api/api_client.dart';
import '../../../../auth/data/models/auth_models.dart';
import '../dashboard/admin_dashboard_screen.dart';
import '../pending_requests/pending_requests_screen.dart';
import '../members/admin_members_screen.dart';
import '../activities/admin_activity_log_screen.dart';

class AdminShellScreen extends StatefulWidget {
  const AdminShellScreen({
    super.key,
    required this.apiClient,
    required this.session,
    required this.onSignOut,
  });

  final ApiClient apiClient;
  final AuthSession session;
  final Future<void> Function() onSignOut;

  @override
  State<AdminShellScreen> createState() => _AdminShellScreenState();
}

class _AdminShellScreenState extends State<AdminShellScreen> {
  String _selected = 'Dashboard';

  static const _modules = <_AdminModule>[
    _AdminModule('Dashboard', Icons.dashboard_outlined),
    _AdminModule('Profile Reviews', Icons.fact_check_outlined),
    _AdminModule('Members', Icons.groups_outlined),
    _AdminModule('Reports', Icons.flag_outlined),
    _AdminModule('Activity Log', Icons.history_outlined),
    _AdminModule('Mentors', Icons.support_agent_outlined),
    _AdminModule('Mentor Requests', Icons.assignment_ind_outlined),
    _AdminModule('Master Data', Icons.account_tree_outlined),
    _AdminModule('Subscription Plans', Icons.workspace_premium_outlined),
    _AdminModule('Privacy Policy', Icons.policy_outlined),
    _AdminModule('Success Stories', Icons.favorite_border),
    _AdminModule('Support', Icons.headset_mic_outlined),
    _AdminModule('Settings', Icons.settings_outlined),
    _AdminModule('My Profile', Icons.person_outline),
  ];

  void _select(String value) => setState(() => _selected = value);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppPalette.surface,
        foregroundColor: AppPalette.darkMaroon,
        elevation: 0,
        titleSpacing: 0,
        title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('VEDICVIVAH', style: TextStyle(fontFamily: 'sans-serif', fontSize: 10, letterSpacing: 2, color: AppPalette.gold, fontWeight: FontWeight.w700)),
          Text(_selected, style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w700, color: AppPalette.ink)),
        ]),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 14),
            child: CircleAvatar(
              radius: 17,
              backgroundColor: AppPalette.champagne,
              foregroundColor: AppPalette.maroon,
              child: Text(widget.session.userName.isEmpty ? 'A' : widget.session.userName.substring(0, 1).toUpperCase()),
            ),
          ),
        ],
      ),
      drawer: Drawer(
        backgroundColor: AppPalette.surface,
        child: SafeArea(
          child: Column(children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
              decoration: const BoxDecoration(
                gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [AppPalette.darkMaroon, AppPalette.maroon]),
              ),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Icon(Icons.temple_hindu_outlined, color: AppPalette.champagne, size: 30),
                const SizedBox(height: 12),
                const Text('VedicVivah', style: TextStyle(fontSize: 24, color: AppPalette.surface, fontWeight: FontWeight.w700)),
                const Text('ADMIN CONSOLE', style: TextStyle(fontFamily: 'sans-serif', color: AppPalette.champagne, letterSpacing: 2, fontSize: 10)),
                const SizedBox(height: 14),
                Text(widget.session.userName, style: const TextStyle(color: AppPalette.surface, fontWeight: FontWeight.w600)),
              ]),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 10),
                children: [
                  for (final module in _modules)
                    ListTile(
                      selected: _selected == module.label,
                      selectedTileColor: AppPalette.champagne.withValues(alpha: .5),
                      leading: Icon(module.icon, color: _selected == module.label ? AppPalette.maroon : AppPalette.secondary),
                      title: Text(module.label, style: TextStyle(fontFamily: 'sans-serif', fontSize: 13, fontWeight: _selected == module.label ? FontWeight.w700 : FontWeight.w500, color: AppPalette.ink)),
                      onTap: () {
                        Navigator.of(context).pop();
                        _select(module.label);
                      },
                    ),
                ],
              ),
            ),
            const Divider(color: AppPalette.border, height: 1),
            ListTile(
              leading: const Icon(Icons.logout, color: AppPalette.error),
              title: const Text('Sign out', style: TextStyle(fontFamily: 'sans-serif', color: AppPalette.error, fontWeight: FontWeight.w600)),
              onTap: () async {
                Navigator.of(context).pop();
                await widget.onSignOut();
              },
            ),
          ]),
        ),
      ),
      body: switch (_selected) {
        'Dashboard' => AdminDashboardScreen(
            key: const ValueKey('admin-dashboard'),
            apiClient: widget.apiClient,
            userName: widget.session.userName,
            onOpenModule: _select,
          ),
        'Profile Reviews' => PendingRequestsScreen(
            key: const ValueKey('admin-profile-reviews'),
            apiClient: widget.apiClient,
          ),
        'Members' => AdminMembersScreen(
            key: const ValueKey('admin-members'),
            apiClient: widget.apiClient,
          ),
        'Activity Log' => AdminActivityLogScreen(
            key: const ValueKey('admin-activity-log'),
            apiClient: widget.apiClient,
          ),
        _ => _ModuleNotImplementedScreen(module: _selected),
      },
    );
  }
}

class _AdminModule {
  const _AdminModule(this.label, this.icon);
  final String label;
  final IconData icon;
}

class _ModuleNotImplementedScreen extends StatelessWidget {
  const _ModuleNotImplementedScreen({required this.module});
  final String module;

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.construction_outlined, size: 42, color: AppPalette.gold),
            const SizedBox(height: 16),
            Text(module, style: Theme.of(context).textTheme.headlineMedium, textAlign: TextAlign.center),
            const SizedBox(height: 8),
            const Text(
              'This Admin module is recorded in the implementation audit and has not been built yet. No sample data or fake actions are shown.',
              textAlign: TextAlign.center,
              style: TextStyle(fontFamily: 'sans-serif', color: AppPalette.secondary, height: 1.5),
            ),
          ]),
        ),
      );
}
