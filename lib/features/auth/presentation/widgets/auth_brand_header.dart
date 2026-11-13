import 'package:flutter/material.dart';
import '../../../../app/theme/app_theme.dart';

class AuthBrandHeader extends StatelessWidget {
  const AuthBrandHeader({super.key, required this.eyebrow, required this.title, required this.subtitle});
  final String eyebrow, title, subtitle;

  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Row(children: [
      Container(width: 42, height: 42, decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: AppPalette.gold, width: 1.2)), child: const Icon(Icons.favorite_border_rounded, color: AppPalette.maroon, size: 20)),
      const SizedBox(width: 12),
      const Text('VEDICVIVAH', style: TextStyle(color: AppPalette.darkMaroon, fontFamily: 'serif', fontWeight: FontWeight.w700, letterSpacing: 2.5, fontSize: 16)),
    ]),
    const SizedBox(height: 30),
    Row(children: [Container(width: 28, height: 1, color: AppPalette.gold), const SizedBox(width: 10), Text(eyebrow.toUpperCase(), style: const TextStyle(fontFamily: 'sans-serif', fontSize: 10, letterSpacing: 2, fontWeight: FontWeight.w700, color: AppPalette.gold))]),
    const SizedBox(height: 12),
    Text(title, style: Theme.of(context).textTheme.headlineLarge),
    const SizedBox(height: 9),
    Text(subtitle, style: const TextStyle(fontFamily: 'sans-serif', color: AppPalette.secondary, fontSize: 14, height: 1.55)),
  ]);
}
