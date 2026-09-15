import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_shell.dart';
import '../../../core/widgets/data_table_card.dart';
import '../../../core/widgets/page_header.dart';

// NB: Ukurasa wa "Expenses" (sidebar) - muundo huu ni sawasawa na
// ukurasa wa "Income" (angalia msajili_dashboard_view.dart): (1) kadi ya
// "Jumla ya Expenses" juu, (2) sehemu ya kusearch Expenses kwa muda
// (kuanzia -> hadi), (3) kadi pana yenye jedwali la Expenses zote
// (Kiasi, Jina, Tarehe), na (4) line graph ya Expenses kwa miezi
// mbalimbali chini kabisa. Backend bado haina moduli ya Expenses (ndiyo
// maana data hapa chini ni ya mfano/placeholder) - ukishaunganisha na
// API, badilisha tu `_allExpenses` kuwa matokeo ya service husika,
// muundo (UI) unabaki vilevile.
//
// MUHIMU: Ukurasa huu ULIKUWA ukionyesha "Audit Trail" (rekodi ya
// matukio ya mfumo, read-only) - kwa maombi ya moja kwa moja, umebadilishwa
// KABISA kuwa ukurasa huu wa Expenses.

class _ExpenseRow {
  final double amount;
  final String name;
  final String category;
  final String description;
  final DateTime paidAt;

  const _ExpenseRow({
    required this.amount,
    required this.name,
    required this.category,
    required this.description,
    required this.paidAt,
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

class AuditView extends StatefulWidget {
  const AuditView({super.key});

  @override
  State<AuditView> createState() => _AuditViewState();
}

class _AuditViewState extends State<AuditView> {
  // Data ya mfano - badilisha na data halisi kutoka Backend pindi moduli
  // ya Expenses itakapokuwa tayari.
  final List<_ExpenseRow> _allExpenses = [
    _ExpenseRow(amount: 900000, name: 'Kodi ya Ofisi', category: 'Ofisi', description: 'Kodi ya mwezi', paidAt: DateTime(2026, 4, 5)),
    _ExpenseRow(amount: 420000, name: 'Umeme na Maji', category: 'Huduma', description: 'Bili za ofisi', paidAt: DateTime(2026, 5, 11)),
    _ExpenseRow(amount: 1350000, name: 'Mafuta ya Gari', category: 'Usafiri', description: 'Mafuta ya gari la kampuni', paidAt: DateTime(2026, 6, 18)),
    _ExpenseRow(amount: 560000, name: 'Vifaa vya Ofisi', category: 'Ofisi', description: 'Stationery', paidAt: DateTime(2026, 7, 9)),
    _ExpenseRow(amount: 780000, name: 'Mishahara ya Muda', category: 'Wafanyakazi', description: 'Malipo ya muda', paidAt: DateTime(2026, 8, 20)),
    _ExpenseRow(amount: 610000, name: 'Matengenezo ya Mfumo', category: 'Teknolojia', description: 'Maintenance', paidAt: DateTime(2026, 9, 3)),
  ];

  DateTime? _fromDate;
  DateTime? _toDate;
  final _dateFmt = DateFormat('dd/MM/yyyy');
  final _monthFmt = DateFormat('MMM yyyy');

  List<_ExpenseRow> get _filtered {
    return _allExpenses.where((r) {
      if (_fromDate != null && r.paidAt.isBefore(DateTime(_fromDate!.year, _fromDate!.month, _fromDate!.day))) return false;
      if (_toDate != null && r.paidAt.isAfter(DateTime(_toDate!.year, _toDate!.month, _toDate!.day, 23, 59, 59))) return false;
      return true;
    }).toList();
  }

  double get _totalExpenses => _filtered.fold(0.0, (sum, r) => sum + r.amount);

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

  void _registerExpense(_ExpenseRow expense) {
    setState(() => _allExpenses.insert(0, expense));
  }

  // Jumla ya Expenses kwa kila mwezi, kwa ajili ya line graph chini ya
  // ukurasa - inapangwa kwa DateTime halisi (siyo kwa jina la mwezi
  // lililoumbizwa) ili kuepuka hitilafu za kupanga tarehe.
  List<MapEntry<String, double>> get _monthlyTotals {
    final Map<DateTime, double> totals = {};
    for (final r in _allExpenses) {
      final key = DateTime(r.paidAt.year, r.paidAt.month);
      totals[key] = (totals[key] ?? 0) + r.amount;
    }
    final sortedKeys = totals.keys.toList()..sort();
    return [for (final k in sortedKeys) MapEntry(_monthFmt.format(k), totals[k]!)];
  }

  @override
  Widget build(BuildContext context) {
    final rows = _filtered;
    return AppShell(
      title: 'Expenses',
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Expanded(
                  child: PageHeader(
                    title: 'Expenses',
                    subtitle: 'Rekodi na fuatilia matumizi yote ya kampuni.',
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () => showDialog<void>(
                    context: context,
                    builder: (_) => _RegisterExpenseDialog(onSubmit: _registerExpense),
                  ),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Sajili Expense'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _TotalCard(label: 'Jumla ya Expenses Kwa Sasa', value: _fmtMoney(_totalExpenses), color: AppColors.danger),
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
            DataTableCard(
              emptyIcon: Icons.receipt_long_outlined,
              emptyTitle: 'Hakuna Expenses',
              emptySubtitle: 'Hakuna expense kwa muda uliouchagua.',
              columns: const [
                DataColumn(label: Text('Kiasi')),
                DataColumn(label: Text('Jina')),
                DataColumn(label: Text('Category')),
                DataColumn(label: Text('Maelezo')),
                DataColumn(label: Text('Tarehe')),
              ],
              rows: rows.map((r) {
                return DataRow(cells: [
                  DataCell(Text(_fmtMoney(r.amount), style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.danger))),
                  DataCell(Text(r.name)),
                  DataCell(Text(r.category)),
                  DataCell(Text(r.description.isEmpty ? '-' : r.description)),
                  DataCell(Text(_dateFmt.format(r.paidAt))),
                ]);
              }).toList(),
            ),
            const SizedBox(height: 20),
            _MonthlyBarChartCard(title: 'Expenses kwa Miezi Mbalimbali', color: AppColors.danger, points: _monthlyTotals),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }
}

/// Kadi rahisi ya "jumla".
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

class _RegisterExpenseDialog extends StatefulWidget {
  final void Function(_ExpenseRow expense) onSubmit;

  const _RegisterExpenseDialog({required this.onSubmit});

  @override
  State<_RegisterExpenseDialog> createState() => _RegisterExpenseDialogState();
}

class _RegisterExpenseDialogState extends State<_RegisterExpenseDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _categoryCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();
  final _descriptionCtrl = TextEditingController();
  DateTime? _paidAt;
  final _dateFmt = DateFormat('dd/MM/yyyy');

  @override
  void dispose() {
    _nameCtrl.dispose();
    _categoryCtrl.dispose();
    _amountCtrl.dispose();
    _descriptionCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _paidAt ?? DateTime.now(),
      firstDate: DateTime(2015),
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => _paidAt = picked);
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    if (_paidAt == null) {
      Get.snackbar('Kosa', 'Chagua tarehe ya expense.', snackPosition: SnackPosition.BOTTOM);
      return;
    }
    widget.onSubmit(_ExpenseRow(
      amount: double.parse(_amountCtrl.text.trim()),
      name: _nameCtrl.text.trim(),
      category: _categoryCtrl.text.trim(),
      description: _descriptionCtrl.text.trim(),
      paidAt: _paidAt!,
    ));
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Sajili Expense'),
      content: SizedBox(
        width: 460,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _nameCtrl,
                  decoration: const InputDecoration(labelText: 'Jina la Expense'),
                  validator: (value) => value == null || value.trim().isEmpty ? 'Jaza jina la expense' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _categoryCtrl,
                  decoration: const InputDecoration(labelText: 'Category'),
                  validator: (value) => value == null || value.trim().isEmpty ? 'Jaza category' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _amountCtrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(labelText: 'Kiasi'),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) return 'Jaza kiasi';
                    if (double.tryParse(value.trim()) == null) return 'Kiasi si namba sahihi';
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                InkWell(
                  onTap: _pickDate,
                  child: InputDecorator(
                    decoration: const InputDecoration(labelText: 'Tarehe', suffixIcon: Icon(Icons.calendar_today_outlined, size: 16)),
                    child: Text(_paidAt == null ? 'Chagua tarehe' : _dateFmt.format(_paidAt!)),
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _descriptionCtrl,
                  maxLines: 2,
                  decoration: const InputDecoration(labelText: 'Maelezo (hiari)'),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Ghairi')),
        ElevatedButton(onPressed: _submit, child: const Text('Sajili')),
      ],
    );
  }
}
