import 'package:flutter/material.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../core/api/api_client.dart';
import '../../../auth/data/models/auth_models.dart';
import 'dashboard/user_dashboard_screen.dart';
import 'user_tools_screen.dart';
import 'user_interests_screen.dart';

class UserPanelShell extends StatefulWidget {
  const UserPanelShell({super.key, required this.apiClient, required this.session, required this.onSignOut});
  final ApiClient apiClient;
  final AuthSession session;
  final Future<void> Function() onSignOut;

  @override
  State<UserPanelShell> createState() => _UserPanelShellState();
}

class _UserPanelShellState extends State<UserPanelShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final pages = <Widget>[
      UserDashboardScreen(apiClient: widget.apiClient, session: widget.session, onSignOut: widget.onSignOut),
      UserToolsScreen(apiClient: widget.apiClient, kind: UserToolKind.notifications),
      UserToolsScreen(apiClient: widget.apiClient, kind: UserToolKind.shortlist),
      UserToolsScreen(apiClient: widget.apiClient, kind: UserToolKind.blocked),
      UserToolsScreen(apiClient: widget.apiClient, kind: UserToolKind.reports),
      UserInterestsScreen(apiClient: widget.apiClient),
    ];
    return Scaffold(
      backgroundColor: AppPalette.background,
      body: IndexedStack(index: _index, children: pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (value) => setState(() => _index = value),
        backgroundColor: AppPalette.surface,
        indicatorColor: AppPalette.champagne,
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.notifications_none), selectedIcon: Icon(Icons.notifications), label: 'Updates'),
          NavigationDestination(icon: Icon(Icons.favorite_border), selectedIcon: Icon(Icons.favorite), label: 'Shortlist'),
          NavigationDestination(icon: Icon(Icons.block_outlined), selectedIcon: Icon(Icons.block), label: 'Blocked'),
          NavigationDestination(icon: Icon(Icons.flag_outlined), selectedIcon: Icon(Icons.flag), label: 'Reports'),
          NavigationDestination(icon: Icon(Icons.favorite_outline), selectedIcon: Icon(Icons.favorite), label: 'Interests'),
        ],
      ),
    );
  }
}
