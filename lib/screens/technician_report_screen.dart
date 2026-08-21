import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../balamurugan_data.dart';
import '../models.dart';

class TechnicianReportScreen extends StatefulWidget {
  const TechnicianReportScreen({super.key});

  @override
  State<TechnicianReportScreen> createState() => _TechnicianReportScreenState();
}

class _TechnicianReportScreenState extends State<TechnicianReportScreen> {
  DateTimeRange? _dateRange;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Default to current month
    final now = DateTime.now();
    _dateRange = DateTimeRange(
      start: DateTime(now.year, now.month, 1),
      end: DateTime(now.year, now.month, now.day, 23, 59, 59),
    );
  }

  @override
  Widget build(BuildContext context) {
    final data = context.watch<BalamuruganData>();
    final performance = data.getFilteredTechnicianPerformance(
      start: _dateRange?.start,
      end: _dateRange?.end,
    );

    // Apply search filter
    final filteredPerformance = performance.entries.where((e) {
      return e.key.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();

    // Calculate Summary KPIs
    double totalRevenue = 0;
    int totalJobs = 0;
    int completedJobs = 0;
    for (var stats in performance.values) {
      totalRevenue += stats['totalRevenue'];
      totalJobs += stats['totalJobs'] as int;
      completedJobs += stats['completedJobs'] as int;
    }
    final avgCompletionRate = totalJobs > 0 ? (completedJobs / totalJobs * 100) : 0.0;

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('TECHNICIAN PERFORMANCE'),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_month),
            onPressed: _selectDateRange,
            tooltip: 'Select Period',
          ),
        ],
      ),
      body: Column(
        children: [
          _buildPeriodIndicator(),
          _buildSummaryCards(totalRevenue, totalJobs, completedJobs, avgCompletionRate),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search Technician...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
              onChanged: (value) => setState(() => _searchQuery = value),
            ),
          ),
          Expanded(
            child: filteredPerformance.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: filteredPerformance.length,
                    itemBuilder: (context, index) {
                      final engineer = filteredPerformance[index].key;
                      final stats = filteredPerformance[index].value;
                      return _buildTechnicianCard(engineer, stats);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildPeriodIndicator() {
    final fmt = DateFormat('dd MMM yyyy');
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      color: Theme.of(context).primaryColor.withValues(alpha: 0.05),
      child: Row(
        children: [
          Icon(Icons.timer_outlined, size: 14, color: Colors.grey.shade700),
          const SizedBox(width: 8),
          Text(
            'PERIOD: ${fmt.format(_dateRange!.start)} - ${fmt.format(_dateRange!.end)}',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade700,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCards(double revenue, int jobs, int completed, double rate) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: GridView.count(
        shrinkWrap: true,
        crossAxisCount: 2,
        childAspectRatio: 2.5,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        physics: const NeverScrollableScrollPhysics(),
        children: [
          _kpiCard('TOTAL REVENUE', '₹ ${revenue.toStringAsFixed(0)}', Colors.green, Icons.payments),
          _kpiCard('TOTAL JOBS', jobs.toString(), Colors.blue, Icons.assignment),
          _kpiCard('COMPLETED', completed.toString(), Colors.indigo, Icons.check_circle),
          _kpiCard('SUCCESS RATE', '${rate.toStringAsFixed(1)}%', Colors.orange, Icons.trending_up),
        ],
      ),
    );
  }

  Widget _kpiCard(String label, String value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.1), shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(label, style: TextStyle(fontSize: 9, color: Colors.grey.shade600, fontWeight: FontWeight.bold)),
                Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTechnicianCard(String name, Map<String, dynamic> stats) {
    final int total = stats['totalJobs'];
    final int done = stats['completedJobs'];
    final double revenue = stats['totalRevenue'];
    final double rate = total > 0 ? (done / total) : 0.0;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _showActivityLog(name),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: Colors.blue.shade50,
                    child: Text(name[0].toUpperCase(), style: TextStyle(color: Colors.blue.shade800, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(name.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                        Text('$total Jobs Assigned', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('₹ ${revenue.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.w900, color: Colors.green)),
                      Text('${(rate * 100).toStringAsFixed(0)}% Success', style: TextStyle(fontSize: 10, color: Colors.grey.shade500)),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: LinearProgressIndicator(
                  value: rate,
                  minHeight: 6,
                  backgroundColor: Colors.grey.shade100,
                  valueColor: AlwaysStoppedAnimation(rate > 0.8 ? Colors.green : (rate > 0.5 ? Colors.orange : Colors.red)),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _miniStat('PENDING', (total - done).toString()),
                  _miniStat('COMPLETED', done.toString()),
                  TextButton.icon(
                    onPressed: () => _showActivityLog(name),
                    icon: const Icon(Icons.history, size: 16),
                    label: const Text('EDIT LOG', style: TextStyle(fontSize: 12)),
                    style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _miniStat(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 8, color: Colors.grey.shade500, fontWeight: FontWeight.bold)),
        Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.engineering_outlined, size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text('No technicians found for this period', style: TextStyle(color: Colors.grey.shade600)),
          if (_searchQuery.isNotEmpty)
            TextButton(onPressed: () => setState(() {
              _searchController.clear();
              _searchQuery = '';
            }), child: const Text('Clear Search')),
        ],
      ),
    );
  }

  Future<void> _selectDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDateRange: _dateRange,
    );
    if (picked != null) {
      setState(() => _dateRange = picked);
    }
  }

  void _showActivityLog(String engineerName) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _ActivityLogSheet(
        engineerName: engineerName,
        start: _dateRange?.start,
        end: _dateRange?.end,
      ),
    );
  }
}

class _ActivityLogSheet extends StatelessWidget {
  final String engineerName;
  final DateTime? start;
  final DateTime? end;

  const _ActivityLogSheet({
    required this.engineerName,
    this.start,
    this.end,
  });

  @override
  Widget build(BuildContext context) {
    final data = context.read<BalamuruganData>();
    final jobs = data.getTechnicianJobs(engineerName, start: start, end: end);

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          Container(
            margin: const EdgeInsets.only(top: 12, bottom: 8),
            width: 40,
            height: 4,
            decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$engineerName\'s ACTIVITY LOG',
                        style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
                      ),
                      Text(
                        'Total ${jobs.length} jobs in this period',
                        style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close)),
              ],
            ),
          ),
          const Divider(),
          Expanded(
            child: jobs.isEmpty
                ? const Center(child: Text('No activity found for this period'))
                : ListView.separated(
                    padding: const EdgeInsets.all(20),
                    itemCount: jobs.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final job = jobs[index];
                      return _buildJobLogItem(context, job);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildJobLogItem(BuildContext context, ServiceJob job) {
    Color statusColor;
    switch (job.status) {
      case ServiceStatus.delivered: statusColor = Colors.green; break;
      case ServiceStatus.ready: statusColor = Colors.blue; break;
      case ServiceStatus.waitingForParts: statusColor = Colors.orange; break;
      case ServiceStatus.diagnosing: statusColor = Colors.purple; break;
      case ServiceStatus.received: statusColor = Colors.grey; break;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(DateFormat('dd MMM yyyy').format(job.date), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.blueGrey)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(4)),
                child: Text(
                  job.status.name.toUpperCase(),
                  style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: statusColor),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(job.jobCode, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14)),
          Text('Customer: ${job.customerName}', style: const TextStyle(fontSize: 12)),
          const SizedBox(height: 4),
          Text('Description: ${job.description}', style: TextStyle(fontSize: 11, color: Colors.grey.shade700)),
          const Divider(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                job.isPaid ? 'PAID' : 'UNPAID',
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: job.isPaid ? Colors.green : Colors.red),
              ),
              Text(
                '₹ ${job.amountCharged.toStringAsFixed(2)}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
