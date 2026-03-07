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
      body: Stack(
        children: [
          // Background Image
          Positioned.fill(
            child: Image.asset('assets/char.jpg', fit: BoxFit.cover),
          ),
          // Blur Effect
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
              child: Container(color: Colors.black.withOpacity(0.35)),
            ),
          ),
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24.0,
                    vertical: 20.0,
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(
                          Icons.arrow_back_ios_new_rounded,
                          color: Colors.white,
                        ),
                        onPressed: () => Navigator.pop(context),
                      ),
                      Expanded(
                        child: Text(
                          'SELECT ARCHETYPE',
                          style: GoogleFonts.quicksand(
                            color: Colors.white.withOpacity(0.8),
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.2,
                            fontSize: 12,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.2),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.bolt_rounded,
                              color: _realismMode
                                  ? AppTheme.earth
                                  : AppTheme.sage,
                              size: 14,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'REALISM',
                              style: GoogleFonts.quicksand(
                                fontWeight: FontWeight.w800,
                                fontSize: 9,
                                color: Colors.white,
                                letterSpacing: 0.5,
                              ),
                            ),
                            Transform.scale(
                              scale: 0.7,
                              child: Switch(
                                value: _realismMode,
                                activeColor: AppTheme.earth,
                                materialTapTargetSize:
                                    MaterialTapTargetSize.shrinkWrap,
                                onChanged: (val) {
                                  setState(() {
                                    _realismMode = val;
                                  });
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
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

                      return AnimatedContainer(
                        duration: 400.ms,
                        curve: Curves.easeOutCubic,
                        margin: EdgeInsets.only(
                          top: isSelected ? 0 : 40,
                          bottom: isSelected ? 0 : 40,
                          left: 10,
                          right: 10,
                        ),
                        child: SingleChildScrollView(
                          clipBehavior: Clip.none,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              // Character Name (Top)
                              if (isSelected)
                                Transform.translate(
                                  offset: Offset(depthOffset * -40, 0),
                                  child:
                                      Text(
                                            character.name,
                                            textAlign: TextAlign.center,
                                            style: GoogleFonts.outfit(
                                              color: Colors.white,
                                              fontSize: 38,
                                              fontWeight: FontWeight.w900,
                                              height: 1.1,
                                              letterSpacing: -1,
                                            ),
                                          )
                                          .animate()
                                          .fadeIn(duration: 400.ms)
                                          .slideY(begin: 0.2, end: 0),
                                )
                              else
                                const SizedBox(height: 42),

                              const SizedBox(height: 32),

                              // Avatar + Aura effect
                              SizedBox(
                                height: 280,
                                child: Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    // Pulsing ambient aura
                                    if (isSelected)
                                      AnimatedBuilder(
                                        animation: _breathingController,
                                        builder: (context, child) {
                                          return Transform.scale(
                                            scale:
                                                1.0 +
                                                (_breathingController.value *
                                                    0.15),
                                            child: Container(
                                              width: 240,
                                              height: 240,
                                              decoration: BoxDecoration(
                                                shape: BoxShape.circle,
                                                gradient: RadialGradient(
                                                  colors: [
                                                    AppTheme.sage.withOpacity(
                                                      0.3,
                                                    ),
                                                    AppTheme.moss.withOpacity(
                                                      0.05,
                                                    ),
                                                    Colors.transparent,
                                                  ],
                                                  stops: const [0.3, 0.7, 1.0],
                                                ),
                                              ),
                                            ),
                                          );
                                        },
                                      ),

                                    // Main Circular Profile
                                    Transform.translate(
                                      offset: Offset(depthOffset * 60, 0),
                                      child: AnimatedScale(
                                        duration: 600.ms,
                                        scale: isSelected ? 1.0 : 0.85,
                                        curve: Curves.easeOutBack,
                                        child: AnimatedContainer(
                                          duration: 400.ms,
                                          width: 240,
                                          height: 320,
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(
                                              36,
                                            ),
                                            color: Colors.white,
                                            border: Border.all(
                                              color: isSelected
                                                  ? Colors.white
                                                  : Colors.white.withOpacity(
                                                      0.4,
                                                    ),
                                              width: isSelected ? 4 : 2,
                                            ),
                                            boxShadow: isSelected
                                                ? [
                                                    BoxShadow(
                                                      color: Colors.black
                                                          .withOpacity(0.3),
                                                      blurRadius: 30,
                                                      offset: const Offset(
                                                        0,
                                                        15,
                                                      ),
                                                    ),
                                                  ]
                                                : [],
                                          ),
                                          child: ClipRRect(
                                            borderRadius: BorderRadius.circular(
                                              32,
                                            ),
                                            child: ColorFiltered(
                                              colorFilter: ColorFilter.mode(
                                                Colors.black.withOpacity(
                                                  isSelected ? 0 : 0.5,
                                                ), // Grayscale effect when not selected
                                                BlendMode.saturation,
                                              ),
                                              child: Image.network(
                                                'https://id.gogram.fun${character.avatarUrl}',
                                                fit: BoxFit.cover,
                                                errorBuilder:
                                                    (
                                                      context,
                                                      error,
                                                      stackTrace,
                                                    ) => Container(
                                                      color: AppTheme.sage
                                                          .withOpacity(0.2),
                                                      child: const Icon(
                                                        Icons.person,
                                                        size: 80,
                                                        color: AppTheme.forest,
                                                      ),
                                                    ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),

                                    // Slick archetypes badge overlapping bottom
                                    if (isSelected)
                                      Positioned(
                                        bottom: 0,
                                        child: Transform.translate(
                                          offset: Offset(depthOffset * 100, 0),
                                          child:
                                              Container(
                                                    padding:
                                                        const EdgeInsets.symmetric(
                                                          horizontal: 20,
                                                          vertical: 8,
                                                        ),
                                                    decoration: BoxDecoration(
                                                      gradient:
                                                          const LinearGradient(
                                                            colors: [
                                                              AppTheme.earth,
                                                              Color(0xFFE67E22),
                                                            ],
                                                          ),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            24,
                                                          ),
                                                      boxShadow: [
                                                        BoxShadow(
                                                          color: AppTheme.earth
                                                              .withOpacity(0.4),
                                                          blurRadius: 12,
                                                          offset: const Offset(
                                                            0,
                                                            4,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                    child: Text(
                                                      character.tagline
                                                          .toUpperCase(),
                                                      style:
                                                          GoogleFonts.quicksand(
                                                            color: Colors.white,
                                                            fontWeight:
                                                                FontWeight.w900,
                                                            fontSize: 12,
                                                            letterSpacing: 2,
                                                          ),
                                                    ),
                                                  )
                                                  .animate()
                                                  .fadeIn(delay: 200.ms)
                                                  .slideY(begin: 0.5, end: 0),
                                        ),
                                      ),
                                  ],
                                ),
                              ),

                              const SizedBox(height: 16),

                              // Description
                              if (isSelected)
                                Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 18,
                                        vertical: 12,
                                      ),
                                      constraints: const BoxConstraints(
                                        maxWidth: 320,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.black.withOpacity(0.35),
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(
                                          color: Colors.white.withOpacity(0.2),
                                          width: 1.5,
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withOpacity(
                                              0.1,
                                            ),
                                            blurRadius: 16,
                                            offset: const Offset(0, 8),
                                          ),
                                        ],
                                      ),
                                      child: Text(
                                        character.description,
                                        textAlign: TextAlign.center,
                                        style: GoogleFonts.inter(
                                          color: Colors.white.withOpacity(0.9),
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          height: 1.4,
                                        ),
                                      ),
                                    )
                                    .animate()
                                    .fadeIn(duration: 400.ms)
                                    .slideY(begin: 0.1, end: 0)
                              else
                                const SizedBox(height: 120),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),

                // Action Button
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 40.0,
                    vertical: 16,
                  ),
                  child:
                      ElevatedButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => StoryPage(
                                    gameId: widget.gameId,
                                    character:
                                        widget.characters[_selectedIndex],
                                    realismMode: _realismMode,
                                  ),
                                ),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: AppTheme.forest,
                              minimumSize: const Size(double.infinity, 64),
                              elevation: 10,
                              shadowColor: Colors.black.withOpacity(0.3),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(32),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'EMBRACE DESTINY',
                                  style: GoogleFonts.quicksand(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 2,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                const Icon(
                                  Icons.arrow_forward_rounded,
                                  size: 20,
                                ),
                              ],
                            ),
                          )
                          .animate(onPlay: (c) => c.repeat(reverse: true))
                          .shimmer(color: Colors.black12, duration: 2.seconds)
                          .then(delay: 1.seconds),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
