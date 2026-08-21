import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models.dart';
import '../balamurugan_data.dart';
import 'service_pdf_screen.dart';

class ServiceListScreen extends StatefulWidget {
  final VoidCallback? onAddJob;
  final Function(ServiceJob)? onEditJob;
  const ServiceListScreen({super.key, this.onAddJob, this.onEditJob});

  @override
  State<ServiceListScreen> createState() => _ServiceListScreenState();
}

class _ServiceListScreenState extends State<ServiceListScreen> {
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AppBar(
          title: const Text('SERVICE JOBS REGISTER'),
          elevation: 2,
          backgroundColor: Colors.white,
          foregroundColor: Theme.of(context).primaryColor,
          automaticallyImplyLeading: false,
          actions: [
            IconButton(
              onPressed: () {
                if (widget.onAddJob != null) widget.onAddJob!();
              },
              icon: const Icon(Icons.add_task),
              tooltip: 'New Service Job',
            ),
            const SizedBox(width: 10),
          ],
        ),
        Container(
          padding: const EdgeInsets.all(16),
          color: Colors.white,
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search by customer, description or job code...',
              prefixIcon: const Icon(Icons.search),
              isDense: true,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onChanged: (v) => setState(() => _searchQuery = v),
          ),
        ),
        Expanded(
          child: Consumer<BalamuruganData>(
            builder: (context, data, _) {
              final query = _searchQuery.toLowerCase();
              final filteredJobs = data.serviceJobs.where((j) =>
                j.customerName.toLowerCase().contains(query) ||
                j.description.toLowerCase().contains(query) ||
                j.jobCode.toLowerCase().contains(query)).toList();

              if (filteredJobs.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.engineering_outlined, size: 64, color: Colors.grey.shade300),
                      const SizedBox(height: 16),
                      Text(data.serviceJobs.isEmpty ? 'No service jobs found' : 'No results found',
                        style: const TextStyle(color: Colors.grey)),
                    ],
                  ),
                );
              }
              return ListView.builder(
                padding: const EdgeInsets.all(24),
                itemCount: filteredJobs.length,
                itemBuilder: (context, i) {
                  final job = filteredJobs[i];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      leading: CircleAvatar(
                        backgroundColor: _getStatusColor(job.status).withValues(alpha: 0.1),
                        child: Icon(_getStatusIcon(job.status), color: _getStatusColor(job.status)),
                      ),
                      title: Text('${job.customerName.toUpperCase()} - ${job.jobCode}', style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Padding(
                        padding: const EdgeInsets.only(top: 6.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(job.description, style: const TextStyle(fontSize: 12)),
                            if (job.serialNumber.isNotEmpty)
                              Text('S/N: ${job.serialNumber}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.blueGrey)),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Text('Eng: ${job.engineerName} | ${DateFormat('dd-MM-yy').format(job.date)}', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                                const Spacer(),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(color: _getStatusColor(job.status), borderRadius: BorderRadius.circular(4)),
                                  child: Text(job.status.name.toUpperCase(), style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold)),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text('₹ ${job.amountCharged.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                              const SizedBox(height: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: (job.isPaid ? Colors.green : Colors.red).withValues(alpha: 0.1), 
                                  borderRadius: BorderRadius.circular(4)
                                ),
                                child: Text(
                                  job.isPaid ? 'RECEIVED' : 'DUE',
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                    color: job.isPaid ? Colors.green : Colors.red,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(width: 15),
                          IconButton(
                            icon: const Icon(Icons.edit_note, color: Colors.grey),
                            onPressed: () {
                              if (widget.onEditJob != null) widget.onEditJob!(job);
                            },
                            tooltip: 'Edit Job',
                          ),
                          IconButton(
                            icon: const Icon(Icons.print, color: Colors.blue),
                            onPressed: () {
                              Navigator.push(context, MaterialPageRoute(builder: (context) => ServicePdfScreen(job: job)));
                            },
                            tooltip: 'Print Service Bill',
                          ),
                          IconButton(
                            icon: Icon(job.isPaid ? Icons.check_circle : Icons.pending_actions, color: job.isPaid ? Colors.green : Colors.red),
                            onPressed: () => data.toggleServicePaymentStatus(job.jobCode),
                            tooltip: job.isPaid ? 'Mark as Due' : 'Mark as Paid',
                          ),
                        ],
                      ),
                      isThreeLine: true,
                      onTap: () {
                        if (widget.onEditJob != null) widget.onEditJob!(job);
                      },
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Color _getStatusColor(ServiceStatus status) {
    switch (status) {
      case ServiceStatus.received: return Colors.blue;
      case ServiceStatus.diagnosing: return Colors.orange;
      case ServiceStatus.waitingForParts: return Colors.redAccent;
      case ServiceStatus.ready: return Colors.purple;
      case ServiceStatus.delivered: return Colors.green;
    }
  }

  IconData _getStatusIcon(ServiceStatus status) {
    switch (status) {
      case ServiceStatus.received: return Icons.downloading;
      case ServiceStatus.diagnosing: return Icons.biotech;
      case ServiceStatus.waitingForParts: return Icons.settings_input_component;
      case ServiceStatus.ready: return Icons.fact_check;
      case ServiceStatus.delivered: return Icons.check_circle;
    }
  }
}
