import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../core/data/client_project_store.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_shell.dart';
import '../../../core/widgets/page_header.dart';

// Kiumbizi cha fedha kinachotumika humu (sawa na kwenye Dashboard/Projects).
String _fmtMoney(num value) {
  final raw = value.toInt().toString();
  final buffer = StringBuffer();
  for (var i = 0; i < raw.length; i++) {
    if (i != 0 && (raw.length - i) % 3 == 0) buffer.write(',');
    buffer.write(raw[i]);
  }
  return 'TZS $buffer';
}

/// Ukurasa wa "Performance ya Projects Zote".
///
/// Hii NI ukurasa mpya, tofauti na Projects (AppRoutes.forumContent).
/// Unafikiwa TU kupitia kitufe cha "Tazama Zote" kwenye Performance card
/// ya Dashboard - HAUKO kwenye Sidebar kwa makusudi (angalia app_sidebar.dart,
/// hakuna reference ya AppRoutes.projectsPerformance humo).
///
/// Extra data inayoongezwa hapa (isiyokuwepo kwenye card ndogo ya Dashboard):
/// asilimia ya "income" ya kila project ikilinganishwa na jumla ya malipo
/// (paid) ya projects zote zilizosajiliwa mwezi huu - "Total Income ya Mwezi".
class ProjectPerformanceView extends StatelessWidget {
  const ProjectPerformanceView({super.key});

  @override
  Widget build(BuildContext context) {
    final store = Get.find<ClientProjectStore>();
    return AnimatedBuilder(
      animation: store,
      builder: (context, _) {
        final now = DateTime.now();

        // Jumla ya Income ya Mwezi = jumla ya 'paid' ya projects zote
        // zilizosajiliwa (registeredAt) mwezi na mwaka wa sasa.
        final monthlyIncome = store.projects
            .where((p) => p.registeredAt.year == now.year && p.registeredAt.month == now.month)
            .fold<double>(0, (sum, p) => sum + p.paid);

        // Projects zote, zikipangwa kwa 'paid' kubwa kwenda ndogo (performance).
        final points = [...store.projects]..sort((a, b) => b.paid.compareTo(a.paid));
        final maxV = points.isEmpty ? 0.0 : points.map((p) => p.paid).fold<double>(0, (a, b) => a > b ? a : b);
        final dateFmt = DateFormat('dd/MM/yyyy');

        return AppShell(
          title: 'Performance ya Projects',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Expanded(
                    child: PageHeader(
                      title: 'Performance ya Projects Zote',
                      subtitle: 'Orodha kamili ya projects na performance yake, ikijumuisha asilimia ya Income ya Mwezi kwa kila project.',
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () => Get.back(),
                    icon: const Icon(Icons.arrow_back, size: 18),
                    label: const Text('Rudi Dashboard'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      const Icon(Icons.pie_chart_outline_rounded, color: AppColors.primaryTeal),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Total Income ya Mwezi', style: TextStyle(fontSize: 12.5, color: AppColors.textSecondary, fontWeight: FontWeight.w700)),
                            const SizedBox(height: 2),
                            Text(_fmtMoney(monthlyIncome), style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: SingleChildScrollView(
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Performance ya Projects Zote', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                          const SizedBox(height: 14),
                          if (points.isEmpty)
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 12),
                              child: Text('Hakuna project bado.', style: TextStyle(color: AppColors.textSecondary)),
                            )
                          else
                            Column(
                              children: [
                                for (final p in points)
                                  Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 10),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(p.name, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700)),
                                                  const SizedBox(height: 2),
                                                  Text(
                                                    'Tarehe: ${dateFmt.format(p.registeredAt)}',
                                                    style: const TextStyle(fontSize: 11.5, color: AppColors.textSecondary),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            Column(
                                              crossAxisAlignment: CrossAxisAlignment.end,
                                              children: [
                                                Text(_fmtMoney(p.paid), style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800)),
                                                const SizedBox(height: 2),
                                                Text(
                                                  '${monthlyIncome == 0 ? '0.0' : (p.paid / monthlyIncome * 100).toStringAsFixed(1)}% ya Income ya Mwezi',
                                                  style: const TextStyle(fontSize: 11.5, color: AppColors.primaryTeal, fontWeight: FontWeight.w700),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 6),
                                        ClipRRect(
                                          borderRadius: BorderRadius.circular(4),
                                          child: LinearProgressIndicator(
                                            value: maxV == 0 ? 0 : p.paid / maxV,
                                            minHeight: 7,
                                            backgroundColor: AppColors.neutralGrayBg,
                                            valueColor: const AlwaysStoppedAnimation(AppColors.primaryTeal),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
