import 'package:flutter/material.dart';
import '../../../../app/theme/app_theme.dart';

class AuthFeedback extends StatelessWidget {
  const AuthFeedback({super.key, required this.message, this.isSuccess = false});
  final String message;
  final bool isSuccess;

  @override
  Widget build(BuildContext context) {
    final color = isSuccess ? const Color(0xFF356B4A) : AppPalette.error;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(color: color.withValues(alpha: .07), border: Border.all(color: color.withValues(alpha: .25)), borderRadius: BorderRadius.circular(12)),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(isSuccess ? Icons.check_circle_outline : Icons.info_outline, color: color, size: 18),
        const SizedBox(width: 10),
        Expanded(child: Text(message, style: TextStyle(fontFamily: 'sans-serif', color: color, fontSize: 13, height: 1.4))),
      ]),
    );
  }
}
