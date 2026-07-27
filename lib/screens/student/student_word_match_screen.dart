import 'dart:math';
import 'package:flutter/material.dart';
import 'package:readright/services/word_respository.dart';
import 'package:readright/utils/app_colors.dart';
import 'package:readright/utils/enums.dart';

class StudentWordMatchPage extends StatefulWidget {
  const StudentWordMatchPage({super.key});

  @override
  State<StudentWordMatchPage> createState() => _StudentWordMatchPageState();
}

class _StudentWordMatchPageState extends State<StudentWordMatchPage> {
  bool _started = false;
  bool _finished = false;
  int _score = 0;
  int _round = 0;
  List<String> _choices = [];
  String? _correctWord;
  Set<String> _selected = {};
  List<String> _usedWords = [];

  Future<List<String>> _loadWords() async {
    final repo = WordRepository();
    final words = await repo.fetchLevelWords(WordLevel.prePrimer);
    final sightWords = words.map((w) => w.text).whereType<String>().toList();
    return sightWords.take(20).toList();
  }

  Future<void> _startGame() async {
    final words = await _loadWords();
    if (!mounted) return;
    if (words.length < 4) {
      setState(() {
        _finished = true;
        _score = 0;
      });
      return;
    }
    setState(() {
      _started = true;
      _finished = false;
      _score = 0;
      _round = 0;
      _usedWords = [];
      _selected = {};
      _buildRound(words);
    });
  }

  void _buildRound(List<String> allWords) {
    final available = allWords.where((word) => !_usedWords.contains(word)).toList();
    if (available.length < 4) {
      setState(() {
        _finished = true;
      });
      return;
    }

    final correct = available[Random().nextInt(available.length)];
    final distractors = <String>[];
    final pool = available.where((w) => w != correct).toList();
    while (distractors.length < 3 && pool.isNotEmpty) {
      final idx = Random().nextInt(pool.length);
      distractors.add(pool.removeAt(idx));
    }

    final merged = <String>[correct, ...distractors]..shuffle();
    setState(() {
      _correctWord = correct;
      _choices = merged;
      _round += 1;
      _selected = {};
    });
  }

  void _handleChoice(String word) {
    if (_selected.contains(word)) return;
    setState(() {
      _selected.add(word);
    });

    if (word == _correctWord) {
      setState(() {
        _score += 1;
        _usedWords.add(_correctWord!);
      });
      Future.delayed(const Duration(milliseconds: 450), () {
        if (!mounted) return;
        final words = _loadWords();
        words.then((allWords) {
          if (!mounted) return;
          if (allWords.length <= _usedWords.length) {
            setState(() {
              _finished = true;
            });
          } else {
            _buildRound(allWords);
          }
        });
      });
    } else if (_selected.length >= 2) {
      Future.delayed(const Duration(milliseconds: 450), () {
        if (!mounted) return;
        final words = _loadWords();
        words.then((allWords) {
          if (!mounted) return;
          if (allWords.length <= _usedWords.length) {
            setState(() {
              _finished = true;
            });
          } else {
            _buildRound(allWords);
          }
        });
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: AppColors.bgPrimaryLightBlue,
        title: const Text('Word Match'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: _finished
              ? _buildResults()
              : _started
                  ? _buildGame()
                  : _buildStartScreen(),
        ),
      ),
    );
  }

  Widget _buildStartScreen() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            'Word Match',
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          const Text(
            'Pick the word you hear from the sight-word cards.',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _startGame,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: AppColors.bgPrimaryOrange,
              ),
              child: const Text('Start Game', style: TextStyle(fontSize: 18)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGame() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text('Round', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
            const SizedBox(width: 8),
            Text('$_round', style: const TextStyle(fontSize: 18)),
            const Spacer(),
            Text('Score: $_score', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.bgPrimaryLightBlue,
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Center(
            child: Text(
              'Tap the matching sight word',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
            ),
          ),
        ),
        const SizedBox(height: 20),
        Expanded(
          child: GridView.count(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.1,
            children: _choices.map((word) {
              final isSelected = _selected.contains(word);
              return ElevatedButton(
                onPressed: () => _handleChoice(word),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isSelected ? AppColors.bgPrimaryOrange : Colors.white,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.all(12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                    side: const BorderSide(color: Color(0xFFB6C7D1), width: 2),
                  ),
                ),
                child: Text(
                  word,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildResults() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('Great job!', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Text('You matched $_score sight words!', style: const TextStyle(fontSize: 20)),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                setState(() {
                  _finished = false;
                  _started = false;
                });
              },
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: AppColors.bgPrimaryOrange,
              ),
              child: const Text('Play Again', style: TextStyle(fontSize: 18)),
            ),
          ),
        ],
      ),
    );
  }
}
