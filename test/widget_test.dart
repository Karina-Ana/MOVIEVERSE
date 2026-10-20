import 'package:flutter_test/flutter_test.dart';
import 'package:uts/main.dart';

void main() {
  testWidgets('MOVIEVERSE menampilkan halaman utama', (
      WidgetTester tester,
      ) async {
    await tester.pumpWidget(const MovieVerseApp());
    await tester.pump();
    expect(find.text('MOVIEVERSE'), findsOneWidget);
  });
}
