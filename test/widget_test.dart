import 'package:flutter_test/flutter_test.dart';
import 'package:collectionrini/main.dart';

void main() {
  testWidgets('KoleksiRiniApp smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const KoleksiRiniApp());
    await tester.pump();

    // Verify main app renders
    expect(find.byType(KoleksiRiniApp), findsOneWidget);
  });
}
