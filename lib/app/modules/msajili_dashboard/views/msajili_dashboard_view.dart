import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_shell.dart';
import '../../../core/widgets/data_table_card.dart';
import '../../../core/widgets/page_header.dart';

// NB: Ukurasa wa "Income" (sidebar) unaonyesha: (1) kadi ya "Jumla ya
// Income" juu, (2) sehemu ya kusearch Income kwa muda (kuanzia -> hadi),
// (3) kadi pana yenye jedwali la Income zote (Kiasi, Jina la Mteja,
// Tarehe), na (4) line graph ya Income kwa miezi mbalimbali chini kabisa.
// Backend bado haina moduli ya Income (ndiyo maana data hapa chini ni ya
// mfano/placeholder) - ukishaunganisha na API, badilisha tu
// `_allIncome` kuwa matokeo ya service husika, muundo (UI) unabaki
// vilevile.
//
// MUHIMU: Ukurasa huu ULIKUWA ukionyesha "Dashibodi ya Msajili" (takwimu
// za wanachama waliosajiliwa kwa Mkoa/Tawi) - kwa maombi ya moja kwa
// moja, umebadilishwa KABISA kuwa ukurasa huu wa Income. Route
// `AppRoutes.msajiliDashboard` inatumika pia na menyu ya role "MSAJILI"
// ('sb_msajili_dashboard') - hivyo mtumiaji wa role hiyo NAYE ataona
// ukurasa huu wa Income badala ya dashibodi yake ya awali.

class _IncomeRow {
  final double amount;
  final String customerName;
  final DateTime receivedAt;

  const _IncomeRow({
    required this.amount,
    required this.customerName,
    required this.receivedAt,
  });
}

// Kiumbizi salama cha namba za fedha (mfano "TZS 1,600,000").
String _fmtMoney(num v) {
  final s = v.toInt().toString();
  final buf = StringBuffer();
  for (int i = 0; i < s.length; i++) {
    if (i != 0 && (s.length - i) % 3 == 0) buf.write(',');
    buf.write(s[i]);
  }
  return 'TZS $buf';
}

class MsajiliDashboardView extends StatefulWidget {
  const MsajiliDashboardView({super.key});

  @override
  State<MsajiliDashboardView> createState() => _MsajiliDashboardViewState();
}

class _MsajiliDashboardViewState extends State<MsajiliDashboardView> {
  // Data ya mfano - badilisha na data halisi kutoka Backend pindi moduli
  // ya Income itakapokuwa tayari.
  final List<_IncomeRow> _allIncome = [
    _IncomeRow(amount: 1500000, customerName: 'Juma Mwakalinga', receivedAt: DateTime(2026, 4, 3)),
    _IncomeRow(amount: 850000, customerName: 'Neema Kessy', receivedAt: DateTime(2026, 5, 14)),
    _IncomeRow(amount: 2200000, customerName: 'Baraka Mushi', receivedAt: DateTime(2026, 6, 9)),
    _IncomeRow(amount: 640000, customerName: 'Amina Rajabu', receivedAt: DateTime(2026, 7, 22)),
    _IncomeRow(amount: 1980000, customerName: 'Godfrey Materu', receivedAt: DateTime(2026, 8, 2)),
    _IncomeRow(amount: 1100000, customerName: 'Rehema Chacha', receivedAt: DateTime(2026, 9, 6)),
  ];

  DateTime? _fromDate;
  DateTime? _toDate;
  final _dateFmt = DateFormat('dd/MM/yyyy');
  final _monthFmt = DateFormat('MMM yyyy');

  List<_IncomeRow> get _filtered {
    return _allIncome.where((r) {
      if (_fromDate != null && r.receivedAt.isBefore(DateTime(_fromDate!.year, _fromDate!.month, _fromDate!.day))) return false;
      if (_toDate != null && r.receivedAt.isAfter(DateTime(_toDate!.year, _toDate!.month, _toDate!.day, 23, 59, 59))) return false;
      return true;
    }).toList();
  }

  double get _totalIncome => _filtered.fold(0.0, (sum, r) => sum + r.amount);

  Future<void> _pickFromDate() async {
    final picked = await showDatePicker(context: context, initialDate: _fromDate ?? DateTime.now(), firstDate: DateTime(2015), lastDate: DateTime(2100));
    if (picked != null) setState(() => _fromDate = picked);
  }

  Future<void> _pickToDate() async {
    final picked = await showDatePicker(context: context, initialDate: _toDate ?? DateTime.now(), firstDate: DateTime(2015), lastDate: DateTime(2100));
    if (picked != null) setState(() => _toDate = picked);
  }

  void _clearDates() => setState(() {
        _fromDate = null;
        _toDate = null;
      });

  // Jumla ya Income kwa kila mwezi (miezi yenye data), kwa ajili ya line
  // graph chini ya ukurasa - inapangwa kwa DateTime halisi (siyo kwa
  // jina la mwezi lililoumbizwa) ili kuepuka hitilafu za kupanga tarehe.
  List<MapEntry<String, double>> get _monthlyTotals {
    final Map<DateTime, double> totals = {};
    for (final r in _allIncome) {
      final key = DateTime(r.receivedAt.year, r.receivedAt.month);
      totals[key] = (totals[key] ?? 0) + r.amount;
    }
    final sortedKeys = totals.keys.toList()..sort();
    return [for (final k in sortedKeys) MapEntry(_monthFmt.format(k), totals[k]!)];
  }

  @override
  Widget build(BuildContext context) {
    final rows = _filtered;
    return AppShell(
      title: 'Income',
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const PageHeader(
              title: 'Income',
              subtitle: 'Fuatilia Income yote iliyoingia - tafuta kwa muda (kuanzia - hadi).',
            ),
            const SizedBox(height: 16),
            _TotalCard(label: 'Jumla ya Income Kwa Sasa', value: _fmtMoney(_totalIncome), color: AppColors.success),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: Wrap(
                spacing: 12,
                runSpacing: 12,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  SizedBox(
                    width: 190,
                    child: InkWell(
                      onTap: _pickFromDate,
                      child: InputDecorator(
                        decoration: const InputDecoration(labelText: 'Kuanzia', prefixIcon: Icon(Icons.calendar_today_outlined, size: 18), isDense: true),
                        child: Text(
                          _fromDate == null ? 'Chagua tarehe' : _dateFmt.format(_fromDate!),
                          style: TextStyle(color: _fromDate == null ? AppColors.textSecondary : AppColors.textPrimary, fontSize: 14),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 190,
                    child: InkWell(
                      onTap: _pickToDate,
                      child: InputDecorator(
                        decoration: const InputDecoration(labelText: 'Hadi', prefixIcon: Icon(Icons.calendar_today_outlined, size: 18), isDense: true),
                        child: Text(
                          _toDate == null ? 'Chagua tarehe' : _dateFmt.format(_toDate!),
                          style: TextStyle(color: _toDate == null ? AppColors.textSecondary : AppColors.textPrimary, fontSize: 14),
                        ),
                      ),
                    ),
                  ),
                  if (_fromDate != null || _toDate != null)
                    TextButton.icon(onPressed: _clearDates, icon: const Icon(Icons.close, size: 16), label: const Text('Futa Muda')),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Orodha ya Income', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 14),
                    DataTableCard(
                      emptyIcon: Icons.payments_outlined,
                      emptyTitle: 'Hakuna Income',
                      emptySubtitle: 'Hakuna income kwa muda uliouchagua.',
                      columns: const [
                        DataColumn(label: Text('Kiasi')),
                        DataColumn(label: Text('Jina la Mteja')),
                        DataColumn(label: Text('Tarehe')),
                      ],
                      rows: rows.map((r) {
                        return DataRow(cells: [
                          DataCell(Text(_fmtMoney(r.amount), style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.success))),
                          DataCell(Text(r.customerName)),
                          DataCell(Text(_dateFmt.format(r.receivedAt))),
                        ]);
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            _MonthlyBarChartCard(title: 'Income kwa Miezi Mbalimbali', color: AppColors.success, points: _monthlyTotals),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }
}

/// Kadi rahisi ya "jumla" - inatumika kwa Income na Expenses.
class _TotalCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _TotalCard({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: color)),
          const SizedBox(height: 6),
          Text(value, style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: color)),
        ],
      ),
    );
  }
}

/// Bar graph ya jumla-kwa-mwezi.
class _MonthlyBarChartCard extends StatelessWidget {
  final String title;
  final Color color;
  final List<MapEntry<String, double>> points;
  const _MonthlyBarChartCard({required this.title, required this.color, required this.points});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
          const SizedBox(height: 14),
          if (points.isEmpty)
            const SizedBox(
              height: 100,
              child: Center(child: Text('Hakuna data bado.', style: TextStyle(color: AppColors.textSecondary, fontSize: 12.5))),
            )
          else
            SizedBox(
              height: 240,
              child: BarChart(
                BarChartData(
                  maxY: (points.map((p) => p.value).reduce((a, b) => a > b ? a : b)) * 1.2,
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
                            child: Text(points[i].key, style: const TextStyle(fontSize: 10, color: AppColors.textSecondary)),
                          );
                        },
                      ),
                    ),
                  ),
                  barGroups: [
                    for (int i = 0; i < points.length; i++)
                      BarChartGroupData(
                        x: i,
                        barRods: [
                          BarChartRodData(
                            toY: points[i].value,
                            color: color,
                            width: 22,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
