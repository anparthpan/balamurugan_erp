import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import 'balamurugan_data.dart';
import 'models.dart';
import 'utils.dart';

class TopMenuBar extends StatelessWidget {
  final VoidCallback? onHelp;
  const TopMenuBar({super.key, this.onHelp});
  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      gradient: LinearGradient(
        colors: [Theme.of(context).primaryColor, Theme.of(context).primaryColor.withValues(alpha: 0.8)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2))],
    ),
    height: 50, 
    padding: const EdgeInsets.symmetric(horizontal: 20),
    child: Row(
      children: [
        Image.asset('assets/logo.png', height: 24, width: 24),
        const SizedBox(width: 12),
        const Text('BALAMURUGAN ENTERPRISES', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
        const Spacer(),
        Consumer<BalamuruganData>(
          builder: (context, data, _) {
            if (!data.isNetworkMode) return const SizedBox.shrink();
            return Row(
              children: [
                if (data.isSyncing)
                  const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white70))
                else
                  IconButton(
                    icon: const Icon(Icons.cloud_download_outlined, color: Colors.white70, size: 20),
                    onPressed: () => data.fetchFromServer(),
                    tooltip: 'Pull data from Server',
                  ),
                const SizedBox(width: 10),
                Container(width: 1, height: 20, color: Colors.white24),
                const SizedBox(width: 10),
              ],
            );
          }
        ),
        Consumer<BalamuruganData>(
          builder: (context, data, _) {
            final user = data.currentUser;
            if (user == null) return const SizedBox.shrink();
            return Row(
              children: [
                Icon(Icons.account_circle_outlined, color: Colors.white70, size: 18),
                const SizedBox(width: 4),
                Text(
                  user.username.toUpperCase(),
                  style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                ),
                const SizedBox(width: 10),
                Container(width: 1, height: 20, color: Colors.white24),
                const SizedBox(width: 10),
              ],
            );
          }
        ),
        _topAction(Icons.help_outline, 'Help', onHelp),
      ],
    ),
  );

  Widget _topAction(IconData icon, String label, VoidCallback? onTap) {
    return InkWell(
      onTap: onTap,
      canRequestFocus: false,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            Icon(icon, color: Colors.white70, size: 16),
            const SizedBox(width: 4),
            Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}

class RightButtonBar extends StatelessWidget {
  final Map<String, VoidCallback>? actions;
  const RightButtonBar({super.key, this.actions});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 100, 
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        border: Border(left: BorderSide(color: Colors.grey.shade300)),
      ),
      child: ListView(
        padding: const EdgeInsets.symmetric(vertical: 10),
        children: [
          _F('DATE', 'F2', actions?['F2'], Icons.event),
          _F('PAYMENT', 'F5', actions?['F5'], Icons.call_made),
          _F('RECEIPT', 'F6', actions?['F6'], Icons.call_received),
          _F('JOURNAL', 'F7', actions?['F7'], Icons.history_edu),
          _F('SALES', 'F8', actions?['F8'], Icons.shopping_cart),
          _F('PURCHASE', 'F9', actions?['F9'], Icons.local_shipping),
          _F('QUOTATION', 'F11', actions?['F11'], Icons.request_quote_outlined),
          _F('PROFORMA', 'F12', actions?['F12'], Icons.receipt_long_outlined),
        ],
      ),
    );
  }
}

class _F extends StatelessWidget {
  final String label;
  final String keyName;
  final VoidCallback? onTap;
  final IconData icon;
  const _F(this.label, this.keyName, this.onTap, this.icon);

  @override
  Widget build(BuildContext context) {
    final bool isEnabled = onTap != null;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        canRequestFocus: false,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Column(
            children: [
              Icon(icon, size: 22, color: isEnabled ? Theme.of(context).primaryColor : Colors.grey.shade400),
              const SizedBox(height: 6),
              Text(label, style: TextStyle(
                fontSize: 10, 
                color: isEnabled ? Colors.black87 : Colors.grey,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              )),
              Text('($keyName)', style: TextStyle(
                fontSize: 9, 
                color: isEnabled ? Colors.grey.shade600 : Colors.grey.shade300,
              )),
            ],
          ),
        ),
      ),
    );
  }
}

class BottomStatusBar extends StatelessWidget {
  const BottomStatusBar({super.key});
  @override
  Widget build(BuildContext context) => Container(
    color: Colors.grey.shade900, 
    height: 30, 
    child: const Center(child: Text('Balamurugan Enterprises v2.0  |  Built for modern business', style: TextStyle(color: Colors.white70, fontSize: 11))));
}

class MainLayout extends StatefulWidget {
  final Widget content;
  final Map<String, VoidCallback>? rightActions;
  final int selectedIndex;
  final List<Map<String, dynamic>> menuItems;
  final Function(int) onMenuSelected;
  final VoidCallback? onHelp;
  final VoidCallback? onSettings;
  final Function(String, {dynamic extra})? onNavigate;

  const MainLayout({
    super.key, 
    required this.content, 
    this.rightActions,
    required this.selectedIndex,
    required this.menuItems,
    required this.onMenuSelected,
    this.onHelp,
    this.onSettings,
    this.onNavigate,
  });

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  final _searchController = TextEditingController();
  bool _isSearchVisible = false;
  final _searchFocusNode = FocusNode();

  void _handleGlobalKey(KeyEvent event) {
    if (event is KeyDownEvent) {
      if (HardwareKeyboard.instance.isControlPressed && event.logicalKey == LogicalKeyboardKey.keyG) {
        setState(() {
          _isSearchVisible = true;
          _searchFocusNode.requestFocus();
        });
      }
      if (event.logicalKey == LogicalKeyboardKey.escape) {
        if (_isSearchVisible) {
          setState(() => _isSearchVisible = false);
        } else {
          // If a dialog or sub-screen is not open, we could pop, but Navigator context is tricky here.
          // For now, let's just handle search closing.
        }
      }
    }
  }

  void _onSearchSubmit(String query) {
    setState(() => _isSearchVisible = false);
    try {
      final match = widget.menuItems.firstWhere((a) => a['title'].toString().toLowerCase().contains(query.toLowerCase()));
      final index = widget.menuItems.indexOf(match);
      widget.onMenuSelected(index);
    } catch (_) {
      // No match
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return KeyboardListener(
      focusNode: FocusNode(),
      onKeyEvent: _handleGlobalKey,
      child: Scaffold(
        backgroundColor: const Color(0xFFF0F2F5),
        body: Stack(
          children: [
            Column(
              children: [
                TopMenuBar(onHelp: widget.onHelp),
                Expanded(
                  child: Row(
                    children: [
                      // Permanently Fixed Sidebar
                      Container(
                        width: 260,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.05),
                              blurRadius: 10,
                              offset: const Offset(2, 0),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 20),
                            Expanded(
                              child: ListView.builder(
                                padding: const EdgeInsets.symmetric(vertical: 10),
                                itemCount: widget.menuItems.length,
                                itemBuilder: (context, index) {
                                  final item = widget.menuItems[index];
                                  final isSelected = index == widget.selectedIndex;
                                  return _sideMenuItem(item, isSelected, index);
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Main Content Area (Changes per screen)
                      Expanded(
                        child: widget.content,
                      ),
                      RightButtonBar(actions: widget.rightActions),
                    ],
                  ),
                ),
                const BottomStatusBar(),
              ],
            ),
            if (_isSearchVisible)
              GestureDetector(
                onTap: () => setState(() => _isSearchVisible = false),
                child: Container(
                  color: Colors.black54,
                  child: Center(
                    child: Container(
                      width: 500,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 20)],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.search, color: Theme.of(context).primaryColor),
                              const SizedBox(width: 10),
                              Text('GO TO', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: Theme.of(context).primaryColor)),
                              const Spacer(),
                              const Text('Ctrl+G', style: TextStyle(fontSize: 10, color: Colors.grey)),
                            ],
                          ),
                          const SizedBox(height: 16),
                          TextField(
                            controller: _searchController,
                            focusNode: _searchFocusNode,
                            autofocus: true,
                            decoration: InputDecoration(
                              hintText: 'Type to search screens...',
                              fillColor: Colors.grey.shade100,
                              filled: true,
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                            ),
                            onSubmitted: _onSearchSubmit,
                          ),
                          const SizedBox(height: 12),
                          const Text('Press Enter to Select | Esc to Cancel', style: TextStyle(fontSize: 10, color: Colors.grey)),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _sideMenuItem(Map<String, dynamic> item, bool isSelected, int index) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => widget.onMenuSelected(index),
        canRequestFocus: false,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 1),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? Theme.of(context).primaryColor : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              Icon(
                item['icon'],
                size: 20,
                color: isSelected ? Colors.white : Colors.grey.shade700,
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Text(
                  item['title'].toString(),
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.black87,
                    fontSize: 14,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  ),
                ),
              ),
              if (isSelected)
                const Icon(Icons.chevron_right, color: Colors.white70, size: 16),
            ],
          ),
        ),
      ),
    );
  }
}

class CompanyInfoPanel extends StatelessWidget {
  const CompanyInfoPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<BalamuruganData>(
      builder: (context, data, _) {
        final company = data.currentCompany;
        return LayoutBuilder(
          builder: (context, constraints) {
            final isCompact = constraints.maxWidth < 700;

            return SingleChildScrollView(
              padding: const EdgeInsets.all(30),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, spreadRadius: 2)],
                      ),
                      child: Row(
                        children: [
                          if (company.logoBase64 != null)
                            Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(color: Theme.of(context).primaryColor.withValues(alpha: 0.2), width: 2),
                              ),
                              child: ClipOval(
                                child: Image.memory(base64Decode(company.logoBase64!), width: 70, height: 70, fit: BoxFit.cover),
                              ),
                            )
                          else
                            Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(color: Theme.of(context).primaryColor.withValues(alpha: 0.2), width: 2),
                              ),
                              child: ClipOval(
                                child: Image.asset('assets/logo.png', width: 70, height: 70, fit: BoxFit.contain),
                              ),
                            ),
                          const SizedBox(width: 20),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  company.name.toUpperCase(),
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.w900,
                                    color: Theme.of(context).primaryColor,
                                    letterSpacing: 1,
                                  ),
                                  softWrap: true,
                                ),
                                const SizedBox(height: 4),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(10)),
                                  child: Text(
                                    'GSTIN: ${company.gstin.isNotEmpty ? company.gstin : "NOT SET"}',
                                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.green.shade700),
                                    softWrap: true,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 30),
                    Text('BUSINESS STATUS', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Colors.grey.shade500, letterSpacing: 2)),
                    const SizedBox(height: 20),
                    if (isCompact)
                      Column(
                        children: [
                          _statusCard(context, 'CURRENT DATE', DateFormat('dd MMM yyyy').format(DateTime.now()), Icons.today, Theme.of(context).primaryColor),
                          const SizedBox(height: 16),
                          _statusCard(context, 'PERIOD', getCurrentFinancialYear(), Icons.date_range, Colors.orange),
                        ],
                      )
                    else
                      Row(
                        children: [
                          Expanded(child: _statusCard(context, 'CURRENT DATE', DateFormat('dd MMM yyyy').format(DateTime.now()), Icons.today, Theme.of(context).primaryColor)),
                          const SizedBox(width: 20),
                          Expanded(child: _statusCard(context, 'PERIOD', getCurrentFinancialYear(), Icons.date_range, Colors.orange)),
                        ],
                      ),
                    const SizedBox(height: 20),
                    _statusCard(context, 'CONTACT', company.phone.isNotEmpty ? company.phone : 'No Phone Added', Icons.phone, Colors.green),
                    const SizedBox(height: 30),
                    Consumer<BalamuruganData>(
                      builder: (context, data, _) {
                        final lowStock = data.stockSummary.entries.where((e) {
                          final item = data.stockItems.firstWhere((s) => s.name == e.key, orElse: () => StockItem(name: ''));
                          return e.value <= item.lowStockThreshold;
                        }).toList();

                        if (lowStock.isEmpty) return const SizedBox.shrink();
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.notifications_active_outlined, color: Colors.red.shade400, size: 18),
                                const SizedBox(width: 10),
                                Text('ENTERPRISE ALERT CENTER', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Colors.red.shade400, letterSpacing: 2)),
                              ],
                            ),
                            const SizedBox(height: 15),
                            // Low Stock Warnings
                            ...lowStock.map((e) => _alertTile(
                              context, 
                              'LOW STOCK: ${e.key}', 
                              'Only ${e.value} units remaining. Please reorder.',
                              Icons.warning_amber_rounded,
                              Colors.red,
                            )),
                            // Pending Service Aging
                            ...data.serviceJobs.where((j) => 
                              j.status != ServiceStatus.delivered && 
                              DateTime.now().difference(j.date).inDays > 3
                            ).map((j) => _alertTile(
                              context,
                              'DELAYED SERVICE: ${j.jobCode}',
                              'Job for ${j.customerName} is pending for ${DateTime.now().difference(j.date).inDays} days.',
                              Icons.timer_outlined,
                              Colors.orange,
                            )),
                            const SizedBox(height: 20),
                          ],
                        );
                      }
                    ),
                    Text('FINANCIAL OVERVIEW', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Colors.grey.shade500, letterSpacing: 2)),
                    const SizedBox(height: 20),
                    SizedBox(
                      height: 360,
                      child: const DashboardCharts(),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _statusCard(BuildContext context, String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(fontSize: 9, color: Colors.grey.shade500, fontWeight: FontWeight.w900),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                  softWrap: true,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _alertTile(BuildContext context, String title, String subtitle, IconData icon, Color color) {
    return Card(
      elevation: 0,
      color: color.withValues(alpha: 0.05),
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: color.withValues(alpha: 0.1)),
      ),
      child: ListTile(
        dense: true,
        leading: Icon(icon, color: color, size: 18),
        title: Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: color)),
        subtitle: Text(subtitle, style: TextStyle(fontSize: 11, color: Colors.grey.shade700)),
      ),
    );
  }
}

class DashboardCharts extends StatelessWidget {
  const DashboardCharts({super.key});

  @override
  Widget build(BuildContext context) {
    final data = context.watch<BalamuruganData>().profitLossData;

    final sales = (data['Sales Accounts'] ?? 0).toDouble();
    final services = (data['Service Charges'] ?? 0).toDouble();
    final otherInc = (data['Other Income'] ?? 0).toDouble();
    final purchases = (data['Purchase Accounts'] ?? 0).toDouble();
    final exp = (data['Expenses'] ?? 0).toDouble();

    final totalInc = sales + services + otherInc;
    final totalExp = purchases + exp;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 800;

        final revenueCard = Card(
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: Colors.grey.shade100)),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('REVENUE VS EXPENSES', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black54)),
                const SizedBox(height: 20),
                Expanded(
                  child: BarChart(
                    BarChartData(
                      alignment: BarChartAlignment.spaceAround,
                      maxY: ((totalInc > totalExp ? totalInc : totalExp) == 0 ? 1000 : (totalInc > totalExp ? totalInc : totalExp)) * 1.2,
                      barTouchData: BarTouchData(enabled: true),
                      titlesData: FlTitlesData(
                        show: true,
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (value, meta) {
                              switch (value.toInt()) {
                                case 0: return const Padding(padding: EdgeInsets.only(top: 8), child: Text('Revenue', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)));
                                case 1: return const Padding(padding: EdgeInsets.only(top: 8), child: Text('Expenses', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)));
                                default: return const Text('');
                              }
                            },
                          ),
                        ),
                        leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      ),
                      borderData: FlBorderData(show: false),
                      barGroups: [
                        BarChartGroupData(x: 0, barRods: [BarChartRodData(toY: totalInc, color: Colors.green, width: 40, borderRadius: BorderRadius.circular(4))]),
                        BarChartGroupData(x: 1, barRods: [BarChartRodData(toY: totalExp, color: Colors.red.shade300, width: 40, borderRadius: BorderRadius.circular(4))]),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );

        final profitCard = Card(
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: Colors.grey.shade100)),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('PROFIT MARGIN', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black54)),
                const SizedBox(height: 20),
                Expanded(
                  child: totalInc == 0 && totalExp == 0
                      ? const Center(child: Text('No Data', style: TextStyle(color: Colors.grey)))
                      : PieChart(
                          PieChartData(
                            sectionsSpace: 5,
                            centerSpaceRadius: 30,
                            sections: [
                              if (totalInc > 0)
                                PieChartSectionData(
                                  value: totalInc,
                                  title: 'Inc',
                                  color: Colors.green,
                                  radius: 50,
                                  titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                                ),
                              if (totalExp > 0)
                                PieChartSectionData(
                                  value: totalExp,
                                  title: 'Exp',
                                  color: Colors.red.shade300,
                                  radius: 50,
                                  titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                                ),
                            ],
                          ),
                        ),
                ),
                const SizedBox(height: 10),
                _legendItem('Income', Colors.green),
                _legendItem('Expenses', Colors.red.shade300),
              ],
            ),
          ),
        );

        if (isCompact) {
          return Column(
            children: [
              Expanded(child: revenueCard),
              const SizedBox(height: 20),
              Expanded(child: profitCard),
            ],
          );
        }

        return Row(
          children: [
            Expanded(flex: 3, child: revenueCard),
            const SizedBox(width: 20),
            Expanded(flex: 2, child: profitCard),
          ],
        );
      },
    );
  }

  Widget _legendItem(String label, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(width: 12, height: 12, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 8),
          Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}
