import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:fl_chart/fl_chart.dart';

import '../../../core/data/client_project_store.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/storage/storage_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_shell.dart';
import '../../../core/widgets/stat_card.dart';
import '../controllers/dashboard_controller.dart';

// Kiumbizi salama cha namba za fedha (mfano 1,600,000) - kinatumika
// kwenye Recent Transactions na Performance ili zionekane kama kiasi
// cha fedha (TZS), sio namba tupu.
String _fmtMoney(int v) {
  final s = v.toString();
  final buf = StringBuffer();
  for (int i = 0; i < s.length; i++) {
    if (i != 0 && (s.length - i) % 3 == 0) buf.write(',');
    buf.write(s[i]);
  }
  return 'TZS $buf';
}

class DashboardView extends GetView<DashboardController> {
  const DashboardView({super.key});

  // Kihesabu asilimia salama ya thamani fulani ukilinganisha na Income
  // (jumla ya Wanachama) - kinatumika kwenye subtitle za card za
  // Net Profit/Loss na Outstanding, ili zionekane kama asilimia ya Income.
  static String _pctOfIncome(int part, int total) {
    if (total == 0) return '0.0';
    return (part / total * 100).toStringAsFixed(1);
  }

  @override
  Widget build(BuildContext context) {
    return AppShell(
      title: 'Dashboard',
      child: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }
        if (controller.errorMessage.value != null) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(controller.errorMessage.value!, style: const TextStyle(color: AppColors.danger)),
                const SizedBox(height: 12),
                ElevatedButton(onPressed: controller.loadSummary, child: const Text('Jaribu tena')),
              ],
            ),
          );
        }

        final s = controller.summary.value!;
        final isStaff = Get.find<StorageService>().isStaffOnly;
        return RefreshIndicator(
          onRefresh: controller.loadSummary,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Dashboard', style: TextStyle(fontSize: 25, fontWeight: FontWeight.w900)),
                const SizedBox(height: 5),
                const Text(
                  'Muhtasari wa biashara yako',
                  style: TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 20),
                LayoutBuilder(builder: (_, c) {
                  final count = c.maxWidth > 1050 ? 4 : (c.maxWidth > 650 ? 2 : 1);
                  final cards = isStaff
                      ? [
                          StatCard(
                            title: 'Outstanding',
                            value: '${s.totalBranches}',
                            subtitle: '${_pctOfIncome(s.totalBranches, s.totalRulers)}% ya Income',
                            icon: Icons.pending_actions_rounded,
                            color: AppColors.info,
                          ),
                        ]
                      : [
                          StatCard(
                            title: 'Income ya Mwezi',
                            value: '${s.totalRulers}',
                            subtitle: 'Total Income per month',
                            icon: Icons.payments_rounded,
                            color: AppColors.primaryGreen,
                          ),
                          StatCard(
                            title: 'Expenses za Mwezi',
                            value: '${s.totalLeaders}',
                            subtitle: '${s.leaderPercent.toStringAsFixed(1)}% ya Income',
                            icon: Icons.money_off_rounded,
                            color: AppColors.danger,
                          ),
                          StatCard(
                            title: 'Net Profit/Loss',
                            value: '${s.totalRegions}',
                            subtitle: '${_pctOfIncome(s.totalRegions, s.totalRulers)}% ya Income',
                            icon: Icons.account_balance_rounded,
                            color: AppColors.primaryTeal,
                          ),
                          StatCard(
                            title: 'Outstanding',
                            value: '${s.totalBranches}',
                            subtitle: '${_pctOfIncome(s.totalBranches, s.totalRulers)}% ya Income',
                            icon: Icons.pending_actions_rounded,
                            color: AppColors.info,
                          ),
                        ];
                  return GridView.count(
                    crossAxisCount: isStaff ? (c.maxWidth > 650 ? 2 : 1) : count,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: 14,
                    mainAxisSpacing: 14,
                    childAspectRatio: 2.35,
                    children: cards,
                  );
                }),
                const SizedBox(height: 20),
                if (isStaff)
                  const _RegistrationsBarCard()
                else
                  LayoutBuilder(builder: (_, c) {
                  final wide = c.maxWidth > 900;
                  final charts = [
                    const Expanded(flex: 2, child: _GenderPieCard()),
                    const SizedBox(width: 14, height: 14),
                    const Expanded(flex: 1, child: _RegistrationsBarCard()),
                  ];
                  return wide
                      ? IntrinsicHeight(child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: charts))
                      : const Column(children: [_GenderPieCard(), SizedBox(height: 14), _RegistrationsBarCard()]);
                }),
                if (!isStaff) ...[
                  const SizedBox(height: 14),
                  const _RegionsBarCard(),
                ],
                const SizedBox(height: 20),
                const _RecentLoginsCard(),
              ],
            ),
          ),
        );
      }),
    );
  }
}

// Slot 1 (upande wa kushoto): "Recent Transactions" - mchanganyiko wa
// Expenses (EXPENSE) na malipo ya Projects (INCOME), ukionyesha Tarehe,
// Aina, Jina la muamala na Kiasi - miamala 5 ya hivi karibuni.
class _GenderPieCard extends StatelessWidget {
  const _GenderPieCard();

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<DashboardController>();
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Recent Transactions', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
            const SizedBox(height: 14),
            Obx(() {
              if (controller.isLoadingCharts.value) {
                return const SizedBox(height: 160, child: Center(child: CircularProgressIndicator()));
              }
              final items = controller.charts.value?.recentTransactions ?? [];
              if (items.isEmpty) {
                return const SizedBox(height: 160, child: Center(child: Text('Hakuna miamala bado.', style: TextStyle(color: AppColors.textSecondary))));
              }
              return Column(
                children: [
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 4),
                    child: Row(
                      children: [
                        SizedBox(width: 76, child: Text('Tarehe', style: TextStyle(fontSize: 11, color: AppColors.textSecondary, fontWeight: FontWeight.w700))),
                        SizedBox(width: 70, child: Text('Aina', style: TextStyle(fontSize: 11, color: AppColors.textSecondary, fontWeight: FontWeight.w700))),
                        Expanded(child: Text('Jina', style: TextStyle(fontSize: 11, color: AppColors.textSecondary, fontWeight: FontWeight.w700))),
                        Text('Kiasi', style: TextStyle(fontSize: 11, color: AppColors.textSecondary, fontWeight: FontWeight.w700)),
                      ],
                    ),
                  ),
                  const Divider(height: 22),
                  for (final t in items)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 76,
                            child: Text(
                              '${t.date.day.toString().padLeft(2, '0')}/${t.date.month.toString().padLeft(2, '0')}/${t.date.year}',
                              style: const TextStyle(fontSize: 12.5, color: AppColors.textSecondary),
                            ),
                          ),
                          SizedBox(
                            width: 70,
                            child: Text(
                              t.isIncome ? 'Income' : 'Expense',
                              style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: t.isIncome ? AppColors.primaryGreen : AppColors.danger),
                            ),
                          ),
                          Expanded(child: Text(t.name, style: const TextStyle(fontSize: 13.5), overflow: TextOverflow.ellipsis)),
                          Text(_fmtMoney(t.amount), style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700)),
                        ],
                      ),
                    ),
                ],
              );
            }),
          ],
        ),
      ),
    );
  }
}

// Slot 2 (upande wa kulia): "Performance" - inaonyesha TOP 3 Projects
// (kwa 'paid' kubwa kwenda ndogo) kutoka ClientProjectStore. Kitufe cha
// "Tazama Zote" HAKIENDI tena kwenye ukurasa wa Projects (forumContent) -
// kinaenda kwenye ukurasa mpya wa Performance ya Projects Zote
// (AppRoutes.projectsPerformance), ambao HAUKO kwenye Sidebar.
class _RegistrationsBarCard extends StatelessWidget {
  const _RegistrationsBarCard();

  @override
  Widget build(BuildContext context) {
    final store = Get.find<ClientProjectStore>();
    return AnimatedBuilder(
      animation: store,
      builder: (context, _) {
        final ranked = [...store.projects]..sort((a, b) => b.paid.compareTo(a.paid));
        final points = ranked.take(3).toList();
        final maxV = points.isEmpty ? 0.0 : points.map((p) => p.paid).fold<double>(0, (a, b) => a > b ? a : b);
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: Text('Performance', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
                    ),
                    TextButton.icon(
                      onPressed: () => Get.toNamed(AppRoutes.projectsPerformance),
                      icon: const Icon(Icons.visibility_outlined, size: 18),
                      label: const Text('Tazama Zote'),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                if (points.isEmpty)
                  const SizedBox(height: 200, child: Center(child: Text('Hakuna data bado.', style: TextStyle(color: AppColors.textSecondary))))
                else
                  Column(
                    children: [
                      for (final p in points)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(child: Text(p.name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600))),
                                  Text(_fmtMoney(p.paid.toInt()), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800)),
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
        );
      },
    );
  }
}

// Slot 3: "Income Trend - Last 6 Months" - line graph inayoonyesha
// kupanda/kushuka kwa miezi 6, ikitumia data ya 'registrationsByMonth'
// (tayari ina point 6 - moja kwa kila mwezi).
class _RegionsBarCard extends StatelessWidget {
  const _RegionsBarCard();

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<DashboardController>();
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Income Trend - Last 6 Months', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
            const SizedBox(height: 14),
            Obx(() {
              if (controller.isLoadingCharts.value) {
                return const SizedBox(height: 220, child: Center(child: CircularProgressIndicator()));
              }
              final points = controller.charts.value?.registrationsByMonth ?? [];
              if (points.isEmpty) {
                return const SizedBox(
                  height: 100,
                  child: Center(child: Text('Hakuna data bado.', style: TextStyle(color: AppColors.textSecondary, fontSize: 12.5))),
                );
              }
              final maxY = (points.map((p) => p.value).fold<int>(0, (a, b) => a > b ? a : b)).toDouble();
              return SizedBox(
                height: 240,
                child: LineChart(
                  LineChartData(
                    maxY: maxY == 0 ? 5 : maxY * 1.2,
                    minY: 0,
                    gridData: const FlGridData(show: false),
                    borderData: FlBorderData(show: false),
                    titlesData: FlTitlesData(
                      leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 30,
                          getTitlesWidget: (value, meta) {
                            final i = value.toInt();
                            if (i < 0 || i >= points.length) return const SizedBox();
                            return Padding(
                              padding: const EdgeInsets.only(top: 6),
                              child: Text(points[i].label, style: const TextStyle(fontSize: 10, color: AppColors.textSecondary)),
                            );
                          },
                        ),
                      ),
                    ),
                    lineBarsData: [
                      LineChartBarData(
                        isCurved: true,
                        color: AppColors.primaryTeal,
                        barWidth: 3,
                        dotData: const FlDotData(show: true),
                        belowBarData: BarAreaData(show: true, color: AppColors.primaryTeal.withOpacity(0.12)),
                        spots: [for (int i = 0; i < points.length; i++) FlSpot(i.toDouble(), points[i].value.toDouble())],
                      ),
                    ],
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

// Slot 4 (chini kabisa): "Recent Projects" - inaonyesha baadhi ya
// entries za hivi karibuni (kwa sasa kutoka Login History, kwani hakuna
// bado moduli ya Projects kwenye Backend) + kitufe cha "Tazama Zote"
// chenye alama (icon) ya kutazama.
class _RecentLoginsCard extends StatelessWidget {
  const _RecentLoginsCard();

  @override
  Widget build(BuildContext context) {
    final store = Get.find<ClientProjectStore>();
    return AnimatedBuilder(
      animation: store,
      builder: (context, _) {
        final recent = [...store.projects]
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
        final items = recent.take(5).toList();
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: Text('Recent Projects', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                    ),
                    TextButton.icon(
                      onPressed: () => Get.toNamed(AppRoutes.forumContent),
                      icon: const Icon(Icons.visibility_outlined, size: 18),
                      label: const Text('Tazama Zote'),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (items.isEmpty)
                  const Text(
                    'Hakuna miradi ya hivi karibuni bado.',
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 12.5),
                  )
                else
                  Column(
                    children: [
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 4),
                        child: Row(
                          children: [
                            SizedBox(width: 46),
                            Expanded(child: Text('Jina la Project', style: TextStyle(fontSize: 11, color: AppColors.textSecondary, fontWeight: FontWeight.w700))),
                            Text('Tarehe', style: TextStyle(fontSize: 11, color: AppColors.textSecondary, fontWeight: FontWeight.w700)),
                          ],
                        ),
                      ),
                      const Divider(height: 22),
                      for (final project in items)
                        InkWell(
                          onTap: () => Get.toNamed(AppRoutes.forumContent),
                          borderRadius: BorderRadius.circular(8),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 4),
                            child: Row(
                              children: [
                                Container(
                                  width: 34,
                                  height: 34,
                                  decoration: BoxDecoration(color: AppColors.primaryTeal.withOpacity(0.12), borderRadius: BorderRadius.circular(9)),
                                  alignment: Alignment.center,
                                  child: const Icon(Icons.work_outline_rounded, size: 18, color: AppColors.primaryTeal),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(project.name, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600)),
                                ),
                                Text(
                                  '${project.createdAt.day.toString().padLeft(2, '0')}/${project.createdAt.month.toString().padLeft(2, '0')}/${project.createdAt.year}',
                                  style: const TextStyle(fontSize: 12.5, color: AppColors.textSecondary),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
