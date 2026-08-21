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
import '../utils.dart';

class ServicePdfScreen extends StatefulWidget {
  final ServiceJob job;
  const ServicePdfScreen({super.key, required this.job});

  @override
  State<ServicePdfScreen> createState() => _ServicePdfScreenState();
}

class _ServicePdfScreenState extends State<ServicePdfScreen> {
  @override
  Widget build(BuildContext context) {
    return Consumer<BalamuruganData>(
      builder: (context, data, _) {
        final currentJob = data.serviceJobs.firstWhere((j) => j.jobCode == widget.job.jobCode, orElse: () => widget.job);
        
        return Scaffold(
          appBar: AppBar(
            title: const Text('Service Bill Preview'),
            backgroundColor: Colors.white,
            foregroundColor: Theme.of(context).primaryColor,
            elevation: 2,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => Navigator.pop(context),
            ),
            actions: [
              TextButton.icon(
                onPressed: () => data.toggleServicePaymentStatus(currentJob.jobCode),
                icon: Icon(currentJob.isPaid ? Icons.check_circle : Icons.pending_actions, color: currentJob.isPaid ? Colors.green : Colors.orange),
                label: Text(currentJob.isPaid ? 'RECEIVED' : 'DUE', style: TextStyle(color: currentJob.isPaid ? Colors.green : Colors.orange, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          body: PdfPreview(
            build: (format) => _generatePdf(format, currentJob, data),
            canDebug: false,
          ),
        );
      },
    );
  }

  Future<Uint8List> _generatePdf(PdfPageFormat format, ServiceJob job, BalamuruganData data) async {
    final pdf = pw.Document();
    final company = data.currentCompany;
    
    final logoImage = company.logoBase64 != null 
        ? pw.MemoryImage(base64Decode(company.logoBase64!)) 
        : pw.MemoryImage((await rootBundle.load('assets/logo.png')).buffer.asUint8List());

    // Generate Original and Duplicate
    final copies = ['ORIGINAL FOR RECIPIENT', 'DUPLICATE FOR SUPPLIER'];

    for (var copyLabel in copies) {
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(20),
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.stretch,
              children: _buildPageContent(job, data, company, logoImage, copyLabel),
            );
          },
        ),
      );
    }

    return pdf.save();
  }

  List<pw.Widget> _buildPageContent(ServiceJob job, BalamuruganData data, Company company, pw.MemoryImage logoImage, String copyLabel) {
    final buyer = data.findLedger(job.customerName);
    final displayAddress = buyer?.address ?? 'Address details not provided';

    return [
      // 0. COPY LABEL
      pw.Align(
        alignment: pw.Alignment.topRight,
        child: pw.Text(copyLabel, style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: PdfColors.grey700)),
      ),
      pw.SizedBox(height: 5),

      // 1. HEADER SECTION
      pw.Container(
        decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColors.black)),
        child: pw.Column(
          children: [
            pw.Padding(
              padding: const pw.EdgeInsets.all(10),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Expanded(
                    flex: 2,
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Row(
                          crossAxisAlignment: pw.CrossAxisAlignment.center,
                          children: [
                            pw.Image(logoImage, width: 50, height: 50),
                            pw.SizedBox(width: 10),
                            pw.Text(company.name.toUpperCase(), style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: PdfColors.black)),
                          ],
                        ),
                        pw.Text('All Brands of Desktops, Laptops and Printers Sales and Service. CCTV Sales & Installation', style: const pw.TextStyle(fontSize: 8, color: PdfColors.black)),
                        pw.SizedBox(height: 5),
                        pw.Text(company.address, style: const pw.TextStyle(fontSize: 8, color: PdfColors.black)),
                        if (company.gstin.isNotEmpty) pw.Text('GSTIN ${company.gstin}', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: PdfColors.black)),
                        pw.Text('Phone - ${company.phone}', style: const pw.TextStyle(fontSize: 8, color: PdfColors.black)),
                      ],
                    ),
                  ),
                  pw.Expanded(
                    child: pw.Text('SERVICE BILL', textAlign: pw.TextAlign.right, style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold, color: PdfColors.black)),
                  ),
                ],
              ),
            ),
            
            // 2. METADATA GRID
            pw.Divider(height: 1, color: PdfColors.black),
            pw.Table(
              border: const pw.TableBorder(verticalInside: pw.BorderSide(color: PdfColors.black)),
              columnWidths: {
                0: const pw.FlexColumnWidth(),
                1: const pw.FlexColumnWidth(),
              },
              children: [
                pw.TableRow(
                  children: [
                    pw.Column(
                      children: [
                        _metaRow('Job Code', ': ${job.jobCode}'),
                        _metaRow('Date', ': ${DateFormat('dd/MM/yyyy').format(job.date)}'),
                        _metaRow('Engineer', ': ${job.engineerName}'),
                      ],
                    ),
                    pw.Column(
                      children: [
                        _metaRow('Place Of Service', ': Tamil Nadu (33)'),
                      ],
                    ),
                  ],
                ),
              ],
            ),

            // 3. CUSTOMER DETAILS
            pw.Divider(height: 1, color: PdfColors.black),
            pw.Container(
              width: double.infinity,
              color: PdfColors.grey100,
              padding: const pw.EdgeInsets.all(5),
              child: pw.Text('Customer Details', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9, color: PdfColors.black)),
            ),
            pw.Divider(height: 1, color: PdfColors.black),
            pw.Container(
              width: double.infinity,
              padding: const pw.EdgeInsets.all(8),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(job.customerName.toUpperCase(), style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10, color: PdfColors.black)),
                  pw.Text(displayAddress, style: const pw.TextStyle(fontSize: 8, color: PdfColors.black)),
                  if (buyer?.phone.isNotEmpty ?? false) pw.Text('Phone: ${buyer!.phone}', style: const pw.TextStyle(fontSize: 8, color: PdfColors.black)),
                ],
              ),
            ),
          ],
        ),
      ),

      pw.SizedBox(height: 15),

      // 4. SERVICE TABLE
      pw.Expanded(
        child: pw.Container(
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: PdfColors.black, width: 0.5),
          ),
          child: pw.Table(
            border: const pw.TableBorder(
              verticalInside: pw.BorderSide(color: PdfColors.black, width: 0.5),
            ),
            columnWidths: {
              0: const pw.FixedColumnWidth(40),
              1: const pw.FlexColumnWidth(),
              2: const pw.FixedColumnWidth(100),
            },
            children: [
              pw.TableRow(
                decoration: const pw.BoxDecoration(
                  color: PdfColors.grey200,
                  border: pw.Border(bottom: pw.BorderSide(color: PdfColors.black, width: 0.5)),
                ),
                children: [
                  _tableH('S.NO'),
                  _tableH('SERVICE DESCRIPTION'),
                  _tableH('CHARGES'),
                ],
              ),
              pw.TableRow(
                children: [
                  _tableD('1'),
                  _pdfDescriptionCell(job.description, serial: job.serialNumber, diagnosis: job.diagnosis),
                  _tableD(job.amountCharged.toStringAsFixed(2), align: pw.TextAlign.right, bold: true),
                ],
              ),
            ],
          ),
        ),
      ),

      pw.Container(
        decoration: pw.BoxDecoration(
          border: pw.Border(
            left: pw.BorderSide(color: PdfColors.black, width: 0.5),
            right: pw.BorderSide(color: PdfColors.black, width: 0.5),
            bottom: pw.BorderSide(color: PdfColors.black, width: 0.5),
          ),
        ),
        child: pw.Table(
          border: const pw.TableBorder(verticalInside: pw.BorderSide(color: PdfColors.black)),
          columnWidths: {
            0: const pw.FlexColumnWidth(3),
            1: const pw.FlexColumnWidth(2),
          },
          children: [
            pw.TableRow(
              children: [
                pw.Padding(
                  padding: const pw.EdgeInsets.all(10),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('Total In Words', style: const pw.TextStyle(fontSize: 7, color: PdfColors.black)),
                      pw.Text('${numberToWords(job.amountCharged)} Only', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, fontStyle: pw.FontStyle.italic, color: PdfColors.black)),
                      pw.SizedBox(height: 15),
                      pw.Text('Terms & Conditions', style: pw.TextStyle(fontSize: 8, decoration: pw.TextDecoration.underline, fontWeight: pw.FontWeight.bold, color: PdfColors.black)),
                      pw.Text('1. Goods once sold cannot be taken back/ Exchange due to any reasons.', style: const pw.TextStyle(fontSize: 7, color: PdfColors.black)),
                      pw.Text('2. Product warranty terms & conditions as per the manufacturer\'s warranty.', style: const pw.TextStyle(fontSize: 7, color: PdfColors.black)),
                      pw.Text('3. Subject to Tamil Nadu Jurisdiction.', style: const pw.TextStyle(fontSize: 7, color: PdfColors.black)),
                    ],
                  ),
                ),
                pw.Column(
                  children: [
                    _calcRow('Total Charges', job.amountCharged.toStringAsFixed(2), bold: true, fontSize: 12),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),

      // 6. BOTTOM SECTION (Bank, Signature)
      pw.SizedBox(height: 15),
      pw.Container(
        decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColors.black, width: 0.5)),
        child: pw.Table(
          border: const pw.TableBorder(verticalInside: pw.BorderSide(color: PdfColors.black)),
          columnWidths: {
            0: const pw.FlexColumnWidth(3),
            1: const pw.FlexColumnWidth(2),
          },
          children: [
            pw.TableRow(
              children: [
                pw.Padding(
                  padding: const pw.EdgeInsets.symmetric(vertical: 6.0, horizontal: 10.0),
                  child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text('Company Bank Details:', style: pw.TextStyle(fontSize: 8, decoration: pw.TextDecoration.underline, fontWeight: pw.FontWeight.bold, color: PdfColors.black)),
                          pw.Text('Name: ${company.beneficiaryName.isNotEmpty ? company.beneficiaryName : company.name}', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: PdfColors.black)),
                          pw.Text('Ac/No : ${company.accNo}', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: PdfColors.black)),
                          pw.Text('IFSC : ${company.ifsc}', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: PdfColors.black)),
                          pw.Text('Bank Name: ${company.bankName}', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: PdfColors.black)),
                        ],
                      ),
                      if (company.upiId.isNotEmpty)
                        pw.Column(
                          mainAxisAlignment: pw.MainAxisAlignment.center,
                          children: [
                            pw.BarcodeWidget(
                              data: 'upi://pay?pa=${company.upiId}&pn=${company.name}&am=${job.amountCharged.toStringAsFixed(2)}&cu=INR',
                              barcode: pw.Barcode.qrCode(),
                              width: 50,
                              height: 50,
                            ),
                            pw.SizedBox(height: 2),
                            pw.Text('SCAN TO PAY', style: pw.TextStyle(fontSize: 6, fontWeight: pw.FontWeight.bold)),
                          ],
                        ),
                    ],
                  ),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.symmetric(vertical: 6.0, horizontal: 10.0),
                  child: pw.Column(
                    mainAxisAlignment: pw.MainAxisAlignment.center,
                    crossAxisAlignment: pw.CrossAxisAlignment.center,
                    children: [
                      pw.Text('For BALAMURUGAN ENTERPRISES', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: PdfColors.black)),
                      pw.SizedBox(height: 5),
                      pw.Container(width: 120, height: 30, decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColors.black, style: pw.BorderStyle.dashed))),
                      pw.SizedBox(height: 5),
                      pw.Text('Authorized Signature', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: PdfColors.black)),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ];
  }

  pw.Widget _metaRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      child: pw.Row(
        children: [
          pw.SizedBox(width: 80, child: pw.Text(label, style: const pw.TextStyle(fontSize: 8, color: PdfColors.black))),
          pw.Text(value, style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: PdfColors.black)),
        ],
      ),
    );
  }

  pw.Widget _tableH(String text) => pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text(text, textAlign: pw.TextAlign.center, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8, color: PdfColors.black)));
  
  pw.Widget _tableD(String text, {pw.TextAlign align = pw.TextAlign.center, bool bold = false}) => pw.Padding(
    padding: const pw.EdgeInsets.all(5), 
    child: pw.Text(text, textAlign: align, style: pw.TextStyle(fontSize: 8, fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal, color: PdfColors.black))
  );

  pw.Widget _pdfDescriptionCell(String text, {String? serial, String? diagnosis}) {
    String header = '';
    String specs = '';

    if (text.contains('\n')) {
      final lines = text.split('\n');
      header = lines[0].trim();
      specs = lines.sublist(1).join('\n').trim();
    } else if (text.contains(',')) {
      final commaIndex = text.indexOf(',');
      header = text.substring(0, commaIndex).trim();
      specs = text.substring(commaIndex + 1).trim();
    } else {
      header = text.trim();
    }

    return pw.Padding(
      padding: const pw.EdgeInsets.all(5),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text('COMPLAINT: ${header.toUpperCase()}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9, color: PdfColors.black)),
          if (specs.isNotEmpty) ...[
            pw.SizedBox(height: 2),
            pw.Text(specs, style: const pw.TextStyle(fontSize: 8, color: PdfColors.black)),
          ],
          if (serial != null && serial.isNotEmpty) ...[
            pw.SizedBox(height: 2),
            pw.Text('Serial No: $serial', style: pw.TextStyle(fontSize: 7, fontWeight: pw.FontWeight.bold, color: PdfColors.grey900)),
          ],
          if (diagnosis != null && diagnosis.isNotEmpty) ...[
            pw.SizedBox(height: 6),
            pw.Container(
              padding: const pw.EdgeInsets.all(4),
              decoration: const pw.BoxDecoration(color: PdfColors.grey100),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('DIAGNOSTIC REPORT / FINDINGS:', style: pw.TextStyle(fontSize: 7, fontWeight: pw.FontWeight.bold, color: PdfColors.blueGrey800)),
                  pw.SizedBox(height: 2),
                  pw.Text(diagnosis, style: const pw.TextStyle(fontSize: 8, color: PdfColors.black)),
                ],
              ),
            ),
          ],
          pw.SizedBox(height: 25), // Increased breathing room at the bottom
        ],
      ),
    );
  }

  pw.Widget _calcRow(String label, String value, {bool bold = false, double fontSize = 9}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label, style: pw.TextStyle(fontSize: fontSize, fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal, color: PdfColors.black)),
          pw.Text(value, style: pw.TextStyle(fontSize: fontSize, fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal, color: PdfColors.black)),
        ],
      ),
    );
  }
}
