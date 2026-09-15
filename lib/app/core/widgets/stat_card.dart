import 'package:flutter/material.dart';

class StatCard extends StatelessWidget {
  final String title;
  final String value;
  final String? subtitle;
  final IconData icon;
  final Color color;

  const StatCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    this.subtitle,
    this.color = const Color(0xFF008A3B),
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 1.5,
      shadowColor: color.withOpacity(0.15),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: color.withOpacity(0.18), width: 1),
      ),
      child: Column(
        children: [
          // 'Expanded' hapa ndiyo muhimu - inahakikisha eneo la maudhui
          // (icon + namba) LINAJAZA nafasi yote iliyobaki ya kadi (GridView
          // inalazimisha urefu fulani kwa kadi zote), badala ya
          // kuacha pengo tupu chini kabla ya mstari wa rangi.
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(13)),
                    alignment: Alignment.center,
                    child: Icon(icon, color: color),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(title, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                        const SizedBox(height: 3),
                        Text(value, style: const TextStyle(fontSize: 23, fontWeight: FontWeight.w900)),
                        if (subtitle != null) ...[
                          const SizedBox(height: 2),
                          Text(subtitle!, style: const TextStyle(fontSize: 10.5, color: Colors.grey)),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Mstari wa rangi - sasa UNASHIKAMANA na chini kabisa ya kadi.
          Container(height: 4, color: color),
        ],
      ),
    );
  }
}
