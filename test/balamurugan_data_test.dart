import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:balamurugan_enterprises/models.dart';
import 'package:balamurugan_enterprises/balamurugan_data.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  SharedPreferences.setMockInitialValues({});

  group('BalamuruganData accounting logic', () {
    test('profitLossData exposes the dashboard keys and totals', () {
      final data = BalamuruganData();

      data.addLedger(Master(name: 'Sales Ledger', group: 'Sales Accounts'));
      data.addLedger(Master(name: 'Purchase Ledger', group: 'Purchase Accounts'));
      data.addLedger(Master(name: 'Expense Ledger', group: 'Expenses'));

      data.addVoucher(
        Voucher(
          id: 'V1',
          date: DateTime(2026, 1, 1),
          ledgerName: 'Sales Ledger',
          amount: 1000,
          type: VoucherType.sales,
          narration: 'Sale',
        ),
      );

      data.addVoucher(
        Voucher(
          id: 'V2',
          date: DateTime(2026, 1, 2),
          ledgerName: 'Purchase Ledger',
          amount: 400,
          type: VoucherType.purchase,
          narration: 'Purchase',
        ),
      );

      data.addVoucher(
        Voucher(
          id: 'V3',
          date: DateTime(2026, 1, 3),
          ledgerName: 'Expense Ledger',
          amount: 150,
          type: VoucherType.payment,
          narration: 'Expense',
        ),
      );

      data.addServiceJob(
        ServiceJob(
          jobCode: 'JOB-1',
          date: DateTime(2026, 1, 4),
          customerName: 'Customer A',
          description: 'Repair',
          engineerName: 'Engineer A',
          amountCharged: 200,
          status: ServiceStatus.delivered,
        ),
      );

      final summary = data.profitLossData;

      expect(summary['Sales Accounts'], 1000);
      expect(summary['Service Charges'], 200);
      expect(summary['Purchase Accounts'], 400);
      expect(summary['Other Income'], 0);
      expect(summary['Expenses'], 150);
      expect(summary['Net Profit'], 650);
    });

    test('rejects blank and duplicate company or ledger names', () {
      final data = BalamuruganData();

      expect(() => data.addCompany(Company(name: '   ')), throwsArgumentError);
      data.addCompany(Company(name: 'Alpha'));
      expect(() => data.addCompany(Company(name: 'Alpha')), throwsArgumentError);

      expect(() => data.addLedger(Master(name: '   ', group: 'Cash')), throwsArgumentError);
      data.addLedger(Master(name: 'Bank Ledger', group: 'Cash'));
      expect(() => data.addLedger(Master(name: 'Bank Ledger', group: 'Cash')), throwsArgumentError);
    });
  });
}
