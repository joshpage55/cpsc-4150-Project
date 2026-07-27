import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:readright/models/current_user_model.dart';
import 'package:readright/screens/teacher/teacher_story_builder_screen.dart';
import 'package:readright/firebase_options.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  });

  testWidgets('renders teacher story builder controls', (tester) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => CurrentUserModel()),
        ],
        child: const MaterialApp(home: TeacherStoryBuilderPage()),
      ),
    );

    expect(find.text('Teacher Story Builder'), findsOneWidget);
    expect(find.text('Create a story draft for a student'), findsOneWidget);
    expect(find.text('Generate Story'), findsOneWidget);
  });
}
