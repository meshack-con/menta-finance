import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';

import '../../../core/data/client_project_store.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/web_download.dart';
import 'invoice_pdf_builder.dart';

String _fmtInvoiceMoney(num value) {
  final raw = value.round().toString();
  final buffer = StringBuffer();
  for (var i = 0; i < raw.length; i++) {
    if (i != 0 && (raw.length - i) % 3 == 0) buffer.write(',');
    buffer.write(raw[i]);
  }
  return 'TZS $buffer';
}

/// Dialog ya kuandaa na 'kuchapisha' (print/save PDF) Invoice ya malipo kwa
/// client husika, ikihusisha VAT na Discount - inafunguliwa kutoka kwenye
/// ukurasa wa Taarifa za Client (ClientDetailView), kwa kila project.
class ClientInvoiceDialog extends StatefulWidget {
  final ClientRecord client;
  final ProjectRecord project;

  const ClientInvoiceDialog({super.key, required this.client, required this.project});

  @override
  State<ClientInvoiceDialog> createState() => _ClientInvoiceDialogState();
}

class _ClientInvoiceDialogState extends State<ClientInvoiceDialog> {
  final _discountCtrl = TextEditingController(text: '0');
  final _vatCtrl = TextEditingController(text: '18');
  final _bankNameCtrl = TextEditingController(text: 'NMB Bank');
  final _accountNameCtrl = TextEditingController(text: 'Menta Studio');
  final _accountNumberCtrl = TextEditingController();
  final _notesCtrl = TextEditingController(text: 'Asante kwa kufanya kazi na Menta Studio.');
  final _dateFmt = DateFormat('dd/MM/yyyy');

  DateTime _dueDate = DateTime.now().add(const Duration(days: 14));
  _InvoiceAction? _busy;
  late final String _invoiceNumber;

  @override
  void initState() {
    super.initState();
    final year = DateTime.now().year;
    final seq = widget.project.id.replaceAll(RegExp(r'[^0-9]'), '');
    _invoiceNumber = 'INV-$year-${seq.padLeft(4, '0')}';
  }

  @override
  void dispose() {
    _discountCtrl.dispose();
    _vatCtrl.dispose();
    _bankNameCtrl.dispose();
    _accountNameCtrl.dispose();
    _accountNumberCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  double get _discount => double.tryParse(_discountCtrl.text.trim()) ?? 0;
  double get _vat => double.tryParse(_vatCtrl.text.trim()) ?? 0;

  InvoiceData get _data => InvoiceData(
        invoiceNumber: _invoiceNumber,
        issueDate: DateTime.now(),
        dueDate: _dueDate,
        client: widget.client,
        project: widget.project,
        discountPercent: _discount,
        vatPercent: _vat,
        bankName: _bankNameCtrl.text.trim(),
        accountName: _accountNameCtrl.text.trim(),
        accountNumber: _accountNumberCtrl.text.trim(),
        notes: _notesCtrl.text.trim(),
      );

  Future<void> _pickDueDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dueDate,
      firstDate: DateTime(2015),
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => _dueDate = picked);
  }

  /// Inashughulikia vitufe vyote vitatu vya Invoice: Tazama, Chapisha, Pakua.
  /// Popote programu itakapo-runiwa (Web, Android, iOS, Desktop) 'buildPdf'
  /// inazalisha bytes zilezile za PDF, kisha kila action inatumia utility
  /// ile ile ya cross-platform iliyopo kwenye 'web_download.dart' - hivyo
  /// mazingira ya kuchapisha/kutazama/kupakua yanabaki sahihi bila kujali
  /// jukwaa. 'setState(_busy = action)' inaonyesha ishara ya "inaendelea"
  /// (spinner) kwenye kitufe kilichobofywa pekee, wakati vitufe vingine
  /// vinazuiwa (disabled) hadi hatua hiyo ikamilike - bila kuathiri sehemu
  /// nyingine ya dialog (fields za Discount/VAT/Benki n.k. zinabaki kama zilivyo).
  Future<void> _run(_InvoiceAction action) async {
    setState(() => _busy = action);
    final data = _data;
    try {
      final bytes = await InvoicePdfBuilder.build(data);
      switch (action) {
        case _InvoiceAction.view:
          openPdfBytesInNewTab(bytes);
          break;
        case _InvoiceAction.print:
          await Printing.layoutPdf(onLayout: (format) async => bytes);
          break;
        case _InvoiceAction.download:
          downloadBytesAsFile(bytes, 'Invoice-$_invoiceNumber.pdf');
          break;
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Imeshindikana kuzalisha Invoice. Jaribu tena.')),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final data = _data;
    return AlertDialog(
      title: Text('Invoice - ${widget.project.name}'),
      content: SizedBox(
        width: 480,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Namba ya Invoice: $_invoiceNumber', style: const TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(height: 2),
              Text('Client: ${widget.client.name}', style: const TextStyle(color: AppColors.textSecondary, fontSize: 12.5)),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _discountCtrl,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(labelText: 'Discount (%)'),
                      onChanged: (_) => setState(() {}),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _vatCtrl,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(labelText: 'VAT (%)'),
                      onChanged: (_) => setState(() {}),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              InkWell(
                onTap: _pickDueDate,
                child: InputDecorator(
                  decoration: const InputDecoration(labelText: 'Due Date', suffixIcon: Icon(Icons.calendar_today_outlined, size: 16)),
                  child: Text(_dateFmt.format(_dueDate)),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: TextField(controller: _bankNameCtrl, decoration: const InputDecoration(labelText: 'Benki'))),
                  const SizedBox(width: 12),
                  Expanded(child: TextField(controller: _accountNameCtrl, decoration: const InputDecoration(labelText: 'Jina la Akaunti'))),
                ],
              ),
              const SizedBox(height: 12),
              TextField(controller: _accountNumberCtrl, decoration: const InputDecoration(labelText: 'Namba ya Akaunti (hiari)')),
              const SizedBox(height: 12),
              TextField(controller: _notesCtrl, maxLines: 2, decoration: const InputDecoration(labelText: 'Maelezo / Payment Terms')),
              const SizedBox(height: 18),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: AppColors.neutralGrayBg, borderRadius: BorderRadius.circular(8)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _summaryLine('Subtotal', _fmtInvoiceMoney(data.subtotal)),
                    _summaryLine('Discount', '- ${_fmtInvoiceMoney(data.discountAmount)}'),
                    _summaryLine('VAT', _fmtInvoiceMoney(data.vatAmount)),
                    const Divider(height: 18),
                    _summaryLine('Total', _fmtInvoiceMoney(data.total), bold: true),
                    _summaryLine('Amount Paid', _fmtInvoiceMoney(data.amountPaid)),
                    _summaryLine('Balance Due', _fmtInvoiceMoney(data.balanceDue), bold: true, color: AppColors.primaryGreen),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Funga')),
        _invoiceActionButton(action: _InvoiceAction.view, icon: Icons.visibility_outlined, label: 'Tazama'),
        _invoiceActionButton(action: _InvoiceAction.download, icon: Icons.download_outlined, label: 'Pakua PDF'),
        ElevatedButton.icon(
          onPressed: _busy != null ? null : () => _run(_InvoiceAction.print),
          icon: _busy == _InvoiceAction.print
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : const Icon(Icons.print_outlined, size: 18),
          label: Text(_busy == _InvoiceAction.print ? 'Inaandaa Invoice...' : 'Chapisha Invoice'),
        ),
      ],
    );
  }

  /// Kitufe cha "Tazama" / "Pakua" - kinachoonyesha spinner ndogo ndani ya
  /// yenyewe pekee kikiwa busy (bila kuathiri kitufe cha "Chapisha" wala
  /// fields nyingine za dialog).
  Widget _invoiceActionButton({required _InvoiceAction action, required IconData icon, required String label}) {
    final isBusy = _busy == action;
    return OutlinedButton.icon(
      onPressed: _busy != null ? null : () => _run(action),
      icon: isBusy
          ? const SizedBox(
              width: 15,
              height: 15,
              child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primaryGreen),
            )
          : Icon(icon, size: 17),
      label: Text(label),
    );
  }

  Widget _summaryLine(String label, String value, {bool bold = false, Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 12.5, fontWeight: bold ? FontWeight.w800 : FontWeight.w500, color: color ?? AppColors.textPrimary)),
          Text(value, style: TextStyle(fontSize: 12.5, fontWeight: bold ? FontWeight.w800 : FontWeight.w600, color: color ?? AppColors.textPrimary)),
        ],
      ),
    );
  }
}

/// Vitendo vitatu vinavyopatikana kwa Invoice - kila kimoja kina "spinner"
/// yake pekee (busy state) wakati PDF inazalishwa, bila kuathiri vitufe
/// vingine wala sehemu nyingine ya dialog.
enum _InvoiceAction { view, print, download }
