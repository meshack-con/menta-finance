import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Widget ya pamoja ya "hakuna data/imeshindikana kupakia" kwa Admin -
/// muundo unaofanana na Mobile (icon kwenye duara laini + Kichwa + Maelezo
/// + kitufe cha hiari), rangi za brand (kijani) badala ya zambarau.
class EmptyStateWidget extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;
  final bool isError;

  const EmptyStateWidget({
    super.key,
    this.icon = Icons.inbox_outlined,
    required this.title,
    this.subtitle,
    this.actionLabel,
    this.onAction,
    this.isError = false,
  });

  @override
  Widget build(BuildContext context) {
    final accent = isError ? AppColors.danger : AppColors.primaryGreen;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(color: accent.withOpacity(0.10), shape: BoxShape.circle),
              child: Icon(icon, size: 42, color: accent),
            ),
            const SizedBox(height: 18),
            Text(title, textAlign: TextAlign.center, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
            if (subtitle != null) ...[
              const SizedBox(height: 6),
              Text(subtitle!, textAlign: TextAlign.center, style: const TextStyle(fontSize: 12.5, color: AppColors.textSecondary, height: 1.4)),
            ],
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 18),
              ElevatedButton(onPressed: onAction, child: Text(actionLabel!)),
            ],
          ],
        ),
      ),
    );
  }
}
