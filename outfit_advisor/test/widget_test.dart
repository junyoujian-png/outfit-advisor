import 'package:flutter_test/flutter_test.dart';
import 'package:outfit_advisor/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const OutfitAdvisorApp(initialLanguage: 'zh', onboardingDone: true));
    expect(find.text('星座運勢'), findsOneWidget);
  });
}
