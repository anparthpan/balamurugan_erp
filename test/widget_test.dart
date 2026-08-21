import 'package:flutter_test/flutter_test.dart';

import 'package:balamurugan_enterprises/main.dart';

void main() {
  testWidgets('app renders the ERP dashboard without layout crashes', (tester) async {
    await tester.pumpWidget(const BalamuruganApp());
    await tester.pumpAndSettle();

    expect(find.text('BALAMURUGAN ENTERPRISES'), findsOneWidget);
    expect(find.text('BUSINESS STATUS'), findsOneWidget);
    expect(find.text('FINANCIAL OVERVIEW'), findsOneWidget);
    expect(find.text('BALAMURUGAN ENTERPRISES'), findsOneWidget);
  });
}
