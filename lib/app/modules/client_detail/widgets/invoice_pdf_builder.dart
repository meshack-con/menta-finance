import 'dart:typed_data';

import 'package:flutter/services.dart' show rootBundle;
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../../core/data/client_project_store.dart';

/// Taarifa zote zinazohitajika kuzalisha Invoice moja ya PDF kwa client na
/// project fulani - VAT na Discount vinahesabiwa kutoka humu (asilimia
/// zinazowekwa na Admin kwenye ClientInvoiceDialog).
class InvoiceData {
  final String invoiceNumber;
  final DateTime issueDate;
  final DateTime dueDate;
  final ClientRecord client;
  final ProjectRecord project;
  final double discountPercent;
  final double vatPercent;
  final String bankName;
  final String accountName;
  final String accountNumber;
  final String notes;

  const InvoiceData({
    required this.invoiceNumber,
    required this.issueDate,
    required this.dueDate,
    required this.client,
    required this.project,
    required this.discountPercent,
    required this.vatPercent,
    required this.bankName,
    required this.accountName,
    required this.accountNumber,
    required this.notes,
  });

  double get subtotal => project.amount;
  double get discountAmount => subtotal * (discountPercent / 100);
  double get afterDiscount => subtotal - discountAmount;
  double get vatAmount => afterDiscount * (vatPercent / 100);
  double get total => afterDiscount + vatAmount;
  double get amountPaid => project.paid;

  // Balance Due (deni la invoice hii) haitakiwi kuwa negative - inaanza
  // na sifuri na haiendi chini ya sifuri hata kama amountPaid > total.
  double get balanceDue {
    final value = total - amountPaid;
    return value > 0 ? value : 0;
  }
}

String _fmt(num value) {
  final raw = value.round().toString();
  final buffer = StringBuffer();
  for (var i = 0; i < raw.length; i++) {
    if (i != 0 && (raw.length - i) % 3 == 0) buffer.write(',');
    buffer.write(raw[i]);
  }
  return 'TZS $buffer';
}

/// Huzalisha PDF ya Invoice kufuatana na muundo wa Menta Studio
/// (logo + jina la kampuni, Bill To, Invoice details, jedwali la
/// description/qty/unit price/amount, Subtotal/Discount/VAT/Total,
/// Amount Paid, Balance Due, na taarifa za malipo/benki).
class InvoicePdfBuilder {
  static Future<Uint8List> build(InvoiceData data) async {
    final doc = pw.Document();
    final dateFmt = DateFormat('dd/MM/yyyy');

    pw.MemoryImage? logo;
    try {
      final bytes = await rootBundle.load('assets/images/MENTA STUDIO-01 (1).png');
      logo = pw.MemoryImage(bytes.buffer.asUint8List());
    } catch (_) {
      logo = null;
    }

    final green = PdfColor.fromInt(0xFF2BA94E);
    final teal = PdfColor.fromInt(0xFF02A593);
    final headerBg = PdfColor.fromInt(0xFFF4F7F5);
    final balanceBg = PdfColor.fromInt(0xFFE6F6EC);
    final grey700 = PdfColors.grey700;
    final grey600 = PdfColors.grey600;

    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(30),
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // ---- Header: logo + jina la kampuni + INVOICE ----
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Row(
                    crossAxisAlignment: pw.CrossAxisAlignment.center,
                    children: [
                      if (logo != null) pw.Container(width: 44, height: 44, child: pw.Image(logo)),
                      if (logo != null) pw.SizedBox(width: 10),
                      pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text('MENTA STUDIO', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: green)),
                          pw.Text('Finance & Project Management', style: pw.TextStyle(fontSize: 8, color: grey700)),
                        ],
                      ),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text('INVOICE', style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold, color: teal)),
                      pw.SizedBox(height: 2),
                      pw.Text(data.invoiceNumber, style: pw.TextStyle(fontSize: 10, color: grey700)),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 10),
              pw.Divider(color: PdfColors.grey300),
              pw.SizedBox(height: 14),

              // ---- Bill To  /  Invoice details ----
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Expanded(
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('BILL TO', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: grey600)),
                        pw.SizedBox(height: 4),
                        pw.Text(data.client.name, style: pw.TextStyle(fontSize: 11.5, fontWeight: pw.FontWeight.bold)),
                        if (data.client.phone.isNotEmpty) pw.Text(data.client.phone, style: const pw.TextStyle(fontSize: 9)),
                        if (data.client.email.isNotEmpty) pw.Text(data.client.email, style: const pw.TextStyle(fontSize: 9)),
                      ],
                    ),
                  ),
                  pw.Expanded(
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        _metaLine('Invoice No', data.invoiceNumber, grey600),
                        _metaLine('Issue Date', dateFmt.format(data.issueDate), grey600),
                        _metaLine('Due Date', dateFmt.format(data.dueDate), grey600),
                        _metaLine('Project', data.project.name, grey600),
                      ],
                    ),
                  ),
                ],
              ),
              pw.SizedBox(height: 18),

              // ---- Jedwali la line item ----
              pw.Table(
                border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.6),
                columnWidths: const {
                  0: pw.FlexColumnWidth(4),
                  1: pw.FlexColumnWidth(1),
                  2: pw.FlexColumnWidth(2),
                  3: pw.FlexColumnWidth(2),
                },
                children: [
                  pw.TableRow(
                    decoration: pw.BoxDecoration(color: headerBg),
                    children: [
                      _th('Description'),
                      _th('Qty'),
                      _th('Unit Price'),
                      _th('Amount'),
                    ],
                  ),
                  pw.TableRow(
                    children: [
                      _td('${data.project.name} (${data.project.type})'),
                      _td('1', align: pw.TextAlign.center),
                      _td(_fmt(data.project.amount), align: pw.TextAlign.right),
                      _td(_fmt(data.project.amount), align: pw.TextAlign.right),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 16),

              // ---- Subtotal / Discount / VAT / Total / Paid / Balance ----
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.end,
                children: [
                  pw.SizedBox(
                    width: 240,
                    child: pw.Column(
                      children: [
                        _totalLine('Subtotal', _fmt(data.subtotal), grey700),
                        _totalLine('Discount (${data.discountPercent.toStringAsFixed(1)}%)', '- ${_fmt(data.discountAmount)}', grey700),
                        _totalLine('VAT (${data.vatPercent.toStringAsFixed(1)}%)', _fmt(data.vatAmount), grey700),
                        pw.Divider(color: PdfColors.grey400),
                        _totalLine('Total', _fmt(data.total), PdfColors.black, bold: true),
                        _totalLine('Amount Paid', _fmt(data.amountPaid), grey700),
                        pw.SizedBox(height: 4),
                        pw.Container(
                          padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                          decoration: pw.BoxDecoration(
                            color: balanceBg,
                            borderRadius: pw.BorderRadius.circular(4),
                          ),
                          child: _totalLine('Balance Due', _fmt(data.balanceDue), green, bold: true),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              pw.SizedBox(height: 20),

              // ---- Taarifa za malipo/benki ----
              pw.Text('PAYMENT DETAILS', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: grey600)),
              pw.SizedBox(height: 4),
              pw.Text('Benki: ${data.bankName}', style: const pw.TextStyle(fontSize: 9)),
              pw.Text('Jina la Akaunti: ${data.accountName}', style: const pw.TextStyle(fontSize: 9)),
              if (data.accountNumber.isNotEmpty) pw.Text('Namba ya Akaunti: ${data.accountNumber}', style: const pw.TextStyle(fontSize: 9)),

              if (data.notes.trim().isNotEmpty) ...[
                pw.SizedBox(height: 12),
                pw.Text('MAELEZO / PAYMENT TERMS', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: grey600)),
                pw.SizedBox(height: 4),
                pw.Text(data.notes, style: const pw.TextStyle(fontSize: 9)),
              ],

              pw.Spacer(),
              pw.Divider(color: PdfColors.grey300),
              pw.Center(
                child: pw.Text(
                  'Menta Studio - Asante kwa kufanya kazi nasi.',
                  style: pw.TextStyle(fontSize: 8, color: grey600),
                ),
              ),
            ],
          );
        },
      ),
    );

    return doc.save();
  }

  static pw.Widget _metaLine(String label, String value, PdfColor labelColor) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 3),
      child: pw.Row(
        children: [
          pw.SizedBox(width: 62, child: pw.Text(label, style: pw.TextStyle(fontSize: 9, color: labelColor))),
          pw.Expanded(child: pw.Text(value, style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold))),
        ],
      ),
    );
  }

  static pw.Widget _th(String text) => pw.Padding(
        padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 6),
        child: pw.Text(text, style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
      );

  static pw.Widget _td(String text, {pw.TextAlign align = pw.TextAlign.left}) => pw.Padding(
        padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 6),
        child: pw.Text(text, style: const pw.TextStyle(fontSize: 9), textAlign: align),
      );

  static pw.Widget _totalLine(String label, String value, PdfColor color, {bool bold = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label, style: pw.TextStyle(fontSize: 9, fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal, color: color)),
          pw.Text(value, style: pw.TextStyle(fontSize: 9, fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal, color: color)),
        ],
      ),
    );
  }
}
