import 'package:flutter_test/flutter_test.dart';
import 'package:asifiwe/main.dart';

void main() {
  testWidgets('App loads correctly', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const AsifiweApp());

    // Verify app title appears
    expect(find.text('asifiwe'), findsOneWidget);
  });
}
