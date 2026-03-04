import 'package:flutter_test/flutter_test.dart';

import 'package:gluco_predict/app.dart';

void main() {
  testWidgets('App renders GlucoPredict title', (WidgetTester tester) async {
    await tester.pumpWidget(const GlucoPredictApp());
    await tester.pumpAndSettle();

    expect(find.text('GlucoPredict'), findsOneWidget);
  });
}
