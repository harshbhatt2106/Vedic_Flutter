import 'package:flutter/material.dart';
import '../../data/models/auth_models.dart';
import '../../data/repositories/auth_repository.dart';
import 'login_screen.dart';

class AuthRoleLandingScreen extends StatelessWidget {
  const AuthRoleLandingScreen({super.key, required this.repository, required this.session});
  final AuthRepository repository;
  final AuthSession session;

  String get destination => switch (session.role) {
    'Admin' => 'Admin Dashboard',
    'Mentor' => 'Mentor Dashboard',
    _ => 'User Dashboard',
  };

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFFF7F1E8),
    body: SafeArea(child: Center(child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 440),
      child: Padding(padding: const EdgeInsets.all(28), child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.verified_user_outlined, size: 52, color: Color(0xFFB68A55)),
          const SizedBox(height: 22),
          Text('Welcome, ${session.userName}', textAlign: TextAlign.center, style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 10),
          Text('You are securely signed in as ${session.role}.', textAlign: TextAlign.center),
          const SizedBox(height: 28),
          Text(destination, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 10),
          const Text('Authentication is connected. The role-specific mobile dashboard is separate feature work.', textAlign: TextAlign.center, style: TextStyle(color: Color(0xFF82736C), height: 1.5)),
          const SizedBox(height: 28),
          OutlinedButton(
            onPressed: () async {
              await repository.logout();
              if (!context.mounted) return;
              Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (_) => LoginScreen(repository: repository)), (_) => false);
            },
            child: const Text('Sign out'),
          ),
        ],
      )),
    ))),
  );
}
