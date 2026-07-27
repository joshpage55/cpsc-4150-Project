import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:readright/models/class_model.dart';
import 'package:readright/models/current_user_model.dart';
import 'package:readright/models/story_model.dart';
import 'package:readright/models/user_model.dart';
import 'package:readright/services/story_service.dart';
import 'package:readright/utils/app_colors.dart';
import 'package:readright/utils/enums.dart';

class TeacherStoryBuilderPage extends StatefulWidget {
  const TeacherStoryBuilderPage({super.key});

  @override
  State<TeacherStoryBuilderPage> createState() => _TeacherStoryBuilderPageState();
}

class _TeacherStoryBuilderPageState extends State<TeacherStoryBuilderPage> {
  final StoryService _storyService = StoryService();

  ClassModel? _classSection;
  UserModel? _selectedStudent;
  WordLevel _selectedLevel = WordLevel.prePrimer;
  String _selectedInterest = 'animals';
  bool _isLoading = false;
  String? _error;
  StoryModel? _draft;
  bool _approved = false;

  final List<String> _interestOptions = const [
    'animals',
    'space',
    'sports',
    'friendship',
    'adventure',
    'school',
    'food',
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      setState(() {
        _classSection = context.read<CurrentUserModel>().classSection;
      });
      _loadStudents();
    });
  }

  Future<void> _loadStudents() async {
    final currentUser = context.read<CurrentUserModel>().user;
    final classSection = context.read<CurrentUserModel>().classSection;
    if (currentUser == null || classSection == null) {
      return;
    }

    final snapshot = await FirebaseFirestore.instance
        .collection('users')
        .where('id', whereIn: classSection.studentIds)
        .get();

    final students = snapshot.docs
        .map((doc) => UserModel.fromJson(doc.data()))
        .toList();

    if (students.isNotEmpty && mounted) {
      setState(() {
        _selectedStudent = students.first;
      });
    }
  }

  Future<void> _generateStory() async {
    if (_selectedStudent == null || _classSection == null) {
      setState(() {
        _error = 'Please select a student and make sure the class is loaded.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
      _approved = false;
      _draft = null;
    });

    try {
      final levelWords = <String>[
        'the',
        'and',
        'see',
        'go',
        'play',
        'big',
        'small',
        'dog',
        'cat',
      ];

      final result = await _storyService.generateDraft(
        studentId: _selectedStudent!.id ?? '',
        classId: _classSection!.id ?? '',
        readingLevel: _selectedLevel.name,
        interest: _selectedInterest,
        dolchWords: levelWords,
      );

      if (mounted) {
        setState(() {
          _draft = result.story;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Story generation failed: $e';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _approveStory() async {
    if (_draft == null) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final approved = await _storyService.approve(_draft!.id);
      if (mounted) {
        setState(() {
          _draft = approved;
          _approved = true;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Approval failed: $e';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final students = <UserModel>[];
    if (_selectedStudent != null) {
      students.add(_selectedStudent!);
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Teacher Story Builder'),
        backgroundColor: AppColors.bgPrimaryLightBlue,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Create a story draft for a student',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildStudentSelector(students),
            const SizedBox(height: 12),
            _buildLevelSelector(),
            const SizedBox(height: 12),
            _buildInterestSelector(),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _generateStory,
                icon: _isLoading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.auto_awesome),
                label: const Text('Generate Story'),
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 16),
              Text(_error!, style: const TextStyle(color: Colors.red)),
            ],
            if (_draft != null) ...[
              const SizedBox(height: 24),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.article_outlined),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Preview Draft',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(_draft!.text),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: _isLoading ? null : _generateStory,
                              icon: const Icon(Icons.refresh),
                              label: const Text('Regenerate'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: _isLoading ? null : _approveStory,
                              icon: const Icon(Icons.check_circle),
                              label: const Text('Approve'),
                            ),
                          ),
                        ],
                      ),
                      if (_approved) ...[
                        const SizedBox(height: 12),
                        Text(
                          'Approved for student.',
                          style: TextStyle(color: Colors.green.shade700),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStudentSelector(List<UserModel> students) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Student'),
        const SizedBox(height: 6),
        DropdownButtonFormField<UserModel>(
          initialValue: _selectedStudent,
          items: students
              .map((student) => DropdownMenuItem<UserModel>(
                    value: student,
                    child: Text(student.fullName.isNotEmpty ? student.fullName : student.username),
                  ))
              .toList(),
          onChanged: (student) {
            setState(() {
              _selectedStudent = student;
            });
          },
          decoration: const InputDecoration(border: OutlineInputBorder()),
        ),
      ],
    );
  }

  Widget _buildLevelSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Reading Level'),
        const SizedBox(height: 6),
        DropdownButtonFormField<WordLevel>(
          initialValue: _selectedLevel,
          items: WordLevel.values
              .where((level) => level != WordLevel.custom)
              .map((level) => DropdownMenuItem<WordLevel>(
                    value: level,
                    child: Text(level.name),
                  ))
              .toList(),
          onChanged: (level) {
            if (level != null) {
              setState(() {
                _selectedLevel = level;
              });
            }
          },
          decoration: const InputDecoration(border: OutlineInputBorder()),
        ),
      ],
    );
  }

  Widget _buildInterestSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Interest'),
        const SizedBox(height: 6),
        DropdownButtonFormField<String>(
          initialValue: _selectedInterest,
          items: _interestOptions
              .map((interest) => DropdownMenuItem<String>(
                    value: interest,
                    child: Text(interest),
                  ))
              .toList(),
          onChanged: (interest) {
            if (interest != null) {
              setState(() {
                _selectedInterest = interest;
              });
            }
          },
          decoration: const InputDecoration(border: OutlineInputBorder()),
        ),
      ],
    );
  }
}
