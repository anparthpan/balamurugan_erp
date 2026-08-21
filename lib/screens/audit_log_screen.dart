import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models.dart';
import '../balamurugan_data.dart';

class AuditLogScreen extends StatelessWidget {
  final String? entityId;
  const AuditLogScreen({super.key, this.entityId});

  @override
  Widget build(BuildContext context) {
    final data = context.watch<BalamuruganData>();
    final logs = entityId == null 
      ? data.auditLogs 
      : data.auditLogs.where((l) => l.entityId == entityId).toList();
    
    final sortedLogs = logs.reversed.toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(entityId == null ? 'EDIT LOG (ALL)' : 'EDIT LOG: $entityId'),
        backgroundColor: Colors.white,
        foregroundColor: Theme.of(context).primaryColor,
        elevation: 2,
      ),
      body: sortedLogs.isEmpty 
        ? const Center(child: Text('No logs found for this entry'))
        : ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: sortedLogs.length,
            separatorBuilder: (context, index) => const Divider(),
            itemBuilder: (context, index) {
              final log = sortedLogs[index];
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: _getColor(log.action),
                  child: Icon(_getIcon(log.action), color: Colors.white, size: 20),
                ),
                title: Text(log.details, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 4),
                    Text('Type: ${log.entityType} | ID: ${log.entityId}'),
                    Text('Time: ${DateFormat('dd-MMM-yyyy HH:mm:ss').format(log.timestamp)}'),
                  ],
                ),
                trailing: log.previousState != null 
                  ? IconButton(
                      icon: const Icon(Icons.history),
                      onPressed: () => _showComparison(context, log),
                      tooltip: 'View Previous Version',
                    )
                  : null,
              );
            },
          ),
    );
  }

  Color _getColor(ActionType type) {
    switch (type) {
      case ActionType.create: return Colors.green;
      case ActionType.update: return Colors.blue;
      case ActionType.delete: return Colors.red;
    }
  }

  IconData _getIcon(ActionType type) {
    switch (type) {
      case ActionType.create: return Icons.add;
      case ActionType.update: return Icons.edit;
      case ActionType.delete: return Icons.delete;
    }
  }

  void _showComparison(BuildContext context, AuditLog log) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Previous Version Data'),
        content: SingleChildScrollView(
          child: Text(log.previousState ?? 'No data'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('CLOSE')),
        ],
      ),
    );
  }
}
