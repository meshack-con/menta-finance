import 'package:flutter/material.dart';

/// Header ndogo ya kila ukurasa - jina kubwa + maelezo mafupi ya kijivu.
/// Inatoa muktadha (badala ya ukurasa "kutupwa" moja kwa moja kwenye jedwali).
class PageHeader extends StatelessWidget {
  final String title;
  final String subtitle;

  const PageHeader({super.key, required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
        const SizedBox(height: 4),
        Text(subtitle, style: const TextStyle(color: Colors.grey, fontSize: 13)),
      ],
    );
  }
}
