import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:lottie/lottie.dart';
import 'package:video_player/video_player.dart';
import 'theme.dart';
import 'widgets/talking_character.dart';
import 'services/game_service.dart';
import 'models/game_model.dart';
import 'character_selection_page.dart';
import 'dart:ui';

class GamePage extends StatefulWidget {
  const GamePage({super.key});

  @override
  State<GamePage> createState() => _GamePageState();
}

class _GamePageState extends State<GamePage>
    with SingleTickerProviderStateMixin {
  late AudioPlayer _audioPlayer;
  AnimationController? _animationController;
  bool _isPlaying = false;
  bool _isTalking = false;

  final GameService _gameService = GameService();
  Game? _gameData;
  bool _isLoading = true;
  VideoPlayerController? _videoController;
  bool _isVideoInitialized = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(
        seconds: 2,
      ), // Default duration until Lottie loads
    );
    _audioPlayer = AudioPlayer();

    // Listen to player state to sync the character's mouth
    _audioPlayer.onPlayerStateChanged.listen((state) {
      if (mounted) {
        setState(() {
          _isPlaying = state == PlayerState.playing;
          _isTalking = state == PlayerState.playing;

          if (_isTalking && _animationController != null) {
            _animationController!.repeat();
          } else if (_animationController != null) {
            _animationController!.stop();
          }
        });
      }
    });

    // Optional: listen to completion to reset explicitly
    _audioPlayer.onPlayerComplete.listen((_) {
      if (mounted) {
        setState(() {
          _isPlaying = false;
          _isTalking = false;
          _animationController?.stop();
        });
      }
    });

    _fetchGameData();
    _playIntroAudio();
    _initVideoBackground();
  }

  Future<void> _initVideoBackground() async {
    _videoController = VideoPlayerController.networkUrl(
      Uri.parse('https://id.gogram.fun/assets/video/ok.mp4'),
    );

    try {
      await _videoController!.initialize();
      await _videoController!.setLooping(true);
      await _videoController!.setVolume(0);
      _videoController!.play();
      if (mounted) {
        setState(() {
          _isVideoInitialized = true;
        });
      }
    } catch (e) {
      debugPrint("Video background failed to load: $e");
    }
  }

  Future<void> _fetchGameData() async {
    final data = await _gameService.getGame('stratopolis');
    if (mounted) {
      setState(() {
        _gameData = data;
        _isLoading = false;
      });
    }
  }

  Future<void> _playIntroAudio() async {
    try {
      await _audioPlayer.play(
        UrlSource('https://dl.espressif.com/dl/audio/ff-16b-2c-44100hz.mp3'),
      );
    } catch (e) {
      debugPrint("Could not play intro audio: $e");
    }
  }

  void _toggleAudio() {
    if (_isPlaying) {
      _audioPlayer.pause();
    } else {
      _audioPlayer.resume();
    }
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    _animationController?.dispose();
    _videoController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        body: OrganicBackgroundEnhanced(
          child: Center(child: CircularProgressIndicator(color: AppTheme.moss)),
        ),
      );
    }

    final game = _gameData;
    if (game == null) {
      return Scaffold(
        body: OrganicBackgroundEnhanced(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.error_outline,
                  color: AppTheme.earth,
                  size: 48,
                ),
                const SizedBox(height: 16),
                const Text('Failed to load level data'),
                TextButton(
                  onPressed: _fetchGameData,
                  child: const Text('RETRY'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          // Background Video
          if (_isVideoInitialized && _videoController != null)
            Positioned.fill(
              child: FittedBox(
                fit: BoxFit.cover,
                child: SizedBox(
                  width: _videoController!.value.size.width,
                  height: _videoController!.value.size.height + 900,
                  child: VideoPlayer(_videoController!),
                ),
              ),
            )
          else
            const OrganicBackgroundEnhanced(child: SizedBox.expand()),

          // Overlay for readability
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.4),
                    Colors.black.withOpacity(0.2),
                    Colors.black.withOpacity(0.6),
                  ],
                ),
              ),
            ),
          ),

          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24.0,
                    vertical: 12.0,
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(
                          Icons.arrow_back_ios_new_rounded,
                          color: Colors.white,
                        ),
                        onPressed: () {
                          if (Navigator.canPop(context)) {
                            Navigator.pop(context);
                          }
                        },
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.sage.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: AppTheme.sage.withOpacity(0.5),
                          ),
                        ),
                        child: Text(
                          'SDG ${game.sdgNumber}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Stack(
                          alignment: Alignment.bottomRight,
                          children: [
                            Container(
                              height: 150,
                              width: double.infinity,
                              child: _animationController == null
                                  ? const Center(
                                      child: CircularProgressIndicator(),
                                    )
                                  : Lottie.asset(
                                      'assets/talking_A maya avatar.json',
                                      controller: _animationController,
                                      fit: BoxFit.contain,
                                      errorBuilder:
                                          (context, error, stackTrace) {
                                            return TalkingCharacter(
                                              isTalking: _isTalking,
                                            );
                                          },
                                      onLoaded: (composition) {
                                        setState(() {
                                          _animationController!.duration =
                                              composition.duration;
                                          if (_isTalking) {
                                            _animationController!.repeat();
                                          }
                                        });
                                      },
                                    ),
                            ),
                            Positioned(
                              bottom: 0,
                              right: MediaQuery.of(context).size.width * 0.15,
                              child:
                                  IconButton(
                                    onPressed: _toggleAudio,
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                    icon: Icon(
                                      _isPlaying
                                          ? Icons.pause_circle_filled_rounded
                                          : Icons.play_circle_fill_rounded,
                                    ),
                                    color: AppTheme.earth.withOpacity(0.8),
                                    iconSize: 32,
                                  ).animate().fadeIn(
                                    duration: 800.ms,
                                    delay: 500.ms,
                                  ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 12),

                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                                  game.title,
                                  style: Theme.of(context)
                                      .textTheme
                                      .displayLarge
                                      ?.copyWith(
                                        color: Colors.white,
                                        shadows: [
                                          Shadow(
                                            color: Colors.black.withOpacity(
                                              0.5,
                                            ),
                                            blurRadius: 10,
                                          ),
                                        ],
                                      ),
                                )
                                .animate()
                                .fadeIn(duration: 1500.ms, delay: 300.ms)
                                .slideY(
                                  begin: 0.1,
                                  end: 0,
                                  curve: Curves.easeOutCubic,
                                ),

                            const SizedBox(height: 4),

                            Text(
                                  '${game.tagline}\nEradicating poverty in all its forms everywhere.',
                                  style: Theme.of(context).textTheme.titleLarge
                                      ?.copyWith(
                                        fontSize: 20,
                                        color: Colors.white.withOpacity(0.9),
                                      ),
                                )
                                .animate()
                                .fadeIn(duration: 1500.ms, delay: 400.ms)
                                .slideY(
                                  begin: 0.1,
                                  end: 0,
                                  curve: Curves.easeOutCubic,
                                ),

                            const SizedBox(height: 24),

                            Container(
                                  padding: const EdgeInsets.all(20),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.7),
                                    borderRadius: BorderRadius.circular(24),
                                    border: Border.all(
                                      color: AppTheme.forest.withOpacity(0.05),
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppTheme.forest.withOpacity(
                                          0.03,
                                        ),
                                        blurRadius: 20,
                                        offset: const Offset(0, 10),
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Row(
                                        children: [
                                          const Icon(
                                            Icons.info_outline_rounded,
                                            color: AppTheme.forest,
                                            size: 20,
                                          ),
                                          const SizedBox(width: 10),
                                          Text(
                                            'Level Overview',
                                            style: Theme.of(context)
                                                .textTheme
                                                .titleLarge
                                                ?.copyWith(fontSize: 18),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 12),
                                      Container(
                                        constraints: const BoxConstraints(
                                          maxHeight: 120, // Limit height
                                        ),
                                        child: SingleChildScrollView(
                                          physics:
                                              const BouncingScrollPhysics(),
                                          child: Text(
                                            game.levelOverview,
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodyMedium
                                                ?.copyWith(
                                                  fontSize: 14,
                                                  height: 1.5,
                                                ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                                .animate()
                                .fadeIn(duration: 1000.ms, delay: 600.ms)
                                .slideY(
                                  begin: 0.1,
                                  end: 0,
                                  curve: Curves.easeOutCubic,
                                ),

                            const SizedBox(height: 24),

                            Row(
                              children: [
                                Expanded(
                                  child:
                                      ElevatedButton(
                                        onPressed: () {
                                          _audioPlayer
                                              .pause(); // Pause intro music
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) =>
                                                  CharacterSelectionPage(
                                                    gameId: game.id,
                                                    characters: game.characters,
                                                  ),
                                            ),
                                          ).then((_) {
                                            if (mounted) _audioPlayer.resume();
                                          });
                                        },
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: AppTheme.earth,
                                        ),
                                        child: const Text('BEGIN QUEST'),
                                      ).animate().fadeIn(
                                        duration: 1000.ms,
                                        delay: 800.ms,
                                      ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
