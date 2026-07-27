import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:readright/models/current_user_model.dart';
import 'package:readright/models/story_model.dart';
import 'package:readright/services/story_service.dart';
import 'package:readright/utils/app_colors.dart';

class StudentStoryViewPage extends StatefulWidget {
  const StudentStoryViewPage({super.key});

  @override
  State<StudentStoryViewPage> createState() => _StudentStoryViewPageState();
}

class _StudentStoryViewPageState extends State<StudentStoryViewPage> {
  final StoryService _storyService = StoryService();
  late Future<List<StoryModel>> _storiesFuture;

  @override
  void initState() {
    super.initState();
    _storiesFuture = _loadStories();
  }

  Future<List<StoryModel>> _loadStories() async {
    final user = context.read<CurrentUserModel>().user;
    if (user == null || user.id == null || user.id!.isEmpty) {
      return [];
    }
    return _storyService.approvedForStudent(user.id!);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Stories'),
        backgroundColor: AppColors.bgPrimaryLightBlue,
      ),
      body: FutureBuilder<List<StoryModel>>(
        future: _storiesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Could not load stories: ${snapshot.error}'));
          }

          final stories = snapshot.data ?? [];
          if (stories.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text('Your approved stories will appear here.'),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: stories.length,
            itemBuilder: (context, index) {
              final story = stories[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ExpansionTile(
                  title: Text(story.readingLevel),
                  subtitle: Text(story.interest),
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(story.text),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
