import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../balamurugan_data.dart';
import '../models.dart';
import '../ui_components.dart';
import 'create_master_screen.dart';
import 'alter_master_list_screen.dart';
import 'voucher_entry_screen.dart';
import 'day_book_screen.dart';
import 'balance_sheet_screen.dart';
import 'profit_loss_screen.dart';
import 'stock_summary_screen.dart';
import 'data_management_screen.dart';
import 'service_list_screen.dart';
import 'service_entry_screen.dart';
import 'ledger_entry_screen.dart';
import 'stock_item_entry_screen.dart';
import 'ageing_report_screen.dart';
import 'customer_statement_screen.dart';
import 'login_screen.dart';
import 'audit_log_screen.dart';
import 'company_settings_screen.dart';
import 'technician_report_screen.dart';
import 'sales_person_report_screen.dart';
import 'user_management_screen.dart';

class BalamuruganHomeScreen extends StatefulWidget {
  const BalamuruganHomeScreen({super.key});

  @override
  State<BalamuruganHomeScreen> createState() => _BalamuruganHomeScreenState();
}

class _BalamuruganHomeScreenState extends State<BalamuruganHomeScreen> {
  int _selectedIndex = 0;
  String _currentAction = 'home';
  Voucher? _editingVoucher;
  ServiceJob? _editingJob;
  int? _editingMasterIndex;
  Master? _editingMaster;
  StockItem? _editingStockItem;
  VoucherType? _initialVoucherType;

  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
      context.read<BalamuruganData>().fetchFromServer();
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  final List<Map<String, dynamic>> _menuItems = [
    {'title': 'Dashboard', 'action': 'home', 'icon': Icons.dashboard},
    {'title': 'Create Master', 'action': 'create', 'icon': Icons.add_business},
    {'title': 'Alter Master', 'action': 'alter', 'icon': Icons.edit_note},
    {'title': 'Voucher Entry', 'action': 'vouchers', 'icon': Icons.receipt,},
    {'title': 'Day Book', 'action': 'daybook', 'icon': Icons.book,},
    {'title': 'Balance Sheet', 'action': 'balancesheet', 'icon': Icons.account_balance,},
    {'title': 'Profit & Loss', 'action': 'pl', 'icon': Icons.trending_up,},
    {'title': 'Stock Summary', 'action': 'stock', 'icon': Icons.inventory_2,},
    {'title': 'Service Jobs', 'action': 'service', 'icon': Icons.settings_suggest,},
    {'title': 'Engineer Report', 'action': 'eng_report', 'icon': Icons.engineering_outlined, 'role': UserRole.admin},
    {'title': 'Sales Executive Report', 'action': 'sales_person_report', 'icon': Icons.badge_outlined, 'role': UserRole.admin},
    {'title': 'Ageing Report', 'action': 'ageing', 'icon': Icons.timer_outlined,},
    {'title': 'Party Statement', 'action': 'statement', 'icon': Icons.list_alt,},
    {'title': 'Quotation', 'action': 'vouchers', 'icon': Icons.request_quote_outlined,'extra': VoucherType.quotation},
    {'title': 'Proforma', 'action': 'vouchers', 'icon': Icons.receipt_long_outlined, 'extra': VoucherType.proforma},
    {'title': 'Data Backup', 'action': 'backup', 'icon': Icons.cloud_upload,},
    {'title': 'User Management', 'action': 'users', 'icon': Icons.people_outline, 'role': UserRole.admin},
    {'title': 'Edit Log', 'action': 'audit', 'icon': Icons.history, 'role': UserRole.admin},
    {'title': 'Company Set', 'action': 'settings', 'icon': Icons.settings, 'role': UserRole.admin},
    {'title': 'Logout', 'action': 'logout', 'icon': Icons.logout},
    {'title': 'Quit', 'action': 'quit', 'icon': Icons.exit_to_app},
  ];

  List<Map<String, dynamic>> get _visibleMenuItems {
    final user = context.read<BalamuruganData>().currentUser;
    if (user == null) return [];
    return _menuItems.where((item) {
      if (item['role'] == null) return true;
      return item['role'] == user.role;
    }).toList();
  }

  void _handleKeyEvent(KeyEvent event) {
    if (event is KeyDownEvent) {
      final key = event.logicalKey;
      if (key == LogicalKeyboardKey.arrowDown) {
        setState(() => _selectedIndex = (_selectedIndex + 1) % _menuItems.length);
      } else if (key == LogicalKeyboardKey.arrowUp) {
        setState(() => _selectedIndex = (_selectedIndex - 1 + _menuItems.length) % _menuItems.length);
      } else if (key == LogicalKeyboardKey.enter) {
        final visibleItems = _visibleMenuItems;
        if (_selectedIndex < visibleItems.length) {
          final item = visibleItems[_selectedIndex];
          _executeAction(item['action'], _selectedIndex, extra: item['extra']);
        }
      } else if (key == LogicalKeyboardKey.f1) {
        _showHelpDialog();
      } else if (key == LogicalKeyboardKey.f2) {
        _selectWorkingDate();
      } else if (key == LogicalKeyboardKey.f3) {
        _executeAction('settings', 10);
      } else if (key == LogicalKeyboardKey.f5) {
        _executeAction('vouchers', 3, extra: VoucherType.payment);
      } else if (key == LogicalKeyboardKey.f6) {
        _executeAction('vouchers', 3, extra: VoucherType.receipt);
      } else if (key == LogicalKeyboardKey.f7) {
        _executeAction('vouchers', 3, extra: VoucherType.journal);
      } else if (key == LogicalKeyboardKey.f8) {
        _executeAction('vouchers', 3, extra: VoucherType.sales);
      } else if (key == LogicalKeyboardKey.f9) {
        _executeAction('vouchers', 3, extra: VoucherType.purchase);
      } else if (key == LogicalKeyboardKey.f11) {
        _executeAction('vouchers', 3, extra: VoucherType.quotation);
      } else if (key == LogicalKeyboardKey.f12) {
        _executeAction('vouchers', 3, extra: VoucherType.proforma);
      }
    }
  }

  void _executeAction(String action, int index, {dynamic extra, int? indexExtra}) {
    if (action == 'quit') {
      _showQuitDialog();
      return;
    }
    if (action == 'logout') {
      context.read<BalamuruganData>().logout();
      return;
    }
    setState(() {
      _currentAction = action;
      _selectedIndex = index;
      
      _editingVoucher = null;
      _editingJob = null;
      _editingMaster = null;
      _editingMasterIndex = null;
      _editingStockItem = null;
      _initialVoucherType = null;

      if (action == 'vouchers') {
        if (extra is Voucher) {
          _editingVoucher = extra;
        } else if (extra is VoucherType) {
          _initialVoucherType = extra;
        }
      }
      if (action == 'service_entry' && extra is ServiceJob) {
        _editingJob = extra;
      }
      if (action == 'ledger_entry' && extra is Master) {
        _editingMaster = extra;
        _editingMasterIndex = indexExtra;
      }
      if (action == 'stock_item_entry' && extra is StockItem) {
        _editingStockItem = extra;
        _editingMasterIndex = indexExtra;
      }
    });
  }

  Widget _getBody() {
    switch (_currentAction) {
      case 'home': return const CompanyInfoPanel();
      case 'create': return CreateMasterScreen(
        onAction: (subAction) => _executeAction(subAction, 1),
      );
      case 'ledger_entry': return LedgerEntryScreen(
        index: _editingMasterIndex, 
        master: _editingMaster,
        onActionDone: () => _executeAction(_selectedIndex == 2 ? 'alter' : 'create', _selectedIndex),
      );
      case 'stock_item_entry': return StockItemEntryScreen(
        index: _editingMasterIndex, 
        item: _editingStockItem,
        onActionDone: () => _executeAction(_selectedIndex == 2 ? 'alter' : 'create', _selectedIndex),
      );
      case 'alter': return AlterMasterListScreen(
        onEditLedger: (m, i) => _executeAction('ledger_entry', 2, extra: m, indexExtra: i),
        onEditStockItem: (s, i) => _executeAction('stock_item_entry', 2, extra: s, indexExtra: i),
      );
      case 'vouchers': return VoucherEntryScreen(
        key: ValueKey('voucher_${_initialVoucherType?.index ?? 'sales'}_${_editingVoucher?.id ?? 'new'}'),
        existingVoucher: _editingVoucher,
        initialType: _initialVoucherType,
        onActionDone: () => _executeAction('daybook', 4),
      );
      case 'daybook': return DayBookScreen(
        onEditVoucher: (v) => _executeAction('vouchers', 4, extra: v),
        onEditJob: (j) => _executeAction('service_entry', 4, extra: j),
      );
      case 'balancesheet': return const BalanceSheetScreen();
      case 'pl': return const ProfitLossScreen();
      case 'stock': return const StockSummaryScreen();
      case 'service': return ServiceListScreen(
        onAddJob: () => _executeAction('service_entry', 8),
        onEditJob: (j) => _executeAction('service_entry', 8, extra: j),
      );
      case 'service_entry': return ServiceEntryScreen(
        job: _editingJob,
        onActionDone: () => _executeAction(_selectedIndex == 4 ? 'daybook' : 'service', _selectedIndex),
      );
      case 'eng_report': return const TechnicianReportScreen();
      case 'sales_person_report': return const SalesPersonReportScreen();
      case 'ageing': return const AgeingReportScreen();
      case 'statement': return const CustomerStatementScreen();
      case 'backup': return DataManagementScreen();
      case 'users': return const UserManagementScreen();
      case 'audit': return AuditLogScreen();
      case 'settings': return CompanySettingsScreen();
      default: return const CompanyInfoPanel();
    }
  }

  Map<String, VoidCallback>? _getRightActions() {
    return {
      'F2': () => _selectWorkingDate(),
      'F5': () => _executeAction('vouchers', 3, extra: VoucherType.payment),
      'F6': () => _executeAction('vouchers', 3, extra: VoucherType.receipt),
      'F7': () => _executeAction('vouchers', 3, extra: VoucherType.journal),
      'F8': () => _executeAction('vouchers', 3, extra: VoucherType.sales),
      'F9': () => _executeAction('vouchers', 3, extra: VoucherType.purchase),
      'F11': () => _executeAction('vouchers', 3, extra: VoucherType.quotation),
      'F12': () => _executeAction('vouchers', 3, extra: VoucherType.proforma),
      
    };
  }

  void _selectWorkingDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Working date set to: ${picked.toLocal()}'.split(' ')[0])),
      );
    }
  }

  void _showHelpDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('HELP & SHORTCUTS'),
        content: SizedBox(
          width: 500,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('KEYBOARD SHORTCUTS', style: TextStyle(fontWeight: FontWeight.bold, decoration: TextDecoration.underline)),
                const SizedBox(height: 8),
                const Text('F2 - Date Selection'),
                const Text('F5 - Payment Voucher'),
                const Text('F6 - Receipt Voucher'),
                const Text('F7 - Journal Voucher'),
                const Text('F8 - Sales Voucher'),
                const Text('F9 - Purchase Voucher'),
                const Text('F11 - Quotation'),
                const Text('F12 - Proforma Invoice'),
                const Text('Ctrl+A - Save/Accept'),
                const Text('Esc - Go Back'),
                const SizedBox(height: 20),

              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('CLOSE')),
        ],
      ),
    );
  }

  void _showQuitDialog() {
    showDialog(
      context: context,
      builder: (context) => KeyboardListener(
        focusNode: FocusNode(),
        onKeyEvent: (event) {
          if (event is KeyDownEvent) {
            if (event.logicalKey == LogicalKeyboardKey.keyY) {
              exit(0);
            } else if (event.logicalKey == LogicalKeyboardKey.keyN || event.logicalKey == LogicalKeyboardKey.escape) {
              Navigator.pop(context);
            }
          }
        },
        child: AlertDialog(
          title: const Text('QUIT BALAMURUGAN ENTERPRISES?'),
          content: const Text('Are you sure you want to exit the application? Any unsaved changes may be lost.'),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context), 
              child: const Text('NO (N)', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold))
            ),
            ElevatedButton(
              onPressed: () => exit(0), 
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade400,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('YES, QUIT (Y)', style: TextStyle(fontWeight: FontWeight.bold))
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final data = context.watch<BalamuruganData>();
    if (!data.isAuthenticated) {
      return const LoginScreen();
    }

    final visibleItems = _visibleMenuItems;
    // Ensure selected index is valid for filtered items
    if (_selectedIndex >= visibleItems.length) {
      _selectedIndex = 0;
    }

    return KeyboardListener(
      focusNode: _focusNode,
      onKeyEvent: _handleKeyEvent,
      child: MainLayout(
        selectedIndex: _selectedIndex,
        menuItems: visibleItems,
        onMenuSelected: (index) {
          final item = visibleItems[index];
          _executeAction(item['action'], index, extra: item['extra']);
        },
        content: _getBody(),
        rightActions: _getRightActions(),
        onHelp: _showHelpDialog,
      ),
    );
  }
}
