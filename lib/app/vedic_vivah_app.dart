import 'package:flutter/material.dart';

import '../core/api/api_client.dart';
import '../core/storage/session_store.dart';
import '../features/auth/data/repositories/auth_repository.dart';
import '../features/auth/data/services/auth_api_service.dart';
import '../features/auth/presentation/screens/auth_gate.dart';
import '../features/auth/presentation/screens/forgot_password_screen.dart';
import '../features/auth/presentation/screens/login_screen.dart';
import '../features/auth/presentation/screens/registration_screen.dart';
import 'theme/app_theme.dart';

class VedicVivahApp extends StatefulWidget {
  const VedicVivahApp({super.key});

  @override
  State<VedicVivahApp> createState() => _VedicVivahAppState();
}

class _VedicVivahAppState extends State<VedicVivahApp> {
  late final ApiClient _apiClient;
  late final AuthRepository _authRepository;

  @override
  void initState() {
    super.initState();
    _apiClient = ApiClient();
    _authRepository = AuthRepository(AuthApiService(_apiClient), SessionStore.instance);
  }

  @override
  void dispose() {
    _apiClient.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'VedicVivah',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        initialRoute: '/',
        routes: {
          '/': (_) => AuthGate(repository: _authRepository),
          '/login': (_) => LoginScreen(repository: _authRepository),
          '/register': (_) => RegistrationScreen(repository: _authRepository),
          '/forgot-password': (_) => ForgotPasswordScreen(repository: _authRepository),
        },
      );
}
