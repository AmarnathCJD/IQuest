import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'theme.dart';
import 'models/game_model.dart';
import 'story_page.dart';

class CharacterSelectionPage extends StatefulWidget {
  final String gameId;
  final List<GameCharacter> characters;

  const CharacterSelectionPage({
    super.key,
    required this.gameId,
    required this.characters,
  });

  @override
  State<CharacterSelectionPage> createState() => _CharacterSelectionPageState();
}

class _CharacterSelectionPageState extends State<CharacterSelectionPage>
    with SingleTickerProviderStateMixin {
  int _selectedIndex = 0;
  bool _realismMode = false;
  double _pageOffset = 0;
  final PageController _pageController = PageController(viewportFraction: 0.85);
  late AnimationController _breathingController;

  @override
  void initState() {
    super.initState();
    _pageController.addListener(() {
      if (mounted) {
        setState(() {
          _pageOffset = _pageController.page ?? 0;
        });
      }
    });
    _breathingController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pageController.dispose();
    _breathingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // 1. Dynamic Immersive Background
          Positioned.fill(
            child: AnimatedSwitcher(
              duration: 1200.ms,
              switchInCurve: Curves.easeIn,
              switchOutCurve: Curves.easeOut,
              child: Image.network(
                'https://id.gogram.fun${widget.characters[_selectedIndex].avatarUrl}',
                key: ValueKey(_selectedIndex),
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) =>
                    Image.asset('assets/char.jpg', fit: BoxFit.cover),
              ),
            ),
          ),

          // 2. Cinematic Overlays & Glows
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.7),
                    Colors.black.withOpacity(0.1),
                    Colors.black.withOpacity(0.95),
                  ],
                  stops: const [0.0, 0.45, 0.95],
                ),
              ),
            ),
          ),

          // Side ambient glow
          Positioned(
            right: -150,
            bottom: 100,
            child:
                Container(
                      width: 400,
                      height: 400,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppTheme.earth.withOpacity(0.1),
                      ),
                    )
                    .animate(onPlay: (c) => c.repeat(reverse: true))
                    .scale(
                      begin: const Offset(1, 1),
                      end: const Offset(1.3, 1.3),
                      duration: 5.seconds,
                    )
                    .blur(
                      begin: const Offset(60, 60),
                      end: const Offset(100, 100),
                    ),
          ),

          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildHeader(),

                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    physics: const BouncingScrollPhysics(),
                    onPageChanged: (index) {
                      setState(() => _selectedIndex = index);
                    },
                    itemCount: widget.characters.length,
                    itemBuilder: (context, index) {
                      final character = widget.characters[index];
                      final isSelected = _selectedIndex == index;
                      final depthOffset = (index - _pageOffset);

                      return _buildCharacterSlide(
                        character,
                        isSelected,
                        depthOffset,
                      );
                    },
                  ),
                ),

                _buildActionButton(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(
              Icons.arrow_back_ios_new_rounded,
              color: Colors.white,
            ),
            onPressed: () => Navigator.pop(context),
          ).animate().fadeIn().scale(),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'SELECT ARCHETYPE',
                  style: GoogleFonts.outfit(
                    color: Colors.white70,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 4,
                    fontSize: 12,
                  ),
                ),
                Text(
                  'WHO WILL YOU BE?',
                  style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1,
                    fontSize: 10,
                  ),
                ),
              ],
            ).animate().fadeIn(delay: 200.ms).slideX(begin: -0.2, end: 0),
          ),
          _buildRealismToggle(),
        ],
      ),
    );
  }

  Widget _buildRealismToggle() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.bolt_rounded,
            color: _realismMode ? AppTheme.earth : AppTheme.sage,
            size: 16,
          ),
          const SizedBox(width: 8),
          Text(
            'REALISM',
            style: GoogleFonts.quicksand(
              fontWeight: FontWeight.w800,
              fontSize: 10,
              color: Colors.white,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(width: 4),
          Transform.scale(
            scale: 0.8,
            child: Switch(
              value: _realismMode,
              activeColor: AppTheme.earth,
              onChanged: (val) => setState(() => _realismMode = val),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCharacterSlide(
    GameCharacter character,
    bool isSelected,
    double depthOffset,
  ) {
    return AnimatedContainer(
      duration: 600.ms,
      curve: Curves.easeOutCubic,
      margin: EdgeInsets.only(
        top: isSelected ? 20 : 60,
        bottom: isSelected ? 40 : 80,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // 1. Large immersive portrait
          Expanded(
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Glowing Aura for selected
                if (isSelected)
                  Container(
                        width: 280,
                        height: 450,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(40),
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.earth.withOpacity(0.3),
                              blurRadius: 40,
                              spreadRadius: 5,
                            ),
                          ],
                        ),
                      )
                      .animate(onPlay: (c) => c.repeat(reverse: true))
                      .scale(
                        begin: const Offset(1, 1),
                        end: const Offset(1.05, 1.05),
                        duration: 3.seconds,
                      ),

                // Main Image Container - No width limit (expanded width)
                Transform.translate(
                  offset: Offset(depthOffset * 100, 0),
                  child: AnimatedContainer(
                    duration: 500.ms,
                    width: isSelected ? 300 : 220,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(40),
                      border: Border.all(
                        color: isSelected ? Colors.white : Colors.white24,
                        width: isSelected ? 2 : 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.5),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(38),
                      child: Image.network(
                        'https://id.gogram.fun${character.avatarUrl}',
                        fit: BoxFit.cover,
                        alignment: const Alignment(
                          0,
                          -0.7,
                        ), // Focus slightly above center to capture the head
                        height: double.infinity,
                      ),
                    ),
                  ),
                ),

                // Tagline Badge overlap
                if (isSelected)
                  Positioned(
                    bottom: 20,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.earth,
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black45,
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Text(
                        character.tagline.toUpperCase(),
                        style: GoogleFonts.outfit(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 12,
                          letterSpacing: 2,
                        ),
                      ),
                    ).animate().fadeIn().slideY(begin: 0.5, end: 0),
                  ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // 2. Info Section
          if (isSelected)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  Text(
                    character.name.toUpperCase(),
                    style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontSize: 42,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -1,
                      height: 1,
                    ),
                  ).animate().fadeIn().slideY(begin: 0.2, end: 0),
                  const SizedBox(height: 12),
                  Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: Colors.white10),
                        ),
                        child: Text(
                          character.description,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.quicksand(
                            color: Colors.white70,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            height: 1.5,
                          ),
                        ),
                      )
                      .animate()
                      .fadeIn(delay: 200.ms)
                      .scale(
                        begin: const Offset(0.95, 0.95),
                        end: const Offset(1, 1),
                      ),
                ],
              ),
            )
          else
            const SizedBox(height: 120),
        ],
      ),
    );
  }

  Widget _buildActionButton() {
    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        children: [
          Container(
                height: 64,
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(32),
                  gradient: const LinearGradient(
                    colors: [AppTheme.earth, Color(0xFFD35400)],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.earth.withOpacity(0.4),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(32),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => StoryPage(
                            gameId: widget.gameId,
                            character: widget.characters[_selectedIndex],
                            realismMode: _realismMode,
                          ),
                        ),
                      );
                    },
                    child: Center(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'EMBRACE DESTINY',
                            style: GoogleFonts.outfit(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 2,
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Icon(
                            Icons.auto_awesome,
                            color: Colors.white,
                            size: 20,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              )
              .animate(onPlay: (c) => c.repeat(reverse: true))
              .shimmer(color: Colors.white24, duration: 2.seconds),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
