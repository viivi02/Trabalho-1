import 'package:flutter_test/flutter_test.dart';
import 'package:fabio_work/main.dart';

void main() {
  testWidgets('App renders', (WidgetTester tester) async {
    await tester.pumpWidget(const OrdersDashboardApp());
    expect(find.text('Orders Dashboard'), findsOneWidget);
  });
}
