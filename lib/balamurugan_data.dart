import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pocketbase/pocketbase.dart';
import 'models.dart';
import 'utils.dart';

class CompanyData {
  Company info;
  List<Voucher> vouchers;
  List<Master> ledgers;
  List<StockItem> stockItems;
  List<ServiceJob> serviceJobs;
  List<AuditLog> auditLogs;
  List<User> users;

  CompanyData({
    required this.info,
    List<Voucher>? vouchers,
    List<Master>? ledgers,
    List<StockItem>? stockItems,
    List<ServiceJob>? serviceJobs,
    List<AuditLog>? auditLogs,
    List<User>? users,
  })  : vouchers = vouchers ?? <Voucher>[],
        ledgers = ledgers ?? <Master>[],
        stockItems = stockItems ?? <StockItem>[],
        serviceJobs = serviceJobs ?? <ServiceJob>[],
        auditLogs = auditLogs ?? <AuditLog>[],
        users = users ?? <User>[User(username: 'admin', password: '123', role: UserRole.admin)];

  Map<String, dynamic> toJson() => {
    'info': info.toJson(),
    'vouchers': vouchers.map((e) => e.toJson()).toList(),
    'ledgers': ledgers.map((e) => e.toJson()).toList(),
    'stockItems': stockItems.map((e) => e.toJson()).toList(),
    'serviceJobs': serviceJobs.map((e) => e.toJson()).toList(),
    'auditLogs': auditLogs.map((e) => e.toJson()).toList(),
    'users': users.map((e) => e.toJson()).toList(),
  };

  factory CompanyData.fromJson(Map<String, dynamic> json) => CompanyData(
    info: Company.fromJson(json['info']),
    vouchers: (json['vouchers'] as List).map((e) => Voucher.fromJson(e)).toList(),
    ledgers: (json['ledgers'] as List).map((e) => Master.fromJson(e)).toList(),
    stockItems: (json['stockItems'] as List).map((e) => StockItem.fromJson(e)).toList(),
    serviceJobs: (json['serviceJobs'] as List?)?.map((e) => ServiceJob.fromJson(e)).toList() ?? [],
    auditLogs: (json['auditLogs'] as List?)?.map((e) => AuditLog.fromJson(e)).toList() ?? [],
    users: (json['users'] as List?)?.map((e) => User.fromJson(e)).toList() ?? [User(username: 'admin', password: '123', role: UserRole.admin)],
  );
}

class BalamuruganData extends ChangeNotifier {
  List<CompanyData> _companies = [];
  int _currentCompanyIndex = 0;
  User? _currentUser;

  // LAN Server Settings
  bool _isNetworkMode = false;
  String _serverIp = 'localhost'; // e.g., 192.168.1.5
  String _serverPort = '8090';
  late PocketBase _pb;
  bool _isSyncing = false;

  BalamuruganData() {
    _pb = PocketBase('http://localhost:8090');
    loadSettings();
    loadFromLocal();
  }

  bool get isNetworkMode => _isNetworkMode;
  String get serverIp => _serverIp;
  String get serverPort => _serverPort;
  String get serverUrl => 'http://$_serverIp:$_serverPort';
  bool get isSyncing => _isSyncing;

  void updateNetworkSettings({required bool enabled, required String ip, required String port}) {
    _isNetworkMode = enabled;
    _serverIp = ip;
    _serverPort = port;
    _pb = PocketBase(serverUrl);
    saveSettings();
    if (_isNetworkMode) syncWithServer();
    notifyListeners();
  }

  Future<void> saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('network_mode', _isNetworkMode);
    await prefs.setString('server_ip', _serverIp);
    await prefs.setString('server_port', _serverPort);
  }

  Future<void> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _isNetworkMode = prefs.getBool('network_mode') ?? false;
    _serverIp = prefs.getString('server_ip') ?? 'localhost';
    _serverPort = prefs.getString('server_port') ?? '8090';
    notifyListeners();
  }

  List<CompanyData> get companies => List.unmodifiable(_companies);
  int get currentCompanyIndex => _currentCompanyIndex;
  User? get currentUser => _currentUser;
  bool get isAuthenticated => _currentUser != null;

  bool login(String username, String password) {
    try {
      final user = currentData.users.firstWhere(
        (u) => u.username == username && u.password == password
      );
      _currentUser = user;
      notifyListeners();
      return true;
    } catch (_) {
      return false;
    }
  }

  void logout() {
    _currentUser = null;
    notifyListeners();
  }

  // User Management
  void addUser(User user) {
    if (currentUser?.role != UserRole.admin) {
      throw Exception('Unauthorized: Only administrators can create users');
    }
    if (currentData.users.any((u) => u.username.toLowerCase() == user.username.toLowerCase())) {
      throw Exception('Username already exists');
    }
    currentData.users.add(user);
    recordLog(
      entityId: user.username,
      entityType: 'User',
      action: ActionType.create,
      details: 'Created new user: ${user.username} (${user.role.name})',
    );
    saveToLocal();
    notifyListeners();
  }

  void resetPassword(String username, String newPassword) {
    if (currentUser?.role != UserRole.admin && currentUser?.username != username) {
      throw Exception('Unauthorized: You can only reset your own password');
    }
    final index = currentData.users.indexWhere((u) => u.username == username);
    if (index != -1) {
      final oldUser = currentData.users[index];
      currentData.users[index] = User(
        username: oldUser.username,
        password: newPassword,
        role: oldUser.role,
      );
      recordLog(
        entityId: username,
        entityType: 'User',
        action: ActionType.update,
        details: 'Password reset for user: $username',
      );
      saveToLocal();
      notifyListeners();
    }
  }

  void deleteUser(String username) {
    if (username == 'admin') throw Exception('Cannot delete the primary admin account');
    currentData.users.removeWhere((u) => u.username == username);
    recordLog(
      entityId: username,
      entityType: 'User',
      action: ActionType.delete,
      details: 'Deleted user: $username',
    );
    saveToLocal();
    notifyListeners();
  }
  
  CompanyData get currentData {
    if (_companies.isEmpty) {
      _companies.add(CompanyData(
        info: Company(name: 'BALAMURUGAN ENTERPRISES', address: 'No-2, Yasotha Illam, Santhosh Avenue, Kundrathur, Chennai - 600069', phone: '9841772418'),
        ledgers: [
          Master(name: 'Cash', group: 'Cash'),
          Master(name: 'Profit & Loss A/c', group: 'Others'),
        ],
      ));
    }
    return _companies[_currentCompanyIndex];
  }

  Company get currentCompany => currentData.info;
  List<Voucher> get vouchers => List.unmodifiable(currentData.vouchers);
  List<Master> get ledgers => List.unmodifiable(currentData.ledgers);
  List<StockItem> get stockItems => List.unmodifiable(currentData.stockItems);
  List<ServiceJob> get serviceJobs => List.unmodifiable(currentData.serviceJobs);
  List<AuditLog> get auditLogs => List.unmodifiable(currentData.auditLogs);

  void recordLog({
    required String entityId,
    required String entityType,
    required ActionType action,
    String details = '',
    dynamic previousState,
  }) {
    currentData.auditLogs.add(AuditLog(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      entityId: entityId,
      entityType: entityType,
      action: action,
      timestamp: DateTime.now(),
      details: details,
      previousState: previousState != null ? jsonEncode(previousState) : null,
    ));
  }

  void switchCompany(int index) {
    if (index >= 0 && index < _companies.length) {
      _currentCompanyIndex = index;
      saveToLocal();
      notifyListeners();
    }
  }

  void addCompany(Company info) {
    final name = info.name.trim();
    if (name.isEmpty) {
      throw ArgumentError('Company name cannot be blank');
    }
    if (_companies.any((company) => company.info.name.trim().toLowerCase() == name.toLowerCase())) {
      throw ArgumentError('Company name already exists');
    }

    _companies.add(CompanyData(
      info: Company(
        name: name,
        address: info.address,
        phone: info.phone,
        gstin: info.gstin,
        isGstEnabled: info.isGstEnabled,
        logoBase64: info.logoBase64,
      ),
      ledgers: [
        Master(name: 'Cash', group: 'Cash'),
        Master(name: 'Profit & Loss A/c', group: 'Others'),
      ],
    ));
    saveToLocal();
    notifyListeners();
  }

  void updateCompanyInfo(Company info) {
    recordLog(
      entityId: info.name,
      entityType: 'Company',
      action: ActionType.update,
      details: 'Updated company settings',
      previousState: currentData.info.toJson(),
    );
    currentData.info = info;
    saveToLocal();
    notifyListeners();
  }

  void addVoucher(Voucher voucher) {
    currentData.vouchers.add(voucher);
    recordLog(
      entityId: voucher.id,
      entityType: 'Voucher',
      action: ActionType.create,
      details: 'Created ${voucher.type.name} voucher',
    );
    saveToLocal();
    notifyListeners();
  }

  void updateVoucher(String id, Voucher voucher) {
    final index = currentData.vouchers.indexWhere((v) => v.id == id);
    if (index != -1) {
      final old = currentData.vouchers[index];
      recordLog(
        entityId: id,
        entityType: 'Voucher',
        action: ActionType.update,
        details: 'Updated voucher details',
        previousState: old.toJson(),
      );
      currentData.vouchers[index] = voucher;
      saveToLocal();
      notifyListeners();
    }
  }

  void deleteVoucher(String id) {
    final index = currentData.vouchers.indexWhere((v) => v.id == id);
    if (index != -1) {
      recordLog(
        entityId: id,
        entityType: 'Voucher',
        action: ActionType.delete,
        details: 'Deleted voucher',
        previousState: currentData.vouchers[index].toJson(),
      );
      currentData.vouchers.removeAt(index);
      saveToLocal();
      notifyListeners();
    }
  }

  void addLedger(Master ledger) {
    final name = ledger.name.trim();
    if (name.isEmpty) {
      throw ArgumentError('Ledger name cannot be blank');
    }
    if (currentData.ledgers.any((entry) => entry.name.trim().toLowerCase() == name.toLowerCase())) {
      throw ArgumentError('Ledger name already exists');
    }

    currentData.ledgers.add(Master(
      name: name,
      group: ledger.group,
      address: ledger.address,
      phone: ledger.phone,
      gstin: ledger.gstin,
    ));
    recordLog(
      entityId: name,
      entityType: 'Master',
      action: ActionType.create,
      details: 'Created ledger',
    );
    saveToLocal();
    notifyListeners();
  }

  void updateLedger(int index, Master ledger) {
    final old = currentData.ledgers[index];
    recordLog(
      entityId: old.name,
      entityType: 'Master',
      action: ActionType.update,
      details: 'Updated ledger details',
      previousState: old.toJson(),
    );
    currentData.ledgers[index] = ledger;
    saveToLocal();
    notifyListeners();
  }

  void deleteLedger(int index) {
    if (index >= 0 && index < currentData.ledgers.length) {
      final old = currentData.ledgers[index];
      recordLog(
        entityId: old.name,
        entityType: 'Master',
        action: ActionType.delete,
        details: 'Deleted ledger',
        previousState: old.toJson(),
      );
      currentData.ledgers.removeAt(index);
      saveToLocal();
      notifyListeners();
    }
  }

  void addStockItem(StockItem item) {
    currentData.stockItems.add(item);
    saveToLocal();
    notifyListeners();
  }

  void updateStockItem(int index, StockItem item) {
    currentData.stockItems[index] = item;
    saveToLocal();
    notifyListeners();
  }

  void deleteStockItem(int index) {
    if (index >= 0 && index < currentData.stockItems.length) {
      currentData.stockItems.removeAt(index);
      saveToLocal();
      notifyListeners();
    }
  }

  void togglePaymentStatus(String voucherId) {
    final index = currentData.vouchers.indexWhere((v) => v.id == voucherId);
    if (index != -1) {
      currentData.vouchers[index].isPaid = !currentData.vouchers[index].isPaid;
      saveToLocal();
      notifyListeners();
    }
  }

  // Service Jobs
  void addServiceJob(ServiceJob job) {
    currentData.serviceJobs.add(job);
    saveToLocal();
    notifyListeners();
  }

  void updateServiceJob(ServiceJob job) {
    final index = currentData.serviceJobs.indexWhere((j) => j.jobCode == job.jobCode);
    if (index != -1) {
      currentData.serviceJobs[index] = job;
      saveToLocal();
      notifyListeners();
    }
  }

  void deleteServiceJob(String jobCode) {
    currentData.serviceJobs.removeWhere((j) => j.jobCode == jobCode);
    saveToLocal();
    notifyListeners();
  }

  void toggleServiceJobStatus(String jobCode) {
    final index = currentData.serviceJobs.indexWhere((j) => j.jobCode == jobCode);
    if (index != -1) {
      final currentStatus = currentData.serviceJobs[index].status;
      // Cycle through statuses
      if (currentStatus == ServiceStatus.received) {
        currentData.serviceJobs[index].status = ServiceStatus.diagnosing;
      } else if (currentStatus == ServiceStatus.diagnosing) {
        currentData.serviceJobs[index].status = ServiceStatus.waitingForParts;
      } else if (currentStatus == ServiceStatus.waitingForParts) {
        currentData.serviceJobs[index].status = ServiceStatus.ready;
      } else if (currentStatus == ServiceStatus.ready) {
        currentData.serviceJobs[index].status = ServiceStatus.delivered;
      } else {
        currentData.serviceJobs[index].status = ServiceStatus.received;
      }
      saveToLocal();
      notifyListeners();
    }
  }

  void toggleServicePaymentStatus(String jobCode) {
    final index = currentData.serviceJobs.indexWhere((j) => j.jobCode == jobCode);
    if (index != -1) {
      currentData.serviceJobs[index].isPaid = !currentData.serviceJobs[index].isPaid;
      saveToLocal();
      notifyListeners();
    }
  }

  Master? findLedger(String name) {
    try {
      return currentData.ledgers.firstWhere((l) => l.name == name);
    } catch (_) {
      return null;
    }
  }

  // Persistence logic
  Future<void> saveToLocal() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = {
        'companies': _companies.map((e) => e.toJson()).toList(),
        'currentCompanyIndex': _currentCompanyIndex,
      };
      await prefs.setString('balamurugan_erp_data', jsonEncode(data));
      
      if (_isNetworkMode && !_isSyncing) {
        syncWithServer();
      }
    } on MissingPluginException {
      debugPrint('SharedPreferences not available in this environment; skipping local save.');
    }
  }

  Future<void> syncWithServer() async {
    if (_isSyncing) return;
    _isSyncing = true;
    notifyListeners();

    try {
      // 1. Authenticate (optional for local LAN, but good practice)
      // For PocketBase local LAN, we can use a master record or just simple JSON storage.
      // We'll store the entire 'CompanyData' in a collection named 'erp_data'
      
      final data = {
        'companies_json': jsonEncode(_companies.map((e) => e.toJson()).toList()),
        'current_index': _currentCompanyIndex,
        'last_updated': DateTime.now().toIso8601String(),
      };

      // Try to find if record exists
      try {
        final records = await _pb.collection('erp_sync').getList(page: 1, perPage: 1);
        if (records.items.isNotEmpty) {
          final serverRecord = records.items.first;
          final serverDate = DateTime.parse(serverRecord.getStringValue('last_updated'));
          
          // Simple Conflict Resolution: Newer wins
          // In a production app, we'd sync item-by-item, but for a "Gold" LAN model, 
          // usually the central server is the source of truth.
          
          await _pb.collection('erp_sync').update(serverRecord.id, body: data);
        } else {
          await _pb.collection('erp_sync').create(body: data);
        }
      } catch (e) {
        // Collection might not exist or network down
        debugPrint('Server sync error: $e');
      }
    } finally {
      _isSyncing = false;
      notifyListeners();
    }
  }

  Future<void> fetchFromServer() async {
    if (!_isNetworkMode) return;
    _isSyncing = true;
    notifyListeners();

    try {
      final records = await _pb.collection('erp_sync').getList(page: 1, perPage: 1);
      if (records.items.isNotEmpty) {
        final serverRecord = records.items.first;
        final rawJson = serverRecord.getStringValue('companies_json');
        final decoded = jsonDecode(rawJson) as List;
        _companies = decoded.map((e) => CompanyData.fromJson(e)).toList();
        _currentCompanyIndex = serverRecord.getIntValue('current_index');
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error fetching from server: $e');
    } finally {
      _isSyncing = false;
      notifyListeners();
    }
  }

  Future<void> loadFromLocal() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString('balamurugan_erp_data');
      if (raw != null) {
        try {
          final data = jsonDecode(raw);
          _companies = (data['companies'] as List).map((e) => CompanyData.fromJson(e)).toList();
          _currentCompanyIndex = data['currentCompanyIndex'] ?? 0;
          notifyListeners();
        } catch (e) {
          debugPrint('Error loading local data: $e');
        }
      }
    } on MissingPluginException {
      debugPrint('SharedPreferences not available in this environment; skipping local load.');
    }
  }

  // Backup & Restore
  String exportBackup() {
    final data = {
      'companies': _companies.map((e) => e.toJson()).toList(),
      'currentCompanyIndex': _currentCompanyIndex,
    };
    return jsonEncode(data);
  }

  void importBackup(String jsonString) {
    try {
      final data = jsonDecode(jsonString);
      _companies = (data['companies'] as List).map((e) => CompanyData.fromJson(e)).toList();
      _currentCompanyIndex = data['currentCompanyIndex'] ?? 0;
      saveToLocal();
      notifyListeners();
    } catch (e) {
      throw Exception('Invalid backup file');
    }
  }

  double get cashBalance {
    double balance = 0;
    for (var v in vouchers) {
      // Only Paid vouchers affect actual cash in hand
      if (!v.isPaid) continue;
      
      // Quotations and Proforma don't affect cash
      if (v.type == VoucherType.quotation || v.type == VoucherType.proforma) continue;

      if (v.type == VoucherType.receipt || v.type == VoucherType.sales) {
        balance += v.amount;
      } else if (v.type == VoucherType.payment || v.type == VoucherType.purchase) {
        balance -= v.amount;
      }
    }
    for (var job in serviceJobs) {
      if (job.isPaid) balance += job.amountCharged;
    }
    return balance;
  }

  Map<String, double> get profitLossData {
    double sales = 0;
    double purchases = 0;
    double serviceCharges = 0;
    double indirectIncomes = 0;
    double indirectExpenses = 0;

    for (var v in vouchers) {
      // Quotations and Proforma don't affect profit/loss
      if (v.type == VoucherType.quotation || v.type == VoucherType.proforma) continue;

      final ledger = findLedger(v.ledgerName);
      final group = ledger?.group ?? '';

      if (v.type == VoucherType.sales) {
        sales += v.amount;
      } else if (v.type == VoucherType.purchase) {
        purchases += v.amount;
      } else if (group == 'Other Income' || v.type == VoucherType.receipt) {
        indirectIncomes += v.amount;
      } else if (group == 'Expenses' || v.type == VoucherType.payment) {
        indirectExpenses += v.amount;
      }
    }

    for (var job in serviceJobs) {
      if (job.status == ServiceStatus.delivered || job.status == ServiceStatus.ready || job.isPaid) {
        serviceCharges += job.amountCharged;
      }
    }

    final netProfit = (sales + serviceCharges + indirectIncomes) - (purchases + indirectExpenses);

    return {
      'Sales Accounts': sales,
      'Service Charges': serviceCharges,
      'Purchase Accounts': purchases,
      'Other Income': indirectIncomes,
      'Expenses': indirectExpenses,
      'Indirect Incomes': indirectIncomes,
      'Indirect Expenses': indirectExpenses,
      'Net Profit': netProfit,
    };
  }

  Map<String, double> get stockSummary {
    Map<String, double> summary = {};
    for (var item in stockItems) {
      summary[item.name] = item.openingBalance;
    }

    for (var v in vouchers) {
      // Quotations and Proforma don't affect stock
      if (v.type == VoucherType.quotation || v.type == VoucherType.proforma) continue;

      for (var line in v.items) {
        if (v.type == VoucherType.sales) {
          summary[line.description] = (summary[line.description] ?? 0) - line.quantity;
        } else if (v.type == VoucherType.purchase) {
          summary[line.description] = (summary[line.description] ?? 0) + line.quantity;
        }
      }
    }
    return summary;
  }

  List<Map<String, dynamic>> get partyBalances {
    Map<String, Map<String, double>> balances = {};
    for (var v in vouchers) {
      // Quotations and Proforma don't affect ledger balances
      if (v.type == VoucherType.quotation || v.type == VoucherType.proforma) continue;

      if (v.type == VoucherType.sales) {
        if (!balances.containsKey(v.ledgerName)) {
          balances[v.ledgerName] = {'due': 0, 'received': 0};
        }
        if (v.isPaid) {
          balances[v.ledgerName]!['received'] = (balances[v.ledgerName]!['received'] ?? 0) + v.amount;
        } else {
          balances[v.ledgerName]!['due'] = (balances[v.ledgerName]!['due'] ?? 0) + v.amount;
        }
      }
    }
    for (var job in serviceJobs) {
      if (!balances.containsKey(job.customerName)) {
        balances[job.customerName] = {'due': 0, 'received': 0};
      }
      if (job.isPaid) {
        balances[job.customerName]!['received'] = (balances[job.customerName]!['received'] ?? 0) + job.amountCharged;
      } else {
        balances[job.customerName]!['due'] = (balances[job.customerName]!['due'] ?? 0) + job.amountCharged;
      }
    }
    return balances.entries.map((e) => {
      'name': e.key,
      'due': e.value['due'],
      'received': e.value['received'],
    }).toList();
  }

  Map<String, double> get salesByPerson {
    Map<String, double> stats = {};
    for (var v in vouchers) {
      if (v.type == VoucherType.sales) {
        final name = v.salesPerson.isEmpty ? 'Direct Sales' : v.salesPerson;
        stats[name] = (stats[name] ?? 0) + v.amount;
      }
    }
    return stats;
  }

  Map<String, Map<String, dynamic>> getFilteredTechnicianPerformance({DateTime? start, DateTime? end}) {
    Map<String, Map<String, dynamic>> stats = {};

    for (var job in serviceJobs) {
      if (start != null && job.date.isBefore(start)) continue;
      if (end != null && job.date.isAfter(end)) continue;

      final eng = job.engineerName.trim().isEmpty ? 'Unassigned' : job.engineerName;
      if (!stats.containsKey(eng)) {
        stats[eng] = {
          'totalJobs': 0,
          'completedJobs': 0,
          'totalRevenue': 0.0,
        };
      }

      stats[eng]!['totalJobs'] = (stats[eng]!['totalJobs'] as int) + 1;
      if (job.status == ServiceStatus.delivered || job.status == ServiceStatus.ready || job.isPaid) {
        stats[eng]!['completedJobs'] = (stats[eng]!['completedJobs'] as int) + 1;
      }
      stats[eng]!['totalRevenue'] = (stats[eng]!['totalRevenue'] as double) + job.amountCharged;
    }

    return stats;
  }

  List<ServiceJob> getTechnicianJobs(String engineerName, {DateTime? start, DateTime? end}) {
    return serviceJobs.where((job) {
      final matchName = (job.engineerName.trim().isEmpty ? 'Unassigned' : job.engineerName) == engineerName;
      if (!matchName) return false;
      if (start != null && job.date.isBefore(start)) return false;
      if (end != null && job.date.isAfter(end)) return false;
      return true;
    }).toList()..sort((a, b) => b.date.compareTo(a.date));
  }

  Map<String, Map<String, dynamic>> get technicianPerformance {
    Map<String, Map<String, dynamic>> stats = {};

    for (var job in serviceJobs) {
      final eng = job.engineerName.trim().isEmpty ? 'Unassigned' : job.engineerName;
      if (!stats.containsKey(eng)) {
        stats[eng] = {
          'totalJobs': 0,
          'completedJobs': 0,
          'totalRevenue': 0.0,
        };
      }

      stats[eng]!['totalJobs'] = (stats[eng]!['totalJobs'] as int) + 1;
      if (job.status == ServiceStatus.delivered || job.status == ServiceStatus.ready || job.isPaid) {
        stats[eng]!['completedJobs'] = (stats[eng]!['completedJobs'] as int) + 1;
      }
      stats[eng]!['totalRevenue'] = (stats[eng]!['totalRevenue'] as double) + job.amountCharged;
    }

    return stats;
  }

  Map<String, Map<String, double>> get ageingReport {
    final now = DateTime.now();
    Map<String, Map<String, double>> report = {}; // { 'Bucket': { 'Customer': amount } }

    final buckets = ['0-30 Days', '31-60 Days', '61-90 Days', 'Over 90 Days'];
    for (var b in buckets) {
      report[b] = {};
    }

    for (var v in vouchers) {
      if (v.type != VoucherType.sales || v.isPaid) continue;
      
      final diff = now.difference(v.date).inDays;
      String bucket = '';
      if (diff <= 30) {
        bucket = buckets[0];
      } else if (diff <= 60) {
        bucket = buckets[1];
      } else if (diff <= 90) {
        bucket = buckets[2];
      } else {
        bucket = buckets[3];
      }

      report[bucket]![v.ledgerName] = (report[bucket]![v.ledgerName] ?? 0) + v.amount;
    }

    for (var job in serviceJobs) {
      if (job.isPaid) continue;
      final diff = now.difference(job.date).inDays;
      String bucket = '';
      if (diff <= 30) {
        bucket = buckets[0];
      } else if (diff <= 60) {
        bucket = buckets[1];
      } else if (diff <= 90) {
        bucket = buckets[2];
      } else {
        bucket = buckets[3];
      }

      report[bucket]![job.customerName] = (report[bucket]![job.customerName] ?? 0) + job.amountCharged;
    }

    return report;
  }

  List<Map<String, dynamic>> getCustomerStatement(String customerName, DateTime start, DateTime end) {
    List<Map<String, dynamic>> statement = [];

    // Filter Vouchers
    for (var v in vouchers) {
      if (v.ledgerName != customerName) continue;
      if (v.date.isBefore(start) || v.date.isAfter(end)) continue;

      if (v.type == VoucherType.sales) {
        statement.add({
          'date': v.date,
          'particulars': 'Sales Invoice (${v.id})',
          'billed': v.amount,
          'received': v.isPaid ? v.amount : 0.0,
        });
      } else if (v.type == VoucherType.receipt) {
        statement.add({
          'date': v.date,
          'particulars': 'Receipt (${v.id})',
          'billed': 0.0,
          'received': v.amount,
        });
      }
    }

    // Filter Service Jobs
    for (var job in serviceJobs) {
      if (job.customerName != customerName) continue;
      if (job.date.isBefore(start) || job.date.isAfter(end)) continue;

      statement.add({
        'date': job.date,
        'particulars': 'Service Job (${job.jobCode})',
        'billed': job.amountCharged,
        'received': job.isPaid ? job.amountCharged : 0.0,
      });
    }

    statement.sort((a, b) => (a['date'] as DateTime).compareTo(b['date'] as DateTime));
    return statement;
  }

  String getNextVoucherNumber(VoucherType type) {
    final fy = getCurrentFinancialYear();
    String typeStr = "";
    switch (type) {
      case VoucherType.sales: typeStr = "SALES"; break;
      case VoucherType.purchase: typeStr = "PURCHASE"; break;
      case VoucherType.payment: typeStr = "PAYMENT"; break;
      case VoucherType.receipt: typeStr = "RECEIPT"; break;
      case VoucherType.contra: typeStr = "CONTRA"; break;
      case VoucherType.journal: typeStr = "JOURNAL"; break;
      case VoucherType.quotation: typeStr = "QUOTE"; break;
      case VoucherType.proforma: typeStr = "PROFORMA"; break;
    }

    final prefix = "BM/$fy/ $typeStr - ";
    int maxNum = 0;

    for (var v in vouchers) {
      if (v.id.startsWith(prefix)) {
        final numPart = v.id.replaceFirst(prefix, "");
        final num = int.tryParse(numPart) ?? 0;
        if (num > maxNum) maxNum = num;
      }
    }

    return "$prefix${(maxNum + 1).toString().padLeft(4, '0')}";
  }

  String getNextServiceJobNumber() {
    final fy = getCurrentFinancialYear();
    final prefix = "BM/$fy/ SERVICE - ";
    int maxNum = 0;

    for (var job in serviceJobs) {
      if (job.jobCode.startsWith(prefix)) {
        final numPart = job.jobCode.replaceFirst(prefix, "");
        final num = int.tryParse(numPart) ?? 0;
        if (num > maxNum) maxNum = num;
      }
    }

    return "$prefix${(maxNum + 1).toString().padLeft(4, '0')}";
  }
}

final BalamuruganData globalData = BalamuruganData();
