import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

class StatusBadge extends StatelessWidget {
  final String text;
  final Color color;

  const StatusBadge(this.text, {super.key, this.color = AppColors.success});

  factory StatusBadge.active(bool isActive) =>
      StatusBadge(isActive ? 'Hai' : 'Amezuiwa', color: isActive ? AppColors.success : AppColors.danger);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Text(text, style: TextStyle(color: color, fontSize: 11.5, fontWeight: FontWeight.w600)),
    );
  }
}
