import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';
import '../balamurugan_data.dart';

class DataManagementScreen extends StatefulWidget {
  const DataManagementScreen({super.key});

  @override
  State<DataManagementScreen> createState() => _DataManagementScreenState();
}

class _DataManagementScreenState extends State<DataManagementScreen> {
  Future<void> _import() async {
    final data = context.read<BalamuruganData>();
    final messenger = ScaffoldMessenger.of(context);
    
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
      withData: true,
    );

    if (result != null && result.files.single.bytes != null) {
      final content = utf8.decode(result.files.single.bytes!);
      try {
        data.importBackup(content);
        if (mounted) {
          messenger.showSnackBar(const SnackBar(content: Text('Backup restored successfully')));
        }
      } catch (e) {
        if (mounted) {
          messenger.showSnackBar(const SnackBar(content: Text('Error: Invalid backup file')));
        }
      }
    }
  }

  Future<void> _export() async {
    final data = context.read<BalamuruganData>();
    final payload = data.exportBackup();
    final bytes = utf8.encode(payload);

    await Printing.sharePdf(
      bytes: bytes,
      filename: 'balamurugan_erp_backup_${DateTime.now().millisecondsSinceEpoch}.json',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AppBar(
          title: const Text('DATA MANAGEMENT'),
          elevation: 2,
          backgroundColor: Colors.white,
          foregroundColor: Theme.of(context).primaryColor,
          automaticallyImplyLeading: false,
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(30),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(30),
                    child: Column(
                      children: [
                        Icon(Icons.cloud_upload_outlined, size: 64, color: Theme.of(context).primaryColor.withValues(alpha: 0.5)),
                        const SizedBox(height: 24),
                        const Text('BACKUP & RESTORE', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, letterSpacing: 1.2)),
                        const SizedBox(height: 12),
                        const Text(
                          'Keep your data safe or move it to another device by exporting a JSON backup file.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey, fontSize: 14),
                        ),
                        const SizedBox(height: 40),
                        SizedBox(
                          width: double.infinity,
                          height: 55,
                          child: ElevatedButton.icon(
                            onPressed: _export,
                            icon: const Icon(Icons.download),
                            label: const Text('EXPORT BACKUP', style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          height: 55,
                          child: OutlinedButton.icon(
                            onPressed: _import,
                            icon: const Icon(Icons.upload),
                            label: const Text('RESTORE BACKUP', style: TextStyle(fontWeight: FontWeight.bold)),
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(color: Theme.of(context).primaryColor),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 40),
                const Text(
                  'Note: Your data is also automatically saved locally in this application\'s storage.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
