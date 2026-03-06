import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'theme.dart';
import 'sign_in_page.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.stone,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'IQUEST / HQ',
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
            color: AppTheme.forest,
            letterSpacing: 3.0,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.exit_to_app_rounded, color: AppTheme.forest),
            onPressed: () {
              Navigator.pushReplacement(
                context,
                PageRouteBuilder(
                  pageBuilder: (context, a, b) => const SignInPage(),
                  transitionsBuilder: (context, a, b, child) =>
                      FadeTransition(opacity: a, child: child),
                  transitionDuration: const Duration(milliseconds: 1000),
                ),
              );
            },
          ),
        ],
      ),
      body: OrganicBackground(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildPlayerProfile(context),

              const SizedBox(height: 24),

              _buildQuickStats(context),

              const SizedBox(height: 40),

              _buildDailyChallenge(context),

              const SizedBox(height: 40),

              _buildBadges(context),

              const SizedBox(height: 40),

              Text(
                    'Active Quests.',
                    style: Theme.of(context).textTheme.displayMedium,
                  )
                  .animate()
                  .fadeIn(duration: 1200.ms)
                  .slideY(begin: 0.1, end: 0, curve: Curves.easeOutCubic),

              const SizedBox(height: 16),

              Text(
                    'Dive into interactive scenarios. Your choices impact the ecosystem. Earn insight points by solving real-world challenges.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  )
                  .animate()
                  .fadeIn(duration: 1200.ms, delay: 200.ms)
                  .slideY(begin: 0.1, end: 0, curve: Curves.easeOutCubic),

              const SizedBox(height: 24),

              ..._buildMissions(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlayerProfile(BuildContext context) {
    return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppTheme.forest,
            borderRadius: BorderRadius.circular(32),
          ),
          child: Row(
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: AppTheme.stone.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.person_3_outlined,
                  color: AppTheme.stone,
                  size: 36,
                ),
              ),
              const SizedBox(width: 24),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Novice Steward',
                      style: Theme.of(
                        context,
                      ).textTheme.labelLarge?.copyWith(color: AppTheme.sage),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Level 2',
                      style: Theme.of(
                        context,
                      ).textTheme.titleLarge?.copyWith(color: AppTheme.stone),
                    ),
                    const SizedBox(height: 12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: 0.65,
                        minHeight: 8,
                        backgroundColor: AppTheme.stone.withOpacity(0.2),
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          AppTheme.sage,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '650 / 1000 XP to next rank',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.stone.withOpacity(0.7),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        )
        .animate()
        .fadeIn(duration: 1000.ms)
        .slideY(begin: -0.1, end: 0, curve: Curves.easeOutCubic);
  }

  Widget _buildQuickStats(BuildContext context) {
    return Row(
          children: [
            Expanded(
              child: _buildStatItem(
                context,
                '🔥 Streak',
                '4 Days',
                AppTheme.earth,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildStatItem(
                context,
                '🌍 Impact',
                'Top 15%',
                AppTheme.moss,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildStatItem(
                context,
                '🛡️ Guild',
                'Alpha',
                AppTheme.forest,
              ),
            ),
          ],
        )
        .animate()
        .fadeIn(duration: 1200.ms, delay: 200.ms)
        .slideY(begin: 0.1, end: 0, curve: Curves.easeOutCubic);
  }

  Widget _buildStatItem(
    BuildContext context,
    String label,
    String value,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.labelLarge?.copyWith(color: color, fontSize: 10),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: AppTheme.forest,
              fontSize: 16,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildDailyChallenge(BuildContext context) {
    return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppTheme.sage.withOpacity(0.3),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppTheme.sage, width: 2),
          ),
          child: Row(
            children: [
              Container(
                    padding: const EdgeInsets.all(12),
                    decoration: const BoxDecoration(
                      color: AppTheme.sage,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.timer_outlined,
                      color: AppTheme.forest,
                      size: 28,
                    ),
                  )
                  .animate(onPlay: (c) => c.repeat(reverse: true))
                  .scale(
                    begin: const Offset(1, 1),
                    end: const Offset(1.1, 1.1),
                    duration: 2.seconds,
                  ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'DAILY CHALLENGE',
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: AppTheme.forest,
                        fontSize: 10,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Sort the recycling plant before sundown.',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: AppTheme.forest,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              IconButton(
                onPressed: () {},
                style: IconButton.styleFrom(
                  backgroundColor: AppTheme.forest,
                  foregroundColor: AppTheme.stone,
                ),
                icon: const Icon(Icons.play_arrow_rounded),
              ),
            ],
          ),
        )
        .animate()
        .fadeIn(duration: 1200.ms, delay: 400.ms)
        .slideX(begin: 0.1, end: 0, curve: Curves.easeOutCubic);
  }

  Widget _buildBadges(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Your Achievements',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontSize: 20),
            ),
            TextButton(onPressed: () {}, child: const Text('VIEW ALL')),
          ],
        ).animate().fadeIn(duration: 1200.ms, delay: 500.ms),
        const SizedBox(height: 16),
        SizedBox(
              height: 100,
              child: ListView(
                scrollDirection: Axis.horizontal,
                clipBehavior: Clip.none,
                children: [
                  _buildBadgeItem(
                    context,
                    Icons.water_drop,
                    'Water\nSaver',
                    AppTheme.moss,
                    true,
                  ),
                  _buildBadgeItem(
                    context,
                    Icons.energy_savings_leaf,
                    'Energy\nHero',
                    AppTheme.earth,
                    true,
                  ),
                  _buildBadgeItem(
                    context,
                    Icons.people_alt,
                    'Community\nPillar',
                    AppTheme.sage,
                    true,
                  ),
                  _buildBadgeItem(
                    context,
                    Icons.emoji_nature,
                    'Nature\nGuardian',
                    AppTheme.forest.withOpacity(0.3),
                    false,
                  ),
                ],
              ),
            )
            .animate()
            .fadeIn(duration: 1200.ms, delay: 600.ms)
            .slideX(begin: 0.1, end: 0, curve: Curves.easeOutCubic),
      ],
    );
  }

  Widget _buildBadgeItem(
    BuildContext context,
    IconData icon,
    String label,
    Color color,
    bool unlocked,
  ) {
    return Container(
      width: 80,
      margin: const EdgeInsets.only(right: 16),
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: unlocked ? color.withOpacity(0.2) : Colors.transparent,
              shape: BoxShape.circle,
              border: Border.all(
                color: unlocked ? color : AppTheme.forest.withOpacity(0.2),
                width: 2,
                style: unlocked ? BorderStyle.solid : BorderStyle.solid,
              ),
            ),
            child: Icon(
              icon,
              color: unlocked ? color : AppTheme.forest.withOpacity(0.2),
              size: 28,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: AppTheme.forest.withOpacity(unlocked ? 0.9 : 0.4),
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildMissions(BuildContext context) {
    final missions = [
      {
        'title': 'The Drying\nRiver.',
        'tag': 'MISSION 1 • WATER CRISIS',
        'color': AppTheme.earth,
        'icon': Icons.water_drop_rounded,
        'difficulty': 'EASY',
        'desc':
            'A local village’s primary water source is drying up. Talk to the elders, manage resources, and build a sustainable irrigation system before the dry season peaks.',
        'reward': '+300 XP',
      },
      {
        'title': 'Concrete\nJungle.',
        'tag': 'MISSION 2 • URBAN PLANNING',
        'color': AppTheme.moss,
        'icon': Icons.location_city_rounded,
        'difficulty': 'MEDIUM',
        'desc':
            'The mayor wants to bulldoze the community park for a mall. Gather signatures, propose a green urban design, and sway the city council vote.',
        'reward': '+500 XP',
      },
      {
        'title': 'Silent\nForest.',
        'tag': 'MISSION 3 • BIODIVERSITY',
        'color': AppTheme.forest,
        'icon': Icons.park_outlined,
        'difficulty': 'HARD',
        'desc':
            'An endangered bird species has stopped singing. Investigate the illegal logging camp, collect photographic evidence, and rally local defenders.',
        'reward': '+800 XP',
      },
      {
        'title': 'The Food\nDesert.',
        'tag': 'MISSION 4 • ZERO HUNGER',
        'color': AppTheme.sage,
        'icon': Icons.eco_rounded,
        'difficulty': 'MEDIUM',
        'desc':
            'Corner stores only sell junk food. Partner with local farmers, set up a community garden, and manage the logistics of an organic co-op.',
        'reward': '+400 XP',
      },
    ];

    int delay = 600;
    return missions.map((m) {
      delay += 200;
      return Padding(
        padding: const EdgeInsets.only(bottom: 24.0),
        child:
            _MissionCard(
                  title: m['title'] as String,
                  tag: m['tag'] as String,
                  tagColor: m['color'] as Color,
                  icon: m['icon'] as IconData,
                  difficulty: m['difficulty'] as String,
                  description: m['desc'] as String,
                  reward: m['reward'] as String,
                )
                .animate()
                .fadeIn(duration: 1200.ms, delay: delay.ms)
                .slideY(begin: 0.1, end: 0, curve: Curves.easeOutCubic),
      );
    }).toList();
  }
}

class _MissionCard extends StatelessWidget {
  final String title;
  final String tag;
  final Color tagColor;
  final IconData icon;
  final String description;
  final String difficulty;
  final String reward;

  const _MissionCard({
    required this.title,
    required this.tag,
    required this.tagColor,
    required this.icon,
    required this.description,
    required this.difficulty,
    required this.reward,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppTheme.stone,
        border: Border.all(
          color: AppTheme.forest.withOpacity(0.15),
          width: 1.5,
        ),
        borderRadius: BorderRadius.circular(32),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          // Background shape
          Positioned(
            right: -20,
            top: -20,
            child: Icon(icon, size: 140, color: tagColor.withOpacity(0.06)),
          ),

          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: tagColor.withOpacity(0.1),
                  borderRadius: const BorderRadius.only(
                    bottomRight: Radius.circular(32),
                  ),
                ),
                child: Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    Icon(icon, size: 16, color: tagColor),
                    Text(
                      tag,
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: tagColor,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            style: Theme.of(context).textTheme.displayMedium
                                ?.copyWith(color: AppTheme.forest, height: 1.1),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: AppTheme.forest.withOpacity(0.2),
                            ),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(
                            difficulty,
                            style: Theme.of(context).textTheme.labelLarge
                                ?.copyWith(
                                  color: AppTheme.forest.withOpacity(0.6),
                                  fontSize: 10,
                                ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      description,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: AppTheme.forest.withOpacity(0.8),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Wrap(
                      alignment: WrapAlignment.spaceBetween,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 16,
                      runSpacing: 16,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.stone,
                            border: Border.all(
                              color: AppTheme.forest.withOpacity(0.1),
                            ),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.forest.withOpacity(0.05),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Text(
                            '✨ $reward',
                            style: Theme.of(context).textTheme.labelLarge
                                ?.copyWith(color: AppTheme.forest),
                          ),
                        ),
                        ElevatedButton(
                              onPressed: () {
                                // Navigate to game engine
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: tagColor,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                  horizontal: 24,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(24),
                                ),
                              ),
                              child: const Text('ENGAGE'),
                            )
                            .animate(
                              onPlay: (controller) =>
                                  controller.repeat(reverse: true),
                            )
                            .scale(
                              begin: const Offset(1, 1),
                              end: const Offset(1.05, 1.05),
                              duration: 1500.ms,
                              curve: Curves.easeInOut,
                            ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
