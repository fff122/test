import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:xuebao/main.dart';

void main() {
  testWidgets('shows app title', (tester) async {
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(const XueBaoApp());

    expect(find.text('学宝'), findsOneWidget);
  });
}
