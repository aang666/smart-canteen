import 'package:flutter_test/flutter_test.dart';
import 'package:smart_canteen/main.dart';

void main() {
  testWidgets('Smart Canteen smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const SmartCanteenApp());

    // Verify that Smart Canteen splash/home screen renders.
    expect(find.text('Smart Canteen'), findsOneWidget);
  });
}
