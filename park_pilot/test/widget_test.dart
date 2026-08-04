import 'package:flutter_test/flutter_test.dart';
import 'package:park_pilot/main.dart';

void main() {
  testWidgets('ParkPilotApp renders smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const ParkPilotApp());
    expect(find.text('ParkPilot'), findsOneWidget);
  });
}
