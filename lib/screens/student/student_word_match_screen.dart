import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:provider/provider.dart';

import 'package:readright/games/word_match_engine.dart';
import 'package:readright/models/current_user_model.dart';
import 'package:readright/models/word_model.dart';
import 'package:readright/services/word_respository.dart';
import 'package:readright/utils/app_colors.dart';
import 'package:readright/utils/app_styles.dart';
import 'package:readright/utils/enums.dart';

/// Word Match (PRD Pillar C, Game 1): Start -> 2x2 Gameplay -> Results.
///
/// Built on [WordMatchEngine] (Person 1) and the same Dolch word pool used
/// by student practice (`WordRepository.fetchLevelWords`). Buttons are sized
/// for young readers per the M3 DMMT critique (kid-scale tap targets).
class StudentWordMatchPage extends StatefulWidget {
  const StudentWordMatchPage({super.key});

  @override
  State<StudentWordMatchPage> createState() => _StudentWordMatchPageState();
}

enum _MatchPhase { start, loading, playing, results, error }

class _StudentWordMatchPageState extends State<StudentWordMatchPage> {
  final WordMatchEngine _engine = WordMatchEngine();
  final FlutterTts _flutterTts = FlutterTts();

  bool _argsLoaded = false;
  WordLevel? _wordLevel;

  _MatchPhase _phase = _MatchPhase.start;
  String? _errorMessage;

  List<WordMatchRound> _rounds = [];
  int _roundIndex = 0;
  int _correctCount = 0;
  String? _selectedWordId;
  bool _answered = false;
  WordMatchResult? _result;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_argsLoaded) return;
    _argsLoaded = true;

    final args = ModalRoute.of(context)?.settings.arguments;
    WordLevel? level;
    if (args is Map) {
      level = args['wordLevel'] as WordLevel?;
    }
    level ??= context.read<CurrentUserModel>().currentWordLevel;
    level ??= fetchWordLevelsIncreasingDifficultyOrder().first;

    setState(() {
      _wordLevel = level;
    });
  }

  WordMatchRound get _currentRound => _rounds[_roundIndex];

  Future<void> _startGame() async {
    if (_wordLevel == null) return;

    setState(() {
      _phase = _MatchPhase.loading;
      _errorMessage = null;
    });

    try {
      final words = await WordRepository().fetchLevelWords(_wordLevel!);

      if (words.length < WordMatchEngine.choicesPerRound) {
        setState(() {
          _phase = _MatchPhase.error;
          _errorMessage =
              'Not enough ${_wordLevel!.name} words yet — ask your teacher to add more!';
        });
        return;
      }

      final rounds = _engine.buildSession(words, questionCount: 10);

      setState(() {
        _rounds = rounds;
        _roundIndex = 0;
        _correctCount = 0;
        _answered = false;
        _selectedWordId = null;
        _result = null;
        _phase = _MatchPhase.playing;
      });

      _playCurrentWordAudio();
    } catch (e, st) {
      debugPrint('StudentWordMatchPage: Failed to start game: $e\n$st');
      if (!mounted) return;
      setState(() {
        _phase = _MatchPhase.error;
        _errorMessage = 'Something went wrong loading the game. Please try again.';
      });
    }
  }

  Future<void> _playCurrentWordAudio() async {
    if (_rounds.isEmpty) return;
    final word = _currentRound.target.text;
    final played = await _playAssetAudio(_currentRound.audioAssetPath);
    if (!played && mounted) {
      await _speakTts(word);
    }
  }

  // Play a pre-generated word MP3 from assets. Returns false (instead of
  // throwing) so callers can fall back to on-device TTS.
  Future<bool> _playAssetAudio(String assetPath) async {
    ByteData assetData;
    try {
      assetData = await rootBundle.load(assetPath);
    } catch (assetErr) {
      debugPrint('StudentWordMatchPage: audio asset not found: $assetPath ($assetErr)');
      return false;
    }

    final player = FlutterSoundPlayer();
    final completer = Completer<void>();
    try {
      try {
        await player.openPlayer();
      } catch (openErr) {
        debugPrint('StudentWordMatchPage: openPlayer failed: $openErr');
        return false;
      }

      try {
        await player.startPlayer(
          fromDataBuffer: assetData.buffer.asUint8List(),
          codec: Codec.mp3,
          whenFinished: () {
            if (!completer.isCompleted) completer.complete();
          },
        );
      } catch (startErr) {
        debugPrint('StudentWordMatchPage: startPlayer failed: $startErr');
        return false;
      }

      await completer.future;
      return true;
    } catch (playErr) {
      debugPrint('StudentWordMatchPage: playback error: $playErr');
      return false;
    } finally {
      try {
        await player.stopPlayer();
      } catch (_) {}
      try {
        await player.closePlayer();
      } catch (_) {}
    }
  }

  Future<void> _speakTts(String word) async {
    try {
      await _flutterTts.setLanguage('en-US');
      await _flutterTts.setPitch(1.0);
      await _flutterTts.setSpeechRate(0.45);
      await _flutterTts.speak(word);
    } catch (e) {
      debugPrint('StudentWordMatchPage: TTS speak failed: $e');
    }
  }

  void _handleChoice(WordModel choice) {
    if (_answered) return;

    final correct = _currentRound.isCorrect(choice.id);
    setState(() {
      _answered = true;
      _selectedWordId = choice.id;
      if (correct) _correctCount++;
    });

    Future.delayed(const Duration(milliseconds: 900), () {
      if (!mounted) return;
      _nextRound();
    });
  }

  void _nextRound() {
    final next = _roundIndex + 1;
    if (next >= _rounds.length) {
      final result = _engine.scoreSession(correct: _correctCount, total: _rounds.length);
      setState(() {
        _result = result;
        _phase = _MatchPhase.results;
      });
      return;
    }

    setState(() {
      _roundIndex = next;
      _answered = false;
      _selectedWordId = null;
    });
    _playCurrentWordAudio();
  }

  void _handleDashboard() {
    Navigator.pushNamedAndRemoveUntil(
      context,
      '/student-word-dashboard',
      (route) => false,
    );
  }

  @override
  void dispose() {
    _flutterTts.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: switch (_phase) {
          _MatchPhase.start => _buildStartScreen(),
          _MatchPhase.loading => _buildLoading(),
          _MatchPhase.playing => _buildGameplay(),
          _MatchPhase.results => _buildResults(),
          _MatchPhase.error => _buildError(),
        },
      ),
    );
  }

  // ---------------------------------------------------------------
  // Shared pieces
  // ---------------------------------------------------------------

  Widget _buildHeaderBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(8, 20, 20, 20),
      color: AppColors.bgPrimaryGray,
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: AppColors.buttonPrimaryGray),
            iconSize: 28,
            onPressed: _handleDashboard,
          ),
          const Text('Word Match', style: AppStyles.headerText),
        ],
      ),
    );
  }

  Widget _buildBigButton({
    required String label,
    required Color color,
    required VoidCallback onTap,
    IconData? icon,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 72,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(1000),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.15),
                blurRadius: 10,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(icon, color: Colors.white, size: 30),
                const SizedBox(width: 10),
              ],
              Text(label, style: AppStyles.buttonText.copyWith(fontSize: 22)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoading() {
    return const Center(
      child: CircularProgressIndicator(
        valueColor: AlwaysStoppedAnimation<Color>(AppColors.buttonPrimaryBlue),
      ),
    );
  }

  // ---------------------------------------------------------------
  // Start screen
  // ---------------------------------------------------------------

  Widget _buildStartScreen() {
    final levelLabel = _wordLevel?.name ?? 'Sight Words';
    final levelColor = _wordLevel?.backgroundColor ?? AppColors.bgPrimaryLightBlue;

    return Column(
      children: [
        _buildHeaderBanner(),
        Expanded(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  SizedBox(
                    width: 260,
                    height: 260,
                    child: SvgPicture.asset(
                      'assets/mascot/yeti_music.svg',
                      semanticsLabel: 'Yeti Music',
                      fit: BoxFit.contain,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: levelColor,
                      borderRadius: BorderRadius.circular(1000),
                    ),
                    child: Text(
                      levelLabel,
                      style: AppStyles.chipText.copyWith(fontWeight: FontWeight.w700),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Listen to the word, then tap the matching card. '
                    'Get as many right as you can!',
                    textAlign: TextAlign.center,
                    style: AppStyles.subheaderText,
                  ),
                  const SizedBox(height: 32),
                  _buildBigButton(
                    label: 'Start Game',
                    color: AppColors.bgPrimaryOrange,
                    icon: Icons.play_arrow_rounded,
                    onTap: _startGame,
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: _handleDashboard,
                    child: const Text('Back to Dashboard', style: AppStyles.navigationText),
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------
  // Gameplay screen (2x2)
  // ---------------------------------------------------------------

  Widget _buildGameplay() {
    if (_rounds.isEmpty) return _buildLoading();

    return Column(
      children: [
        _buildGameHeader(),
        const SizedBox(height: 8),
        _buildPromptPanel(),
        const SizedBox(height: 20),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
            child: GridView.count(
              crossAxisCount: 2,
              mainAxisSpacing: 20,
              crossAxisSpacing: 20,
              childAspectRatio: 1.15,
              children: _currentRound.choices.map(_buildChoiceTile).toList(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGameHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 16, 20, 0),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.close_rounded, color: AppColors.buttonPrimaryGray),
            iconSize: 28,
            tooltip: 'Quit to dashboard',
            onPressed: _handleDashboard,
          ),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: _roundIndex / _rounds.length,
                minHeight: 12,
                backgroundColor: AppColors.bgPrimaryLightGrey,
                valueColor: const AlwaysStoppedAnimation<Color>(AppColors.buttonPrimaryOrange),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.bgPrimaryLightBlue,
              borderRadius: BorderRadius.circular(1000),
            ),
            child: Text(
              '⭐ $_correctCount',
              style: AppStyles.chipText.copyWith(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPromptPanel() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.bgPrimaryLightBlue,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          Text(
            'Round ${_roundIndex + 1} of ${_rounds.length}',
            style: AppStyles.chipText.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 10),
          const Text(
            'Tap the word you hear',
            textAlign: TextAlign.center,
            style: AppStyles.subheaderText,
          ),
          const SizedBox(height: 16),
          _buildReplayButton(),
        ],
      ),
    );
  }

  Widget _buildReplayButton() {
    return GestureDetector(
      onTap: _playCurrentWordAudio,
      child: Container(
        width: 84,
        height: 84,
        decoration: BoxDecoration(
          color: AppColors.buttonPrimaryBlue,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.14),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const Icon(Icons.volume_up_rounded, color: Colors.white, size: 44),
      ),
    );
  }

  // Kid-scale answer tile: big tap target, high-contrast correct/wrong states.
  Widget _buildChoiceTile(WordModel choice) {
    final bool isSelected = _selectedWordId == choice.id;
    final bool isTargetTile = _currentRound.isCorrect(choice.id);
    final bool revealCorrect = _answered && isTargetTile;
    final bool wrongPick = _answered && isSelected && !isTargetTile;

    Color bg = Colors.white;
    Color border = const Color(0xFFB6C7D1);

    if (revealCorrect) {
      bg = AppColors.buttonSecondaryLightGreen;
      border = AppColors.buttonSecondaryGreen;
    } else if (wrongPick) {
      bg = AppColors.bgPrimaryLightRed;
      border = AppColors.buttonSecondaryRed;
    }

    return GestureDetector(
      onTap: () => _handleChoice(choice),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: border, width: 3),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        alignment: Alignment.center,
        padding: const EdgeInsets.all(12),
        child: Text(
          choice.text,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontFamily: 'SF Pro',
            fontSize: 32,
            fontWeight: FontWeight.w800,
            color: Colors.black87,
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------
  // Results screen
  // ---------------------------------------------------------------

  Widget _buildResults() {
    final result = _result;
    if (result == null) return _buildLoading();

    final passed = result.stars >= 3;

    return Column(
      children: [
        _buildHeaderBanner(),
        Expanded(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Column(
                children: [
                  const SizedBox(height: 12),
                  SizedBox(
                    width: 240,
                    height: 240,
                    child: SvgPicture.asset(
                      passed ? 'assets/mascot/yeti_happy.svg' : 'assets/mascot/yeti_upset.svg',
                      semanticsLabel: passed ? 'Yeti Happy' : 'Yeti Upset',
                      fit: BoxFit.contain,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildStarRow(result.stars),
                  const SizedBox(height: 16),
                  Text(
                    'You matched ${result.correct} of ${result.total} words!',
                    textAlign: TextAlign.center,
                    style: AppStyles.subsectionText,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    result.encouragement,
                    textAlign: TextAlign.center,
                    style: AppStyles.subheaderText,
                  ),
                  const SizedBox(height: 32),
                  _buildBigButton(
                    label: 'Play Again',
                    color: AppColors.bgPrimaryOrange,
                    icon: Icons.replay_rounded,
                    onTap: _startGame,
                  ),
                  const SizedBox(height: 16),
                  _buildBigButton(
                    label: 'Dashboard',
                    color: AppColors.buttonPrimaryBlue,
                    icon: Icons.home_rounded,
                    onTap: _handleDashboard,
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStarRow(int stars) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List<Widget>.generate(5, (i) {
        final filled = i < stars;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: SvgPicture.asset(
            filled
                ? 'assets/icons/star-yellow-svgrepo-com.svg'
                : 'assets/icons/star-gray-svgrepo-com.svg',
            width: 44,
            height: 44,
            semanticsLabel: filled ? 'Star Yellow' : 'Star Gray',
          ),
        );
      }),
    );
  }

  // ---------------------------------------------------------------
  // Error screen
  // ---------------------------------------------------------------

  Widget _buildError() {
    return Column(
      children: [
        _buildHeaderBanner(),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline_rounded, size: 64, color: AppColors.buttonSecondaryRed),
                  const SizedBox(height: 16),
                  Text(
                    _errorMessage ?? 'Something went wrong.',
                    textAlign: TextAlign.center,
                    style: AppStyles.subheaderText,
                  ),
                  const SizedBox(height: 28),
                  _buildBigButton(
                    label: 'Try Again',
                    color: AppColors.bgPrimaryOrange,
                    onTap: _startGame,
                  ),
                  const SizedBox(height: 16),
                  _buildBigButton(
                    label: 'Dashboard',
                    color: AppColors.buttonPrimaryBlue,
                    onTap: _handleDashboard,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
