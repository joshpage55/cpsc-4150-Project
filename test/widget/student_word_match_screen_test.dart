import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:readright/screens/student/student_word_match_screen.dart';

void main() {
  testWidgets('renders the word match start screen', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: StudentWordMatchPage()));

    expect(find.text('Word Match'), findsOneWidget);
    expect(find.text('Start Game'), findsOneWidget);
  });
}
