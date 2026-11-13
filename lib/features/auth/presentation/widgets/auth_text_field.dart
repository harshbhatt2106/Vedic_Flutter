import 'package:flutter/material.dart';
import '../../../../app/theme/app_theme.dart';

class AuthTextField extends StatelessWidget {
  const AuthTextField({super.key, required this.controller, required this.label, required this.hint, this.errorText, this.keyboardType, this.textInputAction, this.obscureText = false, this.prefixIcon, this.suffix, this.onChanged, this.autofillHints, this.maxLength, this.enabled = true});
  final TextEditingController controller;
  final String label, hint;
  final String? errorText;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final bool obscureText, enabled;
  final IconData? prefixIcon;
  final Widget? suffix;
  final ValueChanged<String>? onChanged;
  final Iterable<String>? autofillHints;
  final int? maxLength;

  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Text(label, style: const TextStyle(fontFamily: 'sans-serif', fontSize: 12, fontWeight: FontWeight.w600, color: AppPalette.secondary)),
    const SizedBox(height: 8),
    TextField(
      controller: controller, enabled: enabled, keyboardType: keyboardType, textInputAction: textInputAction,
      obscureText: obscureText, autofillHints: autofillHints, maxLength: maxLength, onChanged: onChanged,
      style: const TextStyle(fontFamily: 'sans-serif', fontSize: 15, color: AppPalette.ink),
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: prefixIcon == null ? null : Icon(prefixIcon, size: 19, color: AppPalette.gold),
        suffixIcon: suffix, errorText: errorText, counterText: '',
      ),
    ),
  ]);
}
