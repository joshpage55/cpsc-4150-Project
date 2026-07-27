import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:readright/models/current_user_model.dart';
import 'package:readright/screens/student/student_story_view_screen.dart';

void main() {
  testWidgets('renders student story view screen', (tester) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => CurrentUserModel()),
        ],
        child: const MaterialApp(home: StudentStoryViewPage()),
      ),
    );

    expect(find.text('Stories'), findsOneWidget);
    expect(find.text('Your approved stories'), findsOneWidget);
  });
}
