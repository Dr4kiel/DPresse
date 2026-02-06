import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dpresse/app.dart';

void main() {
  testWidgets('App loads without crashing', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: DPresseApp()),
    );
    // App should at least render (will show login screen)
    await tester.pumpAndSettle(const Duration(seconds: 1));
  });
}
