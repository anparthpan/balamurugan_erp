import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';
import '../models.dart';
import '../balamurugan_data.dart';

class StatementPdfScreen extends StatelessWidget {
  final String customerName;
  final DateTime startDate;
  final DateTime endDate;
  final List<Map<String, dynamic>> statement;

  const StatementPdfScreen({
    super.key,
    required this.customerName,
    required this.startDate,
    required this.endDate,
    required this.statement,
  });

  @override
  Widget build(BuildContext context) {
    final data = context.read<BalamuruganData>();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Statement Print Preview'),
        backgroundColor: Colors.white,
        foregroundColor: Theme.of(context).primaryColor,
        elevation: 2,
      ),
      body: PdfPreview(
        build: (format) => _generatePdf(format, data),
        canDebug: false,
      ),
    );
  }

  Future<Uint8List> _generatePdf(PdfPageFormat format, BalamuruganData data) async {
    final pdf = pw.Document();
    final company = data.currentCompany;
    final buyer = data.findLedger(customerName);

    final logoImage = company.logoBase64 != null 
        ? pw.MemoryImage(base64Decode(company.logoBase64!)) 
        : pw.MemoryImage((await rootBundle.load('assets/logo.png')).buffer.asUint8List());

    double totalBilled = 0;
    double totalReceived = 0;
    for (var row in statement) {
      totalBilled += (row['billed'] as double);
      totalReceived += (row['received'] as double);
    }
    final finalBalance = totalBilled - totalReceived;

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(30),
        header: (context) => _buildHeader(company, logoImage),
        footer: (context) => _buildFooter(context),
        build: (context) => [
          pw.SizedBox(height: 20),
          _buildSubHeader(buyer),
          pw.SizedBox(height: 20),
          _buildStatementTable(),
          _buildSignatureAndQr(company, finalBalance),
        ],
      ),
    );

    return pdf.save();
  }

  pw.Widget _buildHeader(Company company, pw.MemoryImage logo) {
    return pw.Column(
      children: [
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Row(
                  children: [
                    pw.Image(logo, width: 40, height: 40),
                    pw.SizedBox(width: 10),
                    pw.Text(company.name.toUpperCase(), style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
                  ],
                ),
                pw.SizedBox(height: 5),
                pw.Text(company.address, style: const pw.TextStyle(fontSize: 8)),
                pw.Text('Phone: ${company.phone}', style: const pw.TextStyle(fontSize: 8)),
                if (company.gstin.isNotEmpty) pw.Text('GSTIN: ${company.gstin}', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
              ],
            ),
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                pw.Text('ACCOUNT STATEMENT', style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold, color: PdfColors.grey700)),
                pw.SizedBox(height: 5),
                pw.Text('Period: ${DateFormat('dd-MMM-yyyy').format(startDate)} to ${DateFormat('dd-MMM-yyyy').format(endDate)}', style: const pw.TextStyle(fontSize: 9)),
              ],
            ),
          ],
        ),
        pw.Divider(thickness: 1, color: PdfColors.black),
      ],
    );
  }

  pw.Widget _buildSubHeader(Master? buyer) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey400),
        color: PdfColors.grey100,
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text('Statement For:', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700)),
          pw.Text(customerName.toUpperCase(), style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
          if (buyer != null) ...[
            pw.Text(buyer.address, style: const pw.TextStyle(fontSize: 9)),
            pw.Text('Phone: ${buyer.phone}', style: const pw.TextStyle(fontSize: 9)),
            if (buyer.gstin.isNotEmpty) pw.Text('GSTIN: ${buyer.gstin}', style: const pw.TextStyle(fontSize: 9)),
          ],
        ],
      ),
    );
  }

  pw.Widget _buildStatementTable() {
    double runningBalance = 0;
    double totalBilled = 0;
    double totalReceived = 0;

    final rows = statement.map((row) {
      final billed = row['billed'] as double;
      final received = row['received'] as double;
      totalBilled += billed;
      totalReceived += received;
      runningBalance += (billed - received);

      return pw.TableRow(
        children: [
          _cell(DateFormat('dd-MMM-yy').format(row['date'])),
          _cell(row['particulars'], align: pw.TextAlign.left),
          _cell(billed > 0 ? billed.toStringAsFixed(2) : ''),
          _cell(received > 0 ? received.toStringAsFixed(2) : ''),
          _cell(runningBalance.toStringAsFixed(2), bold: true),
        ],
      );
    }).toList();

    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey400),
      columnWidths: {
        0: const pw.FixedColumnWidth(60),
        1: const pw.FlexColumnWidth(),
        2: const pw.FixedColumnWidth(80),
        3: const pw.FixedColumnWidth(80),
        4: const pw.FixedColumnWidth(80),
      },
      children: [
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.grey200),
          children: [
            _headerCell('Date'),
            _headerCell('Particulars'),
            _headerCell('Billed (Dr)'),
            _headerCell('Received (Cr)'),
            _headerCell('Balance'),
          ],
        ),
        ...rows,
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.grey100),
          children: [
            _cell(''),
            _cell('TOTAL / CLOSING BALANCE', bold: true, align: pw.TextAlign.right),
            _cell(totalBilled.toStringAsFixed(2), bold: true),
            _cell(totalReceived.toStringAsFixed(2), bold: true),
            _cell(runningBalance.toStringAsFixed(2), bold: true),
          ],
        ),
      ],
    );
  }

  pw.Widget _buildSignatureAndQr(Company company, double balance) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(top: 30),
      child: pw.Row(
        children: [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('For ${company.name.toUpperCase()}', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 30),
              pw.Text('Authorized Signature', style: const pw.TextStyle(fontSize: 9)),
            ],
          ),
          if (company.upiId.isNotEmpty && balance > 0) ...[
            pw.Spacer(),
            pw.Column(
              children: [
                pw.BarcodeWidget(
                  data: 'upi://pay?pa=${company.upiId}&pn=${company.name}&am=${balance.toStringAsFixed(2)}&cu=INR',
                  barcode: pw.Barcode.qrCode(),
                  width: 60,
                  height: 60,
                ),
                pw.SizedBox(height: 4),
                pw.Text('SCAN TO PAY OUTSTANDING', style: pw.TextStyle(fontSize: 7, fontWeight: pw.FontWeight.bold)),
              ],
            ),
          ],
        ],
      ),
    );
  }

  pw.Widget _headerCell(String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(5),
      child: pw.Text(text, textAlign: pw.TextAlign.center, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9)),
    );
  }

  pw.Widget _cell(String text, {bool bold = false, pw.TextAlign align = pw.TextAlign.right}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(5),
      child: pw.Text(text, textAlign: align, style: pw.TextStyle(fontSize: 9, fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal)),
    );
  }

  pw.Widget _buildFooter(pw.Context context) {
    return pw.Column(
      children: [
        pw.Divider(thickness: 1, color: PdfColors.grey400),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text('Generated on ${DateFormat('dd-MMM-yyyy HH:mm').format(DateTime.now())}', style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey700)),
            pw.Text('Page ${context.pageNumber} of ${context.pagesCount}', style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey700)),
          ],
        ),
      ],
    );
  }
}
