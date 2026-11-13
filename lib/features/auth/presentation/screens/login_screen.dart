import 'package:flutter/material.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../core/errors/api_exception.dart';
import '../../data/repositories/auth_repository.dart';
import '../../domain/auth_validation.dart';
import '../widgets/auth_brand_header.dart';
import '../widgets/auth_feedback.dart';
import '../widgets/auth_text_field.dart';
import 'auth_role_landing_screen.dart';
import 'forgot_password_screen.dart';
import 'registration_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key, required this.repository});
  final AuthRepository repository;
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _identifier = TextEditingController(), _password = TextEditingController();
  String? _identifierError, _passwordError, _error;
  bool _showPassword = false, _rememberMe = false, _loading = false;

  @override
  void dispose() { _identifier.dispose(); _password.dispose(); super.dispose(); }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (_loading) return;
    final identifierError = AuthValidation.loginIdentifier(_identifier.text);
    final passwordError = AuthValidation.loginPassword(_password.text);
    setState(() { _identifierError = identifierError; _passwordError = passwordError; _error = null; });
    if (identifierError != null || passwordError != null) return;
    setState(() => _loading = true);
    try {
      final session = await widget.repository.login(identifier: _identifier.text.trim(), password: _password.text, rememberMe: _rememberMe);
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (_) => AuthRoleLandingScreen(repository: widget.repository, session: session)), (_) => false);
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = error is ApiException ? error.message : error.toString().replaceFirst('FormatException: ', ''));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppPalette.background,
    body: SafeArea(child: LayoutBuilder(builder: (context, constraints) => Center(
      child: SingleChildScrollView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 26),
        child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 460), child: Container(
          padding: EdgeInsets.all(constraints.maxWidth < 390 ? 22 : 30),
          decoration: BoxDecoration(color: AppPalette.surface, borderRadius: BorderRadius.circular(24), border: Border.all(color: AppPalette.border), boxShadow: [BoxShadow(color: AppPalette.darkMaroon.withValues(alpha: .055), blurRadius: 35, offset: const Offset(0, 15))]),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const AuthBrandHeader(eyebrow: 'A trusted matrimonial space', title: 'Welcome\nback.', subtitle: 'Continue your journey toward a meaningful connection, guided by tradition and protected with care.'),
            const SizedBox(height: 28),
            if (_error != null) ...[AuthFeedback(message: _error!), const SizedBox(height: 18)],
            AuthTextField(controller: _identifier, label: 'EMAIL OR MOBILE NUMBER', hint: 'you@example.com or 98XXXXXXXX', prefixIcon: Icons.person_outline_rounded, keyboardType: TextInputType.emailAddress, textInputAction: TextInputAction.next, autofillHints: const [AutofillHints.username], errorText: _identifierError, onChanged: (_) => setState(() { _identifierError = null; _error = null; })),
            const SizedBox(height: 18),
            AuthTextField(controller: _password, label: 'PASSWORD', hint: 'Enter your password', prefixIcon: Icons.lock_outline_rounded, obscureText: !_showPassword, textInputAction: TextInputAction.done, autofillHints: const [AutofillHints.password], errorText: _passwordError, onChanged: (_) => setState(() { _passwordError = null; _error = null; }), suffix: IconButton(tooltip: _showPassword ? 'Hide password' : 'Show password', onPressed: () => setState(() => _showPassword = !_showPassword), icon: Icon(_showPassword ? Icons.visibility_off_outlined : Icons.visibility_outlined, color: AppPalette.secondary, size: 20))),
            Align(alignment: Alignment.centerRight, child: TextButton(onPressed: _loading ? null : () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => ForgotPasswordScreen(repository: widget.repository))), child: const Text('Forgot password?'))),
            CheckboxListTile(value: _rememberMe, onChanged: _loading ? null : (value) => setState(() => _rememberMe = value ?? false), contentPadding: EdgeInsets.zero, controlAffinity: ListTileControlAffinity.leading, dense: true, activeColor: AppPalette.maroon, title: const Text('Keep me signed in on this device', style: TextStyle(fontFamily: 'sans-serif', fontSize: 13, color: AppPalette.secondary))),
            const SizedBox(height: 12),
            SizedBox(width: double.infinity, child: ElevatedButton(onPressed: _loading ? null : _submit, child: _loading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: AppPalette.champagne)) : const Row(mainAxisAlignment: MainAxisAlignment.center, children: [Text('SIGN IN'), SizedBox(width: 10), Icon(Icons.arrow_forward_rounded, size: 18)]))),
            const SizedBox(height: 22),
            Center(child: Wrap(alignment: WrapAlignment.center, children: [
              const Text('New to VedicVivah? ', style: TextStyle(fontFamily: 'sans-serif', color: AppPalette.secondary, fontSize: 13)),
              GestureDetector(onTap: _loading ? null : () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => RegistrationScreen(repository: widget.repository))), child: const Text('Create your account', style: TextStyle(fontFamily: 'sans-serif', color: AppPalette.maroon, fontSize: 13, fontWeight: FontWeight.w700))),
            ])),
            const SizedBox(height: 20),
            const Divider(color: AppPalette.border),
            const SizedBox(height: 12),
            const Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.shield_outlined, size: 15, color: AppPalette.gold), SizedBox(width: 8), Flexible(child: Text('SECURE SIGN-IN  ·  YOUR PRIVACY IS PROTECTED', textAlign: TextAlign.center, style: TextStyle(fontFamily: 'sans-serif', fontSize: 9, letterSpacing: 1, color: AppPalette.secondary)))]),
          ]),
        )),
      ),
    ))),
  );
}
