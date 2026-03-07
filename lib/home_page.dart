import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'theme.dart';
class SdgData {
  final int id;
  final String name;
  final String shortDescription;
  final Color color;
  final IconData icon;
  const SdgData({
    required this.id,
    required this.name,
    required this.shortDescription,
    required this.color,
    required this.icon,
  });
}
const List<SdgData> kSdgs = [
  SdgData(
    id: 1,
    name: 'No Poverty',
    shortDescription:
        'End poverty in all its forms everywhere by ensuring social protection and basic resources for all.',
    color: Color(0xFFE5243B),
    icon: Icons.people_alt_rounded,
  ),
  SdgData(
    id: 2,
    name: 'Zero Hunger',
    shortDescription:
        'End hunger, achieve food security and improved nutrition, and promote sustainable agriculture.',
    color: Color(0xFFDDA63A),
    icon: Icons.grass_rounded,
  ),
  SdgData(
    id: 3,
    name: 'Good Health',
    shortDescription:
        'Ensure healthy lives and promote well-being for all at all ages.',
    color: Color(0xFF4C9F38),
    icon: Icons.favorite_rounded,
  ),
  SdgData(
    id: 4,
    name: 'Quality Education',
    shortDescription:
        'Ensure inclusive and equitable quality education and promote lifelong learning opportunities.',
    color: Color(0xFFC5192D),
    icon: Icons.school_rounded,
  ),
  SdgData(
    id: 5,
    name: 'Gender Equality',
    shortDescription:
        'Achieve gender equality and empower all women and girls.',
    color: Color(0xFFFF3A21),
    icon: Icons.balance_rounded,
  ),
  SdgData(
    id: 6,
    name: 'Clean Water',
    shortDescription:
        'Ensure availability and sustainable management of water and sanitation for all.',
    color: Color(0xFF26BDE2),
    icon: Icons.water_drop_rounded,
  ),
  SdgData(
    id: 7,
    name: 'Clean Energy',
    shortDescription:
        'Ensure access to affordable, reliable, sustainable and modern energy for all.',
    color: Color(0xFFFCC30B),
    icon: Icons.wb_sunny_rounded,
  ),
  SdgData(
    id: 8,
    name: 'Decent Work',
    shortDescription:
        'Promote sustained, inclusive and sustainable economic growth, full and productive employment.',
    color: Color(0xFFA21942),
    icon: Icons.work_rounded,
  ),
  SdgData(
    id: 9,
    name: 'Industry & Innovation',
    shortDescription:
        'Build resilient infrastructure, promote inclusive and sustainable industrialization.',
    color: Color(0xFFFF6925),
    icon: Icons.precision_manufacturing_rounded,
  ),
  SdgData(
    id: 10,
    name: 'Reduced Inequalities',
    shortDescription:
        'Reduce inequality within and among countries through inclusive policies.',
    color: Color(0xFFDD1367),
    icon: Icons.compare_arrows_rounded,
  ),
  SdgData(
    id: 11,
    name: 'Sustainable Cities',
    shortDescription:
        'Make cities and human settlements inclusive, safe, resilient and sustainable.',
    color: Color(0xFFFD9D24),
    icon: Icons.location_city_rounded,
  ),
  SdgData(
    id: 12,
    name: 'Responsible Consumption',
    shortDescription: 'Ensure sustainable consumption and production patterns.',
    color: Color(0xFFBF8B2E),
    icon: Icons.recycling_rounded,
  ),
  SdgData(
    id: 13,
    name: 'Climate Action',
    shortDescription:
        'Take urgent action to combat climate change and its impacts.',
    color: Color(0xFF3F7E44),
    icon: Icons.thermostat_rounded,
  ),
  SdgData(
    id: 14,
    name: 'Life Below Water',
    shortDescription:
        'Conserve and sustainably use the oceans, seas and marine resources.',
    color: Color(0xFF0A97D9),
    icon: Icons.waves_rounded,
  ),
  SdgData(
    id: 15,
    name: 'Life on Land',
    shortDescription:
        'Protect, restore and promote sustainable use of terrestrial ecosystems.',
    color: Color(0xFF56C02B),
    icon: Icons.park_rounded,
  ),
  SdgData(
    id: 16,
    name: 'Peace & Justice',
    shortDescription:
        'Promote peaceful and inclusive societies and build effective, accountable institutions.',
    color: Color(0xFF00689D),
    icon: Icons.gavel_rounded,
  ),
  SdgData(
    id: 17,
    name: 'Partnerships',
    shortDescription:
        'Strengthen the means of implementation and revitalize the global partnership for sustainable development.',
    color: Color(0xFF19486A),
    icon: Icons.handshake_rounded,
  ),
];
class Planet {
  final int id;
  final SdgData sdg;
  double radius;
  double theta;
  double phi;
  double depthOffset;
  double dTheta;
  double dPhi;
  double floatPhase;
  double floatAmplitude;
  bool isHighlighted = false;
  Planet({
    required this.id,
    required this.sdg,
    required this.radius,
    required this.theta,
    required this.phi,
    required this.depthOffset,
    required this.dTheta,
    required this.dPhi,
    required this.floatPhase,
    required this.floatAmplitude,
  });
  Offset project(
    double R,
    double rotX,
    double rotY,
    double time,
    Size canvasSize,
  ) {
    final floatDelta = math.sin(time * 0.8 + floatPhase) * floatAmplitude;
    final effTheta = theta + floatDelta * 0.015;
    final effPhi = phi + floatDelta * 0.01;
    double x = R * math.sin(effTheta) * math.cos(effPhi);
    double y = R * math.cos(effTheta);
    double z = R * math.sin(effTheta) * math.sin(effPhi);
    double cosY = math.cos(rotY), sinY = math.sin(rotY);
    double xR = x * cosY + z * sinY;
    double zR = -x * sinY + z * cosY;
    x = xR;
    z = zR;
    double cosX = math.cos(rotX), sinX = math.sin(rotX);
    double yR = y * cosX - z * sinX;
    double zR2 = y * sinX + z * cosX;
    y = yR;
    z = zR2;
    double fov = 600;
    double scale = fov / (fov + z + depthOffset);
    double screenX = canvasSize.width / 2 + x * scale;
    double screenY = canvasSize.height / 2 + y * scale;
    return Offset(screenX, screenY);
  }
  double depth(double R, double rotX, double rotY, double time) {
    final floatDelta = math.sin(time * 0.8 + floatPhase) * floatAmplitude;
    final effTheta = theta + floatDelta * 0.015;
    final effPhi = phi + floatDelta * 0.01;
    double x = R * math.sin(effTheta) * math.cos(effPhi);
    double y = R * math.cos(effTheta);
    double z = R * math.sin(effTheta) * math.sin(effPhi);
    double cosY = math.cos(rotY), sinY = math.sin(rotY);
    double xR = x * cosY + z * sinY;
    double zR = -x * sinY + z * cosY;
    x = xR;
    z = zR;
    double cosX = math.cos(rotX), sinX = math.sin(rotX);
    double zR2 = y * sinX + z * cosX;
    z = zR2;
    return z + depthOffset;
  }
}
class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}
class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  late AnimationController _universeCtrl;
  late AnimationController _starCtrl;
  double _rotX = 0.15;
  double _rotY = 0.0;
  double _lastRotX = 0.0;
  double _lastRotY = 0.0;
  double _zoom = 1.0;
  double _lastZoom = 1.0;
  final List<Planet> _planets = [];
  static const int kPlanetCount = 60;
  static const double kSphereRadius = 130.0;
  Planet? _tappedPlanet;
  final List<Offset> _stars = [];
  final List<double> _starSizes = [];
  final math.Random _rng = math.Random(42);
  @override
  void initState() {
    super.initState();
    _universeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 60),
    )..repeat();
    _starCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat(reverse: true);
    _initPlanets();
    _initStars();
  }
  void _initStars() {
    for (int i = 0; i < 200; i++) {
      _stars.add(Offset(_rng.nextDouble(), _rng.nextDouble()));
      _starSizes.add(_rng.nextDouble() * 2.2 + 0.3);
    }
  }
  void _initPlanets() {
    final goldenAngle = math.pi * (3 - math.sqrt(5));
    for (int i = 0; i < kPlanetCount; i++) {
      final sdg = kSdgs[i % kSdgs.length];
      final theta = math.acos(1 - 2 * (i + 0.5) / kPlanetCount);
      final phi = goldenAngle * i;
      final dPhi =
          (0.0015 + _rng.nextDouble() * 0.002) * (_rng.nextBool() ? 1 : -1);
      final dTheta =
          (0.0005 + _rng.nextDouble() * 0.001) * (_rng.nextBool() ? 1 : -1);
      final sizeVariation = 7.0 + _rng.nextDouble() * 6.0;
      _planets.add(
        Planet(
          id: i,
          sdg: sdg,
          radius: sizeVariation,
          theta: theta,
          phi: phi,
          depthOffset: (_rng.nextDouble() * 10 - 5),
          dTheta: dTheta,
          dPhi: dPhi,
          floatPhase: _rng.nextDouble() * math.pi * 2,
          floatAmplitude: 0.8 + _rng.nextDouble() * 1.2,
        ),
      );
    }
  }
  @override
  void dispose() {
    _universeCtrl.dispose();
    _starCtrl.dispose();
    super.dispose();
  }
  void _onPanStart(DragStartDetails d) {
    _lastRotX = _rotX;
    _lastRotY = _rotY;
  }
  void _onPanUpdate(DragUpdateDetails d) {
    setState(() {
      _rotY =
          _lastRotY +
          d.globalPosition.dx * 0.003 -
          d.localPosition.dx * 0.003 +
          d.delta.dx * 0.008;
      _rotX = (_lastRotX - d.delta.dy * 0.008).clamp(-math.pi / 2, math.pi / 2);
      _lastRotX = _rotX;
      _lastRotY = _rotY;
    });
  }
  void _onScaleStart(ScaleStartDetails d) {
    _lastZoom = _zoom;
  }
  void _onScaleUpdate(ScaleUpdateDetails d) {
    setState(() {
      _zoom = (_lastZoom * d.scale).clamp(0.5, 3.0);
      _rotY += d.focalPointDelta.dx * 0.005;
      _rotX = (_rotX - d.focalPointDelta.dy * 0.005).clamp(
        -math.pi / 2,
        math.pi / 2,
      );
    });
  }
  void _onTapUp(TapUpDetails details) {
    final t = _universeCtrl.value * 2 * math.pi;
    final size = context.size ?? const Size(400, 800);
    final effectiveR = kSphereRadius * _zoom;
    Planet? nearest;
    double minDist = 40.0;
    for (final p in _planets) {
      final pos = p.project(effectiveR, _rotX, _rotY, t, size);
      final dist = (pos - details.localPosition).distance;
      if (dist < minDist) {
        minDist = dist;
        nearest = p;
      }
    }
    if (nearest != null) {
      HapticFeedback.lightImpact();
      setState(() {
        _tappedPlanet = nearest;
      });
      _showSdgModal(nearest.sdg);
    }
  }
  void _showSdgModal(SdgData sdg) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _SdgBottomSheet(sdg: sdg),
    ).then((_) {
      setState(() {
        _tappedPlanet = null;
      });
    });
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF020B18),
      body: Stack(
        children: [
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _starCtrl,
              builder: (_, __) => CustomPaint(
                painter: _SpaceBackgroundPainter(
                  stars: _stars,
                  starSizes: _starSizes,
                  twinkle: _starCtrl.value,
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: GestureDetector(
              onScaleStart: _onScaleStart,
              onScaleUpdate: _onScaleUpdate,
              onTapUp: _onTapUp,
              child: AnimatedBuilder(
                animation: _universeCtrl,
                builder: (_, __) {
                  final t = _universeCtrl.value * 2 * math.pi;
                  for (final p in _planets) {
                    p.phi += p.dPhi * 0.016;
                    p.theta = (p.theta + p.dTheta * 0.016).clamp(
                      0.05,
                      math.pi - 0.05,
                    );
                  }
                  return CustomPaint(
                    painter: _UniversePainter(
                      planets: _planets,
                      time: t,
                      rotX: _rotX,
                      rotY: _rotY,
                      zoom: _zoom,
                      highlightedId: _tappedPlanet?.id,
                    ),
                    size: Size.infinite,
                  );
                },
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Row(
                children: [
                  Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'IQuest',
                            style: GoogleFonts.balsamiqSans(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.5,
                            ),
                          ),
                          Text(
                            'Living Universe',
                            style: GoogleFonts.quicksand(
                              color: AppTheme.moss.withOpacity(0.85),
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 2.5,
                            ),
                          ),
                        ],
                      )
                      .animate()
                      .fadeIn(duration: 1200.ms)
                      .slideX(begin: -0.1, end: 0),
                  const Spacer(),
                  Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: [AppTheme.moss, AppTheme.sage],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.2),
                            width: 1.5,
                          ),
                        ),
                        child: const Icon(
                          Icons.person_rounded,
                          color: Colors.white,
                          size: 22,
                        ),
                      )
                      .animate()
                      .fadeIn(duration: 1200.ms)
                      .slideX(begin: 0.1, end: 0),
                ],
              ),
            ),
          ),
          Align(
            alignment: const Alignment(0, -0.55),
            child: Text(
              '17 GOALS · 60 WORLDS',
              style: GoogleFonts.quicksand(
                color: Colors.white.withOpacity(0.25),
                fontSize: 10,
                fontWeight: FontWeight.w600,
                letterSpacing: 3.5,
              ),
            ),
          ),
          Align(
            alignment: const Alignment(0, 0.92),
            child: SafeArea(
              child: _ExploreButton(onTap: () => _showGoalsOverview(context)),
            ),
          ),
          Align(
            alignment: const Alignment(0, 0.75),
            child: Text(
              'Pinch to zoom · Drag to rotate · Tap a planet',
              style: GoogleFonts.quicksand(
                color: Colors.white.withOpacity(0.18),
                fontSize: 9.5,
                fontWeight: FontWeight.w600,
                letterSpacing: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
  void _showGoalsOverview(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => const _GoalsOverviewSheet(),
    );
  }
}
class _SpaceBackgroundPainter extends CustomPainter {
  final List<Offset> stars;
  final List<double> starSizes;
  final double twinkle;
  _SpaceBackgroundPainter({
    required this.stars,
    required this.starSizes,
    required this.twinkle,
  });
  @override
  void paint(Canvas canvas, Size size) {
    final bgPaint = Paint()
      ..shader = const RadialGradient(
        center: Alignment(0.1, -0.2),
        radius: 1.3,
        colors: [
          Color(0xFF1B3A3A),
          Color(0xFF1B2B38),
          Color(0xFF0D1820),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);
    final mossGlow = Paint()
      ..color = AppTheme.moss.withValues(alpha: 0.02)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 80);
    canvas.drawCircle(Offset(size.width * 0.2, size.height * 0.25), size.width * 0.55, mossGlow);
    final earthGlow = Paint()
      ..color = AppTheme.earth.withValues(alpha: 0.015)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 100);
    canvas.drawCircle(Offset(size.width * 0.8, size.height * 0.7), size.width * 0.5, earthGlow);
    const double minStarOpacity = 0.2;
    for (int i = 0; i < stars.length; i++) {
      final twinkleFactor = 0.5 + 0.5 * math.sin(twinkle * math.pi * 2 + i * 0.7);
      final opacity = twinkleFactor * 0.7;
      if (opacity < minStarOpacity) continue;
      final starSize = starSizes[i] * 0.5;
      final starPaint = Paint()
        ..color = Colors.white.withValues(alpha: opacity);
      canvas.drawCircle(
        Offset(stars[i].dx * size.width, stars[i].dy * size.height),
        starSize,
        starPaint,
      );
    }
  }
  @override
  bool shouldRepaint(_SpaceBackgroundPainter old) => old.twinkle != twinkle;
}
class _UniversePainter extends CustomPainter {
  final List<Planet> planets;
  final double time;
  final double rotX;
  final double rotY;
  final double zoom;
  final int? highlightedId;
  _UniversePainter({
    required this.planets,
    required this.time,
    required this.rotX,
    required this.rotY,
    required this.zoom,
    this.highlightedId,
  });
  @override
  void paint(Canvas canvas, Size size) {
    final effectiveR = _HomePageState.kSphereRadius * zoom;
    final List<(Planet, Offset, double)> projected = planets.map((p) {
      final pos = p.project(effectiveR, rotX, rotY, time, size);
      final d = p.depth(effectiveR, rotX, rotY, time);
      return (p, pos, d);
    }).toList();
    projected.sort((a, b) => a.$3.compareTo(b.$3));
    final Map<int, List<(Planet, Offset, double, double)>> bySdg = {};
    for (final entry in projected) {
      final planet = entry.$1;
      final pos = entry.$2;
      final d = entry.$3;
      final depthFactor = ((d + effectiveR) / (effectiveR * 2)).clamp(0.2, 1.0);
      final fov = 600.0;
      final perspScale = fov / (fov + d);
      final r = planet.radius * perspScale * zoom * depthFactor.clamp(0.5, 1.0);
      bySdg.putIfAbsent(planet.sdg.id, () => [])
          .add((planet, pos, d, r));
    }
    const double maxConnectionDist = 350.0;
    const double minConnectionDist = 50.0;
    for (final group in bySdg.values) {
      if (group.length < 2) continue;
      final sdgColor = group[0].$1.sdg.color;
      for (int i = 0; i < group.length; i++) {
        for (int j = i + 1; j < group.length; j++) {
          final p1 = group[i];
          final p2 = group[j];
          final dist = (p1.$2 - p2.$2).distance;
          if (dist < minConnectionDist || dist > maxConnectionDist) continue;
          final distanceFactor = (1 - (dist - minConnectionDist) / (maxConnectionDist - minConnectionDist))
              .clamp(0.0, 1.0);
          final avgDepth = (p1.$3 + p2.$3) / 2;
          final depthFactor = ((avgDepth + effectiveR) / (effectiveR * 2))
              .clamp(0.0, 1.0);
          final lineOpacity = (distanceFactor * 0.35 * depthFactor).clamp(0.0, 0.35);
          if (lineOpacity < 0.05) continue;
          final linePaint = Paint()
            ..color = sdgColor.withValues(alpha: lineOpacity)
            ..strokeWidth = 1.2;
          canvas.drawLine(p1.$2, p2.$2, linePaint);
        }
      }
    }
    final fov = 600.0;
    for (final (planet, pos, d) in projected) {
      final isHighlighted = planet.id == highlightedId;
      final depthFactor = ((d + effectiveR) / (effectiveR * 2)).clamp(0.2, 1.0);
      final perspScale = fov / (fov + d);
      final r = planet.radius * perspScale * zoom * depthFactor.clamp(0.5, 1.0);
      if (r < 1.5) continue;
      if (depthFactor > 0.25) {
        final glowOpacity = (0.15 * depthFactor).clamp(0.0, 1.0);
        final glowPaint = Paint()
          ..color = planet.sdg.color.withValues(alpha: glowOpacity)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, r * 1.2);
        canvas.drawCircle(pos, r * 1.8, glowPaint);
      }
      final highlightColor = Color.lerp(planet.sdg.color, Colors.white, 0.45)!;
      final darkColor = planet.sdg.color.darken(0.25);
      final gradPaint = Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.3, -0.4),
          radius: 0.8,
          colors: [
            highlightColor.withValues(alpha: depthFactor),
            planet.sdg.color.withValues(alpha: depthFactor * 0.9),
            darkColor.withValues(alpha: depthFactor * 0.8),
          ],
          stops: const [0.0, 0.5, 1.0],
        ).createShader(Rect.fromCircle(center: pos, radius: r));
      canvas.drawCircle(pos, r, gradPaint);
      if (r > 8) {
        final specOpacity = (0.35 * depthFactor).clamp(0.0, 1.0);
        final specPaint = Paint()
          ..color = Colors.white.withValues(alpha: specOpacity)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.5);
        canvas.drawCircle(
          pos + Offset(-r * 0.28, -r * 0.32),
          r * 0.25,
          specPaint,
        );
      }
      if (isHighlighted) {
        final pulsePaint = Paint()
          ..color = Colors.white.withValues(alpha: 0.5)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2;
        canvas.drawCircle(pos, r + 6, pulsePaint);
        final outerPulsePaint = Paint()
          ..color = planet.sdg.color.withValues(alpha: 0.35)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1;
        canvas.drawCircle(pos, r + 11, outerPulsePaint);
      }
      if (r > 11 && depthFactor > 0.45) {
        final label = '${planet.sdg.id}';
        final tp = TextPainter(
          text: TextSpan(
            text: label,
            style: GoogleFonts.quicksand(
              color: Colors.white.withValues(alpha: depthFactor * 0.95),
              fontSize: (r * 0.65).clamp(8, 13),
              fontWeight: FontWeight.w800,
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        tp.paint(canvas, pos - Offset(tp.width / 2, r + tp.height + 2));
      }
    }
    final coreGlowPaint = Paint()
      ..color = AppTheme.moss.withOpacity(0.06)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 60);
    canvas.drawCircle(
      Offset(size.width / 2, size.height / 2),
      effectiveR * 0.8,
      coreGlowPaint,
    );
  }
  @override
  bool shouldRepaint(_UniversePainter old) =>
      time != old.time ||
      rotX != old.rotX ||
      rotY != old.rotY ||
      zoom != old.zoom ||
      highlightedId != old.highlightedId;
}
extension _ColorX on Color {
  Color darken(double amount) {
    final hsl = HSLColor.fromColor(this);
    return hsl
        .withLightness((hsl.lightness - amount).clamp(0.0, 1.0))
        .toColor();
  }
}
class _ExploreButton extends StatelessWidget {
  final VoidCallback onTap;
  const _ExploreButton({required this.onTap});
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(40),
              gradient: LinearGradient(
                colors: [
                  AppTheme.moss.withOpacity(0.85),
                  const Color(0xFF26BDE2).withOpacity(0.75),
                ],
              ),
              border: Border.all(
                color: Colors.white.withOpacity(0.15),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.moss.withOpacity(0.35),
                  blurRadius: 20,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.explore_rounded,
                  color: Colors.white,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Text(
                  'EXPLORE GOALS',
                  style: GoogleFonts.quicksand(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 2,
                  ),
                ),
              ],
            ),
          ),
        )
        .animate(onPlay: (c) => c.repeat(reverse: true))
        .scale(
          begin: const Offset(1.0, 1.0),
          end: const Offset(1.03, 1.03),
          duration: 2800.ms,
          curve: Curves.easeInOutSine,
        )
        .animate()
        .fadeIn(duration: 1500.ms, delay: 800.ms)
        .slideY(begin: 0.2, end: 0, curve: Curves.easeOutCubic);
  }
}
class _SdgBottomSheet extends StatelessWidget {
  final SdgData sdg;
  const _SdgBottomSheet({required this.sdg});
  @override
  Widget build(BuildContext context) {
    return Container(
          margin: const EdgeInsets.fromLTRB(12, 0, 12, 16),
          decoration: BoxDecoration(
            color: const Color(0xFF0D1E2E),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: sdg.color.withOpacity(0.3), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: sdg.color.withOpacity(0.2),
                blurRadius: 30,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            color: sdg.color.withOpacity(0.15),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: sdg.color.withOpacity(0.5),
                              width: 2,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              '${sdg.id}',
                              style: GoogleFonts.balsamiqSans(
                                color: sdg.color,
                                fontSize: 22,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'SDG ${sdg.id}',
                                style: GoogleFonts.quicksand(
                                  color: sdg.color,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 2.5,
                                ),
                              ),
                              Text(
                                sdg.name,
                                style: GoogleFonts.balsamiqSans(
                                  color: Colors.white,
                                  fontSize: 22,
                                  fontWeight: FontWeight.w700,
                                  height: 1.1,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(sdg.icon, color: sdg.color, size: 28),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Container(
                      height: 1,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.transparent,
                            sdg.color.withOpacity(0.4),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      sdg.shortDescription,
                      style: GoogleFonts.quicksand(
                        color: Colors.white.withOpacity(0.75),
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        height: 1.65,
                      ),
                    ),
                    const SizedBox(height: 28),
                    Row(
                      children: [
                        Expanded(
                          child: _ModalButton(
                            label: 'LEARN MORE',
                            color: sdg.color,
                            icon: Icons.open_in_new_rounded,
                            filled: true,
                            onTap: () {},
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _ModalButton(
                            label: 'TAKE ACTION',
                            color: sdg.color,
                            icon: Icons.bolt_rounded,
                            filled: false,
                            onTap: () {},
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        )
        .animate()
        .slideY(
          begin: 0.3,
          end: 0,
          duration: 400.ms,
          curve: Curves.easeOutCubic,
        )
        .fadeIn(duration: 300.ms);
  }
}
class _ModalButton extends StatelessWidget {
  final String label;
  final Color color;
  final IconData icon;
  final bool filled;
  final VoidCallback onTap;
  const _ModalButton({
    required this.label,
    required this.color,
    required this.icon,
    required this.filled,
    required this.onTap,
  });
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: filled ? color.withOpacity(0.9) : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.5), width: 1.5),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: filled ? Colors.white : color, size: 16),
            const SizedBox(width: 6),
            Text(
              label,
              style: GoogleFonts.quicksand(
                color: filled ? Colors.white : color,
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
class _GoalsOverviewSheet extends StatelessWidget {
  const _GoalsOverviewSheet();
  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.72,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      builder: (_, controller) => Container(
        decoration: const BoxDecoration(
          color: Color(0xFF0D1E2E),
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 4),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 8),
              child: Row(
                children: [
                  Text(
                    '17 Global Goals',
                    style: GoogleFonts.balsamiqSans(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    'UN SDGs',
                    style: GoogleFonts.quicksand(
                      color: AppTheme.moss,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 2,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.separated(
                controller: controller,
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                itemCount: kSdgs.length,
                separatorBuilder: (_, __) => const SizedBox(height: 6),
                itemBuilder: (_, i) {
                  final sdg = kSdgs[i];
                  return _SdgListTile(sdg: sdg)
                      .animate()
                      .fadeIn(delay: (i * 40).ms)
                      .slideX(begin: 0.05, end: 0);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
class _SdgListTile extends StatelessWidget {
  final SdgData sdg;
  const _SdgListTile({required this.sdg});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: sdg.color.withOpacity(0.07),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: sdg.color.withOpacity(0.2), width: 1),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: sdg.color.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '${sdg.id}',
                style: GoogleFonts.balsamiqSans(
                  color: sdg.color,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  sdg.name,
                  style: GoogleFonts.quicksand(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  sdg.shortDescription,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.quicksand(
                    color: Colors.white.withOpacity(0.5),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Icon(sdg.icon, color: sdg.color, size: 20),
        ],
      ),
    );
  }
}
