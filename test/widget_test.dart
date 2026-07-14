// test/widget_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:jireta_loan/core/utils/constants.dart';

void main() {
  testWidgets('AppConstants expose correct app name', (tester) async {
    expect(AppConstants.appName, 'Jireta Loan');
    expect(AppConstants.currencySymbol, '₱');
  });

  testWidgets('Role constants are renamed correctly', (tester) async {
    expect(AppConstants.roleHeadManager, 'head_manager');
    expect(AppConstants.roleEmployee, 'employee');
    expect(AppConstants.roleRider, 'rider');
    expect(AppConstants.roleLender, 'lender');
    expect(AppConstants.validRoles, contains('head_manager'));
    expect(AppConstants.validRoles, contains('employee'));
    expect(AppConstants.validRoles, contains('lender'));
  });

  testWidgets('MaterialApp smoke test', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Center(child: Text('Jireta Loan')),
        ),
      ),
    );
    expect(find.text('Jireta Loan'), findsOneWidget);
  });
}
