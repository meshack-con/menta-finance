import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/web_download.dart';
import '../../../core/widgets/app_shell.dart';
import '../../../core/widgets/page_header.dart';
import '../reports_store.dart';
import '../widgets/report_pdf_builder.dart';

String _fmtMoney(num value) {
  final raw = value.toInt().toString();
  final buffer = StringBuffer();
  for (var i = 0; i < raw.length; i++) {
    if (i != 0 && (raw.length - i) % 3 == 0) buffer.write(',');
    buffer.write(raw[i]);
  }
  return 'TZS $buffer';
}

/// Ukurasa mpya wa "Reports" - CHANZO ni Backend (/api/reports/overview),
/// data halisi ya Clients/Projects/Income/Expenses/Services (siyo mockup).
/// Muundo: kadi (cards) zilizopangwa WIMA (vertical), kila kadi ikiwakilisha
/// Ripoti moja rasmi ya kampuni, ikiwa na vitufe vya "Tazama" (View),
/// "Chapisha" (Print) na "Pakua" (Download) - vyote vinazalisha PDF halisi
/// (logo ya Menta Studio + data ya kweli ya mfumo), tayari kwa uongozi
/// kutumia kufanya maamuzi ya kimkakati.
class ReportsView extends StatefulWidget {
  const ReportsView({super.key});

  @override
  State<ReportsView> createState() => _ReportsViewState();
}

class _ReportsViewState extends State<ReportsView> {
  @override
  void initState() {
    super.initState();
    Get.find<ReportsStore>().startPolling();
  }

  @override
  void dispose() {
    Get.find<ReportsStore>().stopPolling();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final store = Get.find<ReportsStore>();
    return AnimatedBuilder(
      animation: store,
      builder: (context, _) {
        final data = store.data;
        return AppShell(
          title: 'Reports',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Expanded(
                    child: PageHeader(
                      title: 'Reports',
                      subtitle: 'Ripoti rasmi za kampuni - chagua ripoti, kisha Tazama, Chapisha au Pakua kama PDF.',
                    ),
                  ),
                  IconButton(
                    onPressed: store.refresh,
                    tooltip: 'Onyesha upya',
                    icon: const Icon(Icons.refresh),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              if (store.loadError != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    children: [
                      Text(store.loadError!, style: const TextStyle(color: AppColors.danger)),
                      const SizedBox(width: 10),
                      ElevatedButton(onPressed: store.refresh, child: const Text('Jaribu tena')),
                    ],
                  ),
                ),
              if (store.isLoading && data == null)
                const Expanded(child: Center(child: CircularProgressIndicator()))
              else if (data == null)
                const Expanded(child: SizedBox())
              else
                Expanded(child: SingleChildScrollView(child: _ReportsBody(data: data))),
            ],
          ),
        );
      },
    );
  }
}

class _ReportsBody extends StatelessWidget {
  final Map<String, dynamic> data;
  const _ReportsBody({required this.data});

  @override
  Widget build(BuildContext context) {
    final totals = (data['totals'] as Map<String, dynamic>?) ?? {};
    final generatedAt = DateTime.tryParse(data['generated_at']?.toString() ?? '') ?? DateTime.now();
    final dateFmt = DateFormat('dd/MM/yyyy • HH:mm');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ---- Muhtasari mfupi wa haraka (quick glance) - data halisi ----
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.cardBackground,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border),
          ),
          child: Wrap(
            spacing: 22,
            runSpacing: 10,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              _quickStat('Income Mwezi Huu', _fmtMoney(totals['income_month'] ?? 0), AppColors.primaryGreen),
              _quickStat('Net Profit Mwezi Huu', _fmtMoney(totals['net_profit_month'] ?? 0), AppColors.primaryTeal),
              _quickStat('Outstanding', _fmtMoney(totals['outstanding'] ?? 0), AppColors.warning),
              _quickStat('Projects Zilizochelewa', '${totals['overdue_projects'] ?? 0}', AppColors.danger),
              const Spacer(),
              Text('Data ya mwisho: ${dateFmt.format(generatedAt)}', style: const TextStyle(fontSize: 11.5, color: AppColors.textSecondary)),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Text('Ripoti Zinazopatikana', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
        const SizedBox(height: 4),
        const Text(
          'Bofya "Tazama" kuangalia ripoti browser-ni, "Chapisha" kutuma kwenye printa, au "Pakua" kuihifadhi kama PDF.',
          style: TextStyle(fontSize: 12.5, color: AppColors.textSecondary),
        ),
        const SizedBox(height: 16),

        _safeCard(
          () => _ReportCard(
            icon: Icons.pie_chart_outline_rounded,
            iconColor: AppColors.primaryGreen,
            title: 'Ripoti ya Mapato na Matumizi (Kila Mwezi)',
            description:
                'Ripoti kamili yenye kurasa kadhaa: Muhtasari, Income Register, Top Clients, Expense Register, Matumizi kwa Category, na Management Decision Dashboard - data halisi ya mfumo.',
            stats: [
              _CardStat('Income Mwezi Huu', _fmtMoney(totals['income_month'] ?? 0), AppColors.primaryGreen),
              _CardStat('Expenses Mwezi Huu', _fmtMoney(totals['expenses_month'] ?? 0), AppColors.danger),
              _CardStat('Net Profit', _fmtMoney(totals['net_profit_month'] ?? 0), AppColors.primaryTeal),
            ],
            fileName: 'ripoti-mapato-matumizi-${DateTime.now().millisecondsSinceEpoch}.pdf',
            buildPdf: () => ReportPdfBuilder.buildFinancialMonthlyReport(data),
          ),
          title: 'Ripoti ya Mapato na Matumizi (Kila Mwezi)',
        ),
        const SizedBox(height: 16),

        _safeCard(
          () => _ReportCard(
            icon: Icons.dynamic_feed_outlined,
            iconColor: AppColors.primaryTeal,
            title: 'Ripoti ya Performance za Projects',
            description:
                'Orodha kamili ya Projects zote - kiasi, kilicholipwa, kinachodaiwa, deadline na hali (Kamili / Inaendelea / Imechelewa).',
            stats: [
              _CardStat('Jumla ya Projects', '${totals['projects'] ?? 0}', AppColors.primaryTeal),
              _CardStat('Zilizokamilika', '${totals['completed_projects'] ?? 0}', AppColors.primaryGreen),
              _CardStat('Zilizochelewa', '${totals['overdue_projects'] ?? 0}', AppColors.danger),
            ],
            fileName: 'ripoti-performance-projects-${DateTime.now().millisecondsSinceEpoch}.pdf',
            buildPdf: () => ReportPdfBuilder.buildProjectPerformanceReport(data),
          ),
          title: 'Ripoti ya Performance za Projects',
        ),
        const SizedBox(height: 16),

        _safeCard(
          () => _ReportCard(
            icon: Icons.people_alt_outlined,
            iconColor: AppColors.info,
            title: 'Ripoti ya Wateja (Clients)',
            description:
                'Orodha kamili ya Clients wote - jumla ya Income kwa kila mmoja, idadi ya Projects, na deni (outstanding) lililopo.',
            stats: [
              _CardStat('Jumla ya Clients', '${totals['clients'] ?? 0}', AppColors.info),
              _CardStat('Outstanding (Deni)', _fmtMoney(totals['outstanding'] ?? 0), AppColors.warning),
            ],
            fileName: 'ripoti-wateja-${DateTime.now().millisecondsSinceEpoch}.pdf',
            buildPdf: () => ReportPdfBuilder.buildClientsReport(data),
          ),
          title: 'Ripoti ya Wateja (Clients)',
        ),
        const SizedBox(height: 16),

        _safeCard(
          () => _ReportCard(
            icon: Icons.insights_outlined,
            iconColor: AppColors.primaryGreen,
            title: 'Ripoti Kuu ya Mfumo (Muhtasari wa Menejimenti)',
            description:
                'Muhtasari mkubwa wa kampuni kwa uongozi - Income/Expenses, Top Clients, Top Projects na mwenendo wa miezi 6, kwa maamuzi ya kimkakati.',
            stats: [
              _CardStat('Clients', '${totals['clients'] ?? 0}', AppColors.primaryTeal),
              _CardStat('Projects', '${totals['projects'] ?? 0}', AppColors.primaryTeal),
              _CardStat('Income Total', _fmtMoney(totals['income_total'] ?? 0), AppColors.primaryGreen),
            ],
            fileName: 'ripoti-kuu-mfumo-${DateTime.now().millisecondsSinceEpoch}.pdf',
            buildPdf: () => ReportPdfBuilder.buildExecutiveSummaryReport(data),
          ),
          title: 'Ripoti Kuu ya Mfumo (Muhtasari wa Menejimenti)',
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  /// Ujenzi wa kadi moja "kwa usalama" - kama data ya ripoti hii moja
  /// (mfano field fulani ya `totals` haipo/aina yake si sahihi) ikisababisha
  /// hitilafu wakati wa ku-build, TUNAONYESHA KADI YA HITILAFU MAHALI PA HIYO
  /// KADI TU (yenye jina la ripoti husika) - badala ya ripoti ZOTE nne
  /// kutoweka na kuacha "blank gray box" kubwa mahali pake.
  Widget _safeCard(Widget Function() builder, {required String title}) {
    try {
      return builder();
    } catch (e) {
      return _ErrorCardFallback(title: title, error: e.toString());
    }
  }

  Widget _quickStat(String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
        const SizedBox(height: 2),
        Text(value, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: color)),
      ],
    );
  }
}

/// Kadi inayoonekana PALE PALE ambapo ripoti fulani imeshindwa kujengwa -
/// inaonyesha jina la ripoti husika + ujumbe wa hitilafu, na kitufe cha
/// "Jaribu tena" (kinachochochea upya ukurasa mzima kupitia refresh).
class _ErrorCardFallback extends StatelessWidget {
  final String title;
  final String error;
  const _ErrorCardFallback({required this.title, required this.error});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.dangerBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.danger.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.error_outline, color: AppColors.danger, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '"$title" imeshindwa kuonyesha',
                  style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800, color: AppColors.danger),
                ),
              ),
              TextButton(
                onPressed: () => Get.find<ReportsStore>().refresh(),
                child: const Text('Jaribu tena'),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(error, style: const TextStyle(fontSize: 11.5, color: AppColors.danger)),
        ],
      ),
    );
  }
}

class _CardStat {
  final String label;
  final String value;
  final Color color;
  const _CardStat(this.label, this.value, this.color);
}

/// Kadi MOJA ya Ripoti - iliyopangwa WIMA (vertical) kwenye orodha ya
/// Reports. Ina icon, kichwa, maelezo, takwimu za haraka (real data), na
/// vitufe vitatu: Tazama (fungua PDF tab mpya), Chapisha (print dialog),
/// Pakua (download kwenye kifaa) - vyote vinazalisha PDF halisi papo hapo.
class _ReportCard extends StatefulWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String description;
  final List<_CardStat> stats;
  final String fileName;
  final Future<Uint8List> Function() buildPdf;

  const _ReportCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.description,
    required this.stats,
    required this.fileName,
    required this.buildPdf,
  });

  @override
  State<_ReportCard> createState() => _ReportCardState();
}

enum _ReportAction { view, print, download }

class _ReportCardState extends State<_ReportCard> {
  _ReportAction? _busy;

  Future<void> _run(_ReportAction action) async {
    setState(() => _busy = action);
    try {
      final bytes = await widget.buildPdf();
      switch (action) {
        case _ReportAction.view:
          openPdfBytesInNewTab(bytes);
          break;
        case _ReportAction.print:
          await Printing.layoutPdf(onLayout: (format) async => bytes);
          break;
        case _ReportAction.download:
          downloadBytesAsFile(bytes, widget.fileName);
          break;
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Imeshindikana kuzalisha ripoti hii. Jaribu tena.')),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = null);
    }
  }

  Widget _actionButton({
    required _ReportAction action,
    required IconData icon,
    required String label,
    bool filled = false,
  }) {
    final isBusy = _busy == action;
    final child = isBusy
        ? SizedBox(
            width: 15,
            height: 15,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: filled ? Colors.white : AppColors.primaryGreen,
            ),
          )
        : Icon(icon, size: 17);

    if (filled) {
      return ElevatedButton.icon(
        onPressed: _busy != null ? null : () => _run(action),
        icon: child,
        label: Text(label),
      );
    }
    return OutlinedButton.icon(
      onPressed: _busy != null ? null : () => _run(action),
      icon: child,
      label: Text(label),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 3)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(color: widget.iconColor.withOpacity(0.12), borderRadius: BorderRadius.circular(12)),
                alignment: Alignment.center,
                child: Icon(widget.icon, color: widget.iconColor),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.title, style: const TextStyle(fontSize: 15.5, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 4),
                    Text(widget.description, style: const TextStyle(fontSize: 12.5, color: AppColors.textSecondary, height: 1.35)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 24,
            runSpacing: 10,
            children: [
              for (final s in widget.stats)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(s.label, style: const TextStyle(fontSize: 10.5, color: AppColors.textSecondary)),
                    const SizedBox(height: 2),
                    Text(s.value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: s.color)),
                  ],
                ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _actionButton(action: _ReportAction.view, icon: Icons.visibility_outlined, label: 'Tazama', filled: true),
              _actionButton(action: _ReportAction.print, icon: Icons.print_outlined, label: 'Chapisha'),
              _actionButton(action: _ReportAction.download, icon: Icons.download_outlined, label: 'Pakua PDF'),
            ],
          ),
        ],
      ),
    );
  }
}
