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

class RegistrationScreen extends StatefulWidget {
  const RegistrationScreen({super.key, required this.repository});
  final AuthRepository repository;
  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  final _userName = TextEditingController(), _email = TextEditingController(), _phone = TextEditingController(), _password = TextEditingController(), _otp = TextEditingController();
  String? _registrationId, _error, _info;
  bool _loading = false, _resending = false, _showPassword = false, _verified = false;
  int _cooldown = 0, _resendCount = 0;
  Timer? _timer;

  @override
  void dispose() {
    _timer?.cancel();
    _userName.dispose(); _email.dispose(); _phone.dispose(); _password.dispose(); _otp.dispose();
    super.dispose();
  }

  void _startCooldown() {
    _timer?.cancel();
    setState(() => _cooldown = 60);
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      if (_cooldown <= 1) { timer.cancel(); setState(() => _cooldown = 0); }
      else { setState(() => _cooldown--); }
    });
  }

  Future<void> _register() async {
    FocusScope.of(context).unfocus();
    if (_loading) return;
    final errors = <String>[
      if (AuthValidation.userName(_userName.text) != null) AuthValidation.userName(_userName.text)!,
      if (AuthValidation.mobile(_phone.text) != null) AuthValidation.mobile(_phone.text)!,
      if (AuthValidation.email(_email.text) != null) AuthValidation.email(_email.text)!,
      if (AuthValidation.password(_password.text) != null) AuthValidation.password(_password.text)!,
    ];
    if (errors.isNotEmpty) { setState(() => _error = errors.join('\n')); return; }
    setState(() { _loading = true; _error = null; _info = null; });
    try {
      final result = await widget.repository.beginRegistration(
        userName: _userName.text.trim().toLowerCase(),
        email: _email.text.trim(),
        phoneNumber: _phone.text,
        password: _password.text,
      );
      if (!mounted) return;
      setState(() { _registrationId = result.registrationId; _otp.clear(); _resendCount = 0; _info = result.message; });
      _startCooldown();
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = error is ApiException ? error.message : error.toString().replaceFirst('FormatException: ', ''));
    } finally { if (mounted) setState(() => _loading = false); }
  }

  Future<void> _verify() async {
    if (_loading || _verified || _registrationId == null) return;
    final validation = AuthValidation.otp(_otp.text);
    if (validation != null) { setState(() => _error = validation); return; }
    FocusScope.of(context).unfocus();
    setState(() { _loading = true; _error = null; _info = null; });
    try {
      await widget.repository.verifyEmail(registrationId: _registrationId!, otp: _otp.text);
      if (!mounted) return;
      setState(() { _verified = true; _info = 'Your email has been verified and your account is active.'; });
      await Future<void>.delayed(const Duration(milliseconds: 900));
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (_) => LoginScreen(repository: widget.repository)), (_) => false);
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = error is ApiException ? error.message : error.toString().replaceFirst('FormatException: ', ''));
    } finally { if (mounted) setState(() => _loading = false); }
  }

  Future<void> _resend() async {
    if (_registrationId == null || _resending || _loading || _verified || _cooldown > 0 || _resendCount >= 3) return;
    setState(() { _resending = true; _error = null; _info = null; });
    try {
      final message = await widget.repository.resendEmailOtp(_registrationId!);
      if (!mounted) return;
      setState(() { _otp.clear(); _resendCount++; _info = message; });
      _startCooldown();
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = error is ApiException ? error.message : error.toString().replaceFirst('FormatException: ', ''));
    } finally { if (mounted) setState(() => _resending = false); }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppPalette.background,
    appBar: AppBar(backgroundColor: AppPalette.background, elevation: 0, leading: IconButton(icon: const Icon(Icons.arrow_back_rounded, color: AppPalette.darkMaroon), onPressed: _loading ? null : () => Navigator.of(context).maybePop())),
    body: SafeArea(child: Center(child: SingleChildScrollView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: const EdgeInsets.fromLTRB(22, 8, 22, 30),
      child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 460), child: Container(
        padding: const EdgeInsets.all(26),
        decoration: BoxDecoration(color: AppPalette.surface, borderRadius: BorderRadius.circular(24), border: Border.all(color: AppPalette.border), boxShadow: [BoxShadow(color: AppPalette.darkMaroon.withValues(alpha: .05), blurRadius: 30, offset: const Offset(0, 14))]),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          AuthBrandHeader(eyebrow: _registrationId == null ? 'Your details' : 'Email verification', title: _registrationId == null ? 'A meaningful\nbeginning.' : 'Verify your\nemail address.', subtitle: _registrationId == null ? 'Create your VedicVivah account with the details below.' : 'Enter the six-digit verification code sent to your registered email address.'),
          const SizedBox(height: 24),
          _StepIndicator(verified: _verified, otpStep: _registrationId != null),
          const SizedBox(height: 22),
          if (_error != null) ...[AuthFeedback(message: _error!), const SizedBox(height: 16)],
          if (_info != null) ...[AuthFeedback(message: _info!, isSuccess: _verified), const SizedBox(height: 16)],
          if (_registrationId == null) _detailsForm() else _otpForm(),
        ]),
      )),
    ))),
  );

  Widget _detailsForm() => Column(children: [
    AuthTextField(controller: _userName, label: 'USERNAME', hint: 'Choose a unique username', prefixIcon: Icons.person_outline_rounded, textInputAction: TextInputAction.next, autofillHints: const [AutofillHints.newUsername], errorText: _userName.text.isEmpty ? null : AuthValidation.userName(_userName.text), onChanged: (_) => setState(() {})),
    const SizedBox(height: 15),
    AuthTextField(controller: _phone, label: 'MOBILE NUMBER', hint: '10-digit mobile number', prefixIcon: Icons.phone_outlined, keyboardType: TextInputType.phone, textInputAction: TextInputAction.next, maxLength: 10, errorText: _phone.text.isEmpty ? null : AuthValidation.mobile(_phone.text), onChanged: (value) {
      final digits = value.replaceAll(RegExp(r'\D'), '');
      if (digits != value) _phone.value = TextEditingValue(text: digits.length > 10 ? digits.substring(0, 10) : digits, selection: TextSelection.collapsed(offset: digits.length.clamp(0, 10).toInt()));
      setState(() {});
    }),
    const SizedBox(height: 15),
    AuthTextField(controller: _email, label: 'EMAIL ADDRESS', hint: 'Enter your email address', prefixIcon: Icons.mail_outline_rounded, keyboardType: TextInputType.emailAddress, textInputAction: TextInputAction.next, autofillHints: const [AutofillHints.email], errorText: _email.text.isEmpty ? null : AuthValidation.email(_email.text), onChanged: (_) => setState(() {})),
    const SizedBox(height: 15),
    AuthTextField(controller: _password, label: 'PASSWORD', hint: 'Minimum 8 characters', prefixIcon: Icons.lock_outline_rounded, obscureText: !_showPassword, textInputAction: TextInputAction.done, errorText: _password.text.isEmpty ? null : AuthValidation.password(_password.text), onChanged: (_) => setState(() {}), suffix: IconButton(onPressed: () => setState(() => _showPassword = !_showPassword), icon: Icon(_showPassword ? Icons.visibility_off_outlined : Icons.visibility_outlined, color: AppPalette.secondary))),
    const SizedBox(height: 22),
    SizedBox(width: double.infinity, child: ElevatedButton(onPressed: _loading ? null : _register, child: _loading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: AppPalette.champagne)) : const Text('CREATE ACCOUNT'))),
    const SizedBox(height: 18),
    _loginLink(),
  ]);

  Widget _otpForm() => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    TextField(
      controller: _otp, enabled: !_loading && !_verified, keyboardType: TextInputType.number, textInputAction: TextInputAction.done,
      autofillHints: const [AutofillHints.oneTimeCode], inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(6)],
      textAlign: TextAlign.center, style: const TextStyle(fontFamily: 'sans-serif', fontSize: 25, letterSpacing: 12, fontWeight: FontWeight.w700, color: AppPalette.darkMaroon),
      decoration: const InputDecoration(labelText: '6-DIGIT EMAIL OTP', hintText: '••••••'),
      onChanged: (_) { if (_error != null) setState(() => _error = null); },
    ),
    const SizedBox(height: 18),
    SizedBox(width: double.infinity, child: ElevatedButton(onPressed: _loading || _verified ? null : _verify, child: _loading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: AppPalette.champagne)) : Text(_verified ? 'EMAIL VERIFIED' : 'VERIFY EMAIL'))),
    const SizedBox(height: 10),
    Center(child: TextButton(onPressed: _resending || _loading || _verified || _cooldown > 0 || _resendCount >= 3 ? null : _resend, child: Text(_resendCount >= 3 ? 'Maximum 3 resends reached' : _cooldown > 0 ? 'Resend code in ${_cooldown}s' : _resending ? 'Requesting new code…' : 'Resend verification code'))),
    Center(child: Text('Check your spam or promotions folder if needed.', style: Theme.of(context).textTheme.bodyMedium, textAlign: TextAlign.center)),
    const SizedBox(height: 12),
    Center(child: TextButton(onPressed: _loading || _verified ? null : () => setState(() { _registrationId = null; _error = null; _info = null; _timer?.cancel(); _cooldown = 0; }), child: const Text('Edit registration details'))),
  ]);

  Widget _loginLink() => Wrap(alignment: WrapAlignment.center, children: [
    const Text('Already registered? ', style: TextStyle(fontFamily: 'sans-serif', color: AppPalette.secondary, fontSize: 13)),
    GestureDetector(onTap: () => Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => LoginScreen(repository: widget.repository))), child: const Text('Sign in', style: TextStyle(fontFamily: 'sans-serif', color: AppPalette.maroon, fontWeight: FontWeight.w700, fontSize: 13))),
  ]);
}

class _StepIndicator extends StatelessWidget {
  const _StepIndicator({required this.verified, required this.otpStep});
  final bool verified, otpStep;
  @override
  Widget build(BuildContext context) => Row(children: [
    _StepDot(number: '01', label: 'DETAILS', active: !otpStep, complete: otpStep),
    Expanded(child: Container(height: 1, color: AppPalette.border)),
    _StepDot(number: '02', label: 'VERIFY', active: otpStep && !verified, complete: verified),
  ]);
}

class _StepDot extends StatelessWidget {
  const _StepDot({required this.number, required this.label, required this.active, required this.complete});
  final String number, label;
  final bool active, complete;
  @override
  Widget build(BuildContext context) => Row(children: [
    Container(width: 28, height: 28, decoration: BoxDecoration(shape: BoxShape.circle, color: active || complete ? AppPalette.maroon : AppPalette.surface, border: Border.all(color: active || complete ? AppPalette.maroon : AppPalette.border)), child: Center(child: complete ? const Icon(Icons.check, color: AppPalette.champagne, size: 16) : Text(number, style: TextStyle(fontFamily: 'sans-serif', fontSize: 9, fontWeight: FontWeight.w700, color: active ? AppPalette.champagne : AppPalette.secondary)))),
    const SizedBox(width: 7),
    Text(label, style: TextStyle(fontFamily: 'sans-serif', fontSize: 9, letterSpacing: 1, fontWeight: FontWeight.w700, color: active || complete ? AppPalette.darkMaroon : AppPalette.secondary)),
    const SizedBox(width: 8),
  ]);
}
