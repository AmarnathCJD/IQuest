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

  // Video background — double-buffered for instant scenario switches
  VideoPlayerController? _activeVideo; // currently shown
  VideoPlayerController? _preloadedVideo; // loading in background
  Timer? _videoLoopTimer;
  bool _videoBgReady = false;
  bool _videoBgBlurry = false;

  String _getVideoUrlForLayer(int layer) {
    // Each character has 2 dedicated videos (e.g., Char 1 uses 1.mp4 and 2.mp4)
    // Layers 1-3 play segments from the 1st video (Part A)
    // Layers 4-6 play segments from the 2nd video (Part B)
    final charId = widget.character.id;
    final isSecondHalf = layer >= 4;
    final videoIndex = (charId - 1) * 2 + (isSecondHalf ? 2 : 1);
    return 'https://id.gogram.fun/api/game/stream-video/$videoIndex.mp4';
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
    _audioPlayer.setReleaseMode(ReleaseMode.loop);
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
    _audioPlayer.dispose();
    _voiceService.stopSpeaking();
    _scrollController.dispose();
    _videoLoopTimer?.cancel();
    _activeVideo?.dispose();
    _preloadedVideo?.dispose();
    super.dispose();
  }

  Future<void> _beginStory() async {
    setState(() => _isLoading = true);
    final scenario = await _storyService.beginStory(
      gameId: widget.gameId,
      characterId: widget.character.id,
      realismMode: widget.realismMode,
    );
    if (mounted && scenario != null) {
      _loadScenario(scenario);
    } else {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _loadScenario(StoryScenario scenario) {
    _playbackSessionId++;
    final currentSession = _playbackSessionId;

    setState(() {
      _isSceneTransitioning = true;
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
    _voiceService.stopSpeaking(); // Changed from _flutterTts.stop()
    _speakNextLine(currentSession);
  }

  void _speakNextLine(int sessionId) async {
    if (!mounted || _currentScenario == null || sessionId != _playbackSessionId)
      return;

    if (_visibleEventCount < _currentScenario!.scene.length) {
      final event = _currentScenario!.scene[_visibleEventCount];

      setState(() {
        _visibleEventCount++;
      });
      HapticFeedback.lightImpact();
      _scrollToBottom();

      if (event.type == 'narration' ||
          event.type == 'dialogue' ||
          event.type == 'conversation' ||
          event.type == 'action') {
        debugPrint(
          '[Story] Speaking event type="${event.type}" speaker="${event.avatarKey}" text="${event.text.substring(0, event.text.length.clamp(0, 40))}..."',
        );
        setState(() => _isSpeaking = true);
        await _audioPlayer.setVolume(0.2);
        try {
          final speakerKey = (event.avatarKey?.isNotEmpty == true)
              ? event.avatarKey!.toLowerCase()
              : (event.character?.isNotEmpty == true)
              ? event.character!.toLowerCase()
              : 'narration';
          // Each character gets their unique vocal profile automatically
          await _speakLine(event.text, characterKey: speakerKey);
        } catch (e) {
          debugPrint('TTS Speak failed: $e');
          setState(() => _isSpeaking = false);
        }

        // Natural pause between lines
        await Future.delayed(const Duration(milliseconds: 500));
        await _audioPlayer.setVolume(1.0);
        if (mounted) _speakNextLine(sessionId);
      } else if (event.type == 'ambience' || event.type == 'player_cue') {
        // Non-spoken events — just show and advance quickly
        debugPrint('[Story] Non-spoken event type="${event.type}"');
        await Future.delayed(const Duration(milliseconds: 800));
        if (mounted) _speakNextLine(sessionId);
      } else {
        debugPrint('[Story] Unknown event type="${event.type}" — advancing');
        await Future.delayed(const Duration(seconds: 1));
        if (mounted) _speakNextLine(sessionId);
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

  /// Skip ALL remaining lines — jump to end (tap on scene body)
  void _skipPlayback() {
    if (_currentScenario == null) return;
    _voiceService.stopSpeaking();
    setState(() {
      _visibleEventCount = _currentScenario!.scene.length;
      _isSpeaking = false;
    });
    _eventTimer?.cancel();
  }

  // ── Video Background — double-buffered ──────────────────────────────────────

  /// First call: load fresh. Subsequent calls: swap from preloaded (instant).
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
        ctrl.setLooping(false);
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
    next!.play();

    // Freeze after 2 seconds and blur the background
    _videoLoopTimer = Timer(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() => _videoBgBlurry = true);
        _activeVideo?.pause();
      }
    });

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
    if (soundSlug == null || soundSlug.isEmpty) {
      await _audioPlayer.stop();
      return;
    }
    try {
      // Plays background ambience (if endpoints exist)
      await _audioPlayer.play(
        UrlSource('https://id.gogram.fun/assets/audio/$soundSlug.mp3'),
      );
    } catch (e) {
      // Ignore if missing to prevent crashes
    }
  }

  Future<void> _makeChoice(StoryChoice choice) async {
    if (_isChoosing) return;
    HapticFeedback.mediumImpact();

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

    setState(() {
      _socialImpact += choice.socialImpact;
      _resourceStability += choice.resourceStability;
      _flashText = choice.consequenceHint;
      _flashSdgFact = current.sdgFact;
      _showFlash = true;
    });

    // 2. Fetch Cached Scenario & Wait for Flash overlay
    StoryScenario? nextScenario;

    final fetchFuture = _storyService.getCachedScenario(choice.cacheKey);
    final flashFuture = Future.delayed(const Duration(milliseconds: 2500));

    final results = await Future.wait([fetchFuture, flashFuture]);
    nextScenario = results[0] as StoryScenario?;

    // 3. Fallback if cache missed
    if (nextScenario == null) {
      setState(() {
        _isLoading = true;
      });
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

    // 4. Load next
    if (mounted) {
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

  /// Capitalizes each word of a speaker key (e.g. 'elder_mage' → 'Elder Mage')
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
        return const Color(0xFF2ECC71); // Emerald Green
      case 'tense':
      case 'warning':
        return const Color(0xFFF1C40F); // Sun Yellow
      case 'chaotic':
      case 'conflict':
        return const Color(0xFFE67E22); // Carrot Orange
      case 'dire':
      case 'danger':
        return const Color(0xFFE74C3C); // Alizarin Red
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

    // Hash-based mapping for consistent NPC avatars fallback
    int id = avatarKey.hashCode.abs() % 5 + 1;
    return 'https://id.gogram.fun/assets/c$id.jpg';
  }

  @override
  Widget build(BuildContext context) {
    final accent = _currentScenario?.moodColor ?? const Color(0xFF4CAF50);

    return Scaffold(
      body: Stack(
        children: [
          // 1. Background (Video or Image Fallback)
          _buildBackground(),

          // 2. Video Player (Layered above fallback but below overlays)
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
                        child: SizedBox(
                          width: _activeVideo!.value.size.width > 0
                              ? _activeVideo!.value.size.width
                              : 1280,
                          height: _activeVideo!.value.size.height > 0
                              ? _activeVideo!.value.size.height
                              : 720,
                          child: VideoPlayer(_activeVideo!),
                        ),
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

          // 3. Stylistic gradient veil
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
                    child: Image.asset('assets/char.jpg', fit: BoxFit.cover),
                  ),
                  Positioned.fill(
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                      child: Container(color: Colors.black.withOpacity(0.35)),
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
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(
              width: 50,
              height: 50,
              child: CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 3,
              ),
            ),
            const SizedBox(height: 32),
            Text(
                  'WEAVING DESTINY...',
                  style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 4,
                    shadows: [
                      Shadow(
                        color: Colors.black.withOpacity(0.8),
                        blurRadius: 12,
                      ),
                    ],
                  ),
                )
                .animate()
                .fadeIn(duration: 800.ms)
                .scale(begin: const Offset(0.9, 0.9)),
          ],
        ),
      );
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
        Expanded(
          child: GestureDetector(
            onTap: _skipPlayback,
            behavior: HitTestBehavior.opaque,
            child: _buildScenePlayback(_currentScenario!),
          ),
        ),
      ],
    );
  }

  Widget _buildHUD(StoryScenario scenario) {
    final accent =
        scenario.moodColor; // use API moodColor instead of old mapper
    final isDark =
        _videoBgReady || scenario.mood == 'dire' || scenario.mood == 'chaotic';
    final textColor = Colors.white;
    final isUrgent =
        (scenario.timePressure?.toLowerCase().contains('hour') ?? false) ||
        scenario.intensity >= 8;

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
              if (scenario.timePressure != null &&
                  scenario.timePressure!.isNotEmpty)
                Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.6),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.15),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.timer_outlined,
                            size: 14,
                            color: Colors.amberAccent,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            scenario.timePressure!.toUpperCase(),
                            style: GoogleFonts.outfit(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 11,
                              letterSpacing: 1,
                              shadows: [
                                Shadow(color: Colors.black, blurRadius: 2),
                              ],
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
                          ? const Offset(1.05, 1.05)
                          : const Offset(1, 1),
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
              _buildMiniMetric(
                Icons.people_rounded,
                _socialImpact,
                Colors.blueAccent,
                isDark,
                onTap: () => _showStatDetails(true),
              ),
              const SizedBox(width: 8),
              _buildMiniMetric(
                Icons.account_balance_wallet_rounded,
                _resourceStability,
                Colors.orangeAccent,
                isDark,
                onTap: () => _showStatDetails(false),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProgressBar(
    String label,
    double value,
    Color color,
    bool isDark,
  ) {
    final bg = _videoBgReady
        ? Colors.black.withOpacity(0.4)
        : (isDark ? Colors.white10 : Colors.black.withOpacity(0.03));
    final textCol = (_videoBgReady || isDark) ? Colors.white : AppTheme.forest;

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
        border: _videoBgReady
            ? Border.all(color: Colors.white.withOpacity(0.05))
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label.toUpperCase(),
                style: GoogleFonts.outfit(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: textCol.withOpacity(0.7),
                  letterSpacing: 1.2,
                ),
              ),
              Text(
                '${(value * 100).toInt()}%',
                style: GoogleFonts.outfit(
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: value,
              backgroundColor: Colors.white.withOpacity(0.1),
              valueColor: AlwaysStoppedAnimation<Color>(color),
              minHeight: 5,
            ),
          ),
        ],
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
    final bg = _videoBgReady
        ? Colors.black.withOpacity(0.4)
        : (isDark ? Colors.white10 : Colors.black.withOpacity(0.03));
    final textCol = (_videoBgReady || isDark) ? Colors.white : AppTheme.forest;

    return GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(10),
              border: _videoBgReady
                  ? Border.all(color: color.withOpacity(0.3))
                  : Border.all(color: color.withOpacity(0.1)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 14, color: color),
                const SizedBox(width: 8),
                Text(
                  value.toString(),
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    color: textCol,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  'PTS',
                  style: GoogleFonts.outfit(
                    fontSize: 8,
                    fontWeight: FontWeight.w800,
                    color: textCol.withOpacity(0.5),
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        )
        .animate(onPlay: (c) => c.repeat(reverse: true))
        .shimmer(
          delay: 2.seconds,
          duration: 3.seconds,
          color: color.withOpacity(0.1),
        );
  }

  void _showStatDetails(bool isWorld) {
    final title = isWorld ? 'WORLD IMPACT' : 'CHARACTER VITALS';
    final score = isWorld ? _socialImpact : _resourceStability;
    final icon = isWorld ? Icons.public : Icons.favorite_rounded;
    final color = isWorld ? Colors.blueAccent : Colors.orangeAccent;

    String description;
    if (isWorld) {
      if (score < 30) {
        description =
            "The world is on the brink of collapse. Your decisions have sowed discord and neglect.";
      } else if (score < 70) {
        description =
            "The global balance is fragile. Every choice you make ripples through the foundations of society.";
      } else {
        description =
            "A beacon of hope. Your actions have fostered a resilient and thriving global community.";
      }
    } else {
      if (score < 30) {
        description =
            "Barely hanging on. Resources are depleted, and your personal standing is compromised.";
      } else if (score < 70) {
        description =
            "Stable but wary. You have just enough to survive, but no margin for error.";
      } else {
        description =
            "Thriving and influential. Your strategic focus has secured a legacy of stability and power.";
      }
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.5,
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.9),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          border: Border.all(color: Colors.white.withOpacity(0.1)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            Icon(icon, size: 48, color: color),
            const SizedBox(height: 16),
            Text(
              title,
              style: GoogleFonts.outfit(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w900,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '$score',
              style: GoogleFonts.outfit(
                color: color,
                fontSize: 42,
                fontWeight: FontWeight.w900,
              ),
            ),
            Text(
              'POINTS',
              style: GoogleFonts.outfit(
                color: color.withOpacity(0.5),
                fontSize: 14,
                fontWeight: FontWeight.w800,
                letterSpacing: 2.0,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                description,
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(
                  color: Colors.white70,
                  fontSize: 16,
                  height: 1.5,
                ),
              ),
            ),
            const Spacer(),
            Text(
              'TAP ANYWHERE TO CLOSE',
              style: GoogleFonts.outfit(
                color: Colors.white24,
                fontSize: 10,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ).animate().slideY(begin: 1.0, end: 0, curve: Curves.easeOutCubic),
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
              // Skip button: tap to reveal all remaining lines
              if (_isSpeaking)
                Center(
                  child: TextButton.icon(
                    onPressed: _skipCurrentLine,
                    icon: const Icon(
                      Icons.skip_next_rounded,
                      size: 16,
                      color: Colors.white70,
                    ),
                    label: Text(
                      'SKIP',
                      style: GoogleFonts.quicksand(
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        color: Colors.white70,
                        letterSpacing: 1.5,
                      ),
                    ),
                    style: TextButton.styleFrom(
                      backgroundColor: Colors.black45,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 8,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                  ).animate().fadeIn(duration: 300.ms),
                ),
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
      return Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 18),
        decoration: BoxDecoration(
          color: _videoBgReady
              ? Colors.black.withOpacity(0.3)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          border: isLatest && _videoBgReady
              ? Border.all(color: moodAccent.withOpacity(0.4), width: 1.5)
              : null,
        ),
        child: Text(
          event.text,
          textAlign: TextAlign.center,
          style: GoogleFonts.outfit(
            color: isLatest ? textColor : textColor.withOpacity(0.6),
            fontSize: isNarration ? 18 : 16,
            fontWeight: isLatest ? FontWeight.w700 : FontWeight.w600,
            fontStyle: isAmbience ? FontStyle.italic : FontStyle.normal,
            height: 1.6,
            shadows: [
              Shadow(
                color: Colors.black.withOpacity(0.8),
                blurRadius: 4,
                offset: const Offset(0, 1.5),
              ),
            ],
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
    final isDark =
        _currentScenario?.mood == 'dire' || _currentScenario?.mood == 'chaotic';
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child:
          ElevatedButton(
                onPressed: _isChoosing ? null : () => _makeChoice(choice),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black.withOpacity(0.4),
                  foregroundColor: AppTheme.forest,
                  padding: const EdgeInsets.all(24),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                    side: BorderSide(
                      color: AppTheme.moss.withOpacity(isDark ? 0.7 : 0.4),
                      width: 2,
                    ),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            choice.text,
                            style: GoogleFonts.outfit(
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              height: 1.3,
                              shadows: [
                                Shadow(color: Colors.black, blurRadius: 4),
                              ],
                            ),
                          ),
                        ),
                        if (choice.realWorldContext.isNotEmpty)
                          Tooltip(
                            message: choice.realWorldContext,
                            triggerMode: TooltipTriggerMode.tap,
                            margin: const EdgeInsets.symmetric(horizontal: 20),
                            padding: const EdgeInsets.all(16),
                            textStyle: GoogleFonts.outfit(
                              fontSize: 14,
                              color: Colors.white,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.9),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.white24),
                            ),
                            child: const Icon(
                              Icons.lightbulb_outline_rounded,
                              color: Colors.amberAccent,
                              size: 22,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        vertical: 10,
                        horizontal: 14,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.1),
                        ),
                      ),
                      child: Text(
                        choice.consequenceHint,
                        style: GoogleFonts.outfit(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: Colors.white70,
                          fontStyle: FontStyle.italic,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ).animate().fadeIn(delay: 600.ms),
                  ],
                ),
              )
              .animate()
              .fadeIn(delay: (index * 200).ms)
              .slideX(begin: 0.1, end: 0)
              .shimmer(
                delay: 1000.ms,
                duration: 1500.ms,
                color: AppTheme.moss.withOpacity(isDark ? 0.3 : 0.15),
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
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const SizedBox(height: 60),
          const Icon(
            Icons.auto_awesome_rounded,
            size: 80,
            color: AppTheme.sage,
          ),
          const SizedBox(height: 24),
          Text(
            'Destiny Forged',
            style: Theme.of(context).textTheme.displayLarge,
          ),
          const SizedBox(height: 40),
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.85),
              borderRadius: BorderRadius.circular(32),
              border: Border.all(
                color: AppTheme.sage.withOpacity(0.5),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.forest.withOpacity(0.05),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Text(
              scenario.characterReaction.isNotEmpty
                  ? scenario.characterReaction
                  : "The end.",
              textAlign: TextAlign.center,
              style: GoogleFonts.quicksand(
                color: AppTheme.forest,
                fontSize: 18,
                fontWeight: FontWeight.w700,
                height: 1.6,
              ),
            ),
          ).animate().fadeIn().slideY(begin: 0.1, end: 0),
          const SizedBox(height: 60),
          ElevatedButton(
            onPressed: () => Navigator.popUntil(context, (r) => r.isFirst),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 64),
            ),
            child: const Text('BACK TO HUB'),
          ).animate().fadeIn(delay: 1.seconds),
        ],
      ),
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
}
