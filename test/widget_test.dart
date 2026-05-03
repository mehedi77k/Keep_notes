import 'package:flutter_test/flutter_test.dart';

import 'package:keep_notes/main.dart';

void main() {
  testWidgets('My Notes home loads', (WidgetTester tester) async {
    await tester.pumpWidget(const KeepNotesApp());

    expect(find.text('My Notes'), findsOneWidget);
    expect(find.text('New note'), findsOneWidget);
  });
}
