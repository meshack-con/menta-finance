import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

class LeadershipBadge extends StatelessWidget {
  final bool isLeader;
  const LeadershipBadge({super.key, required this.isLeader});

  @override
  Widget build(BuildContext context) {
    final color = isLeader ? AppColors.success : AppColors.neutralGray;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Text(
        isLeader ? 'Kiongozi' : 'Mwanachama',
        style: TextStyle(color: color, fontSize: 11.5, fontWeight: FontWeight.w600),
      ),
    );
  }
}
