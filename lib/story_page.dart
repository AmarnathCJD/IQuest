import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:video_player/video_player.dart';
import 'theme.dart';
import 'models/game_model.dart';
import 'models/story_model.dart';
import 'services/story_service.dart';
import 'services/voice_service.dart';
import 'sdg_report_page.dart';

class StoryPage extends StatefulWidget {
  final String gameId;
  final GameCharacter character;
  final bool realismMode;

  const StoryPage({
    super.key,
    required this.gameId,
    required this.character,
    required this.realismMode,
  });

  @override
  State<StoryPage> createState() => _StoryPageState();
}

class _StoryPageState extends State<StoryPage> with TickerProviderStateMixin {
  final StoryService _storyService = StoryService();
  final AudioPlayer _audioPlayer = AudioPlayer();
  final AudioPlayer _ambientPlayer = AudioPlayer();
  final List<HistoryEntry> _history = [];

  StoryScenario? _currentScenario;
  bool _isLoading = true;
  bool _isChoosing = false;

  int _socialImpact = 0;
  int _resourceStability = 0;

  // Cinematic Playback State
  int _visibleEventCount = 0;
  Timer? _eventTimer;
  final ScrollController _scrollController = ScrollController();
  final VoiceService _voiceService = VoiceService();
  bool _isSpeaking = false;
  int _playbackSessionId = 0;
  int _currentSpeakingIndex = -1;
  bool _isPaused = false;

  int _socialDelta = 0;
  int _resourceDelta = 0;
  bool _showDelta = false;
  Timer? _deltaTimer;

  VideoPlayerController? _activeVideo;
  VideoPlayerController? _preloadedVideo;
  Timer? _videoLoopTimer;
  bool _videoBgReady = false;
  bool _videoBgBlurry = false;
  int _loadingLoreIndex = 0;
  bool _isChoiceLoading = false;
  Timer? _loadingLoreTimer;
  Timer? _choiceTimer;
  int _secondsRemaining = 0;
  final List<String> _loadingLore = [
    "Analyzing universal ripples...",
    "Calibrating systemic parameters...",
    "Observing the weave of causality...",
    "Synchronizing timeline with SDG objectives...",
    "Evaluating socio-economic patterns...",
    "Exploring divergent future paths...",
    "Mapping the butterfly effect...",
    "Gathering systemic intelligence...",
  ];
  final List<String> _cookingLore = [
    "Cooking up consequences...",
    "The universe is processing your resolve.",
    "Narrative threads being stitched...",
    "Recalculating fate. Please hold.",
    "Echoing choices across existence...",
    "Writing the next chapter of your legacy...",
    "The future is taking shape.",
    "Defining the impact of your journey...",
  ];

  String _getVideoUrlForLayer(int layer) {
    final charId = widget.character.id;
    final isSecondHalf = layer >= 4;
    final gameId = widget.gameId.toLowerCase();

    final Map<String, Map<int, List<String>>> worldVideos = {
      'stratopolis': {
        1: [
          'https://yj73xzxbti.ucarecd.net/d7c3b95b-87f6-482d-8699-f4ebcc95789f/video.mp4',
          'https://yj73xzxbti.ucarecd.net/be77d667-e2db-4cf5-9cb1-8f45776b8c4b/video.mp4',
        ],
        2: [
          'https://yj73xzxbti.ucarecd.net/28d3e842-8215-4a9e-82c3-a67d3637e770/video.mp4',
          'https://yj73xzxbti.ucarecd.net/b8379a5f-0297-481d-a404-71f454a6d1e8/video.mp4',
        ],
        3: [
          'https://yj73xzxbti.ucarecd.net/fe8f0fb8-b439-4e04-b39f-9d2234cda4ae/video.mp4',
          'https://yj73xzxbti.ucarecd.net/b2c44ac2-c506-4425-87cd-fec1df0d34b0/video.mp4',
        ],
        4: [
          'https://yj73xzxbti.ucarecd.net/003ba120-1cb9-4fa0-a311-9eefcbf2915f/video.mp4',
          'https://yj73xzxbti.ucarecd.net/bac68d99-eb21-4620-addb-d247274ebcf1/video.mp4',
        ],
        5: [
          'https://yj73xzxbti.ucarecd.net/f152c2a8-b3c0-402d-b7f9-814d0b94e122/video.mp4',
          'https://yj73xzxbti.ucarecd.net/30a9d8d8-1248-425a-a106-8cac887e0a9d/video.mp4',
        ],
      },
      'zero_hunger': {
        1: [
          'https://yj73xzxbti.ucarecd.net/9103129c-3f03-449a-a7a9-c3cc301460ad/',
          'https://yj73xzxbti.ucarecd.net/e88abb40-6094-4f25-b7bb-53754f8586d4/',
        ],
        2: [
          'https://yj73xzxbti.ucarecd.net/c9b35cbd-0fe1-4f58-964a-3a0b7b596f95/',
          'https://yj73xzxbti.ucarecd.net/c6ab5db6-6d7d-415e-945e-31637e72482e/',
        ],
        3: [
          'https://yj73xzxbti.ucarecd.net/43144cd0-9118-413b-82d3-9a2887f01179/',
          'https://yj73xzxbti.ucarecd.net/9c1d0368-a41e-4142-9583-adc084e8f3a6/',
        ],
        4: [
          'https://yj73xzxbti.ucarecd.net/b2104398-4e4f-4b15-ab27-28b65f96fb38/',
          'https://yj73xzxbti.ucarecd.net/cb0565f7-6d76-436e-850e-4ead64686f01/',
        ],
        5: [
          'https://yj73xzxbti.ucarecd.net/cbe6c10b-a8f3-4f0d-ad81-4b0d0e57502e/',
          'https://yj73xzxbti.ucarecd.net/71c5dd7d-b597-4a9c-8f1b-6e48b0c66974/',
        ],
      },
      'vitalis_good_health': {
        1: [
          'https://yj73xzxbti.ucarecd.net/9d22c29a-bc15-4519-a39a-475df36c4bf6/adaptive_video/',
          'https://yj73xzxbti.ucarecd.net/9bbdceb2-7df9-4264-9be7-03033e63a8dd/adaptive_video/',
        ],
        2: [
          'https://yj73xzxbti.ucarecd.net/23197ae3-506d-456f-8bfa-288fd2fb1f50/adaptive_video/',
          'https://yj73xzxbti.ucarecd.net/0e07f290-cadd-422f-999a-8de0fa4fb5e2/adaptive_video/',
        ],
        3: [
          'https://yj73xzxbti.ucarecd.net/132b4345-571f-4e9f-8dab-8f9d21f0a16e/adaptive_video/',
          'https://yj73xzxbti.ucarecd.net/3bcd7776-7928-494b-b8c9-ccd6f67062af/adaptive_video/',
        ],
        4: [
          'https://yj73xzxbti.ucarecd.net/c4645d0f-89de-4537-9671-27c47ce9ff46/adaptive_video/',
          'https://yj73xzxbti.ucarecd.net/b867356e-5d17-460e-9d56-9b2fe25c08d5/adaptive_video/',
        ],
        5: [
          'https://yj73xzxbti.ucarecd.net/23a5afb6-7560-46f4-b348-469ffcd4a6b5/adaptive_video/',
          'https://yj73xzxbti.ucarecd.net/76f7479c-e777-4952-b6a5-32eeb5f733cf/adaptive_video/',
        ],
      },
    };

    final charMap = worldVideos[gameId] ?? worldVideos['stratopolis']!;

    final videos = charMap[charId] ?? charMap[1]!;

    return isSecondHalf ? videos[1] : videos[0];
  }

  double _getStartTimeForLayer(int layer) {
    // Each video contains three 2-second segments corresponding to the layers
    // Layer 1/4 -> 0.0s, Layer 2/5 -> 2.0s, Layer 3/6 -> 4.0s
    int relativeLayer;
    if (layer <= 3) {
      relativeLayer = layer - 1;
    } else {
      relativeLayer = layer - 4;
    }
    return relativeLayer * 2.0;
  }

  bool get _useVideoBg =>
      true; // Character-based video bg works for all games now

  // Flash Screen State
  bool _showFlash = false;
  String _flashText = '';
  String _flashSdgFact = '';
  bool _isSceneTransitioning = false;

  @override
  void initState() {
    super.initState();
    _ambientPlayer.setReleaseMode(ReleaseMode.loop);
    _initTts();
    _beginStory();
    // Delay video init until after first frame so platform channels are ready
    if (_useVideoBg) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        debugPrint(
          '[VideoBg] Starting after first frame, gameId="${widget.gameId}"',
        );
        _startVideoBg();
      });
    }
  }

  void _initTts() async {
    await _voiceService.initialize();
  }

  Future<void> _speakLine(
    String text, {
    String characterKey = 'narration',
  }) async {
    setState(() => _isSpeaking = true);
    await _voiceService.speak(text, characterKey: characterKey);
    if (mounted) setState(() => _isSpeaking = false);
  }

  @override
  void dispose() {
    _eventTimer?.cancel();
    _loadingLoreTimer?.cancel();
    _audioPlayer.stop(); // Added explicit stop before dispose
    _audioPlayer.dispose();
    _voiceService.stopSpeaking();
    _voiceService.dispose(); // Ensure isolate is killed
    _scrollController.dispose();
    _videoLoopTimer?.cancel();
    _activeVideo?.dispose();
    _preloadedVideo?.dispose();
    super.dispose();
  }

  Future<void> _beginStory() async {
    setState(() => _isLoading = true);
    _startLoadingLoreTimer();
    final scenario = await _storyService.beginStory(
      gameId: widget.gameId,
      characterId: widget.character.id,
      realismMode: widget.realismMode,
    );
    if (mounted && scenario != null) {
      _stopLoadingLoreTimer();
      _loadScenario(scenario);
    } else {
      if (mounted) {
        _stopLoadingLoreTimer();
        setState(() => _isLoading = false);
      }
    }
  }

  void _startLoadingLoreTimer() {
    _loadingLoreTimer?.cancel();
    _loadingLoreTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (mounted) {
        setState(() {
          _loadingLoreIndex = (_loadingLoreIndex + 1) % _loadingLore.length;
        });
        HapticFeedback.selectionClick();
      }
    });
  }

  void _stopLoadingLoreTimer() {
    _loadingLoreTimer?.cancel();
  }

  void _loadScenario(StoryScenario scenario) {
    _playbackSessionId++;
    final currentSession = _playbackSessionId;

    // Kill all previous audio/voice immediately
    _voiceService.stopSpeaking();
    _stopChoiceTimer();
    _ambientPlayer.stop();
    _audioPlayer.stop();

    // Scroll back to top so new content is visible from the start
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(0.0);
        // Double check/re-scroll after any micro-layout changes
        Future.delayed(const Duration(milliseconds: 100), () {
          if (mounted && _scrollController.hasClients) {
            _scrollController.animateTo(
              0.0,
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOut,
            );
          }
        });
      }
    });

    final nextSocial = scenario.currentSocialImpact;
    final nextResource = scenario.currentResourceStability;

    if (_history.isNotEmpty && _socialImpact != 0) {
      _socialDelta = nextSocial - _socialImpact;
      _resourceDelta = nextResource - _resourceStability;
      _showDelta = true;
      _deltaTimer?.cancel();
      _deltaTimer = Timer(const Duration(milliseconds: 3500), () {
        if (mounted) setState(() => _showDelta = false);
      });
    }

    setState(() {
      _socialImpact = nextSocial;
      _resourceStability = nextResource;
      _isSceneTransitioning = true;
      _isChoiceLoading = false;
      _currentScenario = scenario;
      _isLoading = false;
      _visibleEventCount = 0;
    });

    _playAmbientSound(scenario.ambientSound);

    // Start video bg when choices become visible (after events finish)
    if (_useVideoBg) _startVideoBg();

    // Fade out the transition flash
    Future.delayed(const Duration(milliseconds: 600), () {
      if (mounted) setState(() => _isSceneTransitioning = false);
    });

    // Start playback from fresh
    _eventTimer?.cancel();
    _isPaused = false;
    _voiceService.stopSpeaking();
    _speakNextLine(currentSession);
  }

  void _speakNextLine(int sessionId) async {
    if (!mounted || _currentScenario == null || sessionId != _playbackSessionId)
      return;

    if (_visibleEventCount < _currentScenario!.scene.length) {
      final idx = _visibleEventCount;
      final event = _currentScenario!.scene[idx];
      _currentSpeakingIndex = idx;

      setState(() => _visibleEventCount++);
      HapticFeedback.lightImpact();
      _scrollToBottom();

      await _playEventAudio(event, sessionId);
    } else {
      if (mounted) {
        setState(() => _isSpeaking = false);
        _startChoiceTimer();
      }
    }
  }

  Future<void> _playEventAudio(StoryEvent event, int sessionId) async {
    if (!mounted || sessionId != _playbackSessionId) return;

    if (event.type == 'narration' ||
        event.type == 'dialogue' ||
        event.type == 'conversation' ||
        event.type == 'action') {
      setState(() => _isSpeaking = true);
      await _ambientPlayer.setVolume(0.3);
      try {
        final speakerKey = (event.avatarKey?.isNotEmpty == true)
            ? event.avatarKey!.toLowerCase()
            : (event.character?.isNotEmpty == true)
            ? event.character!.toLowerCase()
            : 'narration';
        await _speakLine(event.text, characterKey: speakerKey);
      } catch (e) {
        debugPrint('TTS Speak failed: $e');
        setState(() => _isSpeaking = false);
      }

      if (!mounted || sessionId != _playbackSessionId) return;

      if (_isPaused) {
        setState(() => _isSpeaking = false);
        return;
      }

      await Future.delayed(const Duration(milliseconds: 400));
      await _ambientPlayer.setVolume(1.0); // Restore music volume
      if (mounted && sessionId == _playbackSessionId && !_isPaused) {
        _speakNextLine(sessionId);
      }
    } else if (event.type == 'ambience' || event.type == 'player_cue') {
      await Future.delayed(const Duration(milliseconds: 600));
      if (mounted && sessionId == _playbackSessionId && !_isPaused) {
        _speakNextLine(sessionId);
      }
    } else {
      await Future.delayed(const Duration(milliseconds: 800));
      if (mounted && sessionId == _playbackSessionId && !_isPaused) {
        _speakNextLine(sessionId);
      }
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent + 200,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeOut,
      );
    }
  }

  void _skipPlayback() {
    if (_currentScenario == null) return;
    _voiceService.stopSpeaking();
    _stopChoiceTimer();
    // Don't stop _ambientPlayer here, we want music to keep playing while they read
    _audioPlayer.stop();
    setState(() {
      _visibleEventCount = _currentScenario!.scene.length;
      _isSpeaking = false;
      _isPaused = false;
    });
    _eventTimer?.cancel();
    _scrollToBottom();
    _startChoiceTimer(); // Start timer after skip
  }

  void _togglePause() {
    if (!_isSpeaking && !_isPaused) return;
    setState(() => _isPaused = !_isPaused);
    if (_isPaused) {
      _voiceService.stopSpeaking();
      HapticFeedback.mediumImpact();
    } else {
      // Resume: re-speak the SAME line that was interrupted
      HapticFeedback.lightImpact();
      final session = _playbackSessionId;
      final idx = _currentSpeakingIndex;
      final scenario = _currentScenario;
      if (idx >= 0 && scenario != null && idx < scenario.scene.length) {
        setState(() => _isSpeaking = true);
        Future.delayed(const Duration(milliseconds: 150), () {
          if (mounted && !_isPaused && session == _playbackSessionId) {
            _playEventAudio(scenario.scene[idx], session);
          }
        });
      }
    }
  }

  void _startVideoBg() async {
    if (_currentScenario == null) return;
    _videoLoopTimer?.cancel();

    final targetLayer = _currentScenario!.currentLayer;
    final startTime = _getStartTimeForLayer(targetLayer);
    final videoUrl = _getVideoUrlForLayer(targetLayer);

    VideoPlayerController? next;

    if (_preloadedVideo != null && _preloadedVideo!.value.isInitialized) {
      // Instant swap — preloaded video is ready at the right URL
      next = _preloadedVideo;
      _preloadedVideo = null;
      debugPrint(
        '[VideoBg] Swapped to preloaded segment for Layer $targetLayer (starts at ${startTime}s)',
      );
    } else {
      // First load or fallback
      debugPrint('[VideoBg] Loading fresh: $videoUrl');
      try {
        final ctrl = VideoPlayerController.networkUrl(
          Uri.parse(videoUrl),
          videoPlayerOptions: VideoPlayerOptions(mixWithOthers: true),
        );
        await ctrl.initialize();
        await ctrl.seekTo(Duration(milliseconds: (startTime * 1000).toInt()));
        ctrl.setVolume(0);
        ctrl.setLooping(true);
        next = ctrl;
      } catch (e) {
        debugPrint('[VideoBg] FAILED: $e URL: $videoUrl');
        return;
      }
    }

    final old = _activeVideo;
    if (!mounted) {
      next?.dispose();
      return;
    }
    setState(() {
      _activeVideo = next;
      _videoBgReady = true;
      _videoBgBlurry = false;
    });
    next?.play();
    next?.setLooping(true);

    // Dispose old + preload the next one in background
    old?.dispose();
    _preloadNextVideo();
  }

  /// Silently pre-initialize the next layer's segment in the background.
  void _preloadNextVideo() async {
    if (_currentScenario == null) return;

    final nextLayer = _currentScenario!.currentLayer + 1;
    final nextStartTime = _getStartTimeForLayer(nextLayer);
    final nextVideoUrl = _getVideoUrlForLayer(nextLayer);

    debugPrint(
      '[VideoBg] Preloading Layer $nextLayer segment (${nextStartTime}s) from $nextVideoUrl',
    );
    try {
      final ctrl = VideoPlayerController.networkUrl(Uri.parse(nextVideoUrl));
      await ctrl.initialize();
      // Pre-seek to the next segment's start time
      await ctrl.seekTo(Duration(milliseconds: (nextStartTime * 1000).toInt()));
      ctrl.setVolume(0);
      ctrl.setLooping(false);

      if (!mounted) {
        ctrl.dispose();
        return;
      }
      _preloadedVideo?.dispose();
      _preloadedVideo = ctrl;
      debugPrint('[VideoBg] Preload for next segment ready!');
    } catch (e) {
      debugPrint('[VideoBg] Preload failed: $e');
    }
  }

  /// Skip only the CURRENT utterance and play the next one
  void _skipCurrentLine() {
    if (!_isSpeaking) return;
    _voiceService.stopSpeaking();
    setState(() => _isSpeaking = false);
    _audioPlayer.setVolume(1.0);
    final session = _playbackSessionId;
    Future.delayed(const Duration(milliseconds: 150), () {
      if (mounted) _speakNextLine(session);
    });
  }

  void _playAmbientSound(String? soundSlug) async {
    String? finalSlug = soundSlug;

    if (finalSlug != null && finalSlug.isNotEmpty) {
      finalSlug = finalSlug.replaceAll('.mp3', '').replaceAll('.wav', '');
    }

    if (finalSlug == null || finalSlug.isEmpty) {
      if (_currentScenario != null) {
        final mood = _currentScenario!.mood.toLowerCase();
        final location = _currentScenario!.sceneLocation.toLowerCase();

        // 1. Situation-based mapping
        if (mood.contains('tense') ||
            mood.contains('danger') ||
            mood.contains('fear') ||
            mood.contains('urgent') ||
            mood.contains('desperate') ||
            _currentScenario!.intensity > 6) {
          finalSlug = 'tense';
        } else if (mood.contains('hope') ||
            mood.contains('happy') ||
            mood.contains('light') ||
            mood.contains('joy')) {
          finalSlug = 'hopeful';
        } else if (mood.contains('success') ||
            mood.contains('triumph') ||
            mood.contains('win')) {
          finalSlug = 'success';
        } else if (location.contains('slum') ||
            location.contains('street') ||
            location.contains('alley') ||
            mood.contains('sad') ||
            mood.contains('neutral') ||
            mood.contains('reflective')) {
          finalSlug = 'neutral';
        } else {
          finalSlug = 'hopeful'; // Default positive vibe
        }
      } else {
        finalSlug = 'hopeful';
      }
    }

    try {
      await _ambientPlayer.setReleaseMode(ReleaseMode.loop);
      await _ambientPlayer.setVolume(1.0);
      await _ambientPlayer.play(
        UrlSource('https://id.gogram.fun/assets/audio/$finalSlug.mp3'),
      );
      debugPrint(
        '[Ambient] Playing $finalSlug for mood: ${_currentScenario?.mood}',
      );
    } catch (e) {
      debugPrint('[Ambient] Play failed: $e');
    }
  }

  Future<void> _makeChoice(StoryChoice choice) async {
    if (_isChoosing) return;
    HapticFeedback.mediumImpact();

    // Stop all audio as soon as a choice is made
    _voiceService.stopSpeaking();
    _audioPlayer.stop();

    setState(() {
      _isChoosing = true;
    });

    // 1. Record History & Impact
    final current = _currentScenario!;
    final storyText = current.scene
        .where((e) => e.type == 'narration')
        .map((e) => e.text)
        .join(' ');

    _history.add(
      HistoryEntry(
        scenarioTitle: current.scenarioTitle,
        storyText: storyText.isNotEmpty ? storyText : current.scenarioTitle,
        choiceTaken: choice.text,
      ),
    );

    // Show transition flash (delta animations will trigger upon new scenario load)
    _deltaTimer?.cancel();
    setState(() {
      _showDelta = false;
      _flashText = choice.consequenceHint;
      _flashSdgFact = current.sdgFact;
      _showFlash = true;
    });

    StoryScenario? nextScenario;

    final fetchFuture = _storyService.getCachedScenario(choice.cacheKey);
    final flashFuture = Future.delayed(const Duration(milliseconds: 5000));

    final results = await Future.wait([fetchFuture, flashFuture]);
    nextScenario = results[0] as StoryScenario?;

    if (nextScenario == null) {
      setState(() {
        _isLoading = true;
      });
      _startLoadingLoreTimer();
      setState(() => _isChoiceLoading = true);
      nextScenario = await _storyService.continueStory(
        gameId: widget.gameId,
        characterId: widget.character.id,
        choiceId: choice.id,
        choiceText: choice.text,
        cacheKey: choice.cacheKey,
        realismMode: widget.realismMode,
        history: _history,
      );
    }

    if (mounted) {
      _stopLoadingLoreTimer();
      if (nextScenario != null) {
        setState(() {
          _showFlash = false;
          _isChoosing = false;
        });
        _loadScenario(nextScenario);
      } else {
        setState(() {
          _isLoading = false;
          _isChoosing = false;
          _showFlash = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed to link to the next scenario timeline. Destiny falters.',
              style: GoogleFonts.inter(fontWeight: FontWeight.w600),
            ),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  String _formatSpeakerName(String key) {
    return key
        .split(RegExp(r'[_\s]+'))
        .map(
          (w) => w.isEmpty
              ? ''
              : '${w[0].toUpperCase()}${w.substring(1).toLowerCase()}',
        )
        .join(' ');
  }

  Color _getMoodAccent(String mood) {
    switch (mood.toLowerCase()) {
      case 'hopeful':
      case 'success':
        return const Color(0xFF2ECC71);
      case 'tense':
      case 'warning':
        return const Color(0xFFF1C40F);
      case 'chaotic':
      case 'conflict':
        return const Color(0xFFE67E22);
      case 'dire':
      case 'danger':
        return const Color(0xFFE74C3C);
      default:
        return AppTheme.moss;
    }
  }

  String _getAvatarUrl(String? avatarKey, {String? avatarUrl}) {
    if (avatarUrl != null && avatarUrl.isNotEmpty) {
      if (avatarUrl.startsWith('http')) return avatarUrl;
      if (avatarUrl.startsWith('/')) {
        return 'https://id.gogram.fun$avatarUrl';
      }
      return 'https://id.gogram.fun/$avatarUrl';
    }

    if (avatarKey == null || avatarKey.isEmpty) {
      return 'https://id.gogram.fun/assets/c1.jpg';
    }
    if (avatarKey == 'player') return 'https://id.gogram.fun/assets/player.jpg';

    int id = avatarKey.hashCode.abs() % 5 + 1;
    return 'https://id.gogram.fun/assets/c$id.jpg';
  }

  @override
  Widget build(BuildContext context) {
    final accent = _currentScenario?.moodColor ?? const Color(0xFF4CAF50);

    return Scaffold(
      body: Stack(
        children: [
          _buildBackground(),

          if (_videoBgReady &&
              _activeVideo != null &&
              _activeVideo!.value.isInitialized)
            Positioned.fill(
              child: AnimatedOpacity(
                opacity: 1.0,
                duration: const Duration(milliseconds: 800),
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: FittedBox(
                        fit: BoxFit.cover,
                        alignment: Alignment.center,
                        child: _activeVideo!.value.size.width > 0
                            ? SizedBox(
                                width: _activeVideo!.value.size.width,
                                height: _activeVideo!.value.size.height,
                                child: AspectRatio(
                                  aspectRatio: _activeVideo!.value.aspectRatio,
                                  child: VideoPlayer(_activeVideo!),
                                ),
                              )
                            : const SizedBox(width: 1280, height: 720),
                      ),
                    ),
                    // Post-2s Blur to highlight text
                    if (_videoBgBlurry)
                      Positioned.fill(
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 5.5, sigmaY: 5.5),
                          child: Container(color: Colors.black12),
                        ).animate().fadeIn(duration: 800.ms),
                      ),
                  ],
                ),
              ),
            ),

          if (_videoBgReady &&
              _activeVideo != null &&
              _activeVideo!.value.isInitialized)
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    stops: const [0.0, 0.4, 0.8, 1.0],
                    colors: [
                      Colors.black.withOpacity(0.55),
                      Colors.black.withOpacity(0.35),
                      Colors.black.withOpacity(0.65),
                      Colors.black.withOpacity(0.85),
                    ],
                  ),
                ),
              ),
            ),

          // 4. Particle Overlays & Content
          AtmosphericParticleOverlay(baseColor: accent),
          SafeArea(child: _buildContent()),
          if (_isSceneTransitioning)
            IgnorePointer(
              child: Container(
                color: Colors.white,
                width: double.infinity,
                height: double.infinity,
              ).animate().fadeOut(duration: 600.ms, curve: Curves.easeIn),
            ),
          if (_showFlash) _buildFlashScreen(),
        ],
      ),
    );
  }

  Widget _buildBackground() {
    final mood = _currentScenario?.mood ?? 'hopeful';
    final moodColor = _currentScenario?.moodColor ?? AppTheme.moss;
    Color moodOverlay = moodColor.withOpacity(0.05);
    Color vignetteColor = Colors.transparent;

    switch (mood.toLowerCase()) {
      case 'hopeful':
      case 'peaceful':
        moodOverlay = moodColor.withOpacity(0.05);
        break;
      case 'tense':
      case 'urgent':
      case 'reflective':
        moodOverlay = moodColor.withOpacity(0.1);
        vignetteColor = moodColor.withOpacity(0.1);
        break;
      case 'chaotic':
      case 'violent':
      case 'powerful':
        moodOverlay = moodColor.withOpacity(0.15);
        vignetteColor = Colors.black.withOpacity(0.4);
        break;
      case 'dire':
      case 'desperate':
      case 'heartbreaking':
        moodOverlay = Colors.black.withOpacity(0.4);
        vignetteColor = Colors.black.withOpacity(0.85);
        break;
    }

    final videoReady =
        _videoBgReady &&
        _activeVideo != null &&
        _activeVideo!.value.isInitialized;

    return Positioned.fill(
      child: Stack(
        children: [
          // Fallback Background Image (always present if video not ready)
          if (!videoReady)
            Positioned.fill(
              child: Stack(
                children: [
                  Positioned.fill(
                    child: AnimatedCrossFade(
                      duration: const Duration(seconds: 2),
                      crossFadeState: (_currentScenario?.isFinal == true)
                          ? CrossFadeState.showSecond
                          : CrossFadeState.showFirst,
                      firstChild: Image.asset(
                        'assets/char.jpg',
                        fit: BoxFit.cover,
                        width: double.infinity,
                        height: double.infinity,
                      ),
                      secondChild: Image.network(
                        'https://yj73xzxbti.ucarecd.net/20b504eb-a43f-4f95-ab59-5bfeeb740570/-/preview/557x1000/',
                        fit: BoxFit.cover,
                        width: double.infinity,
                        height: double.infinity,
                      ),
                    ),
                  ),
                  Positioned.fill(
                    child: BackdropFilter(
                      filter: ImageFilter.blur(
                        sigmaX: (_currentScenario?.isFinal == true) ? 0 : 8,
                        sigmaY: (_currentScenario?.isFinal == true) ? 0 : 8,
                      ),
                      child: AnimatedContainer(
                        duration: const Duration(seconds: 2),
                        color: Colors.black.withOpacity(
                          (_currentScenario?.isFinal == true) ? 0.20 : 0.35,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // Mood colour overlay
          Positioned.fill(
            child: AnimatedContainer(
              duration: const Duration(seconds: 1),
              curve: Curves.easeInOutSine,
              color: moodOverlay,
            ),
          ),

          // Vignette
          if (vignetteColor != Colors.transparent)
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment.center,
                    radius: 1.3,
                    colors: [Colors.transparent, vignetteColor],
                  ),
                ),
              ).animate().fadeIn(duration: 1.seconds),
            ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return _buildLoadingScreen();
    }

    if (_currentScenario == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: AppTheme.earth),
            const SizedBox(height: 24),
            Text(
              'Timeline Severed',
              style: GoogleFonts.balsamiqSans(
                fontSize: 28,
                color: AppTheme.forest,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _beginStory,
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.earth),
              child: const Text('RETRY LINK'),
            ),
          ],
        ),
      );
    }

    if (_currentScenario!.isFinal) {
      return _buildFinalScene(_currentScenario!);
    }

    return Column(
      children: [
        _buildHUD(_currentScenario!),
        Expanded(child: _buildScenePlayback(_currentScenario!)),
      ],
    );
  }

  void _startChoiceTimer() {
    _stopChoiceTimer();
    if (_currentScenario?.timeConstraint == null) return;

    setState(() {
      _secondsRemaining = _currentScenario!.timeConstraint!;
    });

    _choiceTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_isPaused) return;

      setState(() {
        if (_secondsRemaining > 0) {
          _secondsRemaining--;
          if (_secondsRemaining <= 5) {
            HapticFeedback.mediumImpact();
          }
        } else {
          timer.cancel();
          _handleTimerExpired();
        }
      });
    });
  }

  void _stopChoiceTimer() {
    _choiceTimer?.cancel();
    _choiceTimer = null;
  }

  void _handleTimerExpired() {
    if (_currentScenario == null || _isChoiceLoading) return;
    // Auto-pick first choice or handle "nothing" choice
    if (_currentScenario!.choices.isNotEmpty) {
      _makeChoice(_currentScenario!.choices.first);
    }
  }

  Widget _buildHUD(StoryScenario scenario) {
    debugPrint('Scenario: ${scenario.sceneLocation}');
    final accent = scenario.moodColor;
    final isDark =
        _videoBgReady || scenario.mood == 'dire' || scenario.mood == 'chaotic';
    final textColor = Colors.white;
    final isUrgent = _secondsRemaining <= 10 || scenario.intensity >= 8;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                icon: Icon(Icons.close_rounded, color: textColor),
                onPressed: _showExitDialog,
              ),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.6),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: accent.withOpacity(0.4),
                      width: 1.0,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.explore_rounded, size: 14, color: accent),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          scenario.sceneLocation.isEmpty
                              ? 'The Unknown'
                              : scenario.sceneLocation.toUpperCase(),
                          style: GoogleFonts.outfit(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 12,
                            letterSpacing: 1.5,
                            shadows: [
                              Shadow(color: Colors.black, blurRadius: 2),
                            ],
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              if (scenario.timeConstraint != null)
                Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: _secondsRemaining <= 5
                            ? Colors.redAccent.withOpacity(0.8)
                            : Colors.black.withOpacity(0.6),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _secondsRemaining <= 5
                              ? Colors.redAccent
                              : Colors.white.withOpacity(0.15),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.timer_outlined,
                            size: 14,
                            color: _secondsRemaining <= 5
                                ? Colors.white
                                : Colors.amberAccent,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            "${_secondsRemaining}S",
                            style: GoogleFonts.outfit(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                              fontSize: 11,
                              letterSpacing: 1,
                            ),
                          ),
                        ],
                      ),
                    )
                    .animate(
                      onPlay: isUrgent ? (c) => c.repeat(reverse: true) : null,
                    )
                    .scale(
                      begin: const Offset(1, 1),
                      end: isUrgent
                          ? const Offset(1.1, 1.1)
                          : const Offset(1, 1),
                      duration: 400.ms,
                    ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                flex: 2,
                child: _buildProgressBar(
                  'PROGRESS',
                  scenario.currentLayer /
                      (scenario.totalLayers > 0 ? scenario.totalLayers : 1),
                  accent,
                  isDark,
                ),
              ),
              const SizedBox(width: 8),
              // Social stat with delta float
              Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.topCenter,
                children: [
                  _buildMiniMetric(
                    Icons.people_rounded,
                    _socialImpact,
                    AppTheme.moss,
                    isDark,
                    onTap: () => _showStatDetails(true),
                  ),
                  if (_showDelta && _socialDelta != 0)
                    Positioned(
                      top: -24,
                      child: _buildDeltaFloater(_socialDelta, AppTheme.moss),
                    ),
                ],
              ),
              const SizedBox(width: 8),
              // Resource stat with delta float
              Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.topCenter,
                children: [
                  _buildMiniMetric(
                    Icons.account_balance_wallet_rounded,
                    _resourceStability,
                    AppTheme.earth,
                    isDark,
                    onTap: () => _showStatDetails(false),
                  ),
                  if (_showDelta && _resourceDelta != 0)
                    Positioned(
                      top: -24,
                      child: _buildDeltaFloater(_resourceDelta, AppTheme.earth),
                    ),
                ],
              ),
            ],
          ),

          if (_isLoading == false &&
              _currentScenario != null &&
              !_currentScenario!.isFinal &&
              (_isSpeaking ||
                  _isPaused ||
                  _visibleEventCount < _currentScenario!.scene.length))
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  GestureDetector(
                    onTap: _togglePause,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.4),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        _isPaused
                            ? Icons.play_arrow_rounded
                            : Icons.pause_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: _skipPlayback,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.4),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.fast_forward_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ).animate().fadeIn(),
            ),
        ],
      ),
    );
  }

  Widget _buildDeltaFloater(int delta, Color color) {
    final isPos = delta >= 0;
    return Text(
          '${isPos ? '+' : ''}$delta',
          style: GoogleFonts.outfit(
            fontSize: 13,
            fontWeight: FontWeight.w900,
            color: isPos ? color : Colors.redAccent,
            shadows: [Shadow(color: Colors.black, blurRadius: 4)],
          ),
        )
        .animate()
        .fadeIn(duration: 200.ms)
        .slideY(begin: 0, end: -1.4, duration: 1800.ms, curve: Curves.easeOut)
        .fadeOut(delay: 1200.ms, duration: 600.ms);
  }

  Widget _buildProgressBar(
    String label,
    double value,
    Color color,
    bool isDark,
  ) {
    final scenario = _currentScenario;
    final layer = scenario?.currentLayer ?? 1;
    final total = scenario?.totalLayers ?? 1;
    final chapterLabel = 'CH $layer / $total';

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.4),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(Icons.auto_awesome, size: 12, color: color),
                      const SizedBox(width: 6),
                      Text(
                        label.toUpperCase(),
                        style: GoogleFonts.outfit(
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          color: Colors.white70,
                          letterSpacing: 2.0,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      chapterLabel,
                      style: GoogleFonts.outfit(
                        fontSize: 9,
                        fontWeight: FontWeight.w900,
                        color: color,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Stack(
                children: [
                  Container(
                    height: 6,
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  FractionallySizedBox(
                    widthFactor: value.clamp(0.0, 1.0),
                    child: Container(
                      height: 6,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [color.withOpacity(0.6), color],
                          stops: const [0.0, 1.0],
                        ),
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMiniMetric(
    IconData icon,
    int value,
    Color color,
    bool isDark, {
    VoidCallback? onTap,
  }) {
    return GestureDetector(
          onTap: onTap,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 500),
                curve: Curves.easeOut,
                width: 58,
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(icon, size: 18, color: color),
                    const SizedBox(height: 4),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 400),
                      transitionBuilder: (child, anim) => SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(0, -0.5),
                          end: Offset.zero,
                        ).animate(anim),
                        child: FadeTransition(opacity: anim, child: child),
                      ),
                      child: Text(
                        value.toString(),
                        key: ValueKey<int>(value),
                        style: GoogleFonts.outfit(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        )
        .animate(onPlay: (c) => c.repeat(reverse: true))
        .shimmer(
          delay: 3.seconds,
          duration: 3.seconds,
          color: Colors.white.withOpacity(0.1),
        );
  }

  void _showStatDetails(bool isWorld) {
    final title = isWorld ? 'WORLD IMPACT' : 'CHARACTER VITALS';
    final score = isWorld ? _socialImpact : _resourceStability;
    final icon = isWorld ? Icons.public : Icons.account_balance_wallet_rounded;
    final color = isWorld ? AppTheme.moss : AppTheme.earth;

    String statusTitle;
    String statusDesc;
    if (score < 30) {
      statusTitle = isWorld ? 'CRITICAL INSTABILITY' : 'SEVERE DEFICIT';
      statusDesc = isWorld
          ? "The world edges toward collapse. Trust in institutions is broken, and societal structures are actively failing."
          : "Resources are depleted. Your personal standing, health, or wealth is critically compromised. Survival is not guaranteed.";
    } else if (score < 70) {
      statusTitle = isWorld ? 'FRAGILE EQUILIBRIUM' : 'WARY STABILITY';
      statusDesc = isWorld
          ? "A tenuous balance. The community survives, but remains highly vulnerable to the next crisis."
          : "You have just enough to maintain your position, but lack the surplus to absorb major shocks or take large risks.";
    } else {
      statusTitle = isWorld ? 'THRIVING UTOPIA' : 'POWER & INFLUENCE';
      statusDesc = isWorld
          ? "A beacon of civilization. Your actions have fostered an era of unprecedented resilience and prosperity."
          : "Your strategic focus has paid off. You command immense resources, security, and personal leverage.";
    }

    // Algorithm Details
    final algoTitle = isWorld
        ? 'SOCIAL COEFFICIENT ALGORITHM'
        : 'RESOURCE ACCUMULATION ALGORITHM';
    final algoSteps = isWorld
        ? [
            '+ POSITIVE: Empowering community, resolving conflict, broad wealth distribution.',
            '- NEGATIVE: Marginalizing classes, inciting panic, ignoring collective needs.',
            '× MODIFIER: High-intensity scenarios scale impact by 1.5x.',
          ]
        : [
            '+ POSITIVE: Securing assets, political leverage, physical preservation.',
            '- NEGATIVE: Reckless spending, taking physical damage, alienating key allies.',
            '× MODIFIER: Severe time pressure increases resource entropy by 2x.',
          ];

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(36)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Container(
            height: MediaQuery.of(context).size.height * 0.65,
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.75),
              border: Border(
                top: BorderSide(color: color.withOpacity(0.4), width: 1.5),
              ),
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Drag handle
                  Center(
                    child: Container(
                      margin: const EdgeInsets.only(top: 10, bottom: 12),
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),

                  // Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(icon, size: 24, color: color),
                      const SizedBox(width: 10),
                      Text(
                        title,
                        style: GoogleFonts.outfit(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 2,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Score Display
                  Center(
                    child: Column(
                      children: [
                        Text(
                          '$score',
                          style: GoogleFonts.outfit(
                            color: color,
                            fontSize: 52,
                            fontWeight: FontWeight.w900,
                            height: 1.0,
                            shadows: [
                              Shadow(
                                color: color.withOpacity(0.5),
                                blurRadius: 15,
                              ),
                            ],
                          ),
                        ).animate().scale(
                          begin: const Offset(0.8, 0.8),
                          curve: Curves.easeOutBack,
                        ),
                        Text(
                          'TOTAL POINTS',
                          style: GoogleFonts.outfit(
                            color: Colors.white54,
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 3.0,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Status Block
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 20),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white.withOpacity(0.1)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(
                                color: color,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(color: color, blurRadius: 4),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              statusTitle,
                              style: GoogleFonts.outfit(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1.2,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          statusDesc,
                          style: GoogleFonts.quicksand(
                            color: Colors.white70,
                            fontSize: 13,
                            height: 1.4,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ).animate().slideY(begin: 0.2, end: 0).fadeIn(),

                  const SizedBox(height: 16),

                  // Algorithm Block
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 20),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: color.withOpacity(0.2)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.functions_rounded,
                              size: 14,
                              color: color,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                algoTitle,
                                style: GoogleFonts.outfit(
                                  color: color,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 1.0,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        ...algoSteps
                            .map(
                              (step) => Padding(
                                padding: const EdgeInsets.only(bottom: 6.0),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '>',
                                      style: TextStyle(
                                        color: color.withOpacity(0.7),
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        step,
                                        style: GoogleFonts.quicksand(
                                          color: Colors.white70,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                          height: 1.3,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            )
                            .toList(),
                      ],
                    ),
                  ).animate(delay: 100.ms).slideY(begin: 0.2, end: 0).fadeIn(),

                  const SizedBox(height: 32),

                  Center(
                    child: Text(
                      'SWIPE DOWN TO CLOSE',
                      style: GoogleFonts.outfit(
                        color: Colors.white38,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 2.0,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildScenePlayback(StoryScenario scenario) {
    final isDark = scenario.mood == 'dire' || scenario.mood == 'chaotic';
    final textColor = isDark ? Colors.white : AppTheme.forest;
    final accent = _getMoodAccent(scenario.mood);

    bool hasPlayerCue = scenario.scene.any((e) => e.type == 'player_cue');

    // Determine the last speaking event to highlight the active speaker
    String? activeSpeakerKey;
    for (int i = _visibleEventCount - 1; i >= 0; i--) {
      final e = scenario.scene[i];
      if ((e.type == 'dialogue' || e.type == 'action') && e.avatarKey != null) {
        activeSpeakerKey = e.avatarKey;
        break;
      }
    }

    // Collect unique speaker keys (excluding player) for persistent avatars
    final List<String> npcKeys = [];
    for (final e in scenario.scene) {
      if ((e.type == 'dialogue' || e.type == 'action') &&
          e.avatarKey != null &&
          e.avatarKey != 'player' &&
          !npcKeys.contains(e.avatarKey)) {
        npcKeys.add(e.avatarKey!);
      }
    }
    final hasPlayer = scenario.scene.any(
      (e) =>
          (e.type == 'dialogue' || e.type == 'action') &&
          e.avatarKey == 'player',
    );

    return Column(
      children: [
        // Persistent speaker avatars row at the top
        if (npcKeys.isNotEmpty || hasPlayer)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // NPC speaker(s) on the left
                Row(
                  children: npcKeys.take(2).map((key) {
                    final isActive = key == activeSpeakerKey;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: _buildPersistentAvatar(
                        key,
                        isActive,
                        accent,
                        isDark,
                        avatarUrl: scenario.scene
                            .firstWhere(
                              (e) => e.avatarKey == key,
                              orElse: () => scenario.scene.first,
                            )
                            .avatarUrl,
                      ),
                    );
                  }).toList(),
                ),
                // Player on the right
                if (hasPlayer)
                  _buildPersistentAvatar(
                    'player',
                    activeSpeakerKey == 'player',
                    accent,
                    isDark,
                    avatarUrl: scenario.scene
                        .firstWhere(
                          (e) => e.avatarKey == 'player',
                          orElse: () => scenario.scene.first,
                        )
                        .avatarUrl,
                  ),
              ],
            ),
          ).animate().fadeIn(duration: 600.ms),

        // Scene content
        Expanded(
          child: ListView(
            controller: _scrollController,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            children: [
              // Scenario Title
              Text(
                    scenario.scenarioTitle.toUpperCase(),
                    textAlign: TextAlign.center,
                    style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      height: 1.2,
                      letterSpacing: 2.0,
                      shadows: [
                        Shadow(
                          color: Colors.black.withOpacity(0.8),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                  )
                  .animate()
                  .fadeIn(duration: 800.ms)
                  .scale(begin: const Offset(0.9, 0.9)),
              const SizedBox(height: 24),

              // Character Reaction
              if (scenario.characterReaction.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 32),
                  child:
                      Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? Colors.white.withOpacity(0.1)
                                  : Colors.white.withOpacity(0.7),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: AppTheme.sage.withOpacity(
                                  isDark ? 0 : 0.4,
                                ),
                                width: 2,
                              ),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.format_quote_rounded,
                                  color: AppTheme.earth,
                                  size: 28,
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Text(
                                    scenario.characterReaction,
                                    style: GoogleFonts.quicksand(
                                      color: textColor.withOpacity(0.9),
                                      fontSize: 16,
                                      fontStyle: FontStyle.italic,
                                      fontWeight: FontWeight.w700,
                                      height: 1.4,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          )
                          .animate()
                          .fadeIn(duration: 800.ms)
                          .slideY(begin: -0.1, end: 0),
                ),

              // Scene Events
              for (int i = 0; i < _visibleEventCount; i++)
                Padding(
                  padding: const EdgeInsets.only(bottom: 24),
                  child:
                      _buildEventCard(
                            scenario.scene[i],
                            isDark,
                            isLatest: i == _visibleEventCount - 1,
                            accent: accent,
                          )
                          .animate()
                          .fadeIn(duration: 400.ms)
                          .slideY(begin: 0.1, end: 0),
                ),

              if (_visibleEventCount >= scenario.scene.length && !hasPlayerCue)
                _buildChoicesFallback(
                  scenario,
                ).animate().fadeIn(duration: 600.ms),

              const SizedBox(height: 16),

              // Playback controls: pause/resume + skip — only shown while narrating
              if (_isSpeaking || _isPaused)
                Center(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.35),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.1),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Pause / Resume
                            GestureDetector(
                              onTap: _togglePause,
                              child: Icon(
                                _isPaused
                                    ? Icons.play_arrow_rounded
                                    : Icons.pause_rounded,
                                size: 24,
                                color: AppTheme.moss,
                              ),
                            ),

                            Container(
                              width: 1,
                              height: 16,
                              margin: const EdgeInsets.symmetric(
                                horizontal: 16,
                              ),
                              color: Colors.white24,
                            ),

                            // Skip current line
                            GestureDetector(
                              onTap: _skipCurrentLine,
                              child: const Icon(
                                Icons.skip_next_rounded,
                                size: 24,
                                color: Colors.white60,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ).animate().fadeIn(duration: 400.ms),

              const SizedBox(height: 120),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPersistentAvatar(
    String avatarKey,
    bool isActive,
    Color accent,
    bool isDark, {
    String? avatarUrl,
  }) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isActive ? accent : Colors.transparent,
              width: 3,
            ),
            boxShadow: isActive
                ? [
                    BoxShadow(
                      color: accent.withOpacity(0.4),
                      blurRadius: 16,
                      spreadRadius: 2,
                    ),
                  ]
                : [],
          ),
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 400),
            opacity: isActive ? 1.0 : 0.4,
            child: ColorFiltered(
              colorFilter: isActive
                  ? const ColorFilter.mode(Colors.transparent, BlendMode.dst)
                  : const ColorFilter.matrix(<double>[
                      0.2126,
                      0.7152,
                      0.0722,
                      0,
                      0,
                      0.2126,
                      0.7152,
                      0.0722,
                      0,
                      0,
                      0.2126,
                      0.7152,
                      0.0722,
                      0,
                      0,
                      0,
                      0,
                      0,
                      1,
                      0,
                    ]),
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  color: AppTheme.sage.withOpacity(0.2),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.network(
                    _getAvatarUrl(avatarKey, avatarUrl: avatarUrl),
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Icon(
                      avatarKey == 'player'
                          ? Icons.person
                          : Icons.smart_toy_rounded,
                      color: AppTheme.forest,
                      size: 24,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        if (isActive && _isSpeaking)
          Positioned(
            right: -4,
            top: -4,
            child:
                Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: accent,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: accent.withOpacity(0.5),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.volume_up_rounded,
                        size: 10,
                        color: Colors.white,
                      ),
                    )
                    .animate(onPlay: (c) => c.repeat())
                    .scale(
                      begin: const Offset(0.8, 0.8),
                      end: const Offset(1.2, 1.2),
                      duration: 600.ms,
                      curve: Curves.easeInOut,
                    )
                    .then()
                    .scale(
                      begin: const Offset(1.2, 1.2),
                      end: const Offset(0.8, 0.8),
                      duration: 600.ms,
                      curve: Curves.easeInOut,
                    ),
          ),
      ],
    );
  }

  Widget _buildEventCard(
    StoryEvent event,
    bool isDark, {
    bool isLatest = false,
    Color? accent,
  }) {
    if (event.type == 'player_cue') {
      return _buildPlayerCue(event);
    }

    final isNarration = event.type == 'narration';
    final isAmbience = event.type == 'ambience';
    final isPlayer = event.avatarKey == 'player';

    // Premium styling constants
    final textColor = (_videoBgReady || isDark)
        ? Colors.white
        : AppTheme.forest;
    final moodAccent = accent ?? AppTheme.moss;

    if (isNarration || isAmbience) {
      final isLatestNarration = isLatest && isNarration;
      return AnimatedScale(
        duration: const Duration(milliseconds: 400),
        scale: isLatestNarration ? 1.01 : 1.0,
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 400),
          opacity: isLatest ? 1.0 : 0.6,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: 18,
                    horizontal: 24,
                  ),
                  decoration: BoxDecoration(
                    color: isLatest
                        ? Colors.white.withOpacity(0.12)
                        : Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: isLatest
                        ? [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ]
                        : [],
                  ),
                  child: Text(
                    event.text,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.outfit(
                      color: textColor,
                      fontSize: isNarration ? 18 : 15,
                      fontWeight: isLatest ? FontWeight.w700 : FontWeight.w600,
                      fontStyle: isAmbience
                          ? FontStyle.italic
                          : FontStyle.normal,
                      height: 1.5,
                      letterSpacing: 0.2,
                      shadows: [
                        Shadow(
                          color: Colors.black.withOpacity(0.5),
                          blurRadius: 10,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }

    if (event.type == 'dialogue' || event.type == 'action') {
      final portrait = _buildPortrait(
        event.avatarKey,
        event.emotion,
        avatarUrl: event.avatarUrl,
        isActive: isLatest,
        accent: moodAccent,
      );
      final bubble = _buildBubble(
        event.text, // Fix: pass event.text, not event
        isPlayer,
        isDark,
        isLatest: isLatest,
        avatarKey: event.avatarKey,
        accent: moodAccent,
      );

      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: isPlayer
              ? MainAxisAlignment.end
              : MainAxisAlignment.start,
          children: isPlayer
              ? [Expanded(child: bubble), const SizedBox(width: 10), portrait]
              : [portrait, const SizedBox(width: 10), Expanded(child: bubble)],
        ),
      );
    }

    return const SizedBox.shrink();
  }

  Widget _buildPortrait(
    String? avatarKey,
    String? emotion, {
    String? avatarUrl,
    bool isActive = false,
    Color? accent,
  }) {
    String imgName = avatarKey ?? 'unknown';
    if (emotion != null && emotion.isNotEmpty) imgName = '${imgName}_$emotion';
    final glowColor = accent ?? AppTheme.moss;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: AppTheme.sage.withOpacity(0.2),
        border: Border.all(
          color: isActive ? glowColor : AppTheme.sage.withOpacity(0.5),
          width: isActive ? 3 : 2,
        ),
        boxShadow: isActive
            ? [
                BoxShadow(
                  color: glowColor.withOpacity(0.3),
                  blurRadius: 12,
                  spreadRadius: 1,
                ),
              ]
            : [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 6,
                  offset: const Offset(0, 3),
                ),
              ],
      ),
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 300),
        opacity: isActive ? 1.0 : 0.5,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Image.network(
            _getAvatarUrl(avatarKey, avatarUrl: avatarUrl),
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Image.network(
              _getAvatarUrl(avatarKey, avatarUrl: avatarUrl),
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) =>
                  const Icon(Icons.person, color: AppTheme.forest, size: 28),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBubble(
    String text,
    bool isPlayer,
    bool isDark, {
    bool isLatest = false,
    String? avatarKey,
    Color? accent,
  }) {
    final moodAccent = accent ?? AppTheme.moss;

    // Bubble theme: Video-mode uses black glass for all, otherwise classic theme
    Color bubbleBg;
    Color textCol;
    if (_videoBgReady) {
      bubbleBg = isLatest
          ? Colors.black.withOpacity(0.7)
          : Colors.black.withOpacity(0.4);
      textCol = Colors.white;
    } else {
      bubbleBg = isPlayer
          ? (isLatest ? moodAccent : moodAccent.withOpacity(0.15))
          : (isLatest ? Colors.white : Colors.white.withOpacity(0.6));
      textCol = isPlayer
          ? (isLatest ? Colors.white : AppTheme.forest)
          : (isLatest ? AppTheme.forest : AppTheme.forest.withOpacity(0.6));
    }

    final bubbleContent = AnimatedScale(
      duration: const Duration(milliseconds: 400),
      scale: isLatest ? 1.01 : 0.98,
      curve: Curves.easeOutBack,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 400),
        opacity: isLatest ? 1.0 : 0.7,
        child: Container(
          decoration: BoxDecoration(
            color: bubbleBg,
            borderRadius: BorderRadius.circular(16),
            boxShadow: isLatest
                ? [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.15),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ]
                : [],
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Column(
            crossAxisAlignment: isPlayer
                ? CrossAxisAlignment.end
                : CrossAxisAlignment.start,
            children: [
              if (!isPlayer && avatarKey != null && isLatest)
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Text(
                    avatarKey.toUpperCase(),
                    style: GoogleFonts.outfit(
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      color: moodAccent,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
              Text(
                text,
                style: GoogleFonts.outfit(
                  color: textCol,
                  fontSize: 15,
                  fontWeight: isLatest ? FontWeight.w600 : FontWeight.w500,
                  height: 1.45,
                  shadows: _videoBgReady
                      ? [
                          Shadow(
                            color: Colors.black.withOpacity(0.4),
                            blurRadius: 2,
                            offset: const Offset(0, 1),
                          ),
                        ]
                      : [],
                ),
              ),
              // Speaker name shown below every bubble
              if (avatarKey != null && avatarKey.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    '— ${_formatSpeakerName(avatarKey)}',
                    style: GoogleFonts.outfit(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: isPlayer
                          ? Colors.white.withOpacity(0.7)
                          : moodAccent.withOpacity(0.85),
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );

    if (isLatest) {
      return bubbleContent
          .animate(onPlay: (c) => c.repeat(reverse: true))
          .shimmer(duration: 2.seconds, color: Colors.white.withOpacity(0.2));
    }
    return bubbleContent;
  }

  Widget _buildPlayerCue(StoryEvent cue) {
    if (_currentScenario == null) return const SizedBox.shrink();

    final isFinal = _currentScenario!.isFinal;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 32),
        Text(
          isFinal ? 'JOURNEY COMPLETE' : cue.text.toUpperCase(),
          textAlign: TextAlign.center,
          style: GoogleFonts.quicksand(
            color: AppTheme.earth,
            fontWeight: FontWeight.w900,
            letterSpacing: 2,
            fontSize: 13,
          ),
        ),
        const SizedBox(height: 24),
        if (isFinal)
          _buildReportButton()
        else
          ..._currentScenario!.choices.asMap().entries.map(
            (e) => _buildChoiceButton(e.value, e.key),
          ),
      ],
    );
  }

  Widget _buildChoicesFallback(StoryScenario scenario) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 32),
        Text(
          scenario.isFinal ? 'JOURNEY COMPLETE' : 'WHAT WILL YOU DO?',
          textAlign: TextAlign.center,
          style: GoogleFonts.quicksand(
            color: AppTheme.earth,
            fontWeight: FontWeight.w900,
            letterSpacing: 2,
            fontSize: 13,
          ),
        ),
        const SizedBox(height: 24),
        if (scenario.isFinal)
          _buildReportButton()
        else
          ...scenario.choices.asMap().entries.map(
            (e) => _buildChoiceButton(e.value, e.key),
          ),
      ],
    );
  }

  Widget _buildReportButton() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: ElevatedButton.icon(
        icon: const Icon(Icons.analytics_rounded, size: 22),
        label: Text(
          'VIEW IMPACT REPORT',
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.w800,
            fontSize: 15,
            letterSpacing: 2,
          ),
        ),
        onPressed: _isLoading ? null : _viewReportCallback,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: AppTheme.forest,
          elevation: 4,
          padding: const EdgeInsets.symmetric(vertical: 22),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.1, end: 0);
  }

  Future<void> _viewReportCallback() async {
    setState(() => _isLoading = true);
    final report = await _storyService.fetchSdgReport(
      gameId: widget.gameId,
      characterId: widget.character.id,
      history: _history,
      finalScore: {
        'social_impact': _socialImpact,
        'resource_stability': _resourceStability,
      },
    );
    setState(() => _isLoading = false);
    if (mounted && report != null) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => SdgReportPage(
            report: report,
            character: widget.character,
            gameId: widget.gameId,
          ),
        ),
      );
    }
  }

  Widget _buildChoiceButton(StoryChoice choice, int index) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child:
          Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: _isChoosing ? null : () => _makeChoice(choice),
                  borderRadius: BorderRadius.circular(20),
                  splashColor: AppTheme.moss.withOpacity(0.1),
                  highlightColor: AppTheme.moss.withOpacity(0.05),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.12),
                            width: 1.5,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: 26,
                                  height: 26,
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    color: AppTheme.moss.withOpacity(0.12),
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: AppTheme.moss.withOpacity(0.3),
                                      width: 1.0,
                                    ),
                                  ),
                                  child: Text(
                                    '${index + 1}',
                                    style: GoogleFonts.outfit(
                                      color: AppTheme.moss,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Text(
                                    choice.text,
                                    style: GoogleFonts.outfit(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                      height: 1.35,
                                      shadows: [
                                        Shadow(
                                          color: Colors.black.withOpacity(0.5),
                                          blurRadius: 6,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                if (choice.realWorldContext.isNotEmpty)
                                  _buildInfoTooltip(choice.realWorldContext),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                vertical: 10,
                                horizontal: 14,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.04),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.tips_and_updates_outlined,
                                    size: 11,
                                    color: AppTheme.sage.withOpacity(0.5),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      choice.consequenceHint,
                                      style: GoogleFonts.quicksand(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white.withOpacity(0.45),
                                        fontStyle: FontStyle.italic,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ).animate().fadeIn(delay: 400.ms),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              )
              .animate()
              .fadeIn(delay: (index * 120).ms, duration: 500.ms)
              .slideY(begin: 0.15, end: 0, curve: Curves.easeOut),
    );
  }

  Widget _buildInfoTooltip(String message) {
    return Tooltip(
      message: message,
      triggerMode: TooltipTriggerMode.tap,
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(18),
      textStyle: GoogleFonts.quicksand(
        fontSize: 14,
        color: Colors.white,
        fontWeight: FontWeight.w600,
      ),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.95),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white24, width: 1.5),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 20),
        ],
      ),
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: Colors.amberAccent.withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: const Icon(
          Icons.lightbulb_outline_rounded,
          color: Colors.amberAccent,
          size: 20,
        ),
      ),
    );
  }

  Widget _buildFlashScreen() {
    return Container(
      color: Colors.black.withOpacity(0.95),
      width: double.infinity,
      height: double.infinity,
      child: Column(
        children: [
          Expanded(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child:
                    Text(
                          _flashText,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.balsamiqSans(
                            color: Colors.white,
                            fontSize: 32,
                            fontWeight: FontWeight.w700,
                            height: 1.2,
                          ),
                        )
                        .animate()
                        .fadeIn(duration: 400.ms)
                        .then(delay: 1500.ms)
                        .fadeOut(duration: 400.ms),
              ),
            ),
          ),
          if (_flashSdgFact.isNotEmpty)
            Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.transparent, AppTheme.forest],
                    ),
                  ),
                  child: SafeArea(
                    top: false,
                    child: Row(
                      children: [
                        const Icon(
                          Icons.public,
                          color: AppTheme.sage,
                          size: 32,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Text(
                            _flashSdgFact,
                            style: GoogleFonts.inter(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
                .animate()
                .slideY(
                  begin: 1.0,
                  end: 0,
                  duration: 400.ms,
                  curve: Curves.easeOut,
                )
                .then(delay: 1500.ms)
                .fadeOut(duration: 400.ms),
        ],
      ),
    );
  }

  Widget _buildFinalScene(StoryScenario scenario) {
    final accent = scenario.moodColor;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(32),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.55),
                borderRadius: BorderRadius.circular(32),
                border: Border.all(color: accent.withOpacity(0.4), width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: accent.withOpacity(0.1),
                    blurRadius: 30,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.auto_awesome_rounded, size: 64, color: accent)
                      .animate(onPlay: (c) => c.repeat(reverse: true))
                      .scale(
                        begin: const Offset(1, 1),
                        end: const Offset(1.1, 1.1),
                        duration: 2.seconds,
                      ),
                  const SizedBox(height: 20),
                  Text(
                    'DESTINY FORGED',
                    style: GoogleFonts.outfit(
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: 4,
                      shadows: [
                        Shadow(color: accent.withOpacity(0.5), blurRadius: 10),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildFinalStat(
                        Icons.public,
                        'World',
                        _socialImpact,
                        AppTheme.sage,
                      ),
                      _buildFinalStat(
                        Icons.bolt,
                        'Resources',
                        _resourceStability,
                        AppTheme.earth,
                      ),
                    ],
                  ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.2, end: 0),
                  const SizedBox(height: 32),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white.withOpacity(0.1)),
                    ),
                    child: Text(
                      scenario.characterReaction.isNotEmpty
                          ? scenario.characterReaction
                          : "Your story comes to a close in the district.",
                      textAlign: TextAlign.center,
                      style: GoogleFonts.quicksand(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        height: 1.5,
                      ),
                    ),
                  ).animate().fadeIn(delay: 800.ms).slideY(begin: 0.1, end: 0),
                  const SizedBox(height: 40),

                  // SDG Report Button
                  ElevatedButton.icon(
                    onPressed: () async {
                      setState(() => _isChoiceLoading = true);
                      _startLoadingLoreTimer();
                      final report = await _storyService.fetchSdgReport(
                        gameId: widget.gameId,
                        characterId: widget.character.id,
                        history: _history,
                        finalScore: {
                          'social_impact': _socialImpact,
                          'resource_stability': _resourceStability,
                        },
                      );
                      _stopLoadingLoreTimer();
                      if (mounted) {
                        setState(() => _isChoiceLoading = false);
                        if (report != null) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (ctx) => SdgReportPage(
                                report: report,
                                character: widget.character,
                                gameId: widget.gameId,
                              ),
                            ),
                          ).then((_) {
                            // Ensure we go back to hub if returned from SDG page
                            if (mounted)
                              Navigator.popUntil(context, (r) => r.isFirst);
                          });
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Failed to calculate SDG alignment.',
                              ),
                            ),
                          );
                        }
                      }
                    },
                    icon: const Icon(
                      Icons.analytics_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                    label: Text(
                      'ANALYZE IMPACT',
                      style: GoogleFonts.outfit(
                        fontWeight: FontWeight.w800,
                        letterSpacing: 2,
                        color: Colors.black87,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: accent,
                      minimumSize: const Size(double.infinity, 56),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 8,
                      shadowColor: accent.withOpacity(0.5),
                    ),
                  ).animate().fadeIn(delay: 1200.ms),

                  const SizedBox(height: 16),

                  TextButton(
                    onPressed: () =>
                        Navigator.popUntil(context, (r) => r.isFirst),
                    child: Text(
                      'RETURN TO HUB',
                      style: GoogleFonts.outfit(
                        color: Colors.white54,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ).animate().fadeIn(delay: 1500.ms),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFinalStat(IconData icon, String label, int value, Color color) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.15),
            shape: BoxShape.circle,
            border: Border.all(color: color.withOpacity(0.3)),
          ),
          child: Icon(icon, color: color, size: 28),
        ),
        const SizedBox(height: 12),
        Text(
          value.toString(),
          style: GoogleFonts.outfit(
            color: Colors.white,
            fontSize: 28,
            fontWeight: FontWeight.w900,
            shadows: [Shadow(color: color.withOpacity(0.5), blurRadius: 10)],
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label.toUpperCase(),
          style: GoogleFonts.quicksand(
            color: Colors.white54,
            fontSize: 10,
            fontWeight: FontWeight.w800,
            letterSpacing: 2,
          ),
        ),
      ],
    );
  }

  void _showExitDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          'Abandon Journey?',
          style: GoogleFonts.balsamiqSans(
            color: AppTheme.forest,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          'Your progress in this story will be lost.',
          style: GoogleFonts.quicksand(
            color: AppTheme.forest,
            fontWeight: FontWeight.w600,
          ),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('STAY'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pop(context);
            },
            child: const Text(
              'ABANDON',
              style: TextStyle(color: Colors.redAccent),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingScreen() {
    final loreList = _isChoiceLoading ? _cookingLore : _loadingLore;
    final title = _isChoiceLoading ? 'COOKING...' : 'WEAVING DESTINY';
    final spinIcon = _isChoiceLoading
        ? Icons.restaurant_menu_rounded
        : Icons.auto_awesome;
    final accentColor = _isChoiceLoading ? AppTheme.moss : AppTheme.earth;

    return Scaffold(
      backgroundColor: Colors
          .transparent, // Ensure we see through to story_page background if needed, but we'll add the image directly
      body: Stack(
        children: [
          // If cooking choices, we keep it simple (transparent/dark), if weaving destiny we show the big background
          if (!_isChoiceLoading)
            Positioned.fill(
              child: Image.network(
                'https://yj73xzxbti.ucarecd.net/20b504eb-a43f-4f95-ab59-5bfeeb740570/-/preview/557x1000/',
                fit: BoxFit.cover,
              ),
            ),
          // Dark overlay for readability (no blur)
          Positioned.fill(
            child: Container(color: Colors.black.withOpacity(0.35)),
          ),

          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Cinematic Spinner with pulsing aura
                Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: RadialGradient(
                              colors: [
                                accentColor.withOpacity(0.2),
                                Colors.transparent,
                              ],
                            ),
                          ),
                        )
                        .animate(onPlay: (c) => c.repeat())
                        .scale(
                          begin: const Offset(1, 1),
                          end: const Offset(1.5, 1.5),
                          duration: 2.seconds,
                        )
                        .fadeOut(duration: 2.seconds),

                    const SizedBox(
                      width: 60,
                      height: 60,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    ),
                    Icon(spinIcon, color: Colors.white70, size: 24)
                        .animate(onPlay: (c) => c.repeat())
                        .rotate(duration: 4.seconds),
                  ],
                ),

                const SizedBox(height: 48),

                // Main Title
                Text(
                      title,
                      style: GoogleFonts.outfit(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 10,
                        shadows: [
                          Shadow(
                            color: accentColor.withOpacity(0.8),
                            blurRadius: 20,
                          ),
                          Shadow(
                            color: Colors.black.withOpacity(0.5),
                            blurRadius: 15,
                          ),
                        ],
                      ),
                    )
                    .animate(onPlay: (c) => c.repeat(reverse: true))
                    .fadeIn(duration: 1.seconds)
                    .shimmer(
                      color: accentColor.withOpacity(0.5),
                      duration: 2.seconds,
                    )
                    .scale(
                      begin: const Offset(1, 1),
                      end: const Offset(1.05, 1.05),
                      duration: 3.seconds,
                      curve: Curves.easeInOut,
                    ),

                const SizedBox(height: 24),

                // Lore Artifact Fragment
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 800),
                  transitionBuilder:
                      (Widget child, Animation<double> animation) {
                        return FadeTransition(
                          opacity: animation,
                          child: SlideTransition(
                            position: Tween<Offset>(
                              begin: const Offset(0, 0.2),
                              end: Offset.zero,
                            ).animate(animation),
                            child: child,
                          ),
                        );
                      },
                  child: Container(
                    key: ValueKey<String>(
                      '${_isChoiceLoading}_$_loadingLoreIndex',
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 40,
                      vertical: 20,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white10),
                    ),
                    constraints: const BoxConstraints(maxWidth: 320),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 30,
                          height: 2,
                          decoration: BoxDecoration(
                            color: accentColor.withOpacity(0.5),
                            borderRadius: BorderRadius.circular(1),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          loreList[_loadingLoreIndex % loreList.length]
                              .toUpperCase(),
                          textAlign: TextAlign.center,
                          style: GoogleFonts.quicksand(
                            color: Colors.white.withOpacity(0.8),
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 2,
                            height: 1.6,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 40),

                // Game loading progress bar with glow
                Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      width: 220,
                      height: 6,
                      decoration: BoxDecoration(
                        color: accentColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                            color: accentColor.withOpacity(0.2),
                            blurRadius: 15,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                    ),
                    Container(
                          width: 200,
                          height: 3,
                          decoration: BoxDecoration(
                            color: Colors.white10,
                            borderRadius: BorderRadius.circular(2),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(2),
                            child: LinearProgressIndicator(
                              color: accentColor,
                              backgroundColor: Colors.transparent,
                            ),
                          ),
                        )
                        .animate(onPlay: (c) => c.repeat(reverse: true))
                        .shimmer(color: Colors.white30, duration: 1.5.seconds),
                  ],
                ),
              ],
            ), // closes Column
          ), // closes Center
        ], // closes Stack children
      ), // closes Stack
    ); // closes Scaffold
  }
}
