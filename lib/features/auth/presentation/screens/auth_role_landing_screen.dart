import 'package:flutter/material.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../core/api/api_client.dart';
import '../../../admin/presentation/pages/shell/admin_shell_screen.dart';
import '../../../user/presentation/pages/dashboard/user_dashboard_screen.dart';
import '../../data/models/auth_models.dart';
import '../../data/repositories/auth_repository.dart';
import 'login_screen.dart';

class AuthRoleLandingScreen extends StatelessWidget {
  const AuthRoleLandingScreen({
    super.key,
    required this.repository,
    required this.apiClient,
    required this.session,
  });

  final AuthRepository repository;
  final ApiClient apiClient;
  final AuthSession session;

  Future<void> _signOut(BuildContext context) async {
    await repository.logout();
    if (!context.mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => LoginScreen(repository: repository, apiClient: apiClient)),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (session.role == 'User') {
      return UserDashboardScreen(
        apiClient: apiClient,
        session: session,
        onSignOut: () => _signOut(context),
      );
    }

    if (session.role == 'Admin') {
      return AdminShellScreen(
        apiClient: apiClient,
        session: session,
        onSignOut: () => _signOut(context),
      );
    }

    return Scaffold(
      backgroundColor: AppPalette.background,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.verified_user_outlined, size: 52, color: AppPalette.gold),
                const SizedBox(height: 22),
                Text('Welcome, ${session.userName}', textAlign: TextAlign.center, style: Theme.of(context).textTheme.headlineMedium),
                const SizedBox(height: 10),
                Text('You are securely signed in as ${session.role}.', textAlign: TextAlign.center),
                const SizedBox(height: 28),
                const Text('Mentor Dashboard', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600)),
                const SizedBox(height: 10),
                const Text('The Mentor mobile area is not part of this Admin implementation stage.', textAlign: TextAlign.center),
                const SizedBox(height: 28),
                OutlinedButton(onPressed: () => _signOut(context), child: const Text('Sign out')),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
