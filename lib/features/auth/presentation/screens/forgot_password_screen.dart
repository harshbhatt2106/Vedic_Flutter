import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../core/errors/api_exception.dart';
import '../../data/repositories/auth_repository.dart';
import '../../domain/auth_validation.dart';
import '../widgets/auth_brand_header.dart';
import '../widgets/auth_feedback.dart';
import '../widgets/auth_text_field.dart';
import 'login_screen.dart';

enum _RecoveryStep { email, otp, password, success }

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key, required this.repository});
  final AuthRepository repository;
  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _email = TextEditingController(), _otp = TextEditingController(), _password = TextEditingController(), _confirm = TextEditingController();
  _RecoveryStep _step = _RecoveryStep.email;
  String? _requestId, _error, _info;
  bool _loading = false, _showPassword = false, _showConfirm = false;
  int _cooldown = 0;
  Timer? _timer;

  @override
  void dispose() { _timer?.cancel(); _email.dispose(); _otp.dispose(); _password.dispose(); _confirm.dispose(); super.dispose(); }

  void _startCooldown() {
    _timer?.cancel();
    setState(() => _cooldown = 60);
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      if (_cooldown <= 1) { timer.cancel(); setState(() => _cooldown = 0); }
      else { setState(() => _cooldown--); }
    });
  }

  Future<void> _run(Future<void> Function() action) async {
    if (_loading) return;
    FocusScope.of(context).unfocus();
    setState(() { _loading = true; _error = null; _info = null; });
    try { await action(); }
    catch (error) {
      _error = error is ApiException ? error.message : error.toString().replaceFirst('FormatException: ', '');
    } finally { if (mounted) setState(() => _loading = false); }
  }

  Future<void> _sendEmail() async {
    final error = AuthValidation.email(_email.text);
    if (error != null) { setState(() => _error = error); return; }
    await _run(() async {
      final result = await widget.repository.forgotPassword(_email.text.trim().toLowerCase());
      _requestId = result.resetRequestId;
      _otp.clear();
      _info = 'If an active account exists for this email, a 6-digit OTP has been sent.';
      _step = _RecoveryStep.otp;
      _startCooldown();
    });
  }

  Future<void> _verifyOtp() async {
    final error = AuthValidation.otp(_otp.text);
    if (error != null) { setState(() => _error = error); return; }
    await _run(() async {
      await widget.repository.verifyPasswordResetOtp(resetRequestId: _requestId!, otp: _otp.text);
      _step = _RecoveryStep.password;
      _info = 'OTP verified. Create your new password.';
    });
  }

  Future<void> _resendOtp() async {
    if (_requestId == null || _cooldown > 0 || _loading) return;
    await _run(() async {
      _info = await widget.repository.resendPasswordResetOtp(_requestId!);
      _otp.clear();
      _startCooldown();
    });
  }

  Future<void> _resetPassword() async {
    final p = AuthValidation.password(_password.text);
    final c = AuthValidation.confirmPassword(_confirm.text, _password.text);
    if (p != null || c != null) { setState(() => _error = p ?? c); return; }
    await _run(() async {
      await widget.repository.resetPassword(resetRequestId: _requestId!, newPassword: _password.text);
      _step = _RecoveryStep.success;
      _info = 'Your password has been reset. You can now sign in.';
    });
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppPalette.background,
    appBar: AppBar(backgroundColor: AppPalette.background, elevation: 0, leading: IconButton(
      onPressed: _loading ? null : () {
        if (_step == _RecoveryStep.email || _step == _RecoveryStep.success) { Navigator.of(context).pop(); return; }
        setState(() {
          _error = null; _info = null;
          _step = _step == _RecoveryStep.password ? _RecoveryStep.otp : _RecoveryStep.email;
          if (_step == _RecoveryStep.email) { _requestId = null; _timer?.cancel(); _cooldown = 0; }
        });
      },
      icon: const Icon(Icons.arrow_back_rounded, color: AppPalette.darkMaroon),
    )),
    body: SafeArea(child: Center(child: SingleChildScrollView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: const EdgeInsets.fromLTRB(22, 8, 22, 28),
      child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 460), child: Container(
        padding: const EdgeInsets.all(26),
        decoration: BoxDecoration(color: AppPalette.surface, borderRadius: BorderRadius.circular(24), border: Border.all(color: AppPalette.border)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          AuthBrandHeader(eyebrow: 'Private account recovery', title: switch (_step) {
            _RecoveryStep.email => 'Recover your\naccount.',
            _RecoveryStep.otp => 'Verify your\nemail.',
            _RecoveryStep.password => 'Choose a new\npassword.',
            _RecoveryStep.success => 'All set.',
          }, subtitle: switch (_step) {
            _RecoveryStep.email => 'Enter the email address linked to your VedicVivah account.',
            _RecoveryStep.otp => 'Enter the six-digit code sent to your email.',
            _RecoveryStep.password => 'Create a new password to secure your account.',
            _RecoveryStep.success => 'Your password has been updated successfully.',
          }),
          const SizedBox(height: 24),
          if (_error != null) ...[AuthFeedback(message: _error!), const SizedBox(height: 14)],
          if (_info != null) ...[AuthFeedback(message: _info!, isSuccess: _step == _RecoveryStep.success), const SizedBox(height: 14)],
          if (_step == _RecoveryStep.email) ...[
            AuthTextField(controller: _email, label: 'EMAIL ADDRESS', hint: 'Enter your registered email', prefixIcon: Icons.mail_outline, keyboardType: TextInputType.emailAddress, autofillHints: const [AutofillHints.email]),
            const SizedBox(height: 20), _action('SEND OTP', _sendEmail),
          ] else if (_step == _RecoveryStep.otp) ...[
            AuthTextField(controller: _otp, label: '6-DIGIT OTP', hint: 'Enter verification code', prefixIcon: Icons.password_outlined, keyboardType: TextInputType.number, autofillHints: const [AutofillHints.oneTimeCode], maxLength: 6, onChanged: (value) {
              final digits = value.replaceAll(RegExp(r'\D'), '');
              if (digits != value) _otp.value = TextEditingValue(text: digits.length > 6 ? digits.substring(0, 6) : digits, selection: TextSelection.collapsed(offset: digits.length.clamp(0, 6).toInt()));
            }),
            const SizedBox(height: 16), _action('VERIFY OTP', _verifyOtp),
            Center(child: TextButton(onPressed: _loading || _cooldown > 0 ? null : _resendOtp, child: Text(_cooldown > 0 ? 'Resend code in ${_cooldown}s' : 'Resend OTP'))),
          ] else if (_step == _RecoveryStep.password) ...[
            AuthTextField(controller: _password, label: 'NEW PASSWORD', hint: 'Minimum 8 characters', obscureText: !_showPassword, suffix: IconButton(onPressed: () => setState(() => _showPassword = !_showPassword), icon: Icon(_showPassword ? Icons.visibility_off_outlined : Icons.visibility_outlined))),
            const SizedBox(height: 15),
            AuthTextField(controller: _confirm, label: 'CONFIRM NEW PASSWORD', hint: 'Re-enter new password', obscureText: !_showConfirm, suffix: IconButton(onPressed: () => setState(() => _showConfirm = !_showConfirm), icon: Icon(_showConfirm ? Icons.visibility_off_outlined : Icons.visibility_outlined))),
            const SizedBox(height: 20), _action('RESET PASSWORD', _resetPassword),
          ] else ...[
            const Icon(Icons.check_circle_outline, color: Color(0xFF356B4A), size: 42),
            const SizedBox(height: 18),
            _action('RETURN TO SIGN IN', () async {
              Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (_) => LoginScreen(repository: widget.repository)), (_) => false);
            }),
          ],
        ]),
      )),
    ))),
  );

  Widget _action(String label, Future<void> Function() action) => SizedBox(width: double.infinity, child: ElevatedButton(
    onPressed: _loading ? null : () => action(),
    child: _loading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: AppPalette.champagne)) : Text(label),
  ));
}
