import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme.dart';

class TalkingCharacter extends StatefulWidget {
  final bool isTalking;
  const TalkingCharacter({super.key, required this.isTalking});
  @override
  State<TalkingCharacter> createState() => _TalkingCharacterState();
}

class _TalkingCharacterState extends State<TalkingCharacter>
    with SingleTickerProviderStateMixin {
  late AnimationController _mouthController;
  @override
  void initState() {
    super.initState();
    _mouthController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    if (widget.isTalking) {
      _mouthController.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(covariant TalkingCharacter oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isTalking != oldWidget.isTalking) {
      if (widget.isTalking) {
        _mouthController.repeat(reverse: true);
      } else {
        _mouthController.animateTo(
          0,
          duration: const Duration(milliseconds: 100),
        );
      }
    }
  }

  @override
  void dispose() {
    _mouthController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
          width: 140,
          height: 140,
          decoration: BoxDecoration(
            color: AppTheme.stone,
            shape: BoxShape.circle,
            border: Border.all(color: AppTheme.moss.withOpacity(0.5), width: 4),
            boxShadow: [
              BoxShadow(
                color: AppTheme.moss.withOpacity(0.2),
                blurRadius: 24,
                spreadRadius: 8,
              ),
            ],
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Positioned(
                top: -10,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(width: 4, height: 20, color: AppTheme.earth),
                    const SizedBox(width: 40),
                    Container(width: 4, height: 20, color: AppTheme.earth),
                  ],
                ),
              ),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildEye(),
                      const SizedBox(width: 32),
                      _buildEye(),
                    ],
                  ),
                  const SizedBox(height: 20),
                  AnimatedBuilder(
                    animation: _mouthController,
                    builder: (context, child) {
                      final height = 4.0 + (_mouthController.value * 24.0);
                      final width = 40.0 - (_mouthController.value * 10.0);
                      return Container(
                        width: width,
                        height: height,
                        decoration: BoxDecoration(
                          color: AppTheme.forest,
                          borderRadius: BorderRadius.circular(10),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
        )
        .animate(onPlay: (c) => c.repeat(reverse: true))
        .slideY(
          begin: -0.05,
          end: 0.05,
          duration: 2.seconds,
          curve: Curves.easeInOutSine,
        );
  }

  Widget _buildEye() {
    return Container(
          width: 16,
          height: 16,
          decoration: const BoxDecoration(
            color: AppTheme.forest,
            shape: BoxShape.circle,
          ),
        )
        .animate(onPlay: (c) => c.repeat())
        .scaleY(begin: 1, end: 1, duration: 4.seconds)
        .then(duration: 50.ms)
        .scaleY(begin: 1, end: 0.1)
        .then(duration: 50.ms)
        .scaleY(begin: 0.1, end: 1)
        .then(duration: 1.seconds);
  }
}
