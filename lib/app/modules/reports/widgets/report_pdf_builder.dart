import 'dart:typed_data';

import 'package:flutter/services.dart' show rootBundle;
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

/// Rangi na namba za ripoti - zinafanana na branding ya Menta Studio
/// inayotumika kwenye InvoicePdfBuilder, ili ripoti zote za mfumo ziwe na
/// muonekano mmoja unaovutia (logo, rangi, fonti).
final _green = PdfColor.fromInt(0xFF2BA94E);
final _teal = PdfColor.fromInt(0xFF02A593);
final _danger = PdfColor.fromInt(0xFFD32F2F);
final _warning = PdfColor.fromInt(0xFFE6A900);
final _headerBg = PdfColor.fromInt(0xFFF4F7F5);
final _rowAltBg = PdfColor.fromInt(0xFFFAFBFA);
final _greenBg = PdfColor.fromInt(0xFFE6F6EC);
final _dangerBg = PdfColor.fromInt(0xFFFDECEA);
final _warningBg = PdfColor.fromInt(0xFFFFF6E0);
const _grey700 = PdfColors.grey700;
const _grey600 = PdfColors.grey600;

String _fmtM(num value) {
  final raw = value.round().toString();
  final buffer = StringBuffer();
  for (var i = 0; i < raw.length; i++) {
    if (i != 0 && (raw.length - i) % 3 == 0) buffer.write(',');
    buffer.write(raw[i]);
  }
  return 'TZS $buffer';
}

int _asInt(dynamic v) => v is num ? v.toInt() : int.tryParse('$v') ?? 0;
double _asDouble(dynamic v) => v is num ? v.toDouble() : double.tryParse('$v') ?? 0;
String _asStr(dynamic v) => v?.toString() ?? '-';

DateTime? _tryDate(dynamic v) {
  if (v == null) return null;
  try {
    return DateTime.parse(v.toString());
  } catch (_) {
    return null;
  }
}

/// Huzalisha ripoti (PDF) halisi za kampuni - CHANZO ni data inayotoka
/// kwenye '/api/reports/overview' (ReportsStore) - siyo mockup. Kila ripoti
/// ina logo ya Menta Studio, kichwa, tarehe ya kuzalishwa, na namba za
/// ukurasa kwenye footer, ili ionekane rasmi ikichapishwa au kupakuliwa.
class ReportPdfBuilder {
  static Future<pw.MemoryImage?> _loadLogo() async {
    try {
      final bytes = await rootBundle.load('assets/images/MENTA STUDIO-01 (1).png');
      return pw.MemoryImage(bytes.buffer.asUint8List());
    } catch (_) {
      return null;
    }
  }

  static pw.Widget _brandHeader(pw.MemoryImage? logo, String reportTitle, DateTime generatedAt) {
    final dateFmt = DateFormat('dd/MM/yyyy • HH:mm');
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [
                if (logo != null) pw.Container(width: 40, height: 40, child: pw.Image(logo)),
                if (logo != null) pw.SizedBox(width: 10),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('MENTA STUDIO', style: pw.TextStyle(fontSize: 15, fontWeight: pw.FontWeight.bold, color: _green)),
                    pw.Text('Finance & Project Management', style: pw.TextStyle(fontSize: 8, color: _grey700)),
                  ],
                ),
              ],
            ),
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                pw.Text('RIPOTI', style: pw.TextStyle(fontSize: 9, color: _grey600)),
                pw.Text('Imezalishwa: ${dateFmt.format(generatedAt)}', style: pw.TextStyle(fontSize: 8, color: _grey600)),
              ],
            ),
          ],
        ),
        pw.SizedBox(height: 10),
        pw.Divider(color: PdfColors.grey300),
        pw.SizedBox(height: 10),
        pw.Text(reportTitle, style: pw.TextStyle(fontSize: 17, fontWeight: pw.FontWeight.bold, color: PdfColors.black)),
        pw.SizedBox(height: 2),
      ],
    );
  }

  static pw.Widget _footer(pw.Context context) {
    return pw.Column(
      children: [
        pw.Divider(color: PdfColors.grey300),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text('Menta Studio - Ripoti Rasmi ya Ndani', style: pw.TextStyle(fontSize: 7.5, color: _grey600)),
            pw.Text('Ukurasa ${context.pageNumber} / ${context.pagesCount}', style: pw.TextStyle(fontSize: 7.5, color: _grey600)),
          ],
        ),
      ],
    );
  }

  static pw.Widget _sectionTitle(String text) => pw.Padding(
        padding: const pw.EdgeInsets.only(top: 16, bottom: 8),
        child: pw.Text(text, style: pw.TextStyle(fontSize: 12.5, fontWeight: pw.FontWeight.bold, color: PdfColors.black)),
      );

  static pw.Widget _statBox(String label, String value, PdfColor color) {
    return pw.Expanded(
      child: pw.Container(
        margin: const pw.EdgeInsets.only(right: 8),
        padding: const pw.EdgeInsets.all(10),
        decoration: pw.BoxDecoration(
          color: _headerBg,
          borderRadius: pw.BorderRadius.circular(6),
          border: pw.Border(left: pw.BorderSide(color: color, width: 3)),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(label, style: pw.TextStyle(fontSize: 7.5, color: _grey600)),
            pw.SizedBox(height: 3),
            pw.Text(value, style: pw.TextStyle(fontSize: 11.5, fontWeight: pw.FontWeight.bold, color: PdfColors.black)),
          ],
        ),
      ),
    );
  }

  static pw.Widget _statsRow(List<pw.Widget> boxes) => pw.Row(children: boxes);

  static pw.TableRow _theadRow(List<String> cols, {List<pw.TextAlign>? aligns}) => pw.TableRow(
        decoration: pw.BoxDecoration(color: _headerBg),
        children: [
          for (var i = 0; i < cols.length; i++)
            pw.Padding(
              padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 6),
              child: pw.Text(
                cols[i],
                style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold),
                textAlign: aligns != null ? aligns[i] : pw.TextAlign.left,
              ),
            ),
        ],
      );

  static pw.TableRow _tdataRow(List<String> cols, {List<pw.TextAlign>? aligns, bool alt = false, PdfColor? textColor}) => pw.TableRow(
        decoration: pw.BoxDecoration(color: alt ? _rowAltBg : PdfColors.white),
        children: [
          for (var i = 0; i < cols.length; i++)
            pw.Padding(
              padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 5),
              child: pw.Text(
                cols[i],
                style: pw.TextStyle(fontSize: 8.3, color: textColor ?? PdfColors.black),
                textAlign: aligns != null ? aligns[i] : pw.TextAlign.left,
              ),
            ),
        ],
      );

  static double _ratio(double value, double max) {
    if (max <= 0) return 0.0;
    final r = value / max;
    if (r < 0) return 0.0;
    if (r > 1) return 1.0;
    return r;
  }

  /// Hesabu "nadhifu" za mistari ya y-axis (0, step, 2*step, 3*step, max),
  /// zenye mzunguko wa 1/2/5x10^n, ili chati ya fedha isionyeshe namba
  /// mbaya kama 3,217,406 - badala yake ionyeshe 0 / 1M / 2M / 3M / 4M n.k.
  static List<double> _niceAxisSteps(double maxValue) {
    if (maxValue <= 0) return [0, 1, 2, 3, 4];
    var magnitude = 1.0;
    while (magnitude * 10 <= maxValue) {
      magnitude *= 10;
    }
    final normalized = maxValue / magnitude;
    double niceMax;
    if (normalized <= 1) {
      niceMax = magnitude;
    } else if (normalized <= 2) {
      niceMax = 2 * magnitude;
    } else if (normalized <= 5) {
      niceMax = 5 * magnitude;
    } else {
      niceMax = 10 * magnitude;
    }
    final step = niceMax / 4;
    return [0, step, step * 2, step * 3, niceMax];
  }

  static String _fmtAxis(num v) {
    if (v >= 1000000) {
      final m = v / 1000000;
      return '${m == m.roundToDouble() ? m.toStringAsFixed(0) : m.toStringAsFixed(1)}M';
    }
    if (v >= 1000) return '${(v / 1000).toStringAsFixed(0)}K';
    return v.toStringAsFixed(0);
  }

  static pw.TableRow _categoryBarRow(Map c, bool alt, double maxValue) {
    const double barWidth = 230;
    final width = barWidth * _ratio(_asDouble(c['total']), maxValue);
    return pw.TableRow(
      decoration: pw.BoxDecoration(color: alt ? _rowAltBg : PdfColors.white),
      children: [
        pw.Padding(
          padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 8),
          child: pw.Text(_asStr(c['category']), style: const pw.TextStyle(fontSize: 8.5)),
        ),
        pw.Padding(
          padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 8),
          child: pw.Stack(children: [
            pw.Container(
              width: barWidth,
              height: 10,
              decoration: pw.BoxDecoration(color: PdfColors.grey200, borderRadius: pw.BorderRadius.circular(4)),
            ),
            pw.Container(
              width: width,
              height: 10,
              decoration: pw.BoxDecoration(color: _teal, borderRadius: pw.BorderRadius.circular(4)),
            ),
          ]),
        ),
        pw.Padding(
          padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 8),
          child: pw.Text(_fmtM(_asInt(c['total'])), style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold), textAlign: pw.TextAlign.right),
        ),
      ],
    );
  }

  static pw.TableRow _incomeRow(Map r, int number, bool alt) => pw.TableRow(
        decoration: pw.BoxDecoration(color: alt ? _rowAltBg : PdfColors.white),
        children: [
          _cellPad('$number', align: pw.TextAlign.center),
          _cellPad(_asStr(r['project_name']), bold: true),
          _cellPad(_asStr(r['client_name'])),
          _cellPad(DateFormat('dd/MM/yyyy').format(_tryDate(r['date']) ?? DateTime.now())),
          _cellPad(_fmtM(_asInt(r['amount'])), align: pw.TextAlign.right, color: _green, bold: true),
        ],
      );

  static pw.TableRow _expenseRow(Map r, int number, bool alt) => pw.TableRow(
        decoration: pw.BoxDecoration(color: alt ? _rowAltBg : PdfColors.white),
        children: [
          _cellPad('$number', align: pw.TextAlign.center),
          _cellPad(_asStr(r['name']), bold: true),
          _cellPad(DateFormat('dd/MM/yyyy').format(_tryDate(r['date']) ?? DateTime.now())),
          _cellPad(_asStr(r['approved_by'])),
          _cellPad(_asStr(r['category'])),
          _cellPad(_fmtM(_asInt(r['amount'])), align: pw.TextAlign.right, color: _danger, bold: true),
        ],
      );

  static pw.Widget _cellPad(String text, {pw.TextAlign align = pw.TextAlign.left, PdfColor? color, bool bold = false}) => pw.Padding(
        padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 6),
        child: pw.Text(
          text,
          style: pw.TextStyle(fontSize: 8.3, color: color ?? PdfColors.black, fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal),
          textAlign: align,
        ),
      );

  static pw.Widget _totalRow(List<String> cols, Map<int, pw.TableColumnWidth> widths, {PdfColor? valueColor}) => pw.Table(
        columnWidths: widths,
        children: [
          pw.TableRow(
            decoration: pw.BoxDecoration(color: _headerBg),
            children: [
              for (var i = 0; i < cols.length; i++)
                pw.Padding(
                  padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 8),
                  child: pw.Text(
                    cols[i],
                    style: pw.TextStyle(
                      fontSize: 9,
                      fontWeight: pw.FontWeight.bold,
                      color: i == cols.length - 1 ? (valueColor ?? PdfColors.black) : PdfColors.black,
                    ),
                    textAlign: i == cols.length - 1 ? pw.TextAlign.right : pw.TextAlign.left,
                  ),
                ),
            ],
          ),
        ],
      );

  static pw.Widget _signalLine(String label, String value) => pw.Padding(
        padding: const pw.EdgeInsets.only(bottom: 8),
        child: pw.RichText(
          text: pw.TextSpan(
            children: [
              pw.TextSpan(text: '$label: ', style: pw.TextStyle(fontSize: 8.6, fontWeight: pw.FontWeight.bold, color: PdfColors.black)),
              pw.TextSpan(text: value, style: pw.TextStyle(fontSize: 8.6, color: _grey700)),
            ],
          ),
        ),
      );

  static pw.Widget _insightsPanel(String title, List<pw.Widget> lines) => pw.Container(
        padding: const pw.EdgeInsets.all(12),
        decoration: pw.BoxDecoration(
          border: pw.Border.all(color: PdfColors.grey300, width: 0.6),
          borderRadius: pw.BorderRadius.circular(6),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(title, style: pw.TextStyle(fontSize: 9.5, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 8),
            ...lines,
          ],
        ),
      );

  // ---------------------------------------------------------------------
  // 1) RIPOTI YA MAPATO NA MATUMIZI (Income vs Expenses) - CHANZO ni
  // '/api/reports/overview' (data halisi ya mfumo - Income/Expense
  // registers, mwenendo wa miezi 8, na taarifa za uongozi), ikiwa na
  // kurasa kadhaa (Muhtasari, Income Register, Wateja, Expense Register,
  // Matumizi kwa Category, na Dashboard ya Maamuzi) - kama ripoti rasmi
  // za kifedha za makampuni. Haiathiri ripoti nyingine (2, 3, 4 chini).
  // ---------------------------------------------------------------------
  static Future<Uint8List> buildFinancialMonthlyReport(Map<String, dynamic> data) async {
    final logo = await _loadLogo();
    final totals = (data['totals'] as Map?) ?? {};
    final trend8 = ((data['monthly_trend_8'] as List?) ?? (data['monthly_trend'] as List?) ?? []).cast<Map>();
    final expensesByCategory = (data['expenses_by_category'] as List?) ?? [];
    final incomeRegister = ((data['income_register'] as List?) ?? []).cast<Map>();
    final expenseRegister = ((data['expense_register'] as List?) ?? []).cast<Map>();
    final topClients = ((data['top_clients'] as List?) ?? []).cast<Map>();
    final generatedAt = _tryDate(data['generated_at']) ?? DateTime.now();
    final dateFmt = DateFormat('dd/MM/yyyy');

    final incomeTotal = _asInt(totals['income_total']);
    final expensesTotal = _asInt(totals['expenses_total']);
    final netProfit = incomeTotal - expensesTotal;
    final margin = incomeTotal > 0 ? (netProfit / incomeTotal * 100) : 0.0;
    final expenseRatio = incomeTotal > 0 ? (expensesTotal / incomeTotal * 100) : 0.0;
    final avgProjectValue = incomeRegister.isEmpty ? 0 : (incomeTotal / incomeRegister.length).round();

    Map? strongestIncome;
    for (final item in incomeRegister) {
      if (strongestIncome == null || _asInt(item['amount']) > _asInt(strongestIncome['amount'])) strongestIncome = item;
    }
    Map? largestExpense;
    for (final item in expenseRegister) {
      if (largestExpense == null || _asInt(item['amount']) > _asInt(largestExpense['amount'])) largestExpense = item;
    }
    final topProjectPercent = (incomeTotal > 0 && strongestIncome != null) ? (_asInt(strongestIncome['amount']) / incomeTotal * 100) : 0.0;

    final maxTrendValue = trend8.fold<double>(1, (max, m) {
      final inc = _asDouble(m['income']);
      final exp = _asDouble(m['expenses']);
      return [max, inc, exp].reduce((a, b) => a > b ? a : b);
    });
    final axisSteps = _niceAxisSteps(maxTrendValue);

    final maxCategoryValue = expensesByCategory.fold<double>(1, (max, c) => c['total'] != null && _asDouble(c['total']) > max ? _asDouble(c['total']) : max);

    // ---- Shughuli ya Uidhinishaji (approver -> idadi, jumla) - kutoka
    // Expense Register halisi ----
    final Map<String, List<num>> approvalMap = {};
    for (final e in expenseRegister) {
      final approver = _asStr(e['approved_by']);
      final entry = approvalMap.putIfAbsent(approver, () => [0, 0]);
      entry[0] = entry[0] + 1;
      entry[1] = entry[1] + _asInt(e['amount']);
    }
    final approvalRows = approvalMap.entries.toList()..sort((a, b) => b.value[1].compareTo(a.value[1]));

    final topCategoryName = expensesByCategory.isNotEmpty ? _asStr(expensesByCategory.first['category']) : '-';
    final topClientName = topClients.isNotEmpty ? _asStr(topClients.first['name']) : '-';

    final doc = pw.Document();

    // ---- UKURASA 1: MUHTASARI (Executive Summary) ----
    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(30),
        header: (context) => _brandHeader(logo, 'Muhtasari wa Mapato na Matumizi', generatedAt),
        footer: _footer,
        build: (context) => [
          pw.Text(
            'Muhtasari wa hali ya kifedha ya kampuni kwa sasa - mapato, matumizi, faida na shughuli - '
            'ukitumia data halisi ya mfumo (siyo mockup).',
            style: pw.TextStyle(fontSize: 9, color: _grey700),
          ),
          pw.SizedBox(height: 12),
          _statsRow([
            _statBox('JUMLA YA INCOME', _fmtM(incomeTotal), _green),
            _statBox('JUMLA YA EXPENSES', _fmtM(expensesTotal), _danger),
            _statBox('NET PROFIT (Margin ${margin.toStringAsFixed(1)}%)', _fmtM(netProfit), _teal),
            _statBox('WASTANI WA INCOME/MIAMALA', _fmtM(avgProjectValue), _warning),
          ]),
          _sectionTitle('${trend8.length}-Month Cash Performance Trend'),
          pw.Container(
            height: 200,
            padding: const pw.EdgeInsets.only(top: 6, right: 10),
            child: pw.Chart(
              grid: pw.CartesianGrid(
                xAxis: pw.FixedAxis.fromStrings(
                  [for (final t in trend8) '${t['label']}'],
                  textStyle: pw.TextStyle(fontSize: 7.5, color: _grey700),
                  divisions: true,
                ),
                yAxis: pw.FixedAxis<double>(
                  axisSteps,
                  format: (v) => _fmtAxis(v),
                  textStyle: pw.TextStyle(fontSize: 7.5, color: _grey700),
                  divisions: true,
                ),
              ),
              datasets: [
                pw.LineDataSet(
                  legend: 'Income',
                  color: _green,
                  lineWidth: 2,
                  pointSize: 2.5,
                  isCurved: true,
                  drawSurface: true,
                  surfaceColor: _green,
                  surfaceOpacity: 0.08,
                  data: [for (var i = 0; i < trend8.length; i++) pw.PointChartValue(i.toDouble(), _asDouble(trend8[i]['income']))],
                ),
                pw.LineDataSet(
                  legend: 'Expenses',
                  color: _danger,
                  lineWidth: 2,
                  pointSize: 2.5,
                  isCurved: true,
                  data: [for (var i = 0; i < trend8.length; i++) pw.PointChartValue(i.toDouble(), _asDouble(trend8[i]['expenses']))],
                ),
              ],
              overlay: pw.ChartLegend(textStyle: const pw.TextStyle(fontSize: 8)),
            ),
          ),
          _sectionTitle('Key Management Signals'),
          _insightsPanel('', [
            _signalLine('Strongest project', strongestIncome != null
                ? '${_asStr(strongestIncome['project_name'])} — ${_fmtM(_asInt(strongestIncome['amount']))}'
                : 'Hakuna data ya income bado'),
            _signalLine('Largest expense', largestExpense != null
                ? '${_asStr(largestExpense['name'])} — ${_fmtM(_asInt(largestExpense['amount']))}'
                : 'Hakuna data ya expense bado'),
            _signalLine('Expense ratio', '${expenseRatio.toStringAsFixed(1)}% ya income imetumika kwenye expenses zilizorekodiwa.'),
            _signalLine('Decision focus',
                'Linda wateja wenye mchango mkubwa (kama $topClientName), kagua gharama za category ya "$topCategoryName", '
                'na fuatilia madeni ya wateja (Outstanding: ${_fmtM(_asInt(totals['outstanding']))}).'),
          ]),
          pw.SizedBox(height: 10),
          pw.Table(
            border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
            columnWidths: const {0: pw.FlexColumnWidth(1), 1: pw.FlexColumnWidth(1.4), 2: pw.FlexColumnWidth(1), 3: pw.FlexColumnWidth(1)},
            children: [
              _theadRow(['Miamala ya Income', 'Client Mkubwa Zaidi', 'Profitability', 'Expense Control']),
              _tdataRow([
                '${incomeRegister.length}',
                topClients.isNotEmpty ? '$topClientName (${_fmtM(_asInt(topClients.first['total_income']))})' : '-',
                '${margin.toStringAsFixed(1)}%',
                '${expenseRatio.toStringAsFixed(1)}%',
              ]),
            ],
          ),
        ],
      ),
    );

    // ---- UKURASA 2: INCOME REGISTER ----
    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(30),
        header: (context) => _brandHeader(logo, 'Income Register', generatedAt),
        footer: _footer,
        build: (context) => [
          pw.Text(
            'Miamala yote ya Income iliyorekodiwa kwenye mfumo, ikionyesha project, client, tarehe na kiasi.',
            style: pw.TextStyle(fontSize: 9, color: _grey700),
          ),
          pw.SizedBox(height: 10),
          pw.Table(
            border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
            columnWidths: const {
              0: pw.FlexColumnWidth(0.5),
              1: pw.FlexColumnWidth(2.6),
              2: pw.FlexColumnWidth(2.0),
              3: pw.FlexColumnWidth(1.4),
              4: pw.FlexColumnWidth(1.6),
            },
            children: [
              _theadRow(
                ['#', 'Project Name', 'Client', 'Tarehe', 'Income (TZS)'],
                aligns: [pw.TextAlign.center, pw.TextAlign.left, pw.TextAlign.left, pw.TextAlign.left, pw.TextAlign.right],
              ),
              for (var i = 0; i < incomeRegister.length; i++) _incomeRow(incomeRegister[i], i + 1, i.isOdd),
            ],
          ),
          if (incomeRegister.isNotEmpty) ...[
            pw.SizedBox(height: 2),
            _totalRow(
              ['TOTAL INCOME', '', '', '', _fmtM(incomeTotal)],
              const {0: pw.FlexColumnWidth(0.5), 1: pw.FlexColumnWidth(2.6), 2: pw.FlexColumnWidth(2.0), 3: pw.FlexColumnWidth(1.4), 4: pw.FlexColumnWidth(1.6)},
              valueColor: _green,
            ),
          ],
        ],
      ),
    );

    // ---- UKURASA 3: TOP CLIENT CONTRIBUTION + REVENUE OBSERVATIONS ----
    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(30),
        header: (context) => _brandHeader(logo, 'Top Client Contribution', generatedAt),
        footer: _footer,
        build: (context) => [
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Expanded(
                flex: 3,
                child: pw.Table(
                  border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
                  columnWidths: const {0: pw.FlexColumnWidth(2.4), 1: pw.FlexColumnWidth(1.6)},
                  children: [
                    _theadRow(['Client', 'Jumla ya Income'], aligns: [pw.TextAlign.left, pw.TextAlign.right]),
                    for (var i = 0; i < topClients.length; i++)
                      _tdataRow(
                        [_asStr(topClients[i]['name']), _fmtM(_asInt(topClients[i]['total_income']))],
                        aligns: [pw.TextAlign.left, pw.TextAlign.right],
                        alt: i.isOdd,
                      ),
                  ],
                ),
              ),
              pw.SizedBox(width: 14),
              pw.Expanded(
                flex: 3,
                child: _insightsPanel('Revenue Observations', [
                  _signalLine('Wastani wa income kwa miamala', _fmtM(avgProjectValue)),
                  _signalLine('Income kubwa zaidi', strongestIncome != null
                      ? '${_asStr(strongestIncome['project_name'])} (${_fmtM(_asInt(strongestIncome['amount']))})'
                      : '-'),
                  _signalLine('Mchango wa miamala kubwa zaidi', '${topProjectPercent.toStringAsFixed(1)}% ya income ya mwezi/kipindi husika.'),
                  _signalLine('Ushauri', 'Linganisha income iliyopokelewa dhidi ya invoice zilizotolewa ili kubaini deni lililobaki (outstanding).'),
                ]),
              ),
            ],
          ),
        ],
      ),
    );

    // ---- UKURASA 4: EXPENSE REGISTER ----
    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(30),
        header: (context) => _brandHeader(logo, 'Expense Register', generatedAt),
        footer: _footer,
        build: (context) => [
          pw.Text(
            'Matumizi yote yaliyorekodiwa kwenye mfumo, ikijumuisha aliyeisajili (Approved By) na category yake.',
            style: pw.TextStyle(fontSize: 9, color: _grey700),
          ),
          pw.SizedBox(height: 10),
          pw.Table(
            border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
            columnWidths: const {
              0: pw.FlexColumnWidth(0.5),
              1: pw.FlexColumnWidth(2.4),
              2: pw.FlexColumnWidth(1.3),
              3: pw.FlexColumnWidth(1.6),
              4: pw.FlexColumnWidth(1.5),
              5: pw.FlexColumnWidth(1.5),
            },
            children: [
              _theadRow(
                ['#', 'Expense', 'Tarehe', 'Approved By', 'Category', 'Expense (TZS)'],
                aligns: [pw.TextAlign.center, pw.TextAlign.left, pw.TextAlign.left, pw.TextAlign.left, pw.TextAlign.left, pw.TextAlign.right],
              ),
              for (var i = 0; i < expenseRegister.length; i++) _expenseRow(expenseRegister[i], i + 1, i.isOdd),
            ],
          ),
          if (expenseRegister.isNotEmpty) ...[
            pw.SizedBox(height: 2),
            _totalRow(
              ['TOTAL EXPENSES', '', '', '', '', _fmtM(expensesTotal)],
              const {
                0: pw.FlexColumnWidth(0.5),
                1: pw.FlexColumnWidth(2.4),
                2: pw.FlexColumnWidth(1.3),
                3: pw.FlexColumnWidth(1.6),
                4: pw.FlexColumnWidth(1.5),
                5: pw.FlexColumnWidth(1.5),
              },
              valueColor: _danger,
            ),
          ],
        ],
      ),
    );

    // ---- UKURASA 5: MATUMIZI KWA CATEGORY + COST CONTROL + APPROVAL ----
    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(30),
        header: (context) => _brandHeader(logo, 'Matumizi kwa Category', generatedAt),
        footer: _footer,
        build: (context) => [
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Expanded(
                flex: 3,
                child: pw.Table(
                  border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
                  columnWidths: const {0: pw.FlexColumnWidth(1.3), 1: pw.FlexColumnWidth(2.6), 2: pw.FlexColumnWidth(1.3)},
                  children: [
                    for (var i = 0; i < expensesByCategory.length; i++) _categoryBarRow(expensesByCategory[i], i.isOdd, maxCategoryValue),
                  ],
                ),
              ),
              pw.SizedBox(width: 14),
              pw.Expanded(
                flex: 2,
                child: _insightsPanel('Cost Control Flags', [
                  _signalLine('Largest category', expensesByCategory.isNotEmpty
                      ? '$topCategoryName — ${_fmtM(_asInt(expensesByCategory.first['total']))}'
                      : '-'),
                  _signalLine('Largest single expense', largestExpense != null
                      ? '${_asStr(largestExpense['name'])} — ${_fmtM(_asInt(largestExpense['amount']))}'
                      : '-'),
                  _signalLine('Expense ratio', '${expenseRatio.toStringAsFixed(1)}% ya jumla ya expenses.'),
                  _signalLine('Ushauri', 'Hifadhi ushahidi wa uidhinishaji kwa kila expense na kagua wasambazaji/gharama zinazojirudia kila mwezi.'),
                ]),
              ),
            ],
          ),
          _sectionTitle('Approval Activity'),
          pw.Table(
            border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
            columnWidths: const {0: pw.FlexColumnWidth(2), 1: pw.FlexColumnWidth(2), 2: pw.FlexColumnWidth(2)},
            children: [
              _theadRow(['Approver', 'Idadi ya Expenses', 'Jumla Iliyoidhinishwa (TZS)'],
                  aligns: [pw.TextAlign.left, pw.TextAlign.center, pw.TextAlign.right]),
              for (var i = 0; i < approvalRows.length; i++)
                _tdataRow(
                  [approvalRows[i].key, '${approvalRows[i].value[0]}', _fmtM(approvalRows[i].value[1])],
                  aligns: [pw.TextAlign.left, pw.TextAlign.center, pw.TextAlign.right],
                  alt: i.isOdd,
                ),
            ],
          ),
        ],
      ),
    );

    // ---- UKURASA 6: MANAGEMENT DECISION DASHBOARD ----
    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(30),
        header: (context) => _brandHeader(logo, 'Management Decision Dashboard', generatedAt),
        footer: _footer,
        build: (context) => [
          pw.Text(
            'Ukurasa huu unabadilisha register za mfumo kuwa taarifa za maamuzi - kusaidia uongozi kuamua wapi kuweka '
            'nguvu, kudhibiti gharama na kulinda mtiririko wa fedha (cash flow).',
            style: pw.TextStyle(fontSize: 9, color: _grey700),
          ),
          pw.SizedBox(height: 12),
          _statsRow([
            _statBox('PROFITABILITY', '${margin.toStringAsFixed(1)}%', _green),
            _statBox('COST LOAD', '${expenseRatio.toStringAsFixed(1)}%', _danger),
            _statBox('TOP PROJECT', strongestIncome != null ? _fmtM(_asInt(strongestIncome['amount'])) : '-', _teal),
            _statBox('TOP EXPENSE', largestExpense != null ? _fmtM(_asInt(largestExpense['amount'])) : '-', _warning),
          ]),
          _sectionTitle('Management Recommendations'),
          pw.Table(
            border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
            columnWidths: const {0: pw.FlexColumnWidth(0.6), 1: pw.FlexColumnWidth(3.2), 2: pw.FlexColumnWidth(3.2)},
            children: [
              _theadRow(['#', 'Management Recommendation', 'Why It Matters']),
              _tdataRow([
                '01',
                'Fuatilia madeni ya wateja - ongeza invoice number, kiasi kilicholipwa na deni linalobaki kwenye Income Register.',
                'Inazuia mwezi wenye income kubwa kuonekana imara wakati fedha bado hazijakusanywa.',
              ]),
              _tdataRow([
                '02',
                'Weka bajeti kwa kila category (Production, Software, Operations, n.k).',
                'Inafanya matumizi ya ziada yaonekane mapema kabla hayajaathiri faida.',
              ], alt: true),
              _tdataRow([
                '03',
                'Hifadhi ushahidi wa uidhinishaji - kila expense iwe na Approved By, tarehe na hati inayothibitisha.',
                'Inaongeza uwajibikaji na kuwa tayari kwa ukaguzi (audit).',
              ]),
              _tdataRow([
                '04',
                'Kagua faida ya kila project - linganisha income ya kila project na gharama zake za moja kwa moja.',
                'Inaonyesha ni huduma au client gani anayeleta faida kubwa zaidi.',
              ], alt: true),
              _tdataRow([
                '05',
                'Fuatilia mwenendo kila mwezi kwenye dashboard na ulinganishe mwezi hadi mwezi.',
                'Inasaidia kugundua ukuaji, msimu (seasonality) na shinikizo la gharama mapema.',
              ]),
            ],
          ),
          pw.SizedBox(height: 14),
          pw.Table(
            border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
            columnWidths: const {0: pw.FlexColumnWidth(1), 1: pw.FlexColumnWidth(1), 2: pw.FlexColumnWidth(1)},
            children: [
              _tdataRow(['Prepared for', 'Reporting period', 'Currency']),
              _tdataRow(
                ['Menta Studio Administration', 'Tangu mwanzo hadi ${dateFmt.format(generatedAt)}', 'Tanzanian Shilling (TZS)'],
                alt: true,
              ),
            ],
          ),
        ],
      ),
    );

    return doc.save();
  }

  // ---------------------------------------------------------------------
  // 2) RIPOTI YA PERFORMANCE ZA PROJECTS
  // ---------------------------------------------------------------------
  static Future<Uint8List> buildProjectPerformanceReport(Map<String, dynamic> data) async {
    final logo = await _loadLogo();
    final totals = (data['totals'] as Map?) ?? {};
    final allProjects = (data['all_projects'] as List?) ?? [];
    final generatedAt = _tryDate(data['generated_at']) ?? DateTime.now();
    final dateFmt = DateFormat('dd/MM/yyyy');

    final totalProjects = allProjects.length;
    final completed = _asInt(totals['completed_projects']);
    final overdue = _asInt(totals['overdue_projects']);
    final ongoing = totalProjects - completed;
    final totalAmount = allProjects.fold<int>(0, (s, p) => s + _asInt(p['amount']));
    final totalPaid = allProjects.fold<int>(0, (s, p) => s + _asInt(p['paid']));
    final avgProgress = allProjects.isEmpty ? 0.0 : allProjects.fold<double>(0, (s, p) => s + _asDouble(p['progress_percent'])) / allProjects.length;

    String statusOf(Map p) {
      if (p['is_completed'] == true) return 'Kamili';
      if (p['is_overdue'] == true) return 'Imechelewa';
      return 'Inaendelea';
    }

    PdfColor statusColor(String s) => s == 'Kamili' ? _green : (s == 'Imechelewa' ? _danger : _warning);
    PdfColor statusBg(String s) => s == 'Kamili' ? _greenBg : (s == 'Imechelewa' ? _dangerBg : _warningBg);

    final doc = pw.Document();
    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(30),
        header: (context) => context.pageNumber == 1
            ? _brandHeader(logo, 'Ripoti ya Performance za Projects', generatedAt)
            : pw.SizedBox(),
        footer: _footer,
        build: (context) => [
          pw.SizedBox(height: 4),
          _statsRow([
            _statBox('Jumla ya Projects', '$totalProjects', _teal),
            _statBox('Zilizokamilika (Paid Kamili)', '$completed', _green),
            _statBox('Zinazoendelea', '$ongoing', _warning),
            _statBox('Zilizochelewa (Overdue)', '$overdue', _danger),
          ]),
          pw.SizedBox(height: 8),
          _statsRow([
            _statBox('Thamani Jumla ya Projects', _fmtM(totalAmount), _teal),
            _statBox('Jumla Iliyolipwa', _fmtM(totalPaid), _green),
            _statBox('Wastani wa Progress', '${avgProgress.toStringAsFixed(1)}%', _teal),
          ]),
          _sectionTitle('Orodha Kamili ya Projects (${allProjects.length})'),
          pw.Table(
            border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
            columnWidths: const {
              0: pw.FlexColumnWidth(2.4),
              1: pw.FlexColumnWidth(2.0),
              2: pw.FlexColumnWidth(1.5),
              3: pw.FlexColumnWidth(1.5),
              4: pw.FlexColumnWidth(1.5),
              5: pw.FlexColumnWidth(1.3),
              6: pw.FlexColumnWidth(1.6),
            },
            children: [
              _theadRow(
                ['Project', 'Client', 'Kiasi', 'Kimelipwa', 'Kinachodaiwa', 'Deadline', 'Hali'],
                aligns: [
                  pw.TextAlign.left,
                  pw.TextAlign.left,
                  pw.TextAlign.right,
                  pw.TextAlign.right,
                  pw.TextAlign.right,
                  pw.TextAlign.left,
                  pw.TextAlign.left,
                ],
              ),
              for (var i = 0; i < allProjects.length; i++)
                _projectRow(allProjects[i] as Map, i.isOdd, dateFmt, statusOf, statusColor, statusBg),
            ],
          ),
        ],
      ),
    );
    return doc.save();
  }

  static pw.TableRow _clientRow(Map c, bool alt) {
    final outstanding = _asInt(c['outstanding']);
    pw.Widget cell(String text, {pw.TextAlign align = pw.TextAlign.left, PdfColor? color, bool bold = false}) => pw.Padding(
          padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 5),
          child: pw.Text(
            text,
            style: pw.TextStyle(fontSize: 8.3, color: color ?? PdfColors.black, fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal),
            textAlign: align,
          ),
        );
    return pw.TableRow(
      decoration: pw.BoxDecoration(color: alt ? _rowAltBg : PdfColors.white),
      children: [
        cell(_asStr(c['name'])),
        cell(_asStr(c['phone'])),
        cell('${_asInt(c['total_projects'])}', align: pw.TextAlign.center),
        cell(_fmtM(_asInt(c['total_income'])), align: pw.TextAlign.right, color: _green),
        cell(_fmtM(outstanding), align: pw.TextAlign.right, color: outstanding > 0 ? _danger : _grey700, bold: outstanding > 0),
      ],
    );
  }

  static pw.TableRow _projectRow(
    Map p,
    bool alt,
    DateFormat dateFmt,
    String Function(Map) statusOf,
    PdfColor Function(String) statusColor,
    PdfColor Function(String) statusBg,
  ) {
    final status = statusOf(p);
    final outstanding = _asInt(p['outstanding']);
    pw.Widget cell(String text, {pw.TextAlign align = pw.TextAlign.left, PdfColor? color}) => pw.Padding(
          padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 6),
          child: pw.Text(text, style: pw.TextStyle(fontSize: 8.2, color: color ?? PdfColors.black), textAlign: align),
        );
    return pw.TableRow(
      decoration: pw.BoxDecoration(color: alt ? _rowAltBg : PdfColors.white),
      children: [
        cell(_asStr(p['name'])),
        cell(_asStr(p['client_name'])),
        cell(_fmtM(_asInt(p['amount'])), align: pw.TextAlign.right),
        cell(_fmtM(_asInt(p['paid'])), align: pw.TextAlign.right, color: _green),
        cell(_fmtM(outstanding), align: pw.TextAlign.right, color: outstanding > 0 ? _danger : _grey700),
        cell(dateFmt.format(_tryDate(p['deadline']) ?? DateTime.now())),
        pw.Padding(
          padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 6),
          child: pw.Container(
            padding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 2),
            decoration: pw.BoxDecoration(color: statusBg(status), borderRadius: pw.BorderRadius.circular(3)),
            child: pw.Text(status, style: pw.TextStyle(fontSize: 7.5, color: statusColor(status), fontWeight: pw.FontWeight.bold)),
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------
  // 3) RIPOTI YA WATEJA (CLIENTS) - Income na Outstanding kwa kila Client
  // ---------------------------------------------------------------------
  static Future<Uint8List> buildClientsReport(Map<String, dynamic> data) async {
    final logo = await _loadLogo();
    final totals = (data['totals'] as Map?) ?? {};
    final allClients = (data['all_clients'] as List?) ?? [];
    final generatedAt = _tryDate(data['generated_at']) ?? DateTime.now();

    final totalOutstanding = allClients.fold<int>(0, (s, c) => s + _asInt(c['outstanding']));
    final clientsWithDebt = allClients.where((c) => _asInt(c['outstanding']) > 0).length;

    final doc = pw.Document();
    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(30),
        header: (context) => context.pageNumber == 1 ? _brandHeader(logo, 'Ripoti ya Wateja (Clients)', generatedAt) : pw.SizedBox(),
        footer: _footer,
        build: (context) => [
          pw.SizedBox(height: 4),
          _statsRow([
            _statBox('Jumla ya Clients', '${allClients.length}', _teal),
            _statBox('Jumla ya Income (Clients Wote)', _fmtM(_asInt(totals['income_total'])), _green),
            _statBox('Jumla ya Deni (Outstanding)', _fmtM(totalOutstanding), _danger),
            _statBox('Clients Wenye Deni', '$clientsWithDebt', _warning),
          ]),
          _sectionTitle('Orodha Kamili ya Wateja (${allClients.length}) - Kwa Mpangilio wa Income'),
          pw.Table(
            border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
            columnWidths: const {
              0: pw.FlexColumnWidth(2.6),
              1: pw.FlexColumnWidth(1.8),
              2: pw.FlexColumnWidth(1.2),
              3: pw.FlexColumnWidth(1.7),
              4: pw.FlexColumnWidth(1.7),
            },
            children: [
              _theadRow(
                ['Client', 'Simu', 'Projects', 'Jumla ya Income', 'Deni (Outstanding)'],
                aligns: [pw.TextAlign.left, pw.TextAlign.left, pw.TextAlign.center, pw.TextAlign.right, pw.TextAlign.right],
              ),
              for (var i = 0; i < allClients.length; i++) _clientRow(allClients[i] as Map, i.isOdd),
            ],
          ),
        ],
      ),
    );
    return doc.save();
  }

  // ---------------------------------------------------------------------
  // 4) RIPOTI KUU YA MFUMO (MUHTASARI WA MENEJIMENTI / EXECUTIVE SUMMARY)
  // ---------------------------------------------------------------------
  static Future<Uint8List> buildExecutiveSummaryReport(Map<String, dynamic> data) async {
    final logo = await _loadLogo();
    final totals = (data['totals'] as Map?) ?? {};
    final trend = (data['monthly_trend'] as List?) ?? [];
    final topClients = (data['top_clients'] as List?) ?? [];
    final topProjects = (data['top_projects'] as List?) ?? [];
    final generatedAt = _tryDate(data['generated_at']) ?? DateTime.now();

    final doc = pw.Document();
    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(30),
        header: (context) =>
            context.pageNumber == 1 ? _brandHeader(logo, 'Ripoti Kuu ya Mfumo (Muhtasari wa Menejimenti)', generatedAt) : pw.SizedBox(),
        footer: _footer,
        build: (context) => [
          pw.SizedBox(height: 4),
          pw.Text(
            'Muhtasari huu unaonyesha hali ya kifedha na kiutendaji ya kampuni kwa ujumla, kwa lengo la kusaidia '
            'maamuzi ya kimkakati ya uongozi (mapato, matumizi, wateja wakubwa, na projects zenye mchango mkubwa).',
            style: pw.TextStyle(fontSize: 9, color: _grey700),
          ),
          pw.SizedBox(height: 12),
          _statsRow([
            _statBox('Income Mwezi Huu', _fmtM(_asInt(totals['income_month'])), _green),
            _statBox('Expenses Mwezi Huu', _fmtM(_asInt(totals['expenses_month'])), _danger),
            _statBox('Net Profit Mwezi Huu', _fmtM(_asInt(totals['net_profit_month'])), _teal),
          ]),
          pw.SizedBox(height: 8),
          _statsRow([
            _statBox('Clients', '${_asInt(totals['clients'])}', _teal),
            _statBox('Projects', '${_asInt(totals['projects'])}', _teal),
            _statBox('Services', '${_asInt(totals['services'])}', _teal),
            _statBox('Outstanding', _fmtM(_asInt(totals['outstanding'])), _warning),
          ]),
          pw.SizedBox(height: 8),
          _statsRow([
            _statBox('Projects Zilizokamilika', '${_asInt(totals['completed_projects'])}', _green),
            _statBox('Projects Zilizochelewa', '${_asInt(totals['overdue_projects'])}', _danger),
            _statBox('Income Total (Tangu Mwanzo)', _fmtM(_asInt(totals['income_total'])), _green),
          ]),
          _sectionTitle('Mwenendo wa Income vs Expenses - Miezi 6 Iliyopita'),
          pw.Table(
            border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
            columnWidths: const {0: pw.FlexColumnWidth(1.3), 1: pw.FlexColumnWidth(1.6), 2: pw.FlexColumnWidth(1.6), 3: pw.FlexColumnWidth(1.6)},
            children: [
              _theadRow(['Mwezi', 'Income', 'Expenses', 'Net'],
                  aligns: [pw.TextAlign.left, pw.TextAlign.right, pw.TextAlign.right, pw.TextAlign.right]),
              for (var i = 0; i < trend.length; i++)
                _tdataRow(
                  [
                    '${trend[i]['label']}',
                    _fmtM(_asInt(trend[i]['income'])),
                    _fmtM(_asInt(trend[i]['expenses'])),
                    _fmtM(_asInt(trend[i]['income']) - _asInt(trend[i]['expenses'])),
                  ],
                  aligns: [pw.TextAlign.left, pw.TextAlign.right, pw.TextAlign.right, pw.TextAlign.right],
                  alt: i.isOdd,
                ),
            ],
          ),
          _sectionTitle('Top Clients kwa Income'),
          pw.Table(
            border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
            columnWidths: const {0: pw.FlexColumnWidth(3), 1: pw.FlexColumnWidth(2)},
            children: [
              _theadRow(['Client', 'Jumla ya Income'], aligns: [pw.TextAlign.left, pw.TextAlign.right]),
              for (var i = 0; i < topClients.length; i++)
                _tdataRow(
                  [_asStr(topClients[i]['name']), _fmtM(_asInt(topClients[i]['total_income']))],
                  aligns: [pw.TextAlign.left, pw.TextAlign.right],
                  alt: i.isOdd,
                ),
            ],
          ),
          _sectionTitle('Top Projects kwa Malipo Yaliyokamilika'),
          pw.Table(
            border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
            columnWidths: const {0: pw.FlexColumnWidth(2.2), 1: pw.FlexColumnWidth(1.8), 2: pw.FlexColumnWidth(1.4), 3: pw.FlexColumnWidth(1.4)},
            children: [
              _theadRow(['Project', 'Client', 'Paid', 'Outstanding'],
                  aligns: [pw.TextAlign.left, pw.TextAlign.left, pw.TextAlign.right, pw.TextAlign.right]),
              for (var i = 0; i < topProjects.length; i++)
                _tdataRow(
                  [
                    _asStr(topProjects[i]['name']),
                    _asStr(topProjects[i]['client_name']),
                    _fmtM(_asInt(topProjects[i]['paid'])),
                    _fmtM(_asInt(topProjects[i]['outstanding'])),
                  ],
                  aligns: [pw.TextAlign.left, pw.TextAlign.left, pw.TextAlign.right, pw.TextAlign.right],
                  alt: i.isOdd,
                ),
            ],
          ),
        ],
      ),
    );
    return doc.save();
  }
}
