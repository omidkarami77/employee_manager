import 'package:flutter_test/flutter_test.dart';

import 'package:employee_manager/main.dart';

void main() {
  testWidgets('shows the employee dashboard', (tester) async {
    await tester.pumpWidget(const EmployeeManagerApp());

    expect(find.text(AppText.appName), findsOneWidget);
    expect(find.text(AppText.dashboard), findsWidgets);
    expect(find.text('\u06a9\u0644 \u06a9\u0627\u0631\u06a9\u0646\u0627\u0646'), findsOneWidget);
    expect(find.text('\u0633\u0627\u0628\u0642\u0647 \u0628\u0627\u0644\u0627\u06cc \u06f2\u06f0 \u0633\u0627\u0644'), findsOneWidget);
  });
}
