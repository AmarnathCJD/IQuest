import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
class AppTheme {
  static const Color stone = Color(0xFFF9F6EE);
  static const Color forest = Color(
    0xFF1B2B38,
  );
  static const Color moss = Color(0xFF00C482);
  static const Color earth = Color(0xFFFF6D37);
  static const Color sage = Color(0xFFFFD166);
  static ThemeData get lightTheme {
    return ThemeData(
      scaffoldBackgroundColor: stone,
      primaryColor: forest,
      colorScheme: const ColorScheme.light(
        primary: forest,
        secondary: moss,
        surface: stone,
        error: earth,
        onPrimary: stone,
        onSecondary: stone,
        onSurface: forest,
      ),
      textTheme: TextTheme(
        displayLarge: GoogleFonts.balsamiqSans(
          color: forest,
          fontSize: 56,
          fontWeight: FontWeight.w700,
          height: 1.05,
        ),
        displayMedium: GoogleFonts.balsamiqSans(
          color: forest,
          fontSize: 38,
          fontWeight: FontWeight.w700,
          height: 1.15,
        ),
        titleLarge: GoogleFonts.quicksand(
          color: forest,
          fontSize: 26,
          fontWeight: FontWeight.w800,
        ),
        bodyLarge: GoogleFonts.quicksand(
          color: forest,
          fontSize: 18,
          height: 1.6,
          fontWeight: FontWeight.w700,
        ),
        bodyMedium: GoogleFonts.quicksand(
          color: forest.withOpacity(0.8),
          fontSize: 16,
          height: 1.5,
          fontWeight: FontWeight.w600,
        ),
        labelLarge: GoogleFonts.quicksand(
          color: stone,
          fontSize: 14,
          fontWeight: FontWeight.w800,
          letterSpacing: 2.0,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.transparent,
        contentPadding: const EdgeInsets.symmetric(horizontal: 0, vertical: 16),
        enabledBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: forest.withOpacity(0.2), width: 1.0),
        ),
        focusedBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: forest, width: 2.0),
        ),
        labelStyle: GoogleFonts.quicksand(
          color: forest.withOpacity(0.6),
          fontSize: 15,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.0,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: forest,
          foregroundColor: stone,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 32),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(40),
          ),
          textStyle: GoogleFonts.quicksand(
            fontSize: 15,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.5,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: moss,
          textStyle: GoogleFonts.quicksand(
            fontSize: 14,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.0,
          ),
        ),
      ),
    );
  }
}
class OrganicBackground extends StatelessWidget {
  final Widget child;
  const OrganicBackground({super.key, required this.child});
  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(child: CustomPaint(painter: _TopographicPainter())),
        const Positioned(
          top: 100,
          left: -20,
          child: _FloatingIcon(
            icon: Icons.eco_rounded,
            size: 100,
            color: AppTheme.sage,
            duration: 4000,
          ),
        ),
        const Positioned(
          bottom: 200,
          right: -30,
          child: _FloatingIcon(
            icon: Icons.water_drop_rounded,
            size: 120,
            color: AppTheme.earth,
            duration: 5500,
          ),
        ),
        const Positioned(
          top: 300,
          right: 20,
          child: _FloatingIcon(
            icon: Icons.wb_sunny_rounded,
            size: 80,
            color: AppTheme.moss,
            duration: 4500,
          ),
        ),
        const Positioned(
          bottom: 100,
          left: 40,
          child: _FloatingIcon(
            icon: Icons.park_rounded,
            size: 90,
            color: AppTheme.forest,
            duration: 6000,
          ),
        ),
        Positioned.fill(child: child),
      ],
    );
  }
}
class OrganicBackgroundEnhanced extends StatelessWidget {
  final Widget child;
  const OrganicBackgroundEnhanced({super.key, required this.child});
  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(child: CustomPaint(painter: _TopographicPainter())),
        const Positioned(
          top: -100,
          left: -100,
          child: _GlowingOrb(
            size: 400,
            color: AppTheme.sage,
            duration: 8000,
            offsetX: 50,
            offsetY: 30,
          ),
        ),
        const Positioned(
          bottom: -150,
          right: -100,
          child: _GlowingOrb(
            size: 500,
            color: AppTheme.moss,
            duration: 10000,
            offsetX: -40,
            offsetY: -60,
          ),
        ),
        const Positioned(
          top: 300,
          right: -150,
          child: _GlowingOrb(
            size: 450,
            color: AppTheme.earth,
            duration: 12000,
            offsetX: -60,
            offsetY: 50,
          ),
        ),
        Positioned(
          top: 120,
          left: 30,
          child: _FloatingShape(
            size: 40,
            color: AppTheme.earth,
            duration: 5800,
            shape: _ShapeType.circle,
          ),
        ),
        Positioned(
          bottom: 180,
          left: 50,
          child: _FloatingShape(
            size: 35,
            color: AppTheme.sage,
            duration: 4200,
            shape: _ShapeType.square,
          ),
        ),
        Positioned(
          top: 550,
          right: 100,
          child: _FloatingShape(
            size: 50,
            color: AppTheme.moss,
            duration: 6200,
            shape: _ShapeType.circle,
          ),
        ),
        Positioned.fill(child: child),
      ],
    );
  }
}
class _GlowingOrb extends StatelessWidget {
  final double size;
  final Color color;
  final int duration;
  final double offsetX;
  final double offsetY;
  const _GlowingOrb({
    required this.size,
    required this.color,
    required this.duration,
    required this.offsetX,
    required this.offsetY,
  });
  @override
  Widget build(BuildContext context) {
    return Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color.withOpacity(0.15),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.1),
                blurRadius: size / 2,
                spreadRadius: size / 4,
              ),
            ],
          ),
        )
        .animate(onPlay: (controller) => controller.repeat(reverse: true))
        .move(
          duration: duration.ms,
          curve: Curves.easeInOutSine,
          begin: const Offset(0, 0),
          end: Offset(offsetX, offsetY),
        )
        .scale(
          duration: (duration * 1.2).toInt().ms,
          curve: Curves.easeInOut,
          begin: const Offset(1.0, 1.0),
          end: const Offset(1.15, 1.15),
        );
  }
}
class _FloatingIcon extends StatelessWidget {
  final IconData icon;
  final double size;
  final Color color;
  final int duration;
  const _FloatingIcon({
    required this.icon,
    required this.size,
    required this.color,
    required this.duration,
  });
  @override
  Widget build(BuildContext context) {
    return Icon(icon, size: size, color: color.withOpacity(0.06))
        .animate(onPlay: (controller) => controller.repeat(reverse: true))
        .slideY(
          begin: -0.05,
          end: 0.05,
          duration: duration.ms,
          curve: Curves.easeInOutSine,
        )
        .rotate(
          begin: -0.02,
          end: 0.02,
          duration: (duration + 800).ms,
          curve: Curves.easeInOutSine,
        );
  }
}
enum _ShapeType { circle, square, triangle, diamond }
class OrganicBackgroundSignUp extends StatelessWidget {
  final Widget child;
  const OrganicBackgroundSignUp({super.key, required this.child});
  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(child: CustomPaint(painter: _TopographicPainter())),
        const Positioned(
          top: 80,
          left: -10,
          child: _FloatingIcon(
            icon: Icons.eco_rounded,
            size: 90,
            color: AppTheme.earth,
            duration: 4200,
          ),
        ),
        const Positioned(
          top: 200,
          right: -20,
          child: _FloatingIcon(
            icon: Icons.water_drop_rounded,
            size: 110,
            color: AppTheme.sage,
            duration: 5000,
          ),
        ),
        const Positioned(
          bottom: 300,
          left: 30,
          child: _FloatingIcon(
            icon: Icons.wb_sunny_rounded,
            size: 85,
            color: AppTheme.earth,
            duration: 4700,
          ),
        ),
        const Positioned(
          top: 400,
          right: 50,
          child: _FloatingIcon(
            icon: Icons.cloud_rounded,
            size: 70,
            color: AppTheme.moss,
            duration: 5800,
          ),
        ),
        const Positioned(
          bottom: 80,
          right: 40,
          child: _FloatingIcon(
            icon: Icons.favorite_rounded,
            size: 65,
            color: AppTheme.earth,
            duration: 6100,
          ),
        ),
        Positioned(
          top: 150,
          right: 40,
          child: _FloatingShape(
            size: 45,
            color: AppTheme.moss,
            duration: 5400,
            shape: _ShapeType.triangle,
          ),
        ),
        Positioned(
          bottom: 200,
          right: 30,
          child: _FloatingShape(
            size: 50,
            color: AppTheme.earth,
            duration: 6300,
            shape: _ShapeType.diamond,
          ),
        ),
        Positioned(
          top: 500,
          left: 50,
          child: _FloatingShape(
            size: 38,
            color: AppTheme.sage,
            duration: 4900,
            shape: _ShapeType.triangle,
          ),
        ),
        Positioned(
          bottom: 120,
          left: 60,
          child: _FloatingShape(
            size: 42,
            color: AppTheme.moss,
            duration: 5600,
            shape: _ShapeType.square,
          ),
        ),
        Positioned.fill(child: child),
      ],
    );
  }
}
class _FloatingShape extends StatelessWidget {
  final double size;
  final Color color;
  final int duration;
  final _ShapeType shape;
  const _FloatingShape({
    required this.size,
    required this.color,
    required this.duration,
    required this.shape,
  });
  @override
  Widget build(BuildContext context) {
    Widget shapeWidget;
    switch (shape) {
      case _ShapeType.circle:
        shapeWidget = Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: color.withOpacity(0.08),
            shape: BoxShape.circle,
          ),
        );
      case _ShapeType.square:
        shapeWidget = Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: color.withOpacity(0.08),
            borderRadius: BorderRadius.circular(8),
          ),
        );
      case _ShapeType.triangle:
        shapeWidget = CustomPaint(
          size: Size(size, size),
          painter: _TrianglePainter(color: color),
        );
      case _ShapeType.diamond:
        shapeWidget = CustomPaint(
          size: Size(size, size),
          painter: _DiamondPainter(color: color),
        );
    }
    return shapeWidget
        .animate(onPlay: (controller) => controller.repeat(reverse: true))
        .slideY(
          begin: -0.08,
          end: 0.08,
          duration: duration.ms,
          curve: Curves.easeInOutSine,
        )
        .scale(
          begin: const Offset(1, 1),
          end: const Offset(1.1, 1.1),
          duration: (duration + 500).ms,
          curve: Curves.easeInOutSine,
        );
  }
}
class _TrianglePainter extends CustomPainter {
  final Color color;
  _TrianglePainter({required this.color});
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withOpacity(0.08)
      ..style = PaintingStyle.fill;
    final path = Path();
    path.moveTo(size.width / 2, 0);
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();
    canvas.drawPath(path, paint);
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
class _DiamondPainter extends CustomPainter {
  final Color color;
  _DiamondPainter({required this.color});
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withOpacity(0.08)
      ..style = PaintingStyle.fill;
    final path = Path();
    path.moveTo(size.width / 2, 0);
    path.lineTo(size.width, size.height / 2);
    path.lineTo(size.width / 2, size.height);
    path.lineTo(0, size.height / 2);
    path.close();
    canvas.drawPath(path, paint);
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
class _TopographicPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppTheme.forest.withOpacity(0.04)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    final path = Path();
    for (int i = 0; i < 15; i++) {
      double offset = i * 40.0;
      path.moveTo(0, size.height * 0.3 + offset);
      path.quadraticBezierTo(
        size.width * 0.4,
        size.height * 0.1 + offset * 1.5,
        size.width,
        size.height * 0.4 + offset,
      );
      path.moveTo(0, size.height * 0.8 - offset);
      path.quadraticBezierTo(
        size.width * 0.6,
        size.height * 0.95 - offset * 1.2,
        size.width,
        size.height * 0.7 - offset,
      );
    }
    final dotPaint = Paint()
      ..color = AppTheme.forest.withOpacity(0.02)
      ..style = PaintingStyle.fill;
    for (double x = 0; x < size.width; x += 12) {
      for (double y = 0; y < size.height; y += 12) {
        if ((x + y) % 5 == 0) {
          canvas.drawCircle(Offset(x, y), 0.5, dotPaint);
        }
      }
    }
    canvas.drawPath(path, paint);
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
class AtmosphericParticleOverlay extends StatelessWidget {
  final Color baseColor;
  const AtmosphericParticleOverlay({super.key, required this.baseColor});
  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Stack(
        children: List.generate(12, (i) {
          final xPos = (i * 137 % 100) / 100.0;
          final yPos = (i * 251 % 100) / 100.0;
          return Positioned(
            left: xPos * MediaQuery.of(context).size.width,
            top: yPos * MediaQuery.of(context).size.height,
            child: _FloatingPoint(
              color: baseColor,
              duration: 5000 + (i * 450 % 4000),
            ),
          );
        }),
      ),
    );
  }
}
class _FloatingPoint extends StatelessWidget {
  final Color color;
  final int duration;
  const _FloatingPoint({required this.color, required this.duration});
  @override
  Widget build(BuildContext context) {
    return Container(
          width: 5,
          height: 5,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color.withOpacity(0.4),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.3),
                blurRadius: 6,
                spreadRadius: 2,
              ),
            ],
          ),
        )
        .animate(onPlay: (c) => c.repeat(reverse: true))
        .moveY(
          begin: 20,
          end: -40,
          duration: duration.ms,
          curve: Curves.easeInOutSine,
        )
        .moveX(
          begin: -15,
          end: 15,
          duration: (duration * 1.3).toInt().ms,
          curve: Curves.easeInOutSine,
        )
        .scale(
          begin: const Offset(0.5, 0.5),
          end: const Offset(1.2, 1.2),
          duration: duration.ms,
        )
        .fadeOut(duration: duration.ms);
  }
}
